#!/usr/bin/env python3
"""
Environment Validation Script

This script validates the AWS environment and prerequisites
before deploying the infrastructure.
"""

import boto3
import json
import sys
import subprocess
from botocore.exceptions import ClientError, NoCredentialsError
from typing import Dict, List, Tuple

class EnvironmentValidator:
    def __init__(self, region: str = 'ap-south-1'):
        self.region = region
        self.validation_results = []
        
    def validate_aws_credentials(self) -> Tuple[bool, str]:
        """Validate AWS credentials and permissions"""
        try:
            sts_client = boto3.client('sts', region_name=self.region)
            identity = sts_client.get_caller_identity()
            
            account_id = identity['Account']
            user_arn = identity['Arn']
            
            return True, f"✅ AWS credentials valid - Account: {account_id}, User: {user_arn}"
            
        except NoCredentialsError:
            return False, "❌ AWS credentials not found. Please run 'aws configure'"
        except ClientError as e:
            return False, f"❌ AWS credentials error: {e}"
    
    def validate_aws_region(self) -> Tuple[bool, str]:
        """Validate AWS region availability"""
        try:
            ec2_client = boto3.client('ec2', region_name=self.region)
            regions = ec2_client.describe_regions()
            
            available_regions = [r['RegionName'] for r in regions['Regions']]
            
            if self.region in available_regions:
                return True, f"✅ Region {self.region} is available"
            else:
                return False, f"❌ Region {self.region} is not available"
                
        except ClientError as e:
            return False, f"❌ Error validating region: {e}"
    
    def validate_service_availability(self) -> Tuple[bool, str]:
        """Validate required AWS services are available in the region"""
        required_services = [
            ('redshift', 'Amazon Redshift'),
            ('glue', 'AWS Glue'),
            ('lambda', 'AWS Lambda'),
            ('s3', 'Amazon S3'),
            ('stepfunctions', 'AWS Step Functions'),
            ('sns', 'Amazon SNS'),
            ('cloudwatch', 'Amazon CloudWatch')
        ]
        
        unavailable_services = []
        
        for service_name, display_name in required_services:
            try:
                client = boto3.client(service_name, region_name=self.region)
                # Try a simple operation to verify service availability
                if service_name == 'redshift':
                    client.describe_clusters()
                elif service_name == 'glue':
                    client.get_databases()
                elif service_name == 'lambda':
                    client.list_functions(MaxItems=1)
                elif service_name == 's3':
                    client.list_buckets()
                elif service_name == 'stepfunctions':
                    client.list_state_machines(maxResults=1)
                elif service_name == 'sns':
                    client.list_topics()
                elif service_name == 'cloudwatch':
                    client.list_metrics(MaxRecords=1)
                    
            except ClientError as e:
                if 'not available' in str(e).lower() or 'not supported' in str(e).lower():
                    unavailable_services.append(display_name)
        
        if unavailable_services:
            return False, f"❌ Services not available in {self.region}: {', '.join(unavailable_services)}"
        else:
            return True, f"✅ All required AWS services are available in {self.region}"
    
    def validate_iam_permissions(self) -> Tuple[bool, str]:
        """Validate IAM permissions for deployment"""
        required_permissions = [
            ('iam', 'list_roles'),
            ('ec2', 'describe_vpcs'),
            ('s3', 'list_buckets'),
            ('redshift', 'describe_clusters'),
            ('glue', 'get_databases')
        ]
        
        missing_permissions = []
        
        for service, action in required_permissions:
            try:
                client = boto3.client(service, region_name=self.region)
                if action == 'list_roles':
                    client.list_roles(MaxItems=1)
                elif action == 'describe_vpcs':
                    client.describe_vpcs(MaxResults=1)
                elif action == 'list_buckets':
                    client.list_buckets()
                elif action == 'describe_clusters':
                    client.describe_clusters()
                elif action == 'get_databases':
                    client.get_databases()
                    
            except ClientError as e:
                if 'AccessDenied' in str(e) or 'Forbidden' in str(e):
                    missing_permissions.append(f"{service}:{action}")
        
        if missing_permissions:
            return False, f"❌ Missing IAM permissions: {', '.join(missing_permissions)}"
        else:
            return True, "✅ Required IAM permissions are available"
    
    def validate_terraform(self) -> Tuple[bool, str]:
        """Validate Terraform installation and version"""
        try:
            result = subprocess.run(['terraform', 'version', '-json'], 
                                  capture_output=True, text=True, check=True)
            version_info = json.loads(result.stdout)
            terraform_version = version_info['terraform_version']
            
            # Check minimum version (1.0.0)
            version_parts = terraform_version.split('.')
            major, minor = int(version_parts[0]), int(version_parts[1])
            
            if major >= 1:
                return True, f"✅ Terraform {terraform_version} is installed and compatible"
            else:
                return False, f"❌ Terraform {terraform_version} is too old. Minimum version: 1.0.0"
                
        except subprocess.CalledProcessError:
            return False, "❌ Terraform is not installed or not in PATH"
        except (json.JSONDecodeError, KeyError):
            return False, "❌ Unable to determine Terraform version"
    
    def validate_aws_cli(self) -> Tuple[bool, str]:
        """Validate AWS CLI installation"""
        try:
            result = subprocess.run(['aws', '--version'], 
                                  capture_output=True, text=True, check=True)
            version_line = result.stdout.strip()
            return True, f"✅ AWS CLI is installed: {version_line}"
            
        except subprocess.CalledProcessError:
            return False, "❌ AWS CLI is not installed or not in PATH"
    
    def validate_python_dependencies(self) -> Tuple[bool, str]:
        """Validate Python dependencies"""
        required_packages = ['boto3', 'pandas', 'faker']
        missing_packages = []
        
        for package in required_packages:
            try:
                __import__(package)
            except ImportError:
                missing_packages.append(package)
        
        if missing_packages:
            return False, f"❌ Missing Python packages: {', '.join(missing_packages)}"
        else:
            return True, "✅ All required Python packages are installed"
    
    def check_resource_limits(self) -> Tuple[bool, str]:
        """Check AWS service limits and quotas"""
        try:
            # Check VPC limits
            ec2_client = boto3.client('ec2', region_name=self.region)
            vpcs = ec2_client.describe_vpcs()
            vpc_count = len(vpcs['Vpcs'])
            
            # Check if we're close to VPC limit (default is 5)
            if vpc_count >= 4:
                return False, f"❌ VPC limit concern: {vpc_count}/5 VPCs in use"
            
            # Check S3 bucket limits (we'll create 4 buckets)
            s3_client = boto3.client('s3', region_name=self.region)
            buckets = s3_client.list_buckets()
            bucket_count = len(buckets['Buckets'])
            
            # S3 has a default limit of 100 buckets
            if bucket_count >= 96:
                return False, f"❌ S3 bucket limit concern: {bucket_count}/100 buckets in use"
            
            return True, f"✅ Resource limits check passed (VPCs: {vpc_count}, S3 buckets: {bucket_count})"
            
        except ClientError as e:
            return False, f"❌ Error checking resource limits: {e}"
    
    def run_all_validations(self) -> bool:
        """Run all validation checks"""
        print("🔍 Validating environment for E-Commerce Data Warehouse deployment...\n")
        
        validations = [
            ("AWS Credentials", self.validate_aws_credentials),
            ("AWS Region", self.validate_aws_region),
            ("Service Availability", self.validate_service_availability),
            ("IAM Permissions", self.validate_iam_permissions),
            ("Terraform Installation", self.validate_terraform),
            ("AWS CLI Installation", self.validate_aws_cli),
            ("Python Dependencies", self.validate_python_dependencies),
            ("Resource Limits", self.check_resource_limits)
        ]
        
        all_passed = True
        
        for check_name, validation_func in validations:
            try:
                passed, message = validation_func()
                print(f"{check_name}: {message}")
                
                if not passed:
                    all_passed = False
                    
            except Exception as e:
                print(f"{check_name}: ❌ Unexpected error: {e}")
                all_passed = False
        
        print("\n" + "="*60)
        
        if all_passed:
            print("🎉 All validation checks passed! Ready for deployment.")
            print("\nNext steps:")
            print("1. Run: ./scripts/deployment/deploy_infrastructure.sh dev")
            print("2. Generate sample data")
            print("3. Execute ETL pipeline")
        else:
            print("❌ Some validation checks failed. Please fix the issues before deployment.")
            print("\nCommon solutions:")
            print("- Install missing tools: terraform, aws-cli")
            print("- Configure AWS credentials: aws configure")
            print("- Install Python packages: pip install -r requirements.txt")
            print("- Check IAM permissions for your AWS user/role")
        
        return all_passed

def main():
    """Main function"""
    import argparse
    
    parser = argparse.ArgumentParser(description='Validate environment for deployment')
    parser.add_argument('--region', default='ap-south-1', 
                       help='AWS region to validate (default: ap-south-1)')
    
    args = parser.parse_args()
    
    validator = EnvironmentValidator(region=args.region)
    success = validator.run_all_validations()
    
    sys.exit(0 if success else 1)

if __name__ == "__main__":
    main()
