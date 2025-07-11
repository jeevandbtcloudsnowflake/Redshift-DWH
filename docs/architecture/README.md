# 🏗️ AWS Architecture Diagrams

This directory contains comprehensive architecture diagrams for the E-commerce Data Warehouse project with **actual AWS service representations**.

## 📊 **Available Diagram Formats**

### **🌐 Interactive HTML Diagram**
**File**: `AWS_ARCHITECTURE_HTML.html`
- ✅ **Professional layout** with AWS service colors
- ✅ **Interactive elements** with hover effects
- ✅ **Print-friendly** design for PDF generation
- ✅ **Responsive design** for different screen sizes
- ✅ **Service categorization** with color coding

**How to use**:
1. Open `AWS_ARCHITECTURE_HTML.html` in your browser
2. Press `Ctrl+P` (or `Cmd+P` on Mac) to print
3. Select "Save as PDF" as destination
4. Choose **Landscape orientation**
5. Enable **Background graphics**

### **🐍 Python Diagram Generator**
**File**: `AWS_ARCHITECTURE_DIAGRAM.py`
- ✅ **Programmatic generation** using matplotlib
- ✅ **Multiple export formats** (PNG, PDF, SVG)
- ✅ **High-resolution output** (300 DPI)
- ✅ **Customizable styling** and colors

**How to use**:
```bash
cd docs/architecture
python AWS_ARCHITECTURE_DIAGRAM.py
```

### **📄 PDF Generation Script**
**File**: `../../scripts/utilities/generate_architecture_pdf.py`
- ✅ **Automated PDF generation** from HTML
- ✅ **Multiple generation methods** (WeasyPrint, Selenium, matplotlib)
- ✅ **Screenshot capture** for image formats
- ✅ **Fallback options** if one method fails

**How to use**:
```bash
cd scripts/utilities
python generate_architecture_pdf.py
```

## 🎯 **Architecture Components Shown**

### **📊 Data Sources**
- CSV Files (Sample Data)
- APIs (Real-time Data)
- Databases (Transactional Systems)

### **🪣 Data Ingestion & Storage**
- **Amazon S3** - Raw Data Bucket
- **Amazon S3** - Processed Data Bucket
- **Amazon S3** - Scripts Bucket
- **Amazon S3** - Logs Bucket

### **⚙️ ETL & Data Processing**
- **AWS Glue Crawler** - Data Discovery
- **AWS Glue ETL Jobs** - Data Processing
- **AWS Glue Data Catalog** - Metadata Repository
- **AWS Glue Workflows** - ETL Orchestration
- **AWS Step Functions** - Advanced Orchestration
- **Amazon EventBridge** - Event-Driven Automation
- **AWS Lambda** - Serverless Functions

### **🏢 Data Warehouse & Analytics**
- **Amazon Redshift** - ra3.xlplus Cluster
- **Redshift Spectrum** - Query S3 Data
- **Amazon QuickSight** - BI Dashboards
- **Tableau** - Advanced Analytics

### **🔒 Security & Compliance**
- **AWS IAM** - Roles & Policies
- **AWS KMS** - Encryption Keys
- **AWS Secrets Manager** - Credential Management
- **AWS Config** - Compliance Monitoring
- **AWS CloudTrail** - Audit Logging
- **AWS GuardDuty** - Threat Detection
- **AWS Security Hub** - Centralized Security
- **Amazon VPC** - Network Isolation

### **📊 Monitoring & Observability**
- **Amazon CloudWatch** - Metrics & Dashboards
- **CloudWatch Logs** - Centralized Logging
- **CloudWatch Alarms** - Automated Alerting
- **Amazon SNS** - Notifications
- **DevOps Dashboard** - Operational Metrics

### **💾 Backup & Disaster Recovery**
- **AWS Backup** - Automated Backups
- **S3 Cross-Region Replication** - Disaster Recovery
- **Redshift Snapshots** - Point-in-Time Recovery

### **🚀 DevOps & CI/CD**
- **GitHub Actions** - CI/CD Pipelines
- **Terraform** - Infrastructure as Code
- **Infrastructure as Code** - Automated Deployment

## 🎨 **Color Coding**

The diagrams use official AWS color schemes:

