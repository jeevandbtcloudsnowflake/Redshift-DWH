# Sample Data Generation

This directory contains tools and schemas for generating realistic sample data for the e-commerce data warehouse project.

## Directory Structure

```
data/
├── generators/              # Data generation scripts
│   ├── generate_sample_data.py    # Main data generator
│   ├── config.yaml               # Configuration file
│   └── requirements.txt          # Python dependencies
├── schemas/                 # Data schemas and definitions
│   ├── customers.json           # Customer table schema
│   ├── products.json            # Product table schema
│   ├── orders.json              # Orders table schema
│   ├── order_items.json         # Order items table schema
│   └── web_events.json          # Web events table schema
└── sample_data/            # Generated sample data files
    ├── customers.csv
    ├── products.csv
    ├── orders.csv
    ├── order_items.csv
    └── web_events.csv
```

## Data Model Overview

### Core Entities

1. **Customers** - Customer master data with demographics and contact information
2. **Products** - Product catalog with categories, pricing, and inventory
3. **Orders** - Order transactions with payment and shipping details
4. **Order Items** - Individual line items within orders
5. **Web Events** - User interaction events on the website

### Relationships

- Customers → Orders (1:N)
- Orders → Order Items (1:N)
- Products → Order Items (1:N)
- Customers → Web Events (1:N)
- Products → Web Events (1:N)

## Data Generation

### Quick Start

```bash
# Install dependencies
pip install -r data/generators/requirements.txt

# Generate development data (small dataset)
python scripts/utilities/generate_data.py --environment dev

# Generate staging data (medium dataset)
python scripts/utilities/generate_data.py --environment staging

# Generate production data (large dataset)
python scripts/utilities/generate_data.py --environment prod
```

### Custom Data Generation

```bash
# Generate specific quantities
python scripts/utilities/generate_data.py \
  --customers 5000 \
  --products 2000 \
  --orders 25000 \
  --output-dir data/custom_data

# Generate with specific seed for reproducibility
python scripts/utilities/generate_data.py \
  --environment dev \
  --seed 12345
```

### Environment Configurations

| Environment | Customers | Products | Orders | Order Items | Web Events |
|-------------|-----------|----------|--------|-------------|------------|
| **dev**     | 1,000     | 500      | 5,000  | 15,000      | 50,000     |
| **staging** | 10,000    | 5,000    | 50,000 | 150,000     | 500,000    |
| **prod**    | 100,000   | 50,000   | 500,000| 1,500,000   | 5,000,000  |

## Data Quality Features

### Realistic Data Patterns

- **Customer Demographics**: Realistic names, addresses, and contact information
- **Product Catalog**: Hierarchical categories with appropriate pricing
- **Order Behavior**: Realistic order patterns and seasonal variations
- **Web Analytics**: User journey patterns and conversion funnels

### Data Relationships

- **Referential Integrity**: All foreign keys reference valid records
- **Temporal Consistency**: Events occur in logical chronological order
- **Business Rules**: Order totals calculated correctly, status transitions valid

### Data Variety

- **Geographic Distribution**: Customers across all US states
- **Product Categories**: Electronics, Clothing, Home & Garden, Sports, Books
- **Payment Methods**: Credit cards, digital wallets, bank transfers
- **Device Types**: Desktop, mobile, and tablet traffic

## Schema Definitions

Each table schema is defined in JSON format with:

- **Column Definitions**: Name, type, constraints, descriptions
- **Relationships**: Foreign key references
- **Indexes**: Performance optimization hints
- **Business Rules**: Valid values and constraints

### Example Schema Structure

```json
{
  "table_name": "customers",
  "description": "Customer master data",
  "columns": [
    {
      "name": "customer_id",
      "type": "INTEGER",
      "description": "Unique customer identifier",
      "primary_key": true,
      "nullable": false
    }
  ],
  "indexes": [
    {
      "name": "idx_customers_email",
      "columns": ["email"],
      "unique": true
    }
  ]
}
```

## Data Usage

### ETL Testing

The generated data is designed for:

- **ETL Pipeline Testing**: Validate data transformations
- **Performance Testing**: Load testing with realistic data volumes
- **Data Quality Testing**: Verify data validation rules
- **Integration Testing**: End-to-end pipeline validation

### Analytics Use Cases

- **Sales Analysis**: Revenue trends, customer segmentation
- **Product Performance**: Best sellers, category analysis
- **Customer Behavior**: Purchase patterns, lifetime value
- **Web Analytics**: Conversion funnels, user engagement

## File Formats

### CSV Files

- **Primary Format**: Easy to import into databases and analytics tools
- **Headers**: Column names in first row
- **Encoding**: UTF-8
- **Delimiters**: Comma-separated

### JSON Files

- **Sample Data**: Small subsets for inspection and testing
- **Nested Structures**: Complex data relationships
- **API Testing**: Mock data for API development

## Best Practices

### Data Generation

1. **Reproducibility**: Use seeds for consistent test data
2. **Scalability**: Generate appropriate volumes for each environment
3. **Realism**: Maintain realistic business patterns
4. **Performance**: Optimize for large dataset generation

### Data Management

1. **Version Control**: Track schema changes and data versions
2. **Documentation**: Maintain clear data dictionaries
3. **Validation**: Verify data quality after generation
4. **Cleanup**: Remove old datasets to save storage

## Troubleshooting

### Common Issues

1. **Memory Errors**: Reduce dataset size or use chunking
2. **Disk Space**: Monitor available storage for large datasets
3. **Performance**: Use appropriate hardware for large generations
4. **Dependencies**: Ensure all Python packages are installed

### Performance Tips

- Use SSD storage for faster I/O
- Increase available RAM for large datasets
- Consider parallel processing for very large datasets
- Monitor system resources during generation

## Contributing

When adding new data types or modifying schemas:

1. Update schema JSON files
2. Modify data generator accordingly
3. Update documentation
4. Test with all environment sizes
5. Verify data quality and relationships
