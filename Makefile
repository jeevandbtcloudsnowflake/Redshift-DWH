# E-Commerce Data Warehouse Makefile

.PHONY: help setup clean test lint format deploy destroy

# Default target
help:
	@echo "Available commands:"
	@echo "  setup     - Set up development environment"
	@echo "  clean     - Clean temporary files and caches"
	@echo "  test      - Run all tests"
	@echo "  lint      - Run code linting"
	@echo "  format    - Format code"
	@echo "  deploy    - Deploy infrastructure and ETL"
	@echo "  destroy   - Destroy infrastructure"

# Setup development environment
setup:
	@echo "Setting up development environment..."
	python -m venv venv
	./venv/Scripts/activate && pip install -r requirements.txt
	@echo "Development environment setup complete!"

# Clean temporary files
clean:
	@echo "Cleaning temporary files..."
	find . -type f -name "*.pyc" -delete
	find . -type d -name "__pycache__" -delete
	find . -type d -name "*.egg-info" -exec rm -rf {} +
	rm -rf build/ dist/ .pytest_cache/ .coverage
	@echo "Cleanup complete!"

# Run tests
test:
	@echo "Running tests..."
	pytest tests/ -v --cov=etl --cov-report=html
	@echo "Tests complete!"

# Run linting
lint:
	@echo "Running linting..."
	flake8 etl/ tests/
	@echo "Linting complete!"

# Format code
format:
	@echo "Formatting code..."
	black etl/ tests/
	isort etl/ tests/
	@echo "Code formatting complete!"

# Deploy infrastructure
deploy-infra:
	@echo "Deploying infrastructure..."
	cd infrastructure/environments/dev && terraform init && terraform plan && terraform apply -auto-approve
	@echo "Infrastructure deployment complete!"

# Deploy ETL
deploy-etl:
	@echo "Deploying ETL pipelines..."
	python scripts/deployment/deploy_glue_jobs.py
	@echo "ETL deployment complete!"

# Full deployment
deploy: deploy-infra deploy-etl
	@echo "Full deployment complete!"

# Destroy infrastructure
destroy:
	@echo "Destroying infrastructure..."
	cd infrastructure/environments/dev && terraform destroy -auto-approve
	@echo "Infrastructure destroyed!"

# Generate sample data
generate-data:
	@echo "Generating sample data..."
	python data/generators/generate_sample_data.py
	@echo "Sample data generation complete!"