- 🟠 **Orange (#FF9900)** - Storage & Processing Services
- 🔵 **Blue (#3F48CC)** - Analytics & Data Warehouse
- 🔴 **Red (#DD344C)** - Security & Compliance
- 🟢 **Green (#7AA116)** - Monitoring & Observability
- 🔵 **Light Blue (#4B92DB)** - Backup & Disaster Recovery
- ⚫ **Dark Blue (#232F3E)** - DevOps & CI/CD

## 📋 **Data Flow Visualization**

The diagrams show the complete data flow:

```
📄 Data Sources → 🪣 S3 Storage → ⚙️ Glue ETL → 🏢 Redshift → 📊 Analytics
```

With supporting services:
- **Security** - Protecting all layers
- **Monitoring** - Observing all components
- **Backup** - Protecting all data
- **DevOps** - Automating all processes

## 🚀 **Quick Start**

### **Method 1: View HTML Diagram**
```bash
# Open in browser
open docs/architecture/AWS_ARCHITECTURE_HTML.html
# or
start docs/architecture/AWS_ARCHITECTURE_HTML.html
```

### **Method 2: Generate PDF Automatically**
```bash
# Install requirements
pip install matplotlib weasyprint selenium webdriver-manager

# Generate diagrams
python scripts/utilities/generate_architecture_pdf.py
```

### **Method 3: Manual PDF Creation**
1. Open `AWS_ARCHITECTURE_HTML.html` in Chrome/Firefox
2. Press `Ctrl+P` to print
3. Select "Save as PDF"
4. Choose "Landscape" orientation
5. Enable "Background graphics"
6. Click "Save"

## 📁 **Output Files**

After generation, you'll find these files in `docs/architecture/diagrams/`:

- `AWS_Architecture_Diagram.png` - High-resolution image
- `AWS_Architecture_Diagram.pdf` - PDF document
- `AWS_Architecture_Diagram.svg` - Scalable vector graphic
- `AWS_Architecture_Simple.pdf` - Simple matplotlib version

## 🎯 **Use Cases**

### **📋 Documentation**
- Technical documentation
- Architecture reviews
- System design documents

### **📊 Presentations**
- Executive presentations
- Team meetings
- Client demonstrations

### **🎓 Training**
- Team onboarding
- Architecture walkthroughs
- Educational materials

### **📈 Proposals**
- Project proposals
- Architecture decisions
- Technical specifications

## 🔧 **Customization**

### **Modify HTML Diagram**
Edit `AWS_ARCHITECTURE_HTML.html`:
- Change colors in CSS section
- Add/remove services
- Modify layout and styling

### **Modify Python Generator**
Edit `AWS_ARCHITECTURE_DIAGRAM.py`:
- Adjust figure size and DPI
- Change service positions
- Modify colors and styling

### **Add New Services**
To add new AWS services:
1. Add service box in appropriate layer
2. Use correct AWS color scheme
3. Add to legend if new category
4. Update data flow arrows if needed

## 📞 **Support**

If you encounter issues:

1. **HTML not displaying properly**:
   - Try different browser (Chrome recommended)
   - Check if file path is correct
   - Ensure all CSS is loading

2. **PDF generation failing**:
   - Install required Python packages
   - Try manual print-to-PDF method
   - Check browser print settings

3. **Images not generating**:
   - Verify matplotlib installation
   - Check file permissions
   - Ensure output directory exists

## 🎉 **Features**

### **✅ Professional Quality**
- AWS official color schemes
- Clean, modern design
- High-resolution output
- Print-optimized layouts

### **✅ Comprehensive Coverage**
- 20+ AWS services shown
- Complete data flow
- All architecture layers
- Supporting services included

### **✅ Multiple Formats**
- Interactive HTML
- High-resolution PNG
- Vector SVG
- Print-ready PDF

### **✅ Easy to Use**
- One-click generation
- Browser-based viewing
- Automated workflows
- Multiple export options

---

## 🏆 **Architecture Summary**

This comprehensive architecture diagram shows:

- **🏢 Enterprise-grade** data warehouse implementation
- **🔒 Security-first** design with comprehensive compliance
- **📊 Complete data flow** from sources to analytics
- **🚀 DevOps automation** with Infrastructure as Code
- **💾 Disaster recovery** with cross-region backup
- **📈 Scalable architecture** that grows with business needs

**Perfect for presentations, documentation, and team communication!** 🎯
