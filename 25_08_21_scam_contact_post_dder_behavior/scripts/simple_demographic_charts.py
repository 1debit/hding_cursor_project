#!/usr/bin/env python3
"""
Simple Demographic Charts - No hanging version
"""

import matplotlib
matplotlib.use('Agg')  # Non-interactive backend
import matplotlib.pyplot as plt
import sys
import os

def create_simple_charts():
    """Create demographic comparison charts efficiently"""
    
    # Age data from SQL results
    age_data = {
        'ranges': ['18-24', '25-34', '35-44', '45-54', '55-64', '65+'],
        'active': [15.37, 29.67, 23.98, 15.79, 10.03, 5.16],
        'scam': [10.10, 22.52, 23.67, 18.88, 15.61, 9.22]
    }
    
    # State data with "Others" category
    state_data = {
        'states': ['TX', 'CA', 'FL', 'GA', 'NY', 'NC', 'TN', 'AZ', 'IL', 'OH', 'Others'],
        'active': [10.16, 8.09, 7.35, 4.98, 4.78, 3.52, 3.41, 3.35, 3.17, 2.88, 48.31],
        'scam': [8.61, 7.01, 6.67, 5.07, 4.08, 3.91, 3.74, 3.57, 2.72, 3.06, 51.56]
    }
    
    # Create figure
    fig, ((ax1, ax2), (ax3, ax4)) = plt.subplots(2, 2, figsize=(16, 12))
    fig.suptitle('Demographic Comparison: Active Users vs Scam Victims\nActive Users: 30.2M | Scam Victims: 2.9K', 
                 fontsize=16, fontweight='bold')
    
    # Colors
    age_colors = ['#FF6B6B', '#4ECDC4', '#45B7D1', '#96CEB4', '#FFEAA7', '#DDA0DD']
    state_colors = ['#FF8C94', '#FFD3A5', '#FD9853', '#A8E6CF', '#88D8C0', 
                   '#7FDBFF', '#B4A7D6', '#D4A574', '#F7DC6F', '#BB8FCE', '#C0C0C0']
    
    # Age charts
    ax1.pie(age_data['active'], labels=age_data['ranges'], autopct='%1.1f%%',
            colors=age_colors, startangle=90)
    ax1.set_title('Age Distribution - Active Users\n(Avg: 38.8 years, Peak: 25-34)', 
                  fontsize=11, fontweight='bold', pad=20)
    
    ax2.pie(age_data['scam'], labels=age_data['ranges'], autopct='%1.1f%%',
            colors=age_colors, startangle=90)
    ax2.set_title('Age Distribution - Scam Victims\n(Avg: 43.1 years, Older population)', 
                  fontsize=11, fontweight='bold', pad=20)
    
    # State charts
    ax3.pie(state_data['active'], labels=state_data['states'], autopct='%1.1f%%',
            colors=state_colors, startangle=90)
    ax3.set_title('State Distribution - Active Users\n(Top 10 + Others)', 
                  fontsize=11, fontweight='bold', pad=20)
    
    ax4.pie(state_data['scam'], labels=state_data['states'], autopct='%1.1f%%',
            colors=state_colors, startangle=90)
    ax4.set_title('State Distribution - Scam Victims\n(Similar pattern to active users)', 
                  fontsize=11, fontweight='bold', pad=20)
    
    # Save and close immediately
    plt.tight_layout()
    output_file = 'demographic_comparison_final.png'
    plt.savefig(output_file, dpi=300, bbox_inches='tight')
    plt.close()  # Important: close figure to free memory
    
    return output_file

def main():
    """Main function"""
    print("🎨 Creating demographic comparison charts...")
    
    try:
        output_file = create_simple_charts()
        print(f"✅ Charts created successfully: {output_file}")
        
        # Print summary
        print("\n📊 KEY FINDINGS:")
        print("• Scam victims are 4.3 years older on average (43.1 vs 38.8)")
        print("• Age 55-64 most vulnerable (+5.6pp over-representation)")
        print("• Geographic distribution similar between populations")
        print("• Target: 45+ age groups for scam prevention programs")
        
    except Exception as e:
        print(f"❌ Error creating charts: {e}")
        return 1
    
    return 0

if __name__ == "__main__":
    sys.exit(main())
