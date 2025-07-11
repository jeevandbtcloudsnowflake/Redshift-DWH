#!/usr/bin/env python3
"""
Generate Architecture PDF and Images
Converts HTML architecture diagram to PDF and image formats
"""

import os
import sys
import subprocess
import webbrowser
from pathlib import Path

def install_requirements():
    """Install required packages for PDF generation"""
    packages = [
        'weasyprint',
        'Pillow',
        'selenium',
        'webdriver-manager'
    ]
    
    for package in packages:
        try:
            __import__(package.replace('-', '_'))
            print(f"✅ {package} already installed")
        except ImportError:
            print(f"📦 Installing {package}...")
            subprocess.check_call([sys.executable, '-m', 'pip', 'install', package])

def generate_pdf_weasyprint():
    """Generate PDF using WeasyPrint"""
    try:
        from weasyprint import HTML, CSS
        
        # Paths
        html_file = Path('docs/architecture/AWS_ARCHITECTURE_HTML.html')
        pdf_file = Path('docs/architecture/diagrams/AWS_Architecture_Diagram.pdf')
        
        # Create output directory
        pdf_file.parent.mkdir(parents=True, exist_ok=True)
        
        # Generate PDF
        print("🔄 Generating PDF using WeasyPrint...")
        HTML(filename=str(html_file)).write_pdf(str(pdf_file))
        
        print(f"✅ PDF generated: {pdf_file}")
        return True
        
    except Exception as e:
        print(f"❌ WeasyPrint failed: {str(e)}")
        return False

def generate_pdf_browser():
    """Generate PDF using browser print functionality"""
    try:
        from selenium import webdriver
        from selenium.webdriver.chrome.options import Options
        from selenium.webdriver.chrome.service import Service
        from webdriver_manager.chrome import ChromeDriverManager
        
        # Setup Chrome options
        chrome_options = Options()
        chrome_options.add_argument('--headless')
        chrome_options.add_argument('--no-sandbox')
        chrome_options.add_argument('--disable-dev-shm-usage')
        chrome_options.add_argument('--print-to-pdf')
        
        # Paths
        html_file = Path('docs/architecture/AWS_ARCHITECTURE_HTML.html').resolve()
        pdf_file = Path('docs/architecture/diagrams/AWS_Architecture_Diagram_Browser.pdf').resolve()
        
        # Create output directory
        pdf_file.parent.mkdir(parents=True, exist_ok=True)
        
        print("🔄 Generating PDF using Chrome browser...")
        
        # Setup driver
        service = Service(ChromeDriverManager().install())
        driver = webdriver.Chrome(service=service, options=chrome_options)
        
        # Load HTML file
        driver.get(f"file://{html_file}")
        
        # Print to PDF
        pdf_data = driver.execute_cdp_cmd('Page.printToPDF', {
            'format': 'A3',
            'landscape': True,
            'printBackground': True,
            'marginTop': 0.4,
            'marginBottom': 0.4,
            'marginLeft': 0.4,
            'marginRight': 0.4
        })
        
        # Save PDF
        with open(pdf_file, 'wb') as f:
            import base64
            f.write(base64.b64decode(pdf_data['data']))
        
        driver.quit()
        
        print(f"✅ PDF generated: {pdf_file}")
        return True
        
    except Exception as e:
        print(f"❌ Browser PDF generation failed: {str(e)}")
        return False

