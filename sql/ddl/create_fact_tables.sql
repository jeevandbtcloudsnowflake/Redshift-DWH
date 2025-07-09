-- Fact Tables for E-Commerce Data Warehouse
-- Star schema fact tables for transactional and event data

-- Create facts schema if it doesn't exist
CREATE SCHEMA IF NOT EXISTS facts;

-- Drop existing fact tables if they exist
DROP TABLE IF EXISTS facts.fact_sales CASCADE;
DROP TABLE IF EXISTS facts.fact_web_events CASCADE;
DROP TABLE IF EXISTS facts.fact_inventory CASCADE;

-- Sales Fact Table (Order Items Level)
CREATE TABLE facts.fact_sales (
    sales_key BIGINT IDENTITY(1,1) PRIMARY KEY,
    -- Dimension Keys
    order_date_key INTEGER NOT NULL,
    customer_key INTEGER NOT NULL,
    product_key INTEGER NOT NULL,
    shipping_geography_key INTEGER,
    -- Degenerate Dimensions
    order_id INTEGER NOT NULL,
    order_item_id INTEGER NOT NULL,
    sku VARCHAR(50),
    -- Measures
    quantity INTEGER NOT NULL,
    unit_price DECIMAL(10,2) NOT NULL,
    line_total DECIMAL(10,2) NOT NULL,
    unit_cost DECIMAL(10,2),
    line_cost DECIMAL(10,2),
    line_profit DECIMAL(10,2),
    line_profit_margin DECIMAL(5,4),
    -- Order Level Measures (for aggregation)
    order_subtotal DECIMAL(10,2),
    order_tax_amount DECIMAL(10,2),
    order_shipping_cost DECIMAL(10,2),
    order_discount_amount DECIMAL(10,2),
    order_total_amount DECIMAL(10,2),
    -- Additional Attributes
    order_status VARCHAR(20),
    payment_method VARCHAR(30),
    payment_status VARCHAR(20),
    shipping_method VARCHAR(30),
    order_source VARCHAR(20),
    coupon_code VARCHAR(50),
    currency VARCHAR(3),
    -- Date Attributes for Performance
    order_year INTEGER,
    order_month INTEGER,
    order_quarter INTEGER,
    order_day_of_week INTEGER,
    is_weekend_order BOOLEAN,
    -- Shipping Metrics
    days_to_ship INTEGER,
    days_to_deliver INTEGER,
    shipped_date TIMESTAMP,
    delivered_date TIMESTAMP,
    -- ETL Metadata
    etl_batch_id VARCHAR(50),
    created_at TIMESTAMP DEFAULT GETDATE(),
    updated_at TIMESTAMP DEFAULT GETDATE()
)
DISTSTYLE KEY
DISTKEY (customer_key)
SORTKEY (order_date_key, customer_key);

-- Web Events Fact Table
CREATE TABLE facts.fact_web_events (
    web_event_key BIGINT IDENTITY(1,1) PRIMARY KEY,
    -- Dimension Keys
    event_date_key INTEGER NOT NULL,
    customer_key INTEGER,
    product_key INTEGER,
    -- Degenerate Dimensions
    event_id BIGINT NOT NULL,
    session_id VARCHAR(100) NOT NULL,
    -- Event Attributes
    event_type VARCHAR(50) NOT NULL,
    event_timestamp TIMESTAMP NOT NULL,
    page_url VARCHAR(500),
    referrer_url VARCHAR(500),
    -- Device/Browser Attributes
    device_type VARCHAR(20),
    browser VARCHAR(50),
    os VARCHAR(50),
    user_agent VARCHAR(500),
    ip_address VARCHAR(45),
    -- Measures (for aggregation)
    event_count INTEGER DEFAULT 1,
    session_duration_seconds INTEGER,
    page_views_in_session INTEGER,
    -- Conversion Flags
    is_conversion_event BOOLEAN DEFAULT FALSE,
    is_purchase_event BOOLEAN DEFAULT FALSE,
    conversion_value DECIMAL(10,2),
    -- Date Attributes for Performance
    event_year INTEGER,
    event_month INTEGER,
    event_quarter INTEGER,
    event_day_of_week INTEGER,
    event_hour INTEGER,
    -- ETL Metadata
    etl_batch_id VARCHAR(50),
    created_at TIMESTAMP DEFAULT GETDATE()
)
DISTSTYLE KEY
DISTKEY (customer_key)
SORTKEY (event_date_key, event_timestamp);

-- Inventory Fact Table (Daily Snapshots)
CREATE TABLE facts.fact_inventory (
    inventory_key BIGINT IDENTITY(1,1) PRIMARY KEY,
    -- Dimension Keys
    snapshot_date_key INTEGER NOT NULL,
    product_key INTEGER NOT NULL,
    -- Measures
    stock_quantity INTEGER NOT NULL,
    reorder_level INTEGER,
    stock_value DECIMAL(12,2),
    units_sold_today INTEGER DEFAULT 0,
    units_received_today INTEGER DEFAULT 0,
    -- Stock Status Flags
    is_out_of_stock BOOLEAN DEFAULT FALSE,
    is_low_stock BOOLEAN DEFAULT FALSE,
    is_overstock BOOLEAN DEFAULT FALSE,
    days_of_supply INTEGER,
    -- Movement Metrics
    stock_turnover_rate DECIMAL(8,4),
    avg_daily_sales DECIMAL(8,2),
    -- Date Attributes
    snapshot_year INTEGER,
    snapshot_month INTEGER,
    snapshot_quarter INTEGER,
    -- ETL Metadata
    etl_batch_id VARCHAR(50),
    created_at TIMESTAMP DEFAULT GETDATE()
)
DISTSTYLE KEY
DISTKEY (product_key)
SORTKEY (snapshot_date_key, product_key);

