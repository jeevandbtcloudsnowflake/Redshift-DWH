#!/usr/bin/env python3
"""
Analytics Demo Script
Showcases the business intelligence capabilities and dashboard insights
"""

import boto3
import pandas as pd
import json
import os
import sys
from datetime import datetime, timedelta
from typing import Dict, List, Any
import argparse

class AnalyticsDemo:
    def __init__(self, region: str = 'ap-south-1', profile: str = None):
        """Initialize the analytics demo"""
        session = boto3.Session(profile_name=profile) if profile else boto3.Session()
        self.redshift_data = session.client('redshift-data', region_name=region)
        self.quicksight = session.client('quicksight', region_name=region)
        self.sts = session.client('sts', region_name=region)
        
        self.region = region
        self.account_id = self.sts.get_caller_identity()['Account']
        
    def print_header(self, title: str):
        """Print a formatted header"""
        print("\n" + "=" * 80)
        print(f"🎯 {title}")
        print("=" * 80)
    
    def print_section(self, title: str):
        """Print a formatted section"""
        print(f"\n📊 {title}")
        print("-" * 60)
    
    def execute_query(self, query: str, database: str, cluster: str) -> List[Dict]:
        """Execute a query against Redshift and return results"""
        try:
            # Execute query
            response = self.redshift_data.execute_statement(
                ClusterIdentifier=cluster,
                Database=database,
                Sql=query
            )
            
            query_id = response['Id']
            
            # Wait for completion
            import time
            while True:
                status_response = self.redshift_data.describe_statement(Id=query_id)
                status = status_response['Status']
                
                if status == 'FINISHED':
                    break
                elif status == 'FAILED':
                    raise Exception(f"Query failed: {status_response.get('Error', 'Unknown error')}")
                
                time.sleep(1)
            
            # Get results
            result_response = self.redshift_data.get_statement_result(Id=query_id)
            
            # Convert to list of dictionaries
            columns = [col['name'] for col in result_response['ColumnMetadata']]
            rows = []
            
            for record in result_response['Records']:
                row = {}
                for i, col in enumerate(columns):
                    value = record[i]
                    # Extract value from the response format
                    if 'stringValue' in value:
                        row[col] = value['stringValue']
                    elif 'longValue' in value:
                        row[col] = value['longValue']
                    elif 'doubleValue' in value:
                        row[col] = value['doubleValue']
                    elif 'isNull' in value:
                        row[col] = None
                    else:
                        row[col] = str(value)
                rows.append(row)
            
            return rows
            
        except Exception as e:
            print(f"❌ Query execution failed: {e}")
            return []
    
    def demo_executive_insights(self, database: str, cluster: str):
        """Demonstrate executive dashboard insights"""
        self.print_section("Executive Dashboard - Strategic Business Insights")
        
        # Total Revenue
        query = """
        SELECT 
            SUM(total_revenue) as total_revenue,
            COUNT(DISTINCT month_name) as months_tracked,
            AVG(total_revenue) as avg_monthly_revenue
        FROM analytics.monthly_sales_trends
        """
        
        results = self.execute_query(query, database, cluster)
        if results:
            data = results[0]
            print(f"💰 Total Revenue: ${float(data['total_revenue']):,.2f}")
            print(f"📅 Months Tracked: {data['months_tracked']}")
            print(f"📈 Average Monthly Revenue: ${float(data['avg_monthly_revenue']):,.2f}")
        
        # Growth Trends
        query = """
        SELECT 
            month_name,
            total_revenue,
            revenue_growth_percent
        FROM analytics.monthly_sales_trends
        ORDER BY year_number, month_number
        LIMIT 6
        """
        
        results = self.execute_query(query, database, cluster)
        if results:
            print(f"\n📊 Revenue Growth Trends:")
            for row in results:
                growth = float(row['revenue_growth_percent']) if row['revenue_growth_percent'] else 0
                trend = "📈" if growth > 0 else "📉" if growth < 0 else "➡️"
                print(f"   {row['month_name']}: ${float(row['total_revenue']):,.2f} {trend} {growth:+.1f}%")
    
    def demo_customer_insights(self, database: str, cluster: str):
        """Demonstrate customer analytics insights"""
        self.print_section("Customer Analytics - 360° Customer Intelligence")
        
        # Customer Segments
        query = """
        SELECT 
            customer_segment,
            COUNT(*) as customer_count,
            SUM(lifetime_value) as segment_revenue,
            AVG(lifetime_value) as avg_lifetime_value
        FROM analytics.customer_360
        GROUP BY customer_segment
        ORDER BY segment_revenue DESC
        """
        
        results = self.execute_query(query, database, cluster)
        if results:
            print(f"👥 Customer Segmentation Analysis:")
            total_customers = sum(int(row['customer_count']) for row in results)
            total_revenue = sum(float(row['segment_revenue']) for row in results)
            
            for row in results:
                count = int(row['customer_count'])
                revenue = float(row['segment_revenue'])
                avg_ltv = float(row['avg_lifetime_value'])
                pct_customers = (count / total_customers) * 100
                pct_revenue = (revenue / total_revenue) * 100
                
                print(f"   🎯 {row['customer_segment']}: {count} customers ({pct_customers:.1f}%)")
                print(f"      💰 Revenue: ${revenue:,.2f} ({pct_revenue:.1f}% of total)")
                print(f"      📊 Avg LTV: ${avg_ltv:,.2f}")
        
        # Customer Status
        query = """
        SELECT 
            customer_status,
            COUNT(*) as customer_count,
            AVG(days_since_last_order) as avg_days_since_order
        FROM analytics.customer_360
        GROUP BY customer_status
        ORDER BY customer_count DESC
        """
        
        results = self.execute_query(query, database, cluster)
        if results:
            print(f"\n🔍 Customer Health Analysis:")
            for row in results:
                status_emoji = {"Active": "🟢", "At Risk": "🟡", "Churned": "🔴"}.get(row['customer_status'], "⚪")
                avg_days = float(row['avg_days_since_order']) if row['avg_days_since_order'] else 0
                print(f"   {status_emoji} {row['customer_status']}: {row['customer_count']} customers (avg {avg_days:.0f} days since last order)")
    
    def demo_product_insights(self, database: str, cluster: str):
        """Demonstrate product performance insights"""
        self.print_section("Product Performance - Sales & Profitability Analysis")
        
        # Top Products
        query = """
        SELECT 
            product_name,
            category_name,
            total_revenue,
            total_units_sold,
            gross_margin_percent,
            revenue_rank_in_category
        FROM analytics.product_performance
        WHERE overall_revenue_rank <= 10
        ORDER BY total_revenue DESC
        """
        
        results = self.execute_query(query, database, cluster)
        if results:
            print(f"🏆 Top 10 Products by Revenue:")
            for i, row in enumerate(results, 1):
                revenue = float(row['total_revenue'])
                units = int(row['total_units_sold'])
                margin = float(row['gross_margin_percent']) if row['gross_margin_percent'] else 0
                
                print(f"   {i:2d}. {row['product_name'][:30]:<30} | ${revenue:>8,.0f} | {units:>4} units | {margin:>5.1f}% margin")
        
        # Category Performance
        query = """
        SELECT 
            category_name,
            SUM(total_revenue) as category_revenue,
            SUM(total_units_sold) as category_units,
            AVG(gross_margin_percent) as avg_margin,
            COUNT(*) as product_count
        FROM analytics.product_performance
        GROUP BY category_name
        ORDER BY category_revenue DESC
        """
        
        results = self.execute_query(query, database, cluster)
        if results:
            print(f"\n📦 Category Performance Analysis:")
            for row in results:
                revenue = float(row['category_revenue'])
                units = int(row['category_units'])
                margin = float(row['avg_margin']) if row['avg_margin'] else 0
                products = int(row['product_count'])
                
                print(f"   📂 {row['category_name']:<20} | ${revenue:>10,.0f} | {units:>6} units | {margin:>5.1f}% avg margin | {products} products")
    
    def demo_operational_insights(self, database: str, cluster: str):
        """Demonstrate operational dashboard insights"""
        self.print_section("Operational Dashboard - Data Engineering Metrics")
        
        # Data Quality Metrics
        query = """
        SELECT 
            COUNT(DISTINCT customer_id) as total_customers,
            COUNT(DISTINCT product_id) as total_products,
            SUM(total_orders) as total_orders,
            SUM(total_revenue) as total_revenue
        FROM analytics.monthly_sales_trends
        """
        
        results = self.execute_query(query, database, cluster)
        if results:
            data = results[0]
            print(f"📊 Data Quality & Volume Metrics:")
            print(f"   👥 Total Customers: {data['total_customers']:,}")
            print(f"   🛍️ Total Products: {data['total_products']:,}")
            print(f"   📦 Total Orders: {int(data['total_orders']):,}")
            print(f"   💰 Total Revenue: ${float(data['total_revenue']):,.2f}")
        
        # System Health Simulation
        print(f"\n⚙️ System Health Metrics (Simulated):")
        print(f"   🟢 Data Freshness: < 1 hour")
        print(f"   🟢 ETL Success Rate: 99.5%")
        print(f"   🟢 Query Performance: < 10 seconds avg")
        print(f"   🟢 System Uptime: 99.9%")
        print(f"   🟢 Data Quality Score: 98.2%")
    
    def demo_quicksight_dashboards(self):
        """Demonstrate QuickSight dashboard access"""
        self.print_section("QuickSight Dashboards - Interactive Business Intelligence")
        
        try:
            # List dashboards
            response = self.quicksight.list_dashboards(AwsAccountId=self.account_id)
            
            if response['DashboardSummaryList']:
                print(f"📊 Available QuickSight Dashboards:")
                for dashboard in response['DashboardSummaryList']:
                    dashboard_url = f"https://{self.region}.quicksight.aws.amazon.com/sn/dashboards/{dashboard['DashboardId']}"
                    print(f"   🎯 {dashboard['Name']}")
                    print(f"      📅 Last Updated: {dashboard['LastUpdatedTime'].strftime('%Y-%m-%d %H:%M')}")
                    print(f"      🔗 URL: {dashboard_url}")
                    print()
            else:
                print(f"⚠️ No QuickSight dashboards found. Deploy them using:")
                print(f"   cd infrastructure/modules/quicksight/scripts/")
                print(f"   python deploy_dashboards.py --project-name ecommerce-dwh --environment dev")
                
        except Exception as e:
            print(f"⚠️ QuickSight access error: {e}")
            print(f"💡 Ensure QuickSight is enabled and you have appropriate permissions")
    
    def run_complete_demo(self, database: str, cluster: str):
        """Run the complete analytics demo"""
        self.print_header("E-Commerce Data Warehouse - Analytics Demo")
        
        print(f"🎯 Showcasing Business Intelligence Capabilities")
        print(f"📅 Demo Date: {datetime.now().strftime('%Y-%m-%d %H:%M:%S')}")
        print(f"🌍 Region: {self.region}")
        print(f"🏢 Account: {self.account_id}")
        print(f"🗄️ Database: {database}")
        print(f"🔗 Cluster: {cluster}")
        
        # Run all demos
        self.demo_executive_insights(database, cluster)
        self.demo_customer_insights(database, cluster)
        self.demo_product_insights(database, cluster)
        self.demo_operational_insights(database, cluster)
        self.demo_quicksight_dashboards()
        
        # Summary
        self.print_header("Demo Summary - Business Value Delivered")
        print(f"✅ Executive Dashboard: Strategic KPIs and growth trends")
        print(f"✅ Customer Analytics: 360° customer intelligence and segmentation")
        print(f"✅ Product Performance: Sales optimization and profitability insights")
        print(f"✅ Operational Monitoring: Data engineering metrics and system health")
        print(f"✅ Interactive Dashboards: Real-time QuickSight business intelligence")
        
        print(f"\n🎉 This enterprise-grade data warehouse delivers:")
        print(f"   💰 Revenue optimization through data-driven insights")
        print(f"   👥 Customer lifetime value maximization")
        print(f"   🛍️ Product performance optimization")
        print(f"   ⚙️ Operational excellence and monitoring")
        print(f"   📊 Executive decision-making support")
        
        print(f"\n🚀 Next Steps:")
        print(f"   1. Access QuickSight dashboards for interactive analysis")
        print(f"   2. Customize analytics views for specific business needs")
        print(f"   3. Set up automated reporting and alerts")
        print(f"   4. Train business users on dashboard capabilities")
        print(f"   5. Expand data sources and analytics scope")

def main():
    parser = argparse.ArgumentParser(description='Run analytics demo')
    parser.add_argument('--database', default='ecommerce_dwh_dev', help='Redshift database name')
    parser.add_argument('--cluster', default='ecommerce-dwh-dev-cluster', help='Redshift cluster identifier')
    parser.add_argument('--region', default='ap-south-1', help='AWS region')
    parser.add_argument('--profile', help='AWS profile to use')
    
    args = parser.parse_args()
    
    # Initialize demo
    demo = AnalyticsDemo(region=args.region, profile=args.profile)
    
    # Run complete demo
    demo.run_complete_demo(args.database, args.cluster)

if __name__ == '__main__':
    main()
