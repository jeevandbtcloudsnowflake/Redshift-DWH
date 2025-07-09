#!/usr/bin/env python3
"""
E-Commerce Sample Data Generator

This script generates realistic sample data for the e-commerce data warehouse project.
It creates customers, products, orders, and web events with proper relationships.
"""

import json
import random
import csv
import os
from datetime import datetime, timedelta
from typing import List, Dict, Any
from faker import Faker
import pandas as pd

# Initialize Faker
fake = Faker()

# Configuration
CONFIG = {
    'customers': 10000,
    'products': 5000,
    'orders': 50000,
    'order_items': 150000,
    'web_events': 500000,
    'start_date': datetime(2022, 1, 1),
    'end_date': datetime(2024, 12, 31),
    'output_dir': 'data/sample_data'
}

# Product categories and subcategories
PRODUCT_CATEGORIES = {
    1: {
        'name': 'Electronics',
        'subcategories': ['Smartphones', 'Laptops', 'Tablets', 'Headphones', 'Cameras']
    },
    2: {
        'name': 'Clothing',
        'subcategories': ['Men\'s Clothing', 'Women\'s Clothing', 'Kids\' Clothing', 'Shoes', 'Accessories']
    },
    3: {
        'name': 'Home & Garden',
        'subcategories': ['Furniture', 'Kitchen', 'Bathroom', 'Garden', 'Decor']
    },
    4: {
        'name': 'Sports & Outdoors',
        'subcategories': ['Fitness', 'Outdoor Recreation', 'Sports Equipment', 'Athletic Wear']
    },
    5: {
        'name': 'Books & Media',
        'subcategories': ['Books', 'Movies', 'Music', 'Games', 'Software']
    }
}

BRANDS = [
    'Apple', 'Samsung', 'Nike', 'Adidas', 'Sony', 'LG', 'Dell', 'HP', 'Canon', 'Nikon',
    'IKEA', 'Target', 'Amazon Basics', 'Generic', 'Premium Brand', 'Budget Choice'
]

ORDER_STATUSES = ['Pending', 'Processing', 'Shipped', 'Delivered', 'Cancelled', 'Returned']
PAYMENT_METHODS = ['Credit Card', 'Debit Card', 'PayPal', 'Apple Pay', 'Google Pay', 'Bank Transfer']
SHIPPING_METHODS = ['Standard', 'Express', 'Overnight', 'Two-Day', 'Ground']
ORDER_SOURCES = ['Website', 'Mobile App', 'Phone', 'In-Store', 'Marketplace']

