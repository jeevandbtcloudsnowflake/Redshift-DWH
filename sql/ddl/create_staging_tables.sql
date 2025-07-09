-- Staging Tables for E-Commerce Data Warehouse
-- These tables are used for initial data loading and validation

-- Drop existing staging tables if they exist
DROP TABLE IF EXISTS staging.stg_customers CASCADE;
DROP TABLE IF EXISTS staging.stg_products CASCADE;
DROP TABLE IF EXISTS staging.stg_orders CASCADE;
DROP TABLE IF EXISTS staging.stg_order_items CASCADE;
DROP TABLE IF EXISTS staging.stg_web_events CASCADE;

-- Create staging schema if it doesn't exist
CREATE SCHEMA IF NOT EXISTS staging;

-- Staging table for customers
CREATE TABLE staging.stg_customers (
    customer_id INTEGER,
    first_name VARCHAR(50),
    last_name VARCHAR(50),
    email VARCHAR(100),
    phone VARCHAR(20),
    date_of_birth DATE,
    gender VARCHAR(10),
    address_line1 VARCHAR(100),
    address_line2 VARCHAR(100),
    city VARCHAR(50),
    state VARCHAR(50),
    postal_code VARCHAR(20),
    country VARCHAR(50),
    customer_segment VARCHAR(20),
    registration_date TIMESTAMP,
    last_login_date TIMESTAMP,
    is_active BOOLEAN,
    created_at TIMESTAMP,
    updated_at TIMESTAMP,
    -- ETL metadata
    etl_batch_id VARCHAR(50),
    etl_loaded_at TIMESTAMP DEFAULT GETDATE()
)
DISTSTYLE KEY
DISTKEY (customer_id)
SORTKEY (customer_id, registration_date);

-- Staging table for products
CREATE TABLE staging.stg_products (
    product_id INTEGER,
    product_name VARCHAR(200),
    product_description VARCHAR(MAX),
    category_id INTEGER,
    category_name VARCHAR(100),
    subcategory_name VARCHAR(100),
    brand VARCHAR(100),
    sku VARCHAR(50),
    price DECIMAL(10,2),
    cost DECIMAL(10,2),
    weight DECIMAL(8,2),
    dimensions VARCHAR(50),
    color VARCHAR(30),
    size VARCHAR(20),
    material VARCHAR(50),
    stock_quantity INTEGER,
    reorder_level INTEGER,
    supplier_id INTEGER,
    is_active BOOLEAN,
    launch_date DATE,
    created_at TIMESTAMP,
    updated_at TIMESTAMP,
    -- ETL metadata
    etl_batch_id VARCHAR(50),
    etl_loaded_at TIMESTAMP DEFAULT GETDATE()
)
DISTSTYLE KEY
DISTKEY (product_id)
SORTKEY (product_id, category_id);

-- Staging table for orders
CREATE TABLE staging.stg_orders (
    order_id INTEGER,
    customer_id INTEGER,
    order_date TIMESTAMP,
    order_status VARCHAR(20),
    payment_method VARCHAR(30),
    payment_status VARCHAR(20),
    shipping_method VARCHAR(30),
    shipping_address_line1 VARCHAR(100),
    shipping_address_line2 VARCHAR(100),
    shipping_city VARCHAR(50),
    shipping_state VARCHAR(50),
    shipping_postal_code VARCHAR(20),
    shipping_country VARCHAR(50),
    subtotal DECIMAL(10,2),
    tax_amount DECIMAL(10,2),
    shipping_cost DECIMAL(10,2),
    discount_amount DECIMAL(10,2),
    total_amount DECIMAL(10,2),
    currency VARCHAR(3),
    coupon_code VARCHAR(50),
    order_source VARCHAR(20),
    shipped_date TIMESTAMP,
    delivered_date TIMESTAMP,
    created_at TIMESTAMP,
    updated_at TIMESTAMP,
    -- ETL metadata
    etl_batch_id VARCHAR(50),
    etl_loaded_at TIMESTAMP DEFAULT GETDATE()
)
DISTSTYLE KEY
DISTKEY (customer_id)
SORTKEY (order_date, order_id);

-- Staging table for order items
CREATE TABLE staging.stg_order_items (
    order_item_id INTEGER,
    order_id INTEGER,
    product_id INTEGER,
    product_name VARCHAR(200),
    sku VARCHAR(50),
    quantity INTEGER,
    unit_price DECIMAL(10,2),
    line_total DECIMAL(10,2),
    created_at TIMESTAMP,
    updated_at TIMESTAMP,
    -- ETL metadata
    etl_batch_id VARCHAR(50),
    etl_loaded_at TIMESTAMP DEFAULT GETDATE()
)
DISTSTYLE KEY
DISTKEY (order_id)
SORTKEY (order_id, product_id);

-- Staging table for web events
CREATE TABLE staging.stg_web_events (
    event_id BIGINT,
    customer_id INTEGER,
    session_id VARCHAR(100),
    event_type VARCHAR(50),
    event_timestamp TIMESTAMP,
    product_id INTEGER,
    category_id INTEGER,
    page_url VARCHAR(500),
    referrer_url VARCHAR(500),
    user_agent VARCHAR(500),
    ip_address VARCHAR(45),
    device_type VARCHAR(20),
    browser VARCHAR(50),
    os VARCHAR(50),
    created_at TIMESTAMP,
    -- ETL metadata
    etl_batch_id VARCHAR(50),
    etl_loaded_at TIMESTAMP DEFAULT GETDATE()
)
DISTSTYLE KEY
DISTKEY (customer_id)
SORTKEY (event_timestamp, customer_id);

-- Grant permissions to ETL role
GRANT ALL ON SCHEMA staging TO "ecommerce-dwh-dev-glue-service-role";
GRANT ALL ON ALL TABLES IN SCHEMA staging TO "ecommerce-dwh-dev-glue-service-role";

-- Create indexes for better query performance
-- Note: Redshift doesn't support traditional indexes, but we use sort keys instead

COMMENT ON SCHEMA staging IS 'Staging schema for raw data ingestion and validation';
COMMENT ON TABLE staging.stg_customers IS 'Staging table for customer data';
COMMENT ON TABLE staging.stg_products IS 'Staging table for product catalog data';
COMMENT ON TABLE staging.stg_orders IS 'Staging table for order transaction data';
COMMENT ON TABLE staging.stg_order_items IS 'Staging table for order line items';
COMMENT ON TABLE staging.stg_web_events IS 'Staging table for website interaction events';
