#!/usr/bin/env python3
"""
Demographic Visualization Script
Creates side-by-side pie charts comparing active users vs scam victims
"""

import matplotlib
matplotlib.use('Agg')  # Use non-interactive backend to prevent hanging
import matplotlib.pyplot as plt
import numpy as np
from datetime import datetime
import sys
import os

# Add src to path for imports
sys.path.append(os.path.join(os.path.dirname(__file__), '..'))

# Sample data from SQL results
age_data = {
    'age_ranges': ['18-24', '25-34', '35-44', '45-54', '55-64', '65+'],
    'active_users': [15.37, 29.67, 23.98, 15.79, 10.03, 5.16],  # percentages
    'scam_victims': [10.10, 22.52, 23.67, 18.88, 15.61, 9.22]  # percentages
}

state_data = {
    'states': ['TX', 'CA', 'FL', 'GA', 'NY', 'NC', 'TN', 'AZ', 'IL', 'OH', 'Others'],
    'active_users': [10.16, 8.09, 7.35, 4.98, 4.78, 3.52, 3.41, 3.35, 3.17, 2.88, 48.31],  # percentages
    'scam_victims': [8.61, 7.01, 6.67, 5.07, 4.08, 3.91, 3.74, 3.57, 2.72, 3.06, 51.56]  # percentages
}

def create_demographic_comparison():
    """Create side-by-side pie charts for demographic comparison"""
    
    # Set up the figure with subplots
    fig, ((ax1, ax2), (ax3, ax4)) = plt.subplots(2, 2, figsize=(16, 12))
    fig.suptitle('Demographic Comparison: Active Users vs Scam Victims\n'
                 'Active Users: 30.2M | Scam Victims: 2.9K',
                 fontsize=16, fontweight='bold')
    
    # Color schemes
    age_colors = ['#FF6B6B', '#4ECDC4', '#45B7D1', '#96CEB4', '#FFEAA7', '#DDA0DD']
    state_colors = ['#FF8C94', '#FFD3A5', '#FD9853', '#A8E6CF', '#88D8C0', 
                   '#7FDBFF', '#B4A7D6', '#D4A574', '#F7DC6F', '#BB8FCE', '#C0C0C0']
    
    # Age Distribution - Active Users
    ax1.pie(age_data['active_users'], labels=age_data['age_ranges'], autopct='%1.1f%%',
            colors=age_colors, startangle=90)
    ax1.set_title('Age Distribution - Active Users\n(Avg Age: 38.8 years)\nYounger population, peak at 25-34 (29.7%)', 
                  fontsize=11, fontweight='bold', pad=20)
    
    # Age Distribution - Scam Victims  
    ax2.pie(age_data['scam_victims'], labels=age_data['age_ranges'], autopct='%1.1f%%',
            colors=age_colors, startangle=90)
    ax2.set_title('Age Distribution - Scam Victims\n(Avg Age: 43.1 years)\nOlder population, more spread across 35-64', 
                  fontsize=11, fontweight='bold', pad=20)
    
    # State Distribution - Active Users
    ax3.pie(state_data['active_users'], labels=state_data['states'], autopct='%1.1f%%',
            colors=state_colors, startangle=90)
    ax3.set_title('State Distribution - Active Users\n(Top 10 + Others)\nConcentrated: TX (10.2%), CA (8.1%), FL (7.3%)', 
                  fontsize=11, fontweight='bold', pad=20)
    
    # State Distribution - Scam Victims
    ax4.pie(state_data['scam_victims'], labels=state_data['states'], autopct='%1.1f%%',
            colors=state_colors, startangle=90)
    ax4.set_title('State Distribution - Scam Victims\n(Top 10 + Others)\nSimilar pattern: TX (8.6%), CA (7.0%), FL (6.7%)', 
                  fontsize=11, fontweight='bold', pad=20)
    
    # Adjust layout
    plt.tight_layout()
    
    # Save the plot
    output_file = 'demographic_comparison_charts.png'
    plt.savefig(output_file, dpi=300, bbox_inches='tight')
    print(f"✅ Pie charts saved as: {output_file}")
    
    # Don't show plot to avoid hanging, just save
    return output_file

def print_demographic_insights():
    """Print key demographic insights from the analysis"""
    
    print("\n📊 DEMOGRAPHIC ANALYSIS INSIGHTS")
    print("=" * 50)
    
    print("\n👥 POPULATION OVERVIEW:")
    print("• Active Users: 30,193,790 (average age: 38.8 years)")
    print("• Scam Victims: 2,940 (average age: 43.1 years)")
    print("• Age Difference: Scam victims are 4.3 years OLDER on average")
    
    print("\n📈 AGE DISTRIBUTION KEY DIFFERENCES:")
    print("• Younger Groups (18-34): Active users have higher representation")
    print("  - 18-24: 15.4% vs 10.1% (-5.3pp)")
    print("  - 25-34: 29.7% vs 22.5% (-7.1pp)")
    print("• Older Groups (45+): Scam victims have higher representation")
    print("  - 45-54: 15.8% vs 18.9% (+3.1pp)")
    print("  - 55-64: 10.0% vs 15.6% (+5.6pp)")
    print("  - 65+: 5.2% vs 9.2% (+4.0pp)")
    
    print("\n🗺️ STATE DISTRIBUTION PATTERNS:")
    print("• Similar geographic distribution between populations")
    print("• Top 5 states for both: TX, CA, FL, GA, NY")
    print("• Slight differences in concentration:")
    print("  - TX: 10.2% (active) vs 8.6% (scam) - active users more concentrated")
    print("  - CA: 8.1% (active) vs 7.0% (scam) - active users more concentrated")
    print("  - GA: 5.0% (active) vs 5.1% (scam) - nearly identical")
    
    print("\n💡 STRATEGIC IMPLICATIONS:")
    print("• Scam victims skew OLDER - focus retention on 45+ demographics")
    print("• Geographic patterns similar - no major state-specific scam risks")
    print("• Older customers may be more vulnerable to scams")
    print("• Consider age-targeted scam prevention education")

def main():
    """Main function to generate demographic visualization and insights"""
    
    print("🎨 GENERATING DEMOGRAPHIC COMPARISON VISUALIZATIONS")
    print("=" * 60)
    
    # Create the visualization
    output_file = create_demographic_comparison()
    
    # Print insights
    print_demographic_insights()
    
    print(f"\n🎯 VISUALIZATION COMPLETE")
    print(f"📊 Charts saved as: {output_file}")
    print("🔍 Key finding: Scam victims are 4.3 years older on average")

if __name__ == "__main__":
    main()
