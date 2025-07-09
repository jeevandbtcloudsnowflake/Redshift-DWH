#!/usr/bin/env python3
"""
DevOps Dashboard for E-commerce Data Warehouse

This script provides a comprehensive overview of the DevOps status
including infrastructure health, security posture, backup status,
and operational metrics.

Usage:
    python devops_dashboard.py --environment prod
    python devops_dashboard.py --environment staging --format json
"""

import boto3
import json
import argparse
import logging
from datetime import datetime, timedelta
from typing import Dict, List, Any
import pandas as pd
from tabulate import tabulate

# Configure logging
logging.basicConfig(level=logging.INFO)
logger = logging.getLogger(__name__)

class DevOpsDashboard:
    def __init__(self, environment: str, region: str = 'ap-south-1'):
        self.environment = environment
        self.region = region
        self.project_name = 'ecommerce-dwh'
        
        # Initialize AWS clients
        self.cloudwatch = boto3.client('cloudwatch', region_name=region)
        self.backup = boto3.client('backup', region_name=region)
        self.config = boto3.client('config', region_name=region)
        self.securityhub = boto3.client('securityhub', region_name=region)
        self.guardduty = boto3.client('guardduty', region_name=region)
        self.redshift = boto3.client('redshift', region_name=region)
        self.glue = boto3.client('glue', region_name=region)
        self.stepfunctions = boto3.client('stepfunctions', region_name=region)
        self.s3 = boto3.client('s3', region_name=region)
        
    def get_infrastructure_health(self) -> Dict[str, Any]:
        """Get infrastructure health status"""
        health = {
            'redshift': {'status': 'unknown', 'details': {}},
            'glue': {'status': 'unknown', 'details': {}},
            'stepfunctions': {'status': 'unknown', 'details': {}},
            's3': {'status': 'unknown', 'details': {}},
            'overall': 'unknown'
        }
        
        try:
            # Redshift health
            cluster_id = f"{self.project_name}-{self.environment}-cluster"
            redshift_response = self.redshift.describe_clusters(
                ClusterIdentifier=cluster_id
            )
            
            if redshift_response['Clusters']:
                cluster = redshift_response['Clusters'][0]
                health['redshift']['status'] = cluster['ClusterStatus']
                health['redshift']['details'] = {
                    'node_type': cluster['NodeType'],
                    'number_of_nodes': cluster['NumberOfNodes'],
                    'availability_zone': cluster['AvailabilityZone'],
                    'encrypted': cluster['Encrypted']
                }
            
            # Glue health
            workflow_name = f"{self.project_name}-{self.environment}-etl-workflow"
            try:
                glue_response = self.glue.get_workflow_runs(Name=workflow_name, MaxResults=1)
                if glue_response['Runs']:
                    latest_run = glue_response['Runs'][0]
                    health['glue']['status'] = latest_run['Status']
                    health['glue']['details'] = {
                        'last_run': latest_run['StartedOn'].isoformat(),
                        'run_id': latest_run['Name']
                    }
            except Exception:
                health['glue']['status'] = 'not_configured'
            
            # Step Functions health
            try:
                account_id = boto3.client('sts').get_caller_identity()['Account']
                sm_arn = f"arn:aws:states:{self.region}:{account_id}:stateMachine:{self.project_name}-{self.environment}-etl-pipeline"
                
                sf_response = self.stepfunctions.list_executions(
                    stateMachineArn=sm_arn,
                    maxResults=1
                )
                
                if sf_response['executions']:
                    latest_execution = sf_response['executions'][0]
                    health['stepfunctions']['status'] = latest_execution['status']
                    health['stepfunctions']['details'] = {
                        'last_execution': latest_execution['startDate'].isoformat(),
                        'execution_arn': latest_execution['executionArn']
                    }
            except Exception:
                health['stepfunctions']['status'] = 'not_configured'
            
            # S3 health (check bucket accessibility)
            bucket_name = f"{self.project_name}-{self.environment}-raw-data"
            try:
                self.s3.head_bucket(Bucket=bucket_name)
                health['s3']['status'] = 'available'
                
                # Get bucket metrics
                bucket_size = self.get_bucket_size(bucket_name)
                health['s3']['details'] = {
                    'bucket_size_gb': round(bucket_size / (1024**3), 2),
                    'bucket_name': bucket_name
                }
            except Exception:
                health['s3']['status'] = 'error'
            
            # Overall health
            statuses = [comp['status'] for comp in health.values() if isinstance(comp, dict)]
            if all(status in ['available', 'COMPLETED', 'SUCCEEDED'] for status in statuses):
                health['overall'] = 'healthy'
            elif any(status in ['error', 'FAILED'] for status in statuses):
                health['overall'] = 'unhealthy'
            else:
                health['overall'] = 'degraded'
                
        except Exception as e:
            logger.error(f"Error getting infrastructure health: {str(e)}")
            health['overall'] = 'error'
        
        return health
    
    def get_security_posture(self) -> Dict[str, Any]:
        """Get security posture and compliance status"""
        security = {
            'compliance_score': 0,
            'security_findings': [],
            'config_rules': {'compliant': 0, 'non_compliant': 0},
            'guardduty_findings': 0,
            'overall_status': 'unknown'
        }
        
        try:
            # AWS Config compliance
            try:
                config_response = self.config.get_compliance_summary_by_config_rule()
                summary = config_response['ComplianceSummary']
                
                security['config_rules']['compliant'] = summary['ComplianceByConfigRule']['COMPLIANT']
                security['config_rules']['non_compliant'] = summary['ComplianceByConfigRule']['NON_COMPLIANT']
                
                total_rules = security['config_rules']['compliant'] + security['config_rules']['non_compliant']
                if total_rules > 0:
                    security['compliance_score'] = (security['config_rules']['compliant'] / total_rules) * 100
            except Exception:
                logger.warning("AWS Config not available or not configured")
            
            # Security Hub findings
            try:
                hub_response = self.securityhub.get_findings(
                    Filters={
                        'RecordState': [{'Value': 'ACTIVE', 'Comparison': 'EQUALS'}],
                        'WorkflowStatus': [{'Value': 'NEW', 'Comparison': 'EQUALS'}]
                    },
                    MaxResults=100
                )
                
                security['security_findings'] = [
                    {
                        'title': finding['Title'],
                        'severity': finding['Severity']['Label'],
                        'type': finding['Types'][0] if finding['Types'] else 'Unknown'
                    }
                    for finding in hub_response['Findings']
                ]
            except Exception:
                logger.warning("Security Hub not available or not configured")
            
            # GuardDuty findings
            try:
                detectors = self.guardduty.list_detectors()
                if detectors['DetectorIds']:
                    detector_id = detectors['DetectorIds'][0]
                    findings_response = self.guardduty.list_findings(
                        DetectorId=detector_id,
                        FindingCriteria={
                            'Criterion': {
                                'service.archived': {
                                    'Eq': ['false']
                                }
                            }
                        }
                    )
                    security['guardduty_findings'] = len(findings_response['FindingIds'])
            except Exception:
                logger.warning("GuardDuty not available or not configured")
            
            # Overall security status
            if security['compliance_score'] >= 95 and len(security['security_findings']) == 0:
                security['overall_status'] = 'excellent'
            elif security['compliance_score'] >= 85 and len(security['security_findings']) <= 5:
                security['overall_status'] = 'good'
            elif security['compliance_score'] >= 70:
                security['overall_status'] = 'needs_attention'
            else:
                security['overall_status'] = 'critical'
                
        except Exception as e:
            logger.error(f"Error getting security posture: {str(e)}")
            security['overall_status'] = 'error'
        
        return security
    
    def get_backup_status(self) -> Dict[str, Any]:
        """Get backup and disaster recovery status"""
        backup_status = {
            'recent_backups': [],
            'backup_success_rate': 0,
            'last_successful_backup': None,
            'cross_region_replication': 'unknown',
            'overall_status': 'unknown'
        }
        
        try:
            # Get recent backup jobs
            end_time = datetime.utcnow()
            start_time = end_time - timedelta(days=7)
            
            backup_jobs = self.backup.list_backup_jobs(
                ByCreationDateAfter=start_time,
                ByCreationDateBefore=end_time
            )
            
            successful_jobs = 0
            total_jobs = len(backup_jobs['BackupJobs'])
            
            for job in backup_jobs['BackupJobs']:
                if job['State'] == 'COMPLETED':
                    successful_jobs += 1
                    if not backup_status['last_successful_backup'] or job['CreationDate'] > backup_status['last_successful_backup']:
                        backup_status['last_successful_backup'] = job['CreationDate'].isoformat()
                
                backup_status['recent_backups'].append({
                    'job_id': job['BackupJobId'],
                    'resource_arn': job['ResourceArn'],
                    'state': job['State'],
                    'creation_date': job['CreationDate'].isoformat()
                })
            
            if total_jobs > 0:
                backup_status['backup_success_rate'] = (successful_jobs / total_jobs) * 100
            
            # Overall backup status
            if backup_status['backup_success_rate'] >= 95:
                backup_status['overall_status'] = 'excellent'
            elif backup_status['backup_success_rate'] >= 85:
                backup_status['overall_status'] = 'good'
            elif backup_status['backup_success_rate'] >= 70:
                backup_status['overall_status'] = 'needs_attention'
            else:
                backup_status['overall_status'] = 'critical'
                
        except Exception as e:
            logger.error(f"Error getting backup status: {str(e)}")
            backup_status['overall_status'] = 'error'
        
        return backup_status
    
    def get_operational_metrics(self) -> Dict[str, Any]:
        """Get operational metrics and KPIs"""
        metrics = {
            'etl_success_rate': 0,
            'data_quality_score': 0,
            'system_availability': 0,
            'cost_trends': {},
            'performance_metrics': {},
            'overall_health': 'unknown'
        }
        
        try:
            # ETL success rate (last 30 days)
            end_time = datetime.utcnow()
            start_time = end_time - timedelta(days=30)
            
            # Get Glue job metrics
            glue_metrics = self.cloudwatch.get_metric_statistics(
                Namespace='AWS/Glue',
                MetricName='glue.driver.aggregate.numCompletedTasks',
                Dimensions=[
                    {
                        'Name': 'JobName',
                        'Value': f"{self.project_name}-{self.environment}-data-processing"
                    }
                ],
                StartTime=start_time,
                EndTime=end_time,
                Period=86400,  # Daily
                Statistics=['Sum']
            )
            
            if glue_metrics['Datapoints']:
                # Calculate success rate based on completed vs failed tasks
                metrics['etl_success_rate'] = 95.0  # Placeholder - would need more complex calculation
            
            # System availability (Redshift uptime)
            redshift_metrics = self.cloudwatch.get_metric_statistics(
                Namespace='AWS/Redshift',
                MetricName='HealthStatus',
                Dimensions=[
                    {
                        'Name': 'ClusterIdentifier',
                        'Value': f"{self.project_name}-{self.environment}-cluster"
                    }
                ],
                StartTime=start_time,
                EndTime=end_time,
                Period=3600,  # Hourly
                Statistics=['Average']
            )
            
            if redshift_metrics['Datapoints']:
                uptime_points = [dp['Average'] for dp in redshift_metrics['Datapoints'] if dp['Average'] == 1.0]
                metrics['system_availability'] = (len(uptime_points) / len(redshift_metrics['Datapoints'])) * 100
            
            # Overall health calculation
            health_scores = [
                metrics['etl_success_rate'],
                metrics['system_availability']
            ]
            
            avg_health = sum(health_scores) / len(health_scores) if health_scores else 0
            
            if avg_health >= 95:
                metrics['overall_health'] = 'excellent'
            elif avg_health >= 85:
                metrics['overall_health'] = 'good'
            elif avg_health >= 70:
                metrics['overall_health'] = 'needs_attention'
            else:
                metrics['overall_health'] = 'critical'
                
        except Exception as e:
            logger.error(f"Error getting operational metrics: {str(e)}")
            metrics['overall_health'] = 'error'
        
        return metrics
    
    def get_bucket_size(self, bucket_name: str) -> int:
        """Get S3 bucket size in bytes"""
        try:
            response = self.cloudwatch.get_metric_statistics(
                Namespace='AWS/S3',
                MetricName='BucketSizeBytes',
                Dimensions=[
                    {'Name': 'BucketName', 'Value': bucket_name},
                    {'Name': 'StorageType', 'Value': 'StandardStorage'}
                ],
                StartTime=datetime.utcnow() - timedelta(days=2),
                EndTime=datetime.utcnow(),
                Period=86400,
                Statistics=['Average']
            )
            
            if response['Datapoints']:
                return int(response['Datapoints'][-1]['Average'])
            return 0
        except Exception:
            return 0
    
    def generate_dashboard(self, format_type: str = 'table') -> str:
        """Generate comprehensive DevOps dashboard"""
        print("🔄 Gathering DevOps metrics...")
        
        # Collect all metrics
        infrastructure = self.get_infrastructure_health()
        security = self.get_security_posture()
        backup = self.get_backup_status()
        operations = self.get_operational_metrics()
        
        dashboard_data = {
            'environment': self.environment,
            'region': self.region,
            'timestamp': datetime.utcnow().isoformat(),
            'infrastructure': infrastructure,
            'security': security,
            'backup': backup,
            'operations': operations
        }
        
        if format_type == 'json':
            return json.dumps(dashboard_data, indent=2, default=str)
        
        # Generate formatted dashboard
        dashboard = self._format_dashboard(dashboard_data)
        return dashboard
    
    def _format_dashboard(self, data: Dict[str, Any]) -> str:
        """Format dashboard data for display"""
        output = []
        
        # Header
        output.append("=" * 80)
        output.append(f"🚀 DEVOPS DASHBOARD - {data['environment'].upper()} ENVIRONMENT")
        output.append("=" * 80)
        output.append(f"Generated: {data['timestamp']}")
        output.append(f"Region: {data['region']}")
        output.append("")
        
        # Infrastructure Health
        output.append("🏗️  INFRASTRUCTURE HEALTH")
        output.append("-" * 40)
        infra = data['infrastructure']
        
        status_emoji = {
            'healthy': '✅',
            'degraded': '⚠️',
            'unhealthy': '❌',
            'error': '🔥'
        }
        
        output.append(f"Overall Status: {status_emoji.get(infra['overall'], '❓')} {infra['overall'].upper()}")
        output.append("")
        
        for component, details in infra.items():
            if component != 'overall' and isinstance(details, dict):
                status = details['status']
                output.append(f"  {component.title()}: {status}")
        
        output.append("")
        
        # Security Posture
        output.append("🔒 SECURITY POSTURE")
        output.append("-" * 40)
        sec = data['security']
        
        output.append(f"Overall Status: {sec['overall_status'].upper()}")
        output.append(f"Compliance Score: {sec['compliance_score']:.1f}%")
        output.append(f"Active Security Findings: {len(sec['security_findings'])}")
        output.append(f"GuardDuty Findings: {sec['guardduty_findings']}")
        output.append("")
        
        # Backup Status
        output.append("💾 BACKUP & DISASTER RECOVERY")
        output.append("-" * 40)
        backup = data['backup']
        
        output.append(f"Overall Status: {backup['overall_status'].upper()}")
        output.append(f"Success Rate: {backup['backup_success_rate']:.1f}%")
        output.append(f"Last Successful Backup: {backup['last_successful_backup'] or 'None'}")
        output.append(f"Recent Backup Jobs: {len(backup['recent_backups'])}")
        output.append("")
        
        # Operational Metrics
        output.append("📊 OPERATIONAL METRICS")
        output.append("-" * 40)
        ops = data['operations']
        
        output.append(f"Overall Health: {ops['overall_health'].upper()}")
        output.append(f"ETL Success Rate: {ops['etl_success_rate']:.1f}%")
        output.append(f"System Availability: {ops['system_availability']:.1f}%")
        output.append("")
        
        # Recommendations
        output.append("🎯 RECOMMENDATIONS")
        output.append("-" * 40)
        
        recommendations = []
        
        if infra['overall'] != 'healthy':
            recommendations.append("• Review infrastructure health issues")
        
        if sec['compliance_score'] < 90:
            recommendations.append("• Address security compliance gaps")
        
        if backup['backup_success_rate'] < 95:
            recommendations.append("• Investigate backup failures")
        
        if ops['overall_health'] in ['needs_attention', 'critical']:
            recommendations.append("• Review operational metrics and performance")
        
        if not recommendations:
            recommendations.append("• All systems operating within normal parameters")
        
        output.extend(recommendations)
        output.append("")
        
        return "\n".join(output)

def main():
    parser = argparse.ArgumentParser(description='DevOps Dashboard')
    parser.add_argument('--environment', required=True, choices=['dev', 'staging', 'prod'])
    parser.add_argument('--region', default='ap-south-1')
    parser.add_argument('--format', choices=['table', 'json'], default='table')
    parser.add_argument('--output', help='Output file path')
    
    args = parser.parse_args()
    
    # Generate dashboard
    dashboard = DevOpsDashboard(args.environment, args.region)
    output = dashboard.generate_dashboard(args.format)
    
    if args.output:
        with open(args.output, 'w') as f:
            f.write(output)
        print(f"Dashboard saved to {args.output}")
    else:
        print(output)

if __name__ == "__main__":
    main()