class DataGenerator:
    def __init__(self):
        self.customers = []
        self.products = []
        self.orders = []
        self.order_items = []
        self.web_events = []
        
        # Ensure output directory exists
        os.makedirs(CONFIG['output_dir'], exist_ok=True)
    
    def generate_customers(self) -> List[Dict[str, Any]]:
        """Generate customer data"""
        print(f"Generating {CONFIG['customers']} customers...")
        
        customers = []
        for i in range(1, CONFIG['customers'] + 1):
            registration_date = fake.date_time_between(
                start_date=CONFIG['start_date'],
                end_date=CONFIG['end_date']
            )
            
            customer = {
                'customer_id': i,
                'first_name': fake.first_name(),
                'last_name': fake.last_name(),
                'email': fake.unique.email(),
                'phone': fake.phone_number(),
                'date_of_birth': fake.date_of_birth(minimum_age=18, maximum_age=80),
                'gender': random.choice(['Male', 'Female', 'Other', 'Prefer not to say']),
                'address_line1': fake.street_address(),
                'address_line2': fake.secondary_address() if random.random() < 0.3 else None,
                'city': fake.city(),
                'state': fake.state(),
                'postal_code': fake.postcode(),
                'country': 'United States',
                'customer_segment': random.choices(
                    ['Premium', 'Standard', 'Basic'],
                    weights=[0.1, 0.6, 0.3]
                )[0],
                'registration_date': registration_date,
                'last_login_date': fake.date_time_between(
                    start_date=registration_date,
                    end_date=CONFIG['end_date']
                ) if random.random() < 0.8 else None,
                'is_active': random.choices([True, False], weights=[0.9, 0.1])[0],
                'created_at': registration_date,
                'updated_at': fake.date_time_between(
                    start_date=registration_date,
                    end_date=CONFIG['end_date']
                )
            }
            customers.append(customer)
        
        self.customers = customers
        return customers
    
    def generate_products(self) -> List[Dict[str, Any]]:
        """Generate product data"""
        print(f"Generating {CONFIG['products']} products...")
        
        products = []
        for i in range(1, CONFIG['products'] + 1):
            category_id = random.choice(list(PRODUCT_CATEGORIES.keys()))
            category = PRODUCT_CATEGORIES[category_id]
            subcategory = random.choice(category['subcategories'])
            
            launch_date = fake.date_between(
                start_date=CONFIG['start_date'].date(),
                end_date=CONFIG['end_date'].date()
            )
            
            price = round(random.uniform(9.99, 999.99), 2)
            cost = round(price * random.uniform(0.3, 0.7), 2)
            
            product = {
                'product_id': i,
                'product_name': fake.catch_phrase(),
                'product_description': fake.text(max_nb_chars=500),
                'category_id': category_id,
                'category_name': category['name'],
                'subcategory_name': subcategory,
                'brand': random.choice(BRANDS),
                'sku': f"SKU{i:06d}",
                'price': price,
                'cost': cost,
                'weight': round(random.uniform(0.1, 50.0), 2),
                'dimensions': f"{random.randint(1,20)}x{random.randint(1,20)}x{random.randint(1,20)}",
                'color': fake.color_name() if random.random() < 0.7 else None,
                'size': random.choice(['XS', 'S', 'M', 'L', 'XL', 'XXL']) if random.random() < 0.4 else None,
                'material': random.choice(['Cotton', 'Polyester', 'Metal', 'Plastic', 'Wood', 'Glass']) if random.random() < 0.5 else None,
                'stock_quantity': random.randint(0, 1000),
                'reorder_level': random.randint(10, 100),
                'supplier_id': random.randint(1, 100),
                'is_active': random.choices([True, False], weights=[0.95, 0.05])[0],
                'launch_date': launch_date,
                'created_at': datetime.combine(launch_date, datetime.min.time()),
                'updated_at': fake.date_time_between(
                    start_date=datetime.combine(launch_date, datetime.min.time()),
                    end_date=CONFIG['end_date']
                )
            }
            products.append(product)
        
        self.products = products
        return products

    def generate_orders(self) -> List[Dict[str, Any]]:
        """Generate order data"""
        print(f"Generating {CONFIG['orders']} orders...")

        if not self.customers:
            raise ValueError("Customers must be generated before orders")

        orders = []
        for i in range(1, CONFIG['orders'] + 1):
            customer = random.choice(self.customers)
            order_date = fake.date_time_between(
                start_date=max(CONFIG['start_date'], customer['registration_date']),
                end_date=CONFIG['end_date']
            )

            # Generate order amounts
            subtotal = round(random.uniform(25.00, 500.00), 2)
            tax_rate = random.uniform(0.05, 0.12)
            tax_amount = round(subtotal * tax_rate, 2)
            shipping_cost = round(random.uniform(0.00, 25.00), 2)
            discount_amount = round(random.uniform(0.00, subtotal * 0.2), 2)
            total_amount = subtotal + tax_amount + shipping_cost - discount_amount

            # Order status progression
            status_weights = [0.05, 0.1, 0.15, 0.6, 0.08, 0.02]  # Pending to Returned
            order_status = random.choices(ORDER_STATUSES, weights=status_weights)[0]

            # Shipping dates based on status
            shipped_date = None
            delivered_date = None
            if order_status in ['Shipped', 'Delivered']:
                shipped_date = order_date + timedelta(days=random.randint(1, 3))
                if order_status == 'Delivered':
                    delivered_date = shipped_date + timedelta(days=random.randint(1, 7))

            order = {
                'order_id': i,
                'customer_id': customer['customer_id'],
                'order_date': order_date,
                'order_status': order_status,
                'payment_method': random.choice(PAYMENT_METHODS),
                'payment_status': 'Captured' if order_status != 'Cancelled' else 'Failed',
                'shipping_method': random.choice(SHIPPING_METHODS),
                'shipping_address_line1': customer['address_line1'],
                'shipping_address_line2': customer['address_line2'],
                'shipping_city': customer['city'],
                'shipping_state': customer['state'],
                'shipping_postal_code': customer['postal_code'],
                'shipping_country': customer['country'],
                'subtotal': subtotal,
                'tax_amount': tax_amount,
                'shipping_cost': shipping_cost,
                'discount_amount': discount_amount,
                'total_amount': total_amount,
                'currency': 'USD',
                'coupon_code': f"SAVE{random.randint(5,25)}" if random.random() < 0.2 else None,
                'order_source': random.choice(ORDER_SOURCES),
                'shipped_date': shipped_date,
                'delivered_date': delivered_date,
                'created_at': order_date,
                'updated_at': delivered_date or shipped_date or order_date
            }
            orders.append(order)

        self.orders = orders
        return orders

    def generate_order_items(self) -> List[Dict[str, Any]]:
        """Generate order items data"""
        print(f"Generating order items...")

        if not self.orders or not self.products:
            raise ValueError("Orders and products must be generated before order items")

        order_items = []
        item_id = 1

        for order in self.orders:
            # Each order has 1-5 items
            num_items = random.randint(1, 5)
            selected_products = random.sample(self.products, min(num_items, len(self.products)))

            for product in selected_products:
                quantity = random.randint(1, 3)
                unit_price = product['price']
                line_total = quantity * unit_price

                order_item = {
                    'order_item_id': item_id,
                    'order_id': order['order_id'],
                    'product_id': product['product_id'],
                    'product_name': product['product_name'],
                    'sku': product['sku'],
                    'quantity': quantity,
                    'unit_price': unit_price,
                    'line_total': line_total,
                    'created_at': order['order_date'],
                    'updated_at': order['updated_at']
                }
                order_items.append(order_item)
                item_id += 1

        self.order_items = order_items
        return order_items

    def generate_web_events(self) -> List[Dict[str, Any]]:
        """Generate web events data"""
        print(f"Generating {CONFIG['web_events']} web events...")

        if not self.customers or not self.products:
            raise ValueError("Customers and products must be generated before web events")

        event_types = ['page_view', 'product_view', 'add_to_cart', 'remove_from_cart',
                      'checkout_start', 'purchase', 'search', 'login', 'logout']

        web_events = []
        for i in range(1, CONFIG['web_events'] + 1):
            customer = random.choice(self.customers)
            event_date = fake.date_time_between(
                start_date=max(CONFIG['start_date'], customer['registration_date']),
                end_date=CONFIG['end_date']
            )

            event_type = random.choice(event_types)
            product = random.choice(self.products) if event_type in ['product_view', 'add_to_cart', 'remove_from_cart'] else None

            event = {
                'event_id': i,
                'customer_id': customer['customer_id'],
                'session_id': fake.uuid4(),
                'event_type': event_type,
                'event_timestamp': event_date,
                'product_id': product['product_id'] if product else None,
                'category_id': product['category_id'] if product else None,
                'page_url': fake.url(),
                'referrer_url': fake.url() if random.random() < 0.7 else None,
                'user_agent': fake.user_agent(),
                'ip_address': fake.ipv4(),
                'device_type': random.choice(['Desktop', 'Mobile', 'Tablet']),
                'browser': random.choice(['Chrome', 'Firefox', 'Safari', 'Edge']),
                'os': random.choice(['Windows', 'macOS', 'iOS', 'Android', 'Linux']),
                'created_at': event_date
            }
            web_events.append(event)

        self.web_events = web_events
        return web_events

    def save_to_csv(self, data: List[Dict[str, Any]], filename: str):
        """Save data to CSV file"""
        if not data:
            print(f"No data to save for {filename}")
            return

        filepath = os.path.join(CONFIG['output_dir'], f"{filename}.csv")
        df = pd.DataFrame(data)
        df.to_csv(filepath, index=False)
        print(f"Saved {len(data)} records to {filepath}")

    def save_to_json(self, data: List[Dict[str, Any]], filename: str):
        """Save data to JSON file"""
        if not data:
            print(f"No data to save for {filename}")
            return

        filepath = os.path.join(CONFIG['output_dir'], f"{filename}.json")
        with open(filepath, 'w') as f:
            json.dump(data, f, indent=2, default=str)
        print(f"Saved {len(data)} records to {filepath}")

    def generate_all_data(self):
        """Generate all sample data"""
        print("Starting data generation...")
        print(f"Configuration: {CONFIG}")

        # Generate data in dependency order
        self.generate_customers()
        self.generate_products()
        self.generate_orders()
        self.generate_order_items()
        self.generate_web_events()

        # Save to files
        print("\nSaving data to files...")
        self.save_to_csv(self.customers, 'customers')
        self.save_to_csv(self.products, 'products')
        self.save_to_csv(self.orders, 'orders')
        self.save_to_csv(self.order_items, 'order_items')
        self.save_to_csv(self.web_events, 'web_events')

        # Also save as JSON for reference
        self.save_to_json(self.customers[:100], 'customers_sample')
        self.save_to_json(self.products[:100], 'products_sample')
        self.save_to_json(self.orders[:100], 'orders_sample')

        print("\nData generation completed successfully!")
        print(f"Files saved to: {CONFIG['output_dir']}")

def main():
    """Main function"""
    generator = DataGenerator()
    generator.generate_all_data()

if __name__ == "__main__":
    main()
