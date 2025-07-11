#!/usr/bin/env python3
"""
QuickSight Dashboard Deployment Script
Automates the creation of QuickSight dashboards using the JSON templates
"""

import json
import boto3
import os
import sys
from typing import Dict, Any
import argparse
from botocore.exceptions import ClientError

class QuickSightDashboardDeployer:
    def __init__(self, region: str = 'ap-south-1', profile: str = None):
        """Initialize the QuickSight client"""
        session = boto3.Session(profile_name=profile) if profile else boto3.Session()
        self.quicksight = session.client('quicksight', region_name=region)
        self.sts = session.client('sts', region_name=region)
        self.region = region
        
        # Get AWS account ID
        self.account_id = self.sts.get_caller_identity()['Account']
        
    def load_template(self, template_path: str) -> Dict[str, Any]:
        """Load dashboard template from JSON file"""
        try:
            with open(template_path, 'r') as f:
                return json.load(f)
        except FileNotFoundError:
            print(f"❌ Template file not found: {template_path}")
            sys.exit(1)
        except json.JSONDecodeError as e:
            print(f"❌ Invalid JSON in template: {e}")
            sys.exit(1)
    
    def replace_placeholders(self, template: Dict[str, Any], replacements: Dict[str, str]) -> Dict[str, Any]:
        """Replace placeholder values in the template"""
        template_str = json.dumps(template)
        
        for placeholder, value in replacements.items():
            template_str = template_str.replace(placeholder, value)
        
        return json.loads(template_str)
    
    def create_dashboard(self, dashboard_id: str, template: Dict[str, Any]) -> bool:
        """Create a QuickSight dashboard"""
        try:
            print(f"🔄 Creating dashboard: {template['name']}")
            
            response = self.quicksight.create_dashboard(
                AwsAccountId=self.account_id,
                DashboardId=dashboard_id,
                Name=template['name'],
                Definition=template['definition'],
                VersionDescription=f"Initial version created by deployment script",
                DashboardPublishOptions={
                    'AdHocFilteringOption': {
                        'AvailabilityStatus': 'ENABLED'
                    },
                    'ExportToCSVOption': {
                        'AvailabilityStatus': 'ENABLED'
                    },
                    'SheetControlsOption': {
                        'VisibilityState': 'EXPANDED'
                    }
                },
                ThemeArn=template.get('themeArn', 'arn:aws:quicksight::aws:theme/SEASIDE')
            )
            
            print(f"✅ Dashboard created successfully: {dashboard_id}")
            print(f"   Dashboard ARN: {response['Arn']}")
            print(f"   Dashboard URL: https://{self.region}.quicksight.aws.amazon.com/sn/dashboards/{dashboard_id}")
            return True
            
        except ClientError as e:
            error_code = e.response['Error']['Code']
            if error_code == 'ResourceExistsException':
                print(f"⚠️  Dashboard already exists: {dashboard_id}")
                return self.update_dashboard(dashboard_id, template)
            else:
                print(f"❌ Failed to create dashboard: {e}")
                return False
    
    def update_dashboard(self, dashboard_id: str, template: Dict[str, Any]) -> bool:
        """Update an existing QuickSight dashboard"""
        try:
            print(f"🔄 Updating dashboard: {template['name']}")
            
            response = self.quicksight.update_dashboard(
                AwsAccountId=self.account_id,
                DashboardId=dashboard_id,
                Name=template['name'],
                Definition=template['definition'],
                VersionDescription=f"Updated by deployment script",
                DashboardPublishOptions={
                    'AdHocFilteringOption': {
                        'AvailabilityStatus': 'ENABLED'
                    },
                    'ExportToCSVOption': {
                        'AvailabilityStatus': 'ENABLED'
                    },
                    'SheetControlsOption': {
                        'VisibilityState': 'EXPANDED'
                    }
                },
                ThemeArn=template.get('themeArn', 'arn:aws:quicksight::aws:theme/SEASIDE')
            )
            
            print(f"✅ Dashboard updated successfully: {dashboard_id}")
            return True
            
        except ClientError as e:
            print(f"❌ Failed to update dashboard: {e}")
            return False
    
    def get_dataset_arns(self, project_name: str, environment: str) -> Dict[str, str]:
        """Get dataset ARNs for the project"""
        dataset_mapping = {
            'SALES_TRENDS_DATASET_ARN': f'arn:aws:quicksight:{self.region}:{self.account_id}:dataset/{project_name}-{environment}-sales-trends',
            'CUSTOMER_360_DATASET_ARN': f'arn:aws:quicksight:{self.region}:{self.account_id}:dataset/{project_name}-{environment}-customer-360',
            'PRODUCT_PERFORMANCE_DATASET_ARN': f'arn:aws:quicksight:{self.region}:{self.account_id}:dataset/{project_name}-{environment}-product-performance',
            'GEOGRAPHIC_SALES_DATASET_ARN': f'arn:aws:quicksight:{self.region}:{self.account_id}:dataset/{project_name}-{environment}-geographic-sales'
        }
        return dataset_mapping
    
    def deploy_all_dashboards(self, project_name: str, environment: str, template_dir: str):
        """Deploy all dashboards"""
        print(f"🚀 Starting QuickSight dashboard deployment for {project_name}-{environment}")
        print(f"   Region: {self.region}")
        print(f"   Account ID: {self.account_id}")
        print("=" * 60)
        
        # Get dataset ARNs
        dataset_arns = self.get_dataset_arns(project_name, environment)
        
        # Dashboard configurations
        dashboards = [
            {
                'id': f'{project_name}-{environment}-executive-dashboard',
                'template': 'executive_dashboard.json',
                'name': 'Executive Dashboard'
            },
            {
                'id': f'{project_name}-{environment}-customer-dashboard',
                'template': 'customer_dashboard.json',
                'name': 'Customer Analytics Dashboard'
            },
            {
                'id': f'{project_name}-{environment}-product-dashboard',
                'template': 'product_dashboard.json',
                'name': 'Product Performance Dashboard'
            },
            {
                'id': f'{project_name}-{environment}-operational-dashboard',
                'template': 'operational_dashboard.json',
                'name': 'Operational Dashboard'
            }
        ]
        
        success_count = 0
        total_count = len(dashboards)
        
        for dashboard in dashboards:
            print(f"\n📊 Processing {dashboard['name']}...")
            
            # Load template
            template_path = os.path.join(template_dir, dashboard['template'])
            template = self.load_template(template_path)
            
            # Replace placeholders
            template = self.replace_placeholders(template, dataset_arns)
            
            # Create/update dashboard
            if self.create_dashboard(dashboard['id'], template):
                success_count += 1
        
        print("\n" + "=" * 60)
        print(f"🎉 Deployment completed: {success_count}/{total_count} dashboards successful")
        
        if success_count == total_count:
            print("✅ All dashboards deployed successfully!")
            print(f"\n🌐 Access your dashboards at:")
            print(f"   https://{self.region}.quicksight.aws.amazon.com/sn/start")
        else:
            print("⚠️  Some dashboards failed to deploy. Check the logs above.")

def main():
    parser = argparse.ArgumentParser(description='Deploy QuickSight dashboards')
    parser.add_argument('--project-name', required=True, help='Project name (e.g., ecommerce-dwh)')
    parser.add_argument('--environment', required=True, help='Environment (dev, staging, prod)')
    parser.add_argument('--region', default='ap-south-1', help='AWS region')
    parser.add_argument('--profile', help='AWS profile to use')
    parser.add_argument('--template-dir', help='Directory containing dashboard templates')
    
    args = parser.parse_args()
    
    # Set template directory
    if not args.template_dir:
        script_dir = os.path.dirname(os.path.abspath(__file__))
        args.template_dir = os.path.join(os.path.dirname(script_dir), 'dashboard_templates')
    
    # Initialize deployer
    deployer = QuickSightDashboardDeployer(region=args.region, profile=args.profile)
    
    # Deploy dashboards
    deployer.deploy_all_dashboards(args.project_name, args.environment, args.template_dir)

if __name__ == '__main__':
    main()
