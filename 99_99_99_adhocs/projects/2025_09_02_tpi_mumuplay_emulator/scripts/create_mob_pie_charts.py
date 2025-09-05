#!/usr/bin/env python3
"""
MOB Distribution Pie Charts Generator
Creates 4 pie charts comparing MOB distributions across different user groups
"""

import matplotlib
matplotlib.use('Agg')  # Use non-interactive backend
import matplotlib.pyplot as plt
import pandas as pd
import numpy as np
from pathlib import Path

# Set up the plotting style
plt.style.use('default')
plt.rcParams['figure.figsize'] = (16, 12)
plt.rcParams['font.size'] = 10

# Data from SQL queries
data = {
    'US Network Carrier': {
        '0 months': 97609,
        '1 month': 26377,
        '2 months': 23904,
        '3-6 months': 83425,
        '7-12 months': 122442,
        '13-24 months': 0,  # Not shown in results
        '25+ months': 0,    # Not shown in results
        'Unknown': 0
    },
    'Taiwan Network Carrier': {
        '0 months': 12127,
        '1 month': 618,
        '2 months': 836,
        '3-6 months': 1470,
        '7-12 months': 679,
        '13-24 months': 0,  # Not shown in results
        '25+ months': 0,    # Not shown in results
        'Unknown': 0
    },
    'Taiwan Inactive Users': {
        '0 months': 9604,
        '1 month': 404,
        '2 months': 335,
        '3-6 months': 402,
        '7-12 months': 281,
        '13-24 months': 0,  # Not shown in results
        '25+ months': 0,    # Not shown in results
        'Unknown': 0
    },
    'Taiwan Active Users': {
        '0 months': 2523,
        '1 month': 214,
        '2 months': 501,
        '3-6 months': 1068,
        '7-12 months': 398,
        '13-24 months': 0,  # Not shown in results
        '25+ months': 0,    # Not shown in results
        'Unknown': 0
    }
}

# Define colors for consistent visualization
colors = ['#FF6B6B', '#4ECDC4', '#45B7D1', '#96CEB4', '#FFEAA7', '#DDA0DD', '#98D8C8', '#F7DC6F']

# Create figure with 2x2 subplots
fig, axes = plt.subplots(2, 2, figsize=(16, 12))
fig.suptitle('MOB Distribution Analysis - July 2025', fontsize=16, fontweight='bold')

# Plot 1: US Network Carrier MOB Distribution
ax1 = axes[0, 0]
us_data = data['US Network Carrier']
us_labels = [f"{k}\n({v:,} users)" for k, v in us_data.items() if v > 0]
us_values = [v for v in us_data.values() if v > 0]
us_colors = colors[:len(us_values)]

wedges1, texts1, autotexts1 = ax1.pie(us_values, labels=us_labels, colors=us_colors, autopct='%1.1f%%', startangle=90)
ax1.set_title('US Network Carrier\'s MOB Distribution', fontsize=12, fontweight='bold')

# Plot 2: Taiwan Network Carrier MOB Distribution
ax2 = axes[0, 1]
taiwan_data = data['Taiwan Network Carrier']
taiwan_labels = [f"{k}\n({v:,} users)" for k, v in taiwan_data.items() if v > 0]
taiwan_values = [v for v in taiwan_data.values() if v > 0]
taiwan_colors = colors[:len(taiwan_values)]

wedges2, texts2, autotexts2 = ax2.pie(taiwan_values, labels=taiwan_labels, colors=taiwan_colors, autopct='%1.1f%%', startangle=90)
ax2.set_title('Taiwan Network Carrier\'s MOB Distribution', fontsize=12, fontweight='bold')

# Plot 3: Taiwan Inactive User Status MOB Distribution
ax3 = axes[1, 0]
taiwan_inactive_data = data['Taiwan Inactive Users']
taiwan_inactive_labels = [f"{k}\n({v:,} users)" for k, v in taiwan_inactive_data.items() if v > 0]
taiwan_inactive_values = [v for v in taiwan_inactive_data.values() if v > 0]
taiwan_inactive_colors = colors[:len(taiwan_inactive_values)]

wedges3, texts3, autotexts3 = ax3.pie(taiwan_inactive_values, labels=taiwan_inactive_labels, colors=taiwan_inactive_colors, autopct='%1.1f%%', startangle=90)
ax3.set_title('Taiwan Inactive User Status\'s MOB Distribution', fontsize=12, fontweight='bold')

# Plot 4: Taiwan Active User Status MOB Distribution
ax4 = axes[1, 1]
taiwan_active_data = data['Taiwan Active Users']
taiwan_active_labels = [f"{k}\n({v:,} users)" for k, v in taiwan_active_data.items() if v > 0]
taiwan_active_values = [v for v in taiwan_active_data.values() if v > 0]
taiwan_active_colors = colors[:len(taiwan_active_values)]

wedges4, texts4, autotexts4 = ax4.pie(taiwan_active_values, labels=taiwan_active_labels, colors=taiwan_active_colors, autopct='%1.1f%%', startangle=90)
ax4.set_title('Taiwan Active User Status\'s MOB Distribution', fontsize=12, fontweight='bold')

# Adjust layout to prevent overlap
plt.tight_layout()

# Save the plot
output_path = Path('outputs/mob_distribution_pie_charts.png')
output_path.parent.mkdir(exist_ok=True)
plt.savefig(output_path, dpi=300, bbox_inches='tight')
plt.close()

print(f"✅ MOB Distribution Pie Charts saved to: {output_path}")

# Print summary statistics
print("\n📊 MOB Distribution Summary:")
print("=" * 50)

for group_name, group_data in data.items():
    total_users = sum(group_data.values())
    zero_month_pct = (group_data['0 months'] / total_users) * 100 if total_users > 0 else 0
    low_mob_pct = ((group_data['0 months'] + group_data['1 month'] + group_data['2 months']) / total_users) * 100 if total_users > 0 else 0

    print(f"\n{group_name}:")
    print(f"  Total Users: {total_users:,}")
    print(f"  0 months: {group_data['0 months']:,} ({zero_month_pct:.1f}%)")
    print(f"  Low MOB (0-2 months): {group_data['0 months'] + group_data['1 month'] + group_data['2 months']:,} ({low_mob_pct:.1f}%)")
