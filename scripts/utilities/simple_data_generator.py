#!/usr/bin/env python3
"""
Simple Data Generator (No External Dependencies)

This script generates basic sample data using only Python standard library.
"""

import csv
import random
import os
from datetime import datetime, timedelta

# Configuration
OUTPUT_DIR = 'data/sample_data'
NUM_CUSTOMERS = 1000
NUM_PRODUCTS = 500
NUM_ORDERS = 5000

# Sample data
FIRST_NAMES = ['John', 'Jane', 'Michael', 'Sarah', 'David', 'Lisa', 'Robert', 'Emily', 'James', 'Jessica']
LAST_NAMES = ['Smith', 'Johnson', 'Williams', 'Brown', 'Jones', 'Garcia', 'Miller', 'Davis', 'Rodriguez', 'Martinez']
CITIES = ['Mumbai', 'Delhi', 'Bangalore', 'Chennai', 'Kolkata', 'Hyderabad', 'Pune', 'Ahmedabad', 'Jaipur', 'Lucknow']
STATES = ['Maharashtra', 'Delhi', 'Karnataka', 'Tamil Nadu', 'West Bengal', 'Telangana', 'Gujarat', 'Rajasthan', 'Uttar Pradesh']
CATEGORIES = ['Electronics', 'Clothing', 'Home & Garden', 'Sports & Outdoors', 'Books & Media']
BRANDS = ['Apple', 'Samsung', 'Nike', 'Adidas', 'Sony', 'LG', 'Dell', 'HP', 'Generic', 'Premium Brand']

def generate_email(first_name, last_name):
    """Generate email address"""
    domains = ['gmail.com', 'yahoo.com', 'hotmail.com', 'outlook.com', 'company.com']
    return f"{first_name.lower()}.{last_name.lower()}@{random.choice(domains)}"

def generate_phone():
    """Generate Indian phone number"""
    return f"+91-{random.randint(70000, 99999)}-{random.randint(10000, 99999)}"

def generate_date(start_date, end_date):
    """Generate random date between start and end"""
    time_between = end_date - start_date
    days_between = time_between.days
    random_days = random.randrange(days_between)
    return start_date + timedelta(days=random_days)

def generate_customers():
    """Generate customer data"""
    print(f"Generating {NUM_CUSTOMERS} customers...")
    
    customers = []
    for i in range(1, NUM_CUSTOMERS + 1):
        first_name = random.choice(FIRST_NAMES)
        last_name = random.choice(LAST_NAMES)
        registration_date = generate_date(datetime(2022, 1, 1), datetime(2024, 12, 31))
        
        customer = {
            'customer_id': i,
            'first_name': first_name,
            'last_name': last_name,
            'email': generate_email(first_name, last_name),
            'phone': generate_phone(),
            'date_of_birth': generate_date(datetime(1960, 1, 1), datetime(2000, 12, 31)).strftime('%Y-%m-%d'),
            'gender': random.choice(['Male', 'Female', 'Other']),
            'address_line1': f"{random.randint(1, 999)} {random.choice(['Main St', 'Park Ave', 'Oak Rd', 'First St'])}",
            'address_line2': '',
            'city': random.choice(CITIES),
            'state': random.choice(STATES),
            'postal_code': f"{random.randint(100000, 999999)}",
            'country': 'India',
            'customer_segment': random.choices(['Premium', 'Standard', 'Basic'], weights=[0.1, 0.6, 0.3])[0],
            'registration_date': registration_date.strftime('%Y-%m-%d %H:%M:%S'),
            'last_login_date': generate_date(registration_date, datetime(2024, 12, 31)).strftime('%Y-%m-%d %H:%M:%S'),
            'is_active': random.choice([True, False]),
            'created_at': registration_date.strftime('%Y-%m-%d %H:%M:%S'),
            'updated_at': generate_date(registration_date, datetime(2024, 12, 31)).strftime('%Y-%m-%d %H:%M:%S')
        }
        customers.append(customer)
    
    return customers

def generate_products():
    """Generate product data"""
    print(f"Generating {NUM_PRODUCTS} products...")
    
    products = []
    for i in range(1, NUM_PRODUCTS + 1):
        category = random.choice(CATEGORIES)
        price = round(random.uniform(10.0, 1000.0), 2)
        cost = round(price * random.uniform(0.3, 0.7), 2)
        launch_date = generate_date(datetime(2020, 1, 1), datetime(2024, 12, 31))
        
        product = {
            'product_id': i,
            'product_name': f"{random.choice(BRANDS)} {category} Product {i}",
            'product_description': f"High quality {category.lower()} product with excellent features",
            'category_id': CATEGORIES.index(category) + 1,
            'category_name': category,
            'subcategory_name': f"{category} Sub",
            'brand': random.choice(BRANDS),
            'sku': f"SKU{i:06d}",
            'price': price,
            'cost': cost,
            'weight': round(random.uniform(0.1, 10.0), 2),
            'dimensions': f"{random.randint(1,20)}x{random.randint(1,20)}x{random.randint(1,20)}",
            'color': random.choice(['Red', 'Blue', 'Green', 'Black', 'White', 'Gray']),
            'size': random.choice(['S', 'M', 'L', 'XL']) if random.random() < 0.5 else '',
            'material': random.choice(['Cotton', 'Plastic', 'Metal', 'Wood']) if random.random() < 0.5 else '',
            'stock_quantity': random.randint(0, 1000),
            'reorder_level': random.randint(10, 100),
            'supplier_id': random.randint(1, 50),
            'is_active': random.choice([True, False]),
            'launch_date': launch_date.strftime('%Y-%m-%d'),
            'created_at': launch_date.strftime('%Y-%m-%d %H:%M:%S'),
            'updated_at': generate_date(launch_date, datetime(2024, 12, 31)).strftime('%Y-%m-%d %H:%M:%S')
        }
        products.append(product)
    
    return products

