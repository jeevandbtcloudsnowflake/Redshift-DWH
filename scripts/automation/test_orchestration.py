#!/usr/bin/env python3
"""
Test ETL Orchestration Methods

This script tests both Glue Workflows and Step Functions
to ensure they work correctly and helps you choose the best option.

Usage:
    python test_orchestration.py --environment dev
    python test_orchestration.py --environment dev --method glue
    python test_orchestration.py --environment dev --method stepfunctions
"""

import boto3
import time
import argparse
import logging
import json
from datetime import datetime
from typing import Dict, Any, Optional

# Configure logging
logging.basicConfig(
    level=logging.INFO,
    format='%(asctime)s - %(levelname)s - %(message)s'
)
logger = logging.getLogger(__name__)

class OrchestrationTester:
    def __init__(self, environment: str, region: str = 'ap-south-1'):
        self.environment = environment
        self.region = region
        self.project_name = 'ecommerce-dwh'
        
        # Initialize AWS clients
        self.glue_client = boto3.client('glue', region_name=region)
        self.stepfunctions_client = boto3.client('stepfunctions', region_name=region)
        self.events_client = boto3.client('events', region_name=region)
        
        # Resource names
        self.glue_workflow_name = f"{self.project_name}-{environment}-etl-workflow"
        self.stepfunctions_name = f"{self.project_name}-{environment}-etl-pipeline"
        
    def test_glue_workflow(self) -> Dict[str, Any]:
        """Test Glue Workflow execution"""
        logger.info("Testing Glue Workflow...")
        
        result = {
            'method': 'Glue Workflow',
            'success': False,
            'start_time': datetime.now(),
            'end_time': None,
            'duration': None,
            'workflow_run_id': None,
            'error': None
        }
        
        try:
            # Check if workflow exists
            try:
                workflow_response = self.glue_client.get_workflow(Name=self.glue_workflow_name)
                logger.info(f"✓ Workflow found: {self.glue_workflow_name}")
            except self.glue_client.exceptions.EntityNotFoundException:
                result['error'] = f"Workflow {self.glue_workflow_name} not found"
                return result
            
            # Start workflow
            logger.info("Starting Glue Workflow...")
            run_response = self.glue_client.start_workflow_run(Name=self.glue_workflow_name)
            workflow_run_id = run_response['RunId']
            result['workflow_run_id'] = workflow_run_id
            
            logger.info(f"Workflow started with Run ID: {workflow_run_id}")
            
            # Monitor workflow execution
            max_wait_time = 1800  # 30 minutes
            check_interval = 30   # 30 seconds
            elapsed_time = 0
            
            while elapsed_time < max_wait_time:
                run_details = self.glue_client.get_workflow_run(
                    Name=self.glue_workflow_name,
                    RunId=workflow_run_id
                )
                
                status = run_details['Run']['Status']
                logger.info(f"Workflow status: {status}")
                
                if status == 'COMPLETED':
                    result['success'] = True
                    result['end_time'] = datetime.now()
                    result['duration'] = result['end_time'] - result['start_time']
                    logger.info("✓ Glue Workflow completed successfully!")
                    break
                elif status in ['FAILED', 'STOPPED']:
                    result['error'] = f"Workflow failed with status: {status}"
                    result['end_time'] = datetime.now()
                    result['duration'] = result['end_time'] - result['start_time']
                    break
                
                time.sleep(check_interval)
                elapsed_time += check_interval
            
            if elapsed_time >= max_wait_time:
                result['error'] = "Workflow execution timed out"
                result['end_time'] = datetime.now()
                result['duration'] = result['end_time'] - result['start_time']
                
        except Exception as e:
            result['error'] = str(e)
            result['end_time'] = datetime.now()
            result['duration'] = result['end_time'] - result['start_time']
            logger.error(f"Error testing Glue Workflow: {str(e)}")
        
        return result
    
    def test_step_functions(self) -> Dict[str, Any]:
        """Test Step Functions execution"""
        logger.info("Testing Step Functions...")
        
        result = {
            'method': 'Step Functions',
            'success': False,
            'start_time': datetime.now(),
            'end_time': None,
            'duration': None,
            'execution_arn': None,
            'error': None
        }
        
        try:
            # Get state machine ARN
            account_id = boto3.client('sts').get_caller_identity()['Account']
            state_machine_arn = f"arn:aws:states:{self.region}:{account_id}:stateMachine:{self.stepfunctions_name}"
            
            # Check if state machine exists
            try:
                sm_response = self.stepfunctions_client.describe_state_machine(
                    stateMachineArn=state_machine_arn
                )
                logger.info(f"✓ State Machine found: {self.stepfunctions_name}")
            except self.stepfunctions_client.exceptions.StateMachineDoesNotExist:
                result['error'] = f"State Machine {self.stepfunctions_name} not found"
                return result
            
            # Start execution
            logger.info("Starting Step Functions execution...")
            execution_response = self.stepfunctions_client.start_execution(
                stateMachineArn=state_machine_arn,
                name=f"test-execution-{int(time.time())}",
                input=json.dumps({})
            )
            
            execution_arn = execution_response['executionArn']
            result['execution_arn'] = execution_arn
            
            logger.info(f"Execution started: {execution_arn}")
            
            # Monitor execution
            max_wait_time = 1800  # 30 minutes
            check_interval = 30   # 30 seconds
            elapsed_time = 0
            
            while elapsed_time < max_wait_time:
                execution_details = self.stepfunctions_client.describe_execution(
                    executionArn=execution_arn
                )
                
                status = execution_details['status']
                logger.info(f"Execution status: {status}")
                
                if status == 'SUCCEEDED':
                    result['success'] = True
                    result['end_time'] = datetime.now()
                    result['duration'] = result['end_time'] - result['start_time']
                    logger.info("✓ Step Functions execution completed successfully!")
                    break
                elif status in ['FAILED', 'TIMED_OUT', 'ABORTED']:
                    result['error'] = f"Execution failed with status: {status}"
                    if 'error' in execution_details:
                        result['error'] += f" - {execution_details['error']}"
                    result['end_time'] = datetime.now()
                    result['duration'] = result['end_time'] - result['start_time']
                    break
                
                time.sleep(check_interval)
                elapsed_time += check_interval
            
            if elapsed_time >= max_wait_time:
                result['error'] = "Execution timed out"
                result['end_time'] = datetime.now()
                result['duration'] = result['end_time'] - result['start_time']
                
        except Exception as e:
            result['error'] = str(e)
            result['end_time'] = datetime.now()
            result['duration'] = result['end_time'] - result['start_time']
            logger.error(f"Error testing Step Functions: {str(e)}")
        
        return result
    
    def check_schedules(self) -> Dict[str, Any]:
        """Check if schedules are properly configured"""
        logger.info("Checking schedule configurations...")
        
        schedules = {
            'glue_workflow': {
                'rule_name': f"{self.project_name}-{self.environment}-etl-schedule",
                'exists': False,
                'schedule': None,
                'enabled': False
            },
            'step_functions': {
                'rule_name': f"{self.project_name}-{self.environment}-step-functions-schedule",
                'exists': False,
                'schedule': None,
                'enabled': False
            }
        }
        
        for method, schedule_info in schedules.items():
            try:
                rule_response = self.events_client.describe_rule(
                    Name=schedule_info['rule_name']
                )
                
                schedule_info['exists'] = True
                schedule_info['schedule'] = rule_response.get('ScheduleExpression', 'Not set')
                schedule_info['enabled'] = rule_response.get('State') == 'ENABLED'
                
                logger.info(f"✓ {method} schedule: {schedule_info['schedule']} ({'Enabled' if schedule_info['enabled'] else 'Disabled'})")
                
            except self.events_client.exceptions.ResourceNotFoundException:
                logger.warning(f"✗ {method} schedule rule not found: {schedule_info['rule_name']}")
            except Exception as e:
                logger.error(f"Error checking {method} schedule: {str(e)}")
        
        return schedules
    
    def generate_report(self, results: list, schedules: dict):
        """Generate a comprehensive test report"""
        print("\n" + "="*60)
        print("ETL ORCHESTRATION TEST REPORT")
        print("="*60)
        
        print(f"\nEnvironment: {self.environment}")
        print(f"Region: {self.region}")
        print(f"Test Date: {datetime.now().strftime('%Y-%m-%d %H:%M:%S')}")
        
        print("\n📊 EXECUTION RESULTS")
        print("-" * 30)
        
        for result in results:
            status = "✅ SUCCESS" if result['success'] else "❌ FAILED"
            duration = result['duration'].total_seconds() if result['duration'] else 0
            
            print(f"\n{result['method']}: {status}")
            print(f"  Duration: {duration:.1f} seconds")
            
            if result['error']:
                print(f"  Error: {result['error']}")
            
            if 'workflow_run_id' in result and result['workflow_run_id']:
                print(f"  Run ID: {result['workflow_run_id']}")
            
            if 'execution_arn' in result and result['execution_arn']:
                print(f"  Execution ARN: {result['execution_arn']}")
        
        print("\n📅 SCHEDULE CONFIGURATION")
        print("-" * 30)
        
        for method, schedule_info in schedules.items():
            status = "✅ CONFIGURED" if schedule_info['exists'] else "❌ NOT FOUND"
            print(f"\n{method.replace('_', ' ').title()}: {status}")
            
            if schedule_info['exists']:
                print(f"  Schedule: {schedule_info['schedule']}")
                print(f"  Status: {'Enabled' if schedule_info['enabled'] else 'Disabled'}")
        
        print("\n🎯 RECOMMENDATIONS")
        print("-" * 30)
        
        successful_methods = [r for r in results if r['success']]
        
        if len(successful_methods) == 2:
            print("✅ Both orchestration methods are working correctly!")
            print("\nChoose based on your needs:")
            print("• Glue Workflows: Simpler, native Glue integration")
            print("• Step Functions: Advanced features, better error handling")
        elif len(successful_methods) == 1:
            successful_method = successful_methods[0]['method']
            print(f"✅ {successful_method} is working correctly")
            print("❌ The other method needs troubleshooting")
        else:
            print("❌ Both methods failed - check infrastructure deployment")
        
        print("\n📋 NEXT STEPS")
        print("-" * 30)
        print("1. Review any failed tests and fix issues")
        print("2. Choose your preferred orchestration method")
        print("3. Disable unused schedules if desired")
        print("4. Monitor the first scheduled runs")
        print("5. Set up alerting for production use")

def main():
    parser = argparse.ArgumentParser(description='Test ETL Orchestration')
    parser.add_argument(
        '--environment',
        required=True,
        choices=['dev', 'staging', 'prod'],
        help='Environment to test'
    )
    parser.add_argument(
        '--method',
        choices=['glue', 'stepfunctions', 'both'],
        default='both',
        help='Orchestration method to test'
    )
    parser.add_argument(
        '--region',
        default='ap-south-1',
        help='AWS region'
    )
    
    args = parser.parse_args()
    
    # Initialize tester
    tester = OrchestrationTester(args.environment, args.region)
    
    # Check schedules
    schedules = tester.check_schedules()
    
    # Run tests
    results = []
    
    if args.method in ['glue', 'both']:
        logger.info("Testing Glue Workflow...")
        glue_result = tester.test_glue_workflow()
        results.append(glue_result)
    
    if args.method in ['stepfunctions', 'both']:
        logger.info("Testing Step Functions...")
        sf_result = tester.test_step_functions()
        results.append(sf_result)
    
    # Generate report
    tester.generate_report(results, schedules)
    
    # Exit with appropriate code
    all_successful = all(r['success'] for r in results)
    exit(0 if all_successful else 1)

if __name__ == "__main__":
    main()
