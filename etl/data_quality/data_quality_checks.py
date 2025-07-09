"""
Data Quality Validation Framework

This module provides comprehensive data quality checks for the e-commerce
data warehouse, including completeness, accuracy, consistency, and validity checks.

Author: Data Engineering Team
"""

import pandas as pd
import numpy as np
from typing import Dict, List, Any, Optional
from datetime import datetime, timedelta
import re
import logging

# Configure logging
logging.basicConfig(level=logging.INFO)
logger = logging.getLogger(__name__)

class DataQualityChecker:
    """Comprehensive data quality validation framework"""
    
    def __init__(self):
        self.validation_results = []
        self.thresholds = {
            'completeness': 0.95,  # 95% completeness required
            'accuracy': 0.98,      # 98% accuracy required
            'consistency': 0.99,   # 99% consistency required
            'validity': 0.97       # 97% validity required
        }
    
    def check_completeness(self, df: pd.DataFrame, table_name: str, 
                          required_columns: List[str]) -> Dict[str, Any]:
        """Check data completeness"""
        logger.info(f"Checking completeness for {table_name}")
        
        results = {
            'check_type': 'completeness',
            'table_name': table_name,
            'timestamp': datetime.utcnow().isoformat(),
            'passed': True,
            'issues': [],
            'metrics': {}
        }
        
        total_rows = len(df)
        
        for column in required_columns:
            if column not in df.columns:
                results['issues'].append(f"Missing required column: {column}")
                results['passed'] = False
                continue
            
            null_count = df[column].isnull().sum()
            completeness_rate = (total_rows - null_count) / total_rows if total_rows > 0 else 0
            
            results['metrics'][f'{column}_completeness'] = completeness_rate
            
            if completeness_rate < self.thresholds['completeness']:
                results['issues'].append(
                    f"Column {column} completeness {completeness_rate:.2%} below threshold {self.thresholds['completeness']:.2%}"
                )
                results['passed'] = False
        
        return results
    
    def check_accuracy(self, df: pd.DataFrame, table_name: str) -> Dict[str, Any]:
        """Check data accuracy"""
        logger.info(f"Checking accuracy for {table_name}")
        
        results = {
            'check_type': 'accuracy',
            'table_name': table_name,
            'timestamp': datetime.utcnow().isoformat(),
            'passed': True,
            'issues': [],
            'metrics': {}
        }
        
        # Table-specific accuracy checks
        if table_name == 'customers':
            results.update(self._check_customer_accuracy(df))
        elif table_name == 'products':
            results.update(self._check_product_accuracy(df))
        elif table_name == 'orders':
            results.update(self._check_order_accuracy(df))
        elif table_name == 'order_items':
            results.update(self._check_order_items_accuracy(df))
        
        return results
    
    def check_consistency(self, df: pd.DataFrame, table_name: str, 
                         reference_data: Optional[Dict[str, pd.DataFrame]] = None) -> Dict[str, Any]:
        """Check data consistency"""
        logger.info(f"Checking consistency for {table_name}")
        
        results = {
            'check_type': 'consistency',
            'table_name': table_name,
            'timestamp': datetime.utcnow().isoformat(),
            'passed': True,
            'issues': [],
            'metrics': {}
        }
        
        # Check for duplicate records
        if table_name in ['customers', 'products', 'orders', 'order_items']:
            primary_key = {
                'customers': 'customer_id',
                'products': 'product_id',
                'orders': 'order_id',
                'order_items': 'order_item_id'
            }[table_name]
            
            if primary_key in df.columns:
                duplicate_count = df.duplicated(subset=[primary_key]).sum()
                total_count = len(df)
                consistency_rate = (total_count - duplicate_count) / total_count if total_count > 0 else 0
                
                results['metrics'][f'{primary_key}_uniqueness'] = consistency_rate
                
                if consistency_rate < self.thresholds['consistency']:
                    results['issues'].append(
                        f"Found {duplicate_count} duplicate {primary_key} values"
                    )
                    results['passed'] = False
        
        # Cross-table consistency checks
        if reference_data:
            results.update(self._check_cross_table_consistency(df, table_name, reference_data))
        
        return results
    
    def check_validity(self, df: pd.DataFrame, table_name: str) -> Dict[str, Any]:
        """Check data validity"""
        logger.info(f"Checking validity for {table_name}")
        
        results = {
            'check_type': 'validity',
            'table_name': table_name,
            'timestamp': datetime.utcnow().isoformat(),
            'passed': True,
            'issues': [],
            'metrics': {}
        }
        
        # Table-specific validity checks
        if table_name == 'customers':
            results.update(self._check_customer_validity(df))
        elif table_name == 'products':
            results.update(self._check_product_validity(df))
        elif table_name == 'orders':
            results.update(self._check_order_validity(df))
        elif table_name == 'order_items':
            results.update(self._check_order_items_validity(df))
        
        return results
    
    def _check_customer_accuracy(self, df: pd.DataFrame) -> Dict[str, Any]:
        """Customer-specific accuracy checks"""
        issues = []
        metrics = {}
        
        # Email format validation
        if 'email' in df.columns:
            email_pattern = r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$'
            valid_emails = df['email'].str.match(email_pattern, na=False)
            accuracy_rate = valid_emails.sum() / len(df) if len(df) > 0 else 0
            metrics['email_accuracy'] = accuracy_rate
            
            if accuracy_rate < self.thresholds['accuracy']:
                invalid_count = len(df) - valid_emails.sum()
                issues.append(f"Found {invalid_count} invalid email formats")
        
        # Phone number validation
        if 'phone' in df.columns:
            phone_pattern = r'^\+?1?[-.\s]?\(?[0-9]{3}\)?[-.\s]?[0-9]{3}[-.\s]?[0-9]{4}$'
            valid_phones = df['phone'].str.match(phone_pattern, na=False)
            accuracy_rate = valid_phones.sum() / df['phone'].notna().sum() if df['phone'].notna().sum() > 0 else 0
            metrics['phone_accuracy'] = accuracy_rate
        
        return {'issues': issues, 'metrics': metrics}
    
    def _check_product_accuracy(self, df: pd.DataFrame) -> Dict[str, Any]:
        """Product-specific accuracy checks"""
        issues = []
        metrics = {}
        
        # Price validation
        if 'price' in df.columns:
            valid_prices = (df['price'] > 0) & (df['price'] < 10000)  # Reasonable price range
            accuracy_rate = valid_prices.sum() / len(df) if len(df) > 0 else 0
            metrics['price_accuracy'] = accuracy_rate
            
            if accuracy_rate < self.thresholds['accuracy']:
                invalid_count = len(df) - valid_prices.sum()
                issues.append(f"Found {invalid_count} products with invalid prices")
        
        # SKU format validation
        if 'sku' in df.columns:
            sku_pattern = r'^SKU\d{6}$'  # Assuming SKU format like SKU123456
            valid_skus = df['sku'].str.match(sku_pattern, na=False)
            accuracy_rate = valid_skus.sum() / len(df) if len(df) > 0 else 0
            metrics['sku_accuracy'] = accuracy_rate
        
        return {'issues': issues, 'metrics': metrics}
    
    def _check_order_accuracy(self, df: pd.DataFrame) -> Dict[str, Any]:
        """Order-specific accuracy checks"""
        issues = []
        metrics = {}
        
        # Order total calculation validation
        if all(col in df.columns for col in ['subtotal', 'tax_amount', 'shipping_cost', 'discount_amount', 'total_amount']):
            calculated_total = df['subtotal'] + df['tax_amount'] + df['shipping_cost'] - df['discount_amount']
            total_diff = abs(df['total_amount'] - calculated_total)
            accurate_totals = total_diff < 0.01  # Allow for rounding differences
            accuracy_rate = accurate_totals.sum() / len(df) if len(df) > 0 else 0
            metrics['total_calculation_accuracy'] = accuracy_rate
            
            if accuracy_rate < self.thresholds['accuracy']:
                inaccurate_count = len(df) - accurate_totals.sum()
                issues.append(f"Found {inaccurate_count} orders with incorrect total calculations")
        
        return {'issues': issues, 'metrics': metrics}
    
    def _check_order_items_accuracy(self, df: pd.DataFrame) -> Dict[str, Any]:
        """Order items-specific accuracy checks"""
        issues = []
        metrics = {}
        
        # Line total calculation validation
        if all(col in df.columns for col in ['quantity', 'unit_price', 'line_total']):
            calculated_total = df['quantity'] * df['unit_price']
            total_diff = abs(df['line_total'] - calculated_total)
            accurate_totals = total_diff < 0.01
            accuracy_rate = accurate_totals.sum() / len(df) if len(df) > 0 else 0
            metrics['line_total_accuracy'] = accuracy_rate
            
            if accuracy_rate < self.thresholds['accuracy']:
                inaccurate_count = len(df) - accurate_totals.sum()
                issues.append(f"Found {inaccurate_count} order items with incorrect line totals")
        
        return {'issues': issues, 'metrics': metrics}
    
    def _check_customer_validity(self, df: pd.DataFrame) -> Dict[str, Any]:
        """Customer-specific validity checks"""
        issues = []
        metrics = {}
        
        # Age validation
        if 'date_of_birth' in df.columns:
            df['date_of_birth'] = pd.to_datetime(df['date_of_birth'], errors='coerce')
            today = datetime.now()
            ages = (today - df['date_of_birth']).dt.days / 365.25
            valid_ages = (ages >= 13) & (ages <= 120)  # Reasonable age range
            validity_rate = valid_ages.sum() / df['date_of_birth'].notna().sum() if df['date_of_birth'].notna().sum() > 0 else 0
            metrics['age_validity'] = validity_rate
            
            if validity_rate < self.thresholds['validity']:
                invalid_count = df['date_of_birth'].notna().sum() - valid_ages.sum()
                issues.append(f"Found {invalid_count} customers with invalid ages")
        
        return {'issues': issues, 'metrics': metrics}
    
    def _check_product_validity(self, df: pd.DataFrame) -> Dict[str, Any]:
        """Product-specific validity checks"""
        issues = []
        metrics = {}
        
        # Stock quantity validation
        if 'stock_quantity' in df.columns:
            valid_stock = df['stock_quantity'] >= 0
            validity_rate = valid_stock.sum() / len(df) if len(df) > 0 else 0
            metrics['stock_validity'] = validity_rate
            
            if validity_rate < self.thresholds['validity']:
                invalid_count = len(df) - valid_stock.sum()
                issues.append(f"Found {invalid_count} products with negative stock")
        
        return {'issues': issues, 'metrics': metrics}
    
    def _check_order_validity(self, df: pd.DataFrame) -> Dict[str, Any]:
        """Order-specific validity checks"""
        issues = []
        metrics = {}
        
        # Order date validation
        if 'order_date' in df.columns:
            df['order_date'] = pd.to_datetime(df['order_date'], errors='coerce')
            today = datetime.now()
            valid_dates = (df['order_date'] <= today) & (df['order_date'] >= datetime(2020, 1, 1))
            validity_rate = valid_dates.sum() / df['order_date'].notna().sum() if df['order_date'].notna().sum() > 0 else 0
            metrics['order_date_validity'] = validity_rate
            
            if validity_rate < self.thresholds['validity']:
                invalid_count = df['order_date'].notna().sum() - valid_dates.sum()
                issues.append(f"Found {invalid_count} orders with invalid dates")
        
        return {'issues': issues, 'metrics': metrics}
    
    def _check_order_items_validity(self, df: pd.DataFrame) -> Dict[str, Any]:
        """Order items-specific validity checks"""
        issues = []
        metrics = {}
        
        # Quantity validation
        if 'quantity' in df.columns:
            valid_quantities = (df['quantity'] > 0) & (df['quantity'] <= 100)  # Reasonable quantity range
            validity_rate = valid_quantities.sum() / len(df) if len(df) > 0 else 0
            metrics['quantity_validity'] = validity_rate
            
            if validity_rate < self.thresholds['validity']:
                invalid_count = len(df) - valid_quantities.sum()
                issues.append(f"Found {invalid_count} order items with invalid quantities")
        
        return {'issues': issues, 'metrics': metrics}
    
    def _check_cross_table_consistency(self, df: pd.DataFrame, table_name: str, 
                                     reference_data: Dict[str, pd.DataFrame]) -> Dict[str, Any]:
        """Check consistency across tables"""
        issues = []
        metrics = {}
        
        # Check foreign key relationships
        if table_name == 'orders' and 'customers' in reference_data:
            if 'customer_id' in df.columns:
                valid_customers = df['customer_id'].isin(reference_data['customers']['customer_id'])
                consistency_rate = valid_customers.sum() / len(df) if len(df) > 0 else 0
                metrics['customer_id_consistency'] = consistency_rate
                
                if consistency_rate < self.thresholds['consistency']:
                    invalid_count = len(df) - valid_customers.sum()
                    issues.append(f"Found {invalid_count} orders with invalid customer_id references")
        
        return {'issues': issues, 'metrics': metrics}
    
    def run_all_checks(self, df: pd.DataFrame, table_name: str, 
                      required_columns: List[str], 
                      reference_data: Optional[Dict[str, pd.DataFrame]] = None) -> List[Dict[str, Any]]:
        """Run all data quality checks"""
        logger.info(f"Running all data quality checks for {table_name}")
        
        results = []
        
        # Run all check types
        results.append(self.check_completeness(df, table_name, required_columns))
        results.append(self.check_accuracy(df, table_name))
        results.append(self.check_consistency(df, table_name, reference_data))
        results.append(self.check_validity(df, table_name))
        
        # Store results
        self.validation_results.extend(results)
        
        return results
    
    def generate_report(self) -> Dict[str, Any]:
        """Generate comprehensive data quality report"""
        report = {
            'timestamp': datetime.utcnow().isoformat(),
            'summary': {
                'total_checks': len(self.validation_results),
                'passed_checks': sum(1 for r in self.validation_results if r['passed']),
                'failed_checks': sum(1 for r in self.validation_results if not r['passed'])
            },
            'details': self.validation_results
        }
        
        report['summary']['pass_rate'] = (
            report['summary']['passed_checks'] / report['summary']['total_checks'] 
            if report['summary']['total_checks'] > 0 else 0
        )
        
        return report