def generate_screenshot():
    """Generate screenshot of the architecture"""
    try:
        from selenium import webdriver
        from selenium.webdriver.chrome.options import Options
        from selenium.webdriver.chrome.service import Service
        from webdriver_manager.chrome import ChromeDriverManager
        
        # Setup Chrome options
        chrome_options = Options()
        chrome_options.add_argument('--headless')
        chrome_options.add_argument('--no-sandbox')
        chrome_options.add_argument('--disable-dev-shm-usage')
        chrome_options.add_argument('--window-size=1920,1080')
        
        # Paths
        html_file = Path('docs/architecture/AWS_ARCHITECTURE_HTML.html').resolve()
        png_file = Path('docs/architecture/diagrams/AWS_Architecture_Diagram.png')
        
        # Create output directory
        png_file.parent.mkdir(parents=True, exist_ok=True)
        
        print("🔄 Generating screenshot...")
        
        # Setup driver
        service = Service(ChromeDriverManager().install())
        driver = webdriver.Chrome(service=service, options=chrome_options)
        
        # Load HTML file
        driver.get(f"file://{html_file}")
        
        # Take screenshot
        driver.save_screenshot(str(png_file))
        driver.quit()
        
        print(f"✅ Screenshot generated: {png_file}")
        return True
        
    except Exception as e:
        print(f"❌ Screenshot generation failed: {str(e)}")
        return False

def create_simple_pdf():
    """Create a simple PDF using matplotlib"""
    try:
        import matplotlib.pyplot as plt
        from matplotlib.backends.backend_pdf import PdfPages
        import matplotlib.patches as patches
        
        # Create figure
        fig, ax = plt.subplots(1, 1, figsize=(16, 12))
        ax.set_xlim(0, 16)
        ax.set_ylim(0, 12)
        ax.axis('off')
        
        # Title
        ax.text(8, 11.5, 'E-commerce Data Warehouse - AWS Architecture', 
                ha='center', va='center', fontsize=20, weight='bold', color='#232F3E')
        
        # AWS Services
        services = [
            # (x, y, width, height, name, color)
            (1, 9, 2, 1.5, 'Amazon S3\nData Lake', '#FF9900'),
            (4, 9, 2, 1.5, 'AWS Glue\nETL Pipeline', '#FF9900'),
            (7, 9, 2, 1.5, 'Amazon Redshift\nData Warehouse', '#3F48CC'),
            (10, 9, 2, 1.5, 'Amazon QuickSight\nBI Dashboard', '#3F48CC'),
            (13, 9, 2, 1.5, 'Tableau\nAnalytics', '#3F48CC'),
            
            (1, 7, 2, 1.5, 'AWS IAM\nSecurity', '#DD344C'),
            (4, 7, 2, 1.5, 'AWS KMS\nEncryption', '#DD344C'),
            (7, 7, 2, 1.5, 'AWS Config\nCompliance', '#DD344C'),
            (10, 7, 2, 1.5, 'CloudWatch\nMonitoring', '#7AA116'),
            (13, 7, 2, 1.5, 'SNS\nNotifications', '#7AA116'),
            
            (1, 5, 2, 1.5, 'Step Functions\nOrchestration', '#FF9900'),
            (4, 5, 2, 1.5, 'EventBridge\nScheduling', '#FF9900'),
            (7, 5, 2, 1.5, 'AWS Backup\nDR Solution', '#4B92DB'),
            (10, 5, 2, 1.5, 'GitHub Actions\nCI/CD', '#232F3E'),
            (13, 5, 2, 1.5, 'Terraform\nIaC', '#232F3E'),
        ]
        
        for x, y, w, h, name, color in services:
            # Service box
            rect = patches.FancyBboxPatch(
                (x, y), w, h,
                boxstyle="round,pad=0.1",
                facecolor=color,
                edgecolor='black',
                linewidth=1
            )
            ax.add_patch(rect)
            
            # Service name
            ax.text(x + w/2, y + h/2, name, 
                   ha='center', va='center', fontsize=10, 
                   color='white', weight='bold')
        
        # Data flow arrows
        arrows = [
            (3, 9.75, 4, 9.75),  # S3 to Glue
            (6, 9.75, 7, 9.75),  # Glue to Redshift
            (9, 9.75, 10, 9.75), # Redshift to QuickSight
            (12, 9.75, 13, 9.75) # QuickSight to Tableau
        ]
        
        for x1, y1, x2, y2 in arrows:
            ax.annotate('', xy=(x2, y2), xytext=(x1, y1),
                       arrowprops=dict(arrowstyle='->', color='#232F3E', lw=2))
        
        # Legend
        ax.text(8, 3, 'AWS Service Categories', ha='center', va='center', 
               fontsize=14, weight='bold', color='#232F3E')
        
        legend_items = [
            ('Storage & Processing', '#FF9900'),
            ('Analytics', '#3F48CC'),
            ('Security', '#DD344C'),
            ('Monitoring', '#7AA116'),
            ('Backup & DR', '#4B92DB'),
            ('DevOps', '#232F3E')
        ]
        
        x_pos = 2
        for item, color in legend_items:
            rect = patches.Rectangle((x_pos, 2), 0.3, 0.3, facecolor=color)
            ax.add_patch(rect)
            ax.text(x_pos + 0.4, 2.15, item, ha='left', va='center', fontsize=9)
            x_pos += 2.2
        
        # Save PDF
        pdf_file = Path('docs/architecture/diagrams/AWS_Architecture_Simple.pdf')
        pdf_file.parent.mkdir(parents=True, exist_ok=True)
        
        with PdfPages(str(pdf_file)) as pdf:
            pdf.savefig(fig, bbox_inches='tight', facecolor='white')
        
        plt.close()
        
        print(f"✅ Simple PDF generated: {pdf_file}")
        return True
        
    except Exception as e:
        print(f"❌ Simple PDF generation failed: {str(e)}")
        return False