-- Create foreign key constraints (informational in Redshift)
-- Sales Fact Foreign Keys
ALTER TABLE facts.fact_sales 
ADD CONSTRAINT fk_sales_order_date 
FOREIGN KEY (order_date_key) REFERENCES dimensions.dim_date(date_key);

ALTER TABLE facts.fact_sales 
ADD CONSTRAINT fk_sales_customer 
FOREIGN KEY (customer_key) REFERENCES dimensions.dim_customer(customer_key);

ALTER TABLE facts.fact_sales 
ADD CONSTRAINT fk_sales_product 
FOREIGN KEY (product_key) REFERENCES dimensions.dim_product(product_key);

ALTER TABLE facts.fact_sales 
ADD CONSTRAINT fk_sales_geography 
FOREIGN KEY (shipping_geography_key) REFERENCES dimensions.dim_geography(geography_key);

-- Web Events Fact Foreign Keys
ALTER TABLE facts.fact_web_events 
ADD CONSTRAINT fk_web_events_date 
FOREIGN KEY (event_date_key) REFERENCES dimensions.dim_date(date_key);

ALTER TABLE facts.fact_web_events 
ADD CONSTRAINT fk_web_events_customer 
FOREIGN KEY (customer_key) REFERENCES dimensions.dim_customer(customer_key);

ALTER TABLE facts.fact_web_events 
ADD CONSTRAINT fk_web_events_product 
FOREIGN KEY (product_key) REFERENCES dimensions.dim_product(product_key);

-- Inventory Fact Foreign Keys
ALTER TABLE facts.fact_inventory 
ADD CONSTRAINT fk_inventory_date 
FOREIGN KEY (snapshot_date_key) REFERENCES dimensions.dim_date(date_key);

ALTER TABLE facts.fact_inventory 
ADD CONSTRAINT fk_inventory_product 
FOREIGN KEY (product_key) REFERENCES dimensions.dim_product(product_key);

-- Create additional indexes for query performance
CREATE INDEX idx_fact_sales_order_id ON facts.fact_sales(order_id);
CREATE INDEX idx_fact_sales_product_key ON facts.fact_sales(product_key);
CREATE INDEX idx_fact_sales_order_year_month ON facts.fact_sales(order_year, order_month);

CREATE INDEX idx_fact_web_events_session ON facts.fact_web_events(session_id);
CREATE INDEX idx_fact_web_events_event_type ON facts.fact_web_events(event_type);
CREATE INDEX idx_fact_web_events_timestamp ON facts.fact_web_events(event_timestamp);

CREATE INDEX idx_fact_inventory_snapshot_date ON facts.fact_inventory(snapshot_date_key);
CREATE INDEX idx_fact_inventory_stock_status ON facts.fact_inventory(is_out_of_stock, is_low_stock);

-- Grant permissions to ETL role
GRANT ALL ON SCHEMA facts TO "ecommerce-dwh-dev-glue-service-role";
GRANT ALL ON ALL TABLES IN SCHEMA facts TO "ecommerce-dwh-dev-glue-service-role";

-- Add table comments
COMMENT ON SCHEMA facts IS 'Fact tables schema for transactional and event data';
COMMENT ON TABLE facts.fact_sales IS 'Sales fact table at order item level with comprehensive metrics';
COMMENT ON TABLE facts.fact_web_events IS 'Web events fact table for user behavior analysis';
COMMENT ON TABLE facts.fact_inventory IS 'Daily inventory snapshots for stock management and analysis';

-- Add column comments for key measures
COMMENT ON COLUMN facts.fact_sales.line_profit IS 'Calculated as line_total - line_cost';
COMMENT ON COLUMN facts.fact_sales.line_profit_margin IS 'Calculated as line_profit / line_total';
COMMENT ON COLUMN facts.fact_sales.days_to_ship IS 'Business days between order and ship date';
COMMENT ON COLUMN facts.fact_sales.days_to_deliver IS 'Business days between order and delivery date';

COMMENT ON COLUMN facts.fact_web_events.is_conversion_event IS 'True for events that represent conversions (add to cart, purchase)';
COMMENT ON COLUMN facts.fact_web_events.conversion_value IS 'Monetary value associated with conversion events';

COMMENT ON COLUMN facts.fact_inventory.days_of_supply IS 'Current stock quantity divided by average daily sales';
COMMENT ON COLUMN facts.fact_inventory.stock_turnover_rate IS 'Annual rate at which inventory is sold and replaced';
