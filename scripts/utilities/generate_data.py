#!/usr/bin/env python3
"""
Data Generation Utility Script

This script provides a command-line interface for generating sample data
for the e-commerce data warehouse project.
"""

import argparse
import sys
import os
from pathlib import Path

# Add the data generators directory to the Python path
sys.path.append(str(Path(__file__).parent.parent.parent / "data" / "generators"))

from generate_sample_data import DataGenerator, CONFIG

def parse_arguments():
    """Parse command line arguments"""
    parser = argparse.ArgumentParser(
        description="Generate sample data for e-commerce data warehouse"
    )
    
    parser.add_argument(
        "--environment", "-e",
        choices=["dev", "staging", "prod"],
        default="dev",
        help="Environment to generate data for (default: dev)"
    )
    
    parser.add_argument(
        "--customers", "-c",
        type=int,
        help="Number of customers to generate"
    )
    
    parser.add_argument(
        "--products", "-p",
        type=int,
        help="Number of products to generate"
    )
    
    parser.add_argument(
        "--orders", "-o",
        type=int,
        help="Number of orders to generate"
    )
    
    parser.add_argument(
        "--output-dir", "-d",
        type=str,
        default="data/sample_data",
        help="Output directory for generated data"
    )
    
    parser.add_argument(
        "--format", "-f",
        choices=["csv", "json", "both"],
        default="csv",
        help="Output format (default: csv)"
    )
    
    parser.add_argument(
        "--seed", "-s",
        type=int,
        help="Random seed for reproducible data generation"
    )
    
    return parser.parse_args()

def update_config(args):
    """Update configuration based on command line arguments"""
    
    # Environment-specific defaults
    env_configs = {
        "dev": {
            "customers": 1000,
            "products": 500,
            "orders": 5000,
            "order_items": 15000,
            "web_events": 50000
        },
        "staging": {
            "customers": 10000,
            "products": 5000,
            "orders": 50000,
            "order_items": 150000,
            "web_events": 500000
        },
        "prod": {
            "customers": 100000,
            "products": 50000,
            "orders": 500000,
            "order_items": 1500000,
            "web_events": 5000000
        }
    }
    
    # Update CONFIG with environment defaults
    env_config = env_configs.get(args.environment, env_configs["dev"])
    CONFIG.update(env_config)
    
    # Override with command line arguments if provided
    if args.customers:
        CONFIG["customers"] = args.customers
    if args.products:
        CONFIG["products"] = args.products
    if args.orders:
        CONFIG["orders"] = args.orders
    
    # Update output directory
    CONFIG["output_dir"] = args.output_dir
    
    # Set random seed if provided
    if args.seed:
        import random
        random.seed(args.seed)

def main():
    """Main function"""
    args = parse_arguments()
    
    print(f"Generating data for {args.environment} environment...")
    
    # Update configuration
    update_config(args)
    
    # Create output directory
    os.makedirs(CONFIG["output_dir"], exist_ok=True)
    
    # Generate data
    generator = DataGenerator()
    
    try:
        generator.generate_all_data()
        
        print(f"\n✅ Data generation completed successfully!")
        print(f"📁 Output directory: {CONFIG['output_dir']}")
        print(f"📊 Generated data:")
        print(f"   - Customers: {CONFIG['customers']:,}")
        print(f"   - Products: {CONFIG['products']:,}")
        print(f"   - Orders: {CONFIG['orders']:,}")
        print(f"   - Web Events: {CONFIG['web_events']:,}")
        
    except Exception as e:
        print(f"❌ Error during data generation: {e}")
        sys.exit(1)

if __name__ == "__main__":
    main()