def open_html_in_browser():
    """Open HTML file in browser for manual PDF generation"""
    html_file = Path('docs/architecture/AWS_ARCHITECTURE_HTML.html').resolve()
    
    print(f"🌐 Opening HTML file in browser...")
    print(f"📁 File location: {html_file}")
    print("📋 Instructions:")
    print("   1. The architecture diagram will open in your browser")
    print("   2. Press Ctrl+P (or Cmd+P on Mac) to print")
    print("   3. Select 'Save as PDF' as destination")
    print("   4. Choose landscape orientation for best results")
    print("   5. Enable 'Background graphics' option")
    
    webbrowser.open(f"file://{html_file}")
    return True

def main():
    """Main function to generate architecture diagrams"""
    print("🏗️ AWS Architecture Diagram Generator")
    print("=" * 50)
    
    # Create output directory
    output_dir = Path('docs/architecture/diagrams')
    output_dir.mkdir(parents=True, exist_ok=True)
    
    # Try different methods
    methods = [
        ("Simple PDF (matplotlib)", create_simple_pdf),
        ("Browser Screenshot", generate_screenshot),
        ("WeasyPrint PDF", generate_pdf_weasyprint),
        ("Browser PDF", generate_pdf_browser),
        ("Open in Browser", open_html_in_browser)
    ]
    
    success_count = 0
    
    for method_name, method_func in methods:
        print(f"\n🔄 Trying {method_name}...")
        try:
            if method_func():
                success_count += 1
        except Exception as e:
            print(f"❌ {method_name} failed: {str(e)}")
    
    print(f"\n🎯 Summary:")
    print(f"✅ {success_count}/{len(methods)} methods succeeded")
    print(f"📁 Output directory: {output_dir}")
    
    # List generated files
    if output_dir.exists():
        files = list(output_dir.glob('*'))
        if files:
            print(f"📄 Generated files:")
            for file in files:
                print(f"   • {file.name}")
        else:
            print("📄 No files generated automatically")
    
    print(f"\n🌐 HTML Architecture Diagram:")
    print(f"   📁 {Path('docs/architecture/AWS_ARCHITECTURE_HTML.html').resolve()}")
    print(f"   💡 Open this file in your browser and print to PDF manually")
    
    return success_count > 0

if __name__ == "__main__":
    main()
