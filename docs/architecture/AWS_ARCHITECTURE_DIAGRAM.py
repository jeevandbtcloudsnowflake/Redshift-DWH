#!/usr/bin/env python3
"""
AWS Architecture Diagram Generator
Creates professional architecture diagrams with actual AWS service icons
Exports to PDF, PNG, and SVG formats
"""

import matplotlib.pyplot as plt
import matplotlib.patches as patches
from matplotlib.patches import FancyBboxPatch, Rectangle
import numpy as np
from PIL import Image, ImageDraw, ImageFont
import requests
import io
import os

class AWSArchitectureDiagram:
    def __init__(self):
        self.fig, self.ax = plt.subplots(1, 1, figsize=(20, 14))
        self.ax.set_xlim(0, 20)
        self.ax.set_ylim(0, 14)
        self.ax.axis('off')
        
        # AWS Color Palette
        self.colors = {
            'aws_orange': '#FF9900',
            'aws_blue': '#232F3E',
            'aws_light_blue': '#4B92DB',
            'aws_dark_blue': '#161E2D',
            'aws_gray': '#F2F3F3',
            'aws_green': '#7AA116',
            'aws_red': '#D13212'
        }
        
    def create_service_box(self, x, y, width, height, service_name, icon_text, color, text_color='white'):
        """Create a service box with icon and text"""
        # Main box
        box = FancyBboxPatch(
            (x, y), width, height,
            boxstyle="round,pad=0.1",
            facecolor=color,
            edgecolor='black',
            linewidth=1.5
        )
        self.ax.add_patch(box)
        
        # Icon (using text representation for now)
        self.ax.text(x + width/2, y + height*0.7, icon_text, 
                    ha='center', va='center', fontsize=16, color=text_color, weight='bold')
        
        # Service name
        self.ax.text(x + width/2, y + height*0.3, service_name, 
                    ha='center', va='center', fontsize=10, color=text_color, weight='bold')
        
    def create_group_box(self, x, y, width, height, title, color):
        """Create a group box for related services"""
        box = Rectangle((x, y), width, height, 
                       facecolor=color, alpha=0.2, 
                       edgecolor=color, linewidth=2)
        self.ax.add_patch(box)
        
        # Title
        self.ax.text(x + width/2, y + height - 0.3, title, 
                    ha='center', va='center', fontsize=12, weight='bold', color=color)
        
    def draw_arrow(self, start_x, start_y, end_x, end_y, color='black', style='-'):
        """Draw an arrow between services"""
        self.ax.annotate('', xy=(end_x, end_y), xytext=(start_x, start_y),
                        arrowprops=dict(arrowstyle='->', color=color, lw=2))
        
    def create_architecture_diagram(self):
        """Create the complete AWS architecture diagram"""
        
        # Title
        self.ax.text(10, 13.5, 'E-commerce Data Warehouse - AWS Architecture', 
                    ha='center', va='center', fontsize=20, weight='bold', color=self.colors['aws_blue'])
        
        # Data Sources Layer
        self.create_group_box(0.5, 11, 4, 2, 'Data Sources', self.colors['aws_gray'])
        self.create_service_box(1, 11.5, 1.2, 1, 'CSV Files', '📄', self.colors['aws_gray'], 'black')
        self.create_service_box(2.5, 11.5, 1.2, 1, 'APIs', '🌐', self.colors['aws_gray'], 'black')
        
        # Data Ingestion & Storage Layer
        self.create_group_box(5.5, 10, 6, 3.5, 'Data Ingestion & Storage', self.colors['aws_orange'])
        self.create_service_box(6, 12, 1.3, 1, 'S3 Raw\nBucket', '🪣', self.colors['aws_orange'])
        self.create_service_box(7.5, 12, 1.3, 1, 'S3 Processed\nBucket', '🪣', self.colors['aws_orange'])
        self.create_service_box(9, 12, 1.3, 1, 'S3 Scripts\nBucket', '🪣', self.colors['aws_orange'])
        self.create_service_box(6, 10.5, 1.3, 1, 'S3 Logs\nBucket', '🪣', self.colors['aws_orange'])
        
        # ETL Processing Layer
        self.create_group_box(12.5, 9, 7, 5, 'ETL & Data Processing', self.colors['aws_orange'])
        self.create_service_box(13, 12.5, 1.5, 1, 'Glue\nCrawler', '🕷️', self.colors['aws_orange'])
        self.create_service_box(15, 12.5, 1.5, 1, 'Glue\nETL Jobs', '⚙️', self.colors['aws_orange'])
        self.create_service_box(17, 12.5, 1.5, 1, 'Glue Data\nCatalog', '📚', self.colors['aws_orange'])
        self.create_service_box(13, 11, 1.5, 1, 'Glue\nWorkflows', '🔄', self.colors['aws_orange'])
        self.create_service_box(15, 11, 1.5, 1, 'Step\nFunctions', '🚀', self.colors['aws_orange'])
        self.create_service_box(17, 11, 1.5, 1, 'EventBridge', '⏰', self.colors['aws_orange'])
        self.create_service_box(13, 9.5, 1.5, 1, 'Lambda', '⚡', self.colors['aws_orange'])
        
        # Data Warehouse Layer
        self.create_group_box(5.5, 6.5, 6, 2.5, 'Data Warehouse & Analytics', self.colors['aws_light_blue'])
        self.create_service_box(6, 7.5, 2, 1, 'Amazon Redshift\nra3.xlplus', '🏢', self.colors['aws_light_blue'])
        self.create_service_box(8.5, 7.5, 2, 1, 'Redshift\nSpectrum', '🔍', self.colors['aws_light_blue'])
        
        # Security & Compliance Layer
        self.create_group_box(0.5, 4, 8, 4.5, 'Security & Compliance', self.colors['aws_red'])
        self.create_service_box(1, 7.5, 1.2, 0.8, 'IAM', '🔐', self.colors['aws_red'])
        self.create_service_box(2.5, 7.5, 1.2, 0.8, 'KMS', '🔑', self.colors['aws_red'])
        self.create_service_box(4, 7.5, 1.2, 0.8, 'Secrets\nManager', '🔒', self.colors['aws_red'])
        self.create_service_box(1, 6.5, 1.2, 0.8, 'Config', '📋', self.colors['aws_red'])
        self.create_service_box(2.5, 6.5, 1.2, 0.8, 'CloudTrail', '🔍', self.colors['aws_red'])
        self.create_service_box(4, 6.5, 1.2, 0.8, 'GuardDuty', '🛡️', self.colors['aws_red'])
        self.create_service_box(1, 5.5, 1.2, 0.8, 'Security\nHub', '🏛️', self.colors['aws_red'])
        self.create_service_box(2.5, 5.5, 1.2, 0.8, 'VPC', '🌐', self.colors['aws_red'])
        self.create_service_box(4, 5.5, 1.2, 0.8, 'Security\nGroups', '🔒', self.colors['aws_red'])
        
        # Monitoring & Observability Layer
        self.create_group_box(12.5, 4, 7, 4, 'Monitoring & Observability', self.colors['aws_green'])
        self.create_service_box(13, 7, 1.5, 1, 'CloudWatch\nDashboards', '📊', self.colors['aws_green'])
        self.create_service_box(15, 7, 1.5, 1, 'CloudWatch\nLogs', '📝', self.colors['aws_green'])
        self.create_service_box(17, 7, 1.5, 1, 'CloudWatch\nAlarms', '🚨', self.colors['aws_green'])
        self.create_service_box(13, 5.5, 1.5, 1, 'SNS', '📢', self.colors['aws_green'])
        self.create_service_box(15, 5.5, 1.5, 1, 'DevOps\nDashboard', '📊', self.colors['aws_green'])
        
        # Backup & Disaster Recovery Layer
        self.create_group_box(0.5, 1, 8, 2.5, 'Backup & Disaster Recovery', self.colors['aws_blue'])
        self.create_service_box(1, 2.5, 1.5, 1, 'AWS\nBackup', '💾', self.colors['aws_blue'])
        self.create_service_box(3, 2.5, 1.5, 1, 'S3 Cross-Region\nReplication', '🔄', self.colors['aws_blue'])
        self.create_service_box(5, 2.5, 1.5, 1, 'Redshift\nSnapshots', '📸', self.colors['aws_blue'])
        self.create_service_box(1, 1.5, 1.5, 1, 'Point-in-Time\nRecovery', '⏰', self.colors['aws_blue'])
        
        # DevOps & CI/CD Layer
        self.create_group_box(12.5, 1, 7, 2.5, 'DevOps & CI/CD', self.colors['aws_dark_blue'])
        self.create_service_box(13, 2.5, 1.5, 1, 'GitHub\nActions', '🐙', self.colors['aws_dark_blue'])
        self.create_service_box(15, 2.5, 1.5, 1, 'Terraform', '🏗️', self.colors['aws_dark_blue'])
        self.create_service_box(17, 2.5, 1.5, 1, 'Infrastructure\nas Code', '📋', self.colors['aws_dark_blue'])
        
        # Data Flow Arrows
        # Data Sources to S3
        self.draw_arrow(3.2, 12, 6, 12.5, self.colors['aws_blue'])
        
        # S3 to Glue
        self.draw_arrow(7.3, 12.5, 13, 12.8, self.colors['aws_blue'])
        
        # Glue to Redshift
        self.draw_arrow(15.5, 11, 7, 8.5, self.colors['aws_blue'])
        
        # Add legend
        self.create_legend()
        
    def create_legend(self):
        """Create a legend for the diagram"""
        legend_y = 0.5
        self.ax.text(10, legend_y, 'Legend:', ha='center', va='center', fontsize=12, weight='bold')
        
        # Data flow arrow
        self.draw_arrow(8, legend_y - 0.3, 9, legend_y - 0.3, self.colors['aws_blue'])
        self.ax.text(9.5, legend_y - 0.3, 'Data Flow', ha='left', va='center', fontsize=10)
        
        # Service categories
        categories = [
            ('Storage & Processing', self.colors['aws_orange']),
            ('Analytics', self.colors['aws_light_blue']),
            ('Security', self.colors['aws_red']),
            ('Monitoring', self.colors['aws_green']),
            ('DevOps', self.colors['aws_dark_blue'])
        ]
        
        x_pos = 11
        for category, color in categories:
            rect = Rectangle((x_pos, legend_y - 0.4), 0.3, 0.2, facecolor=color, alpha=0.7)
            self.ax.add_patch(rect)
            self.ax.text(x_pos + 0.4, legend_y - 0.3, category, ha='left', va='center', fontsize=9)
            x_pos += 2
    
    def save_diagram(self, output_dir='docs/architecture/diagrams'):
        """Save the diagram in multiple formats"""
        os.makedirs(output_dir, exist_ok=True)
        
        # Save as PNG (high resolution)
        plt.savefig(f'{output_dir}/aws_architecture_diagram.png', 
                   dpi=300, bbox_inches='tight', facecolor='white', edgecolor='none')
        
        # Save as PDF
        plt.savefig(f'{output_dir}/aws_architecture_diagram.pdf', 
                   bbox_inches='tight', facecolor='white', edgecolor='none')
        
        # Save as SVG
        plt.savefig(f'{output_dir}/aws_architecture_diagram.svg', 
                   bbox_inches='tight', facecolor='white', edgecolor='none')
        
        print(f"Architecture diagrams saved to {output_dir}/")
        print("Files created:")
        print("- aws_architecture_diagram.png (High-resolution image)")
        print("- aws_architecture_diagram.pdf (PDF document)")
        print("- aws_architecture_diagram.svg (Scalable vector)")

def main():
    """Generate the AWS architecture diagram"""
    print("Generating AWS Architecture Diagram...")
    
    # Create diagram
    diagram = AWSArchitectureDiagram()
    diagram.create_architecture_diagram()
    
    # Save in multiple formats
    diagram.save_diagram()
    
    # Display the diagram
    plt.tight_layout()
    plt.show()
    
    print("\n✅ Architecture diagram generated successfully!")
    print("📁 Files saved in: docs/architecture/diagrams/")
    print("🎯 Use these files in presentations, documentation, or reports")

if __name__ == "__main__":
    main()