def generate_orders(customers, products):
    """Generate order data"""
    print(f"Generating {NUM_ORDERS} orders...")
    
    orders = []
    order_items = []
    item_id = 1
    
    for i in range(1, NUM_ORDERS + 1):
        customer = random.choice(customers)
        order_date = generate_date(
            datetime.strptime(customer['registration_date'], '%Y-%m-%d %H:%M:%S'),
            datetime(2024, 12, 31)
        )
        
        # Generate order amounts
        subtotal = round(random.uniform(25.0, 500.0), 2)
        tax_amount = round(subtotal * 0.18, 2)  # 18% GST
        shipping_cost = round(random.uniform(0.0, 50.0), 2)
        discount_amount = round(random.uniform(0.0, subtotal * 0.1), 2)
        total_amount = subtotal + tax_amount + shipping_cost - discount_amount
        
        order_status = random.choices(
            ['Pending', 'Processing', 'Shipped', 'Delivered', 'Cancelled'],
            weights=[0.05, 0.1, 0.15, 0.65, 0.05]
        )[0]
        
        shipped_date = ''
        delivered_date = ''
        if order_status in ['Shipped', 'Delivered']:
            shipped_date = (order_date + timedelta(days=random.randint(1, 3))).strftime('%Y-%m-%d %H:%M:%S')
            if order_status == 'Delivered':
                delivered_date = (order_date + timedelta(days=random.randint(4, 10))).strftime('%Y-%m-%d %H:%M:%S')
        
        order = {
            'order_id': i,
            'customer_id': customer['customer_id'],
            'order_date': order_date.strftime('%Y-%m-%d %H:%M:%S'),
            'order_status': order_status,
            'payment_method': random.choice(['Credit Card', 'Debit Card', 'UPI', 'Net Banking']),
            'payment_status': 'Captured' if order_status != 'Cancelled' else 'Failed',
            'shipping_method': random.choice(['Standard', 'Express', 'Same Day']),
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
            'currency': 'INR',
            'coupon_code': f"SAVE{random.randint(5,25)}" if random.random() < 0.2 else '',
            'order_source': random.choice(['Website', 'Mobile App', 'Phone']),
            'shipped_date': shipped_date,
            'delivered_date': delivered_date,
            'created_at': order_date.strftime('%Y-%m-%d %H:%M:%S'),
            'updated_at': (delivered_date if delivered_date else shipped_date if shipped_date else order_date.strftime('%Y-%m-%d %H:%M:%S'))
        }
        orders.append(order)
        
        # Generate order items (1-3 items per order)
        num_items = random.randint(1, 3)
        selected_products = random.sample(products, min(num_items, len(products)))
        
        for product in selected_products:
            quantity = random.randint(1, 3)
            unit_price = product['price']
            line_total = quantity * unit_price
            
            order_item = {
                'order_item_id': item_id,
                'order_id': i,
                'product_id': product['product_id'],
                'product_name': product['product_name'],
                'sku': product['sku'],
                'quantity': quantity,
                'unit_price': unit_price,
                'line_total': line_total,
                'created_at': order_date.strftime('%Y-%m-%d %H:%M:%S'),
                'updated_at': order_date.strftime('%Y-%m-%d %H:%M:%S')
            }
            order_items.append(order_item)
            item_id += 1
    
    return orders, order_items

def save_to_csv(data, filename):
    """Save data to CSV file"""
    if not data:
        print(f"No data to save for {filename}")
        return
    
    filepath = os.path.join(OUTPUT_DIR, f"{filename}.csv")
    
    with open(filepath, 'w', newline='', encoding='utf-8') as csvfile:
        fieldnames = data[0].keys()
        writer = csv.DictWriter(csvfile, fieldnames=fieldnames)
        writer.writeheader()
        writer.writerows(data)
    
    print(f"Saved {len(data)} records to {filepath}")

def main():
    """Main function"""
    print("Starting simple data generation...")
    
    # Create output directory
    os.makedirs(OUTPUT_DIR, exist_ok=True)
    
    # Generate data
    customers = generate_customers()
    products = generate_products()
    orders, order_items = generate_orders(customers, products)
    
    # Save to CSV files
    save_to_csv(customers, 'customers')
    save_to_csv(products, 'products')
    save_to_csv(orders, 'orders')
    save_to_csv(order_items, 'order_items')
    
    print("\nData generation completed successfully!")
    print(f"Generated files in: {OUTPUT_DIR}")
    print(f"- Customers: {len(customers):,}")
    print(f"- Products: {len(products):,}")
    print(f"- Orders: {len(orders):,}")
    print(f"- Order Items: {len(order_items):,}")

if __name__ == "__main__":
    main()
