#!/bin/bash

# E-Commerce Data Warehouse Infrastructure Deployment Script
# This script deploys the complete AWS infrastructure using Terraform

set -e  # Exit on any error

# Configuration
ENVIRONMENT=${1:-dev}
AWS_REGION="ap-south-1"
PROJECT_NAME="ecommerce-dwh"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Logging function
log() {
    echo -e "${BLUE}[$(date +'%Y-%m-%d %H:%M:%S')]${NC} $1"
}

error() {
    echo -e "${RED}[ERROR]${NC} $1" >&2
}

success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

# Check prerequisites
check_prerequisites() {
    log "Checking prerequisites..."
    
    # Check if AWS CLI is installed and configured
    if ! command -v aws &> /dev/null; then
        error "AWS CLI is not installed. Please install it first."
        exit 1
    fi
    
    # Check AWS credentials
    if ! aws sts get-caller-identity &> /dev/null; then
        error "AWS credentials not configured. Please run 'aws configure'."
        exit 1
    fi
    
    # Check if Terraform is installed
    if ! command -v terraform &> /dev/null; then
        error "Terraform is not installed. Please install it first."
        exit 1
    fi
    
    # Check Terraform version
    TERRAFORM_VERSION=$(terraform version -json | jq -r '.terraform_version')
    log "Using Terraform version: $TERRAFORM_VERSION"
    
    # Verify AWS region
    CURRENT_REGION=$(aws configure get region)
    if [ "$CURRENT_REGION" != "$AWS_REGION" ]; then
        warning "Current AWS region is $CURRENT_REGION, but project is configured for $AWS_REGION"
        read -p "Do you want to continue? (y/N): " -n 1 -r
        echo
        if [[ ! $REPLY =~ ^[Yy]$ ]]; then
            exit 1
        fi
    fi
    
    success "Prerequisites check completed"
}

# Generate Redshift password
generate_redshift_password() {
    log "Generating secure Redshift password..."
    
    # Generate a random password with special characters
    REDSHIFT_PASSWORD=$(openssl rand -base64 32 | tr -d "=+/" | cut -c1-25)
    
    # Ensure it meets Redshift requirements (8-64 chars, at least one uppercase, lowercase, and number)
    REDSHIFT_PASSWORD="Dwh${REDSHIFT_PASSWORD}123!"
    
    echo "$REDSHIFT_PASSWORD"
}

# Create terraform.tfvars file
create_tfvars() {
    local env_dir="infrastructure/environments/$ENVIRONMENT"
    local tfvars_file="$env_dir/terraform.tfvars"
    
    log "Creating terraform.tfvars for $ENVIRONMENT environment..."
    
    if [ -f "$tfvars_file" ]; then
        warning "terraform.tfvars already exists. Creating backup..."
        cp "$tfvars_file" "$tfvars_file.backup.$(date +%Y%m%d_%H%M%S)"
    fi
    
    # Generate password if not provided
    if [ -z "$REDSHIFT_PASSWORD" ]; then
        REDSHIFT_PASSWORD=$(generate_redshift_password)
        log "Generated Redshift password (save this securely): $REDSHIFT_PASSWORD"
    fi
    
    cat > "$tfvars_file" << EOF
# Terraform variables for $ENVIRONMENT environment
# Generated on $(date)

# Redshift Configuration
redshift_master_password = "$REDSHIFT_PASSWORD"

# Optional: Override default values if needed
# aws_region = "$AWS_REGION"
# vpc_cidr = "10.0.0.0/16"
EOF
    
    success "Created $tfvars_file"
}

# Deploy infrastructure
deploy_infrastructure() {
    local env_dir="infrastructure/environments/$ENVIRONMENT"
    
    log "Deploying infrastructure for $ENVIRONMENT environment..."
    
    cd "$env_dir"
    
    # Initialize Terraform
    log "Initializing Terraform..."
    terraform init
    
    # Validate configuration
    log "Validating Terraform configuration..."
    terraform validate
    
    # Plan deployment
    log "Creating deployment plan..."
    terraform plan -out=tfplan
    
    # Ask for confirmation
    echo
    warning "This will deploy AWS infrastructure which may incur costs."
    read -p "Do you want to proceed with deployment? (y/N): " -n 1 -r
    echo
    
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        log "Deployment cancelled by user"
        exit 0
    fi
    
    # Apply changes
    log "Applying Terraform configuration..."
    terraform apply tfplan
    
    # Clean up plan file
    rm -f tfplan
    
    success "Infrastructure deployment completed!"
    
    # Return to original directory
    cd - > /dev/null
}

# Display deployment information
show_deployment_info() {
    local env_dir="infrastructure/environments/$ENVIRONMENT"
    
    log "Retrieving deployment information..."
    
    cd "$env_dir"
    
    echo
    echo "=== DEPLOYMENT SUMMARY ==="
    echo "Environment: $ENVIRONMENT"
    echo "Region: $AWS_REGION"
    echo "Project: $PROJECT_NAME"
    echo
    
    # Get outputs
    echo "=== INFRASTRUCTURE OUTPUTS ==="
    terraform output
    
    echo
    echo "=== NEXT STEPS ==="
    echo "1. Generate sample data: python scripts/utilities/generate_data.py --environment $ENVIRONMENT"
    echo "2. Upload data to S3 to trigger ETL pipeline"
    echo "3. Monitor pipeline execution in AWS console"
    echo
    
    cd - > /dev/null
}

# Main execution
main() {
    log "Starting infrastructure deployment for $ENVIRONMENT environment"
    
    check_prerequisites
    create_tfvars
    deploy_infrastructure
    show_deployment_info
    
    success "Deployment process completed successfully!"
}

# Help function
show_help() {
    echo "Usage: $0 [ENVIRONMENT]"
    echo
    echo "Deploy E-Commerce Data Warehouse infrastructure using Terraform"
    echo
    echo "Arguments:"
    echo "  ENVIRONMENT    Target environment (dev, staging, prod). Default: dev"
    echo
    echo "Environment Variables:"
    echo "  REDSHIFT_PASSWORD    Custom Redshift password (optional, will be generated if not provided)"
    echo
    echo "Examples:"
    echo "  $0 dev                    # Deploy to development environment"
    echo "  $0 staging                # Deploy to staging environment"
    echo "  REDSHIFT_PASSWORD=MyPass123! $0 prod    # Deploy to production with custom password"
    echo
}

# Check for help flag
if [[ "$1" == "-h" || "$1" == "--help" ]]; then
    show_help
    exit 0
fi

# Validate environment argument
if [[ "$ENVIRONMENT" != "dev" && "$ENVIRONMENT" != "staging" && "$ENVIRONMENT" != "prod" ]]; then
    error "Invalid environment: $ENVIRONMENT. Must be one of: dev, staging, prod"
    show_help
    exit 1
fi

# Run main function
main
