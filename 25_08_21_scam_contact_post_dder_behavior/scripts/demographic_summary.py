#!/usr/bin/env python3
"""
Demographic Summary Script
Creates text-based demographic comparison between active users vs scam victims
"""

# Data from SQL results
def print_demographic_summary():
    """Print comprehensive demographic summary"""
    
    print("📊 DEMOGRAPHIC COMPARISON: Active Users vs Scam Victims")
    print("=" * 70)
    
    # Population Summary
    print("\n👥 POPULATION OVERVIEW:")
    print("• Active Users: 30,193,790 users (average age: 38.8 years)")
    print("• Scam Victims: 2,940 users (average age: 43.1 years)")
    print("• Key Finding: Scam victims are 4.3 years OLDER on average")
    
    # Age Distribution
    print("\n📈 AGE DISTRIBUTION COMPARISON:")
    print("Age Range    | Active Users | Scam Victims | Difference")
    print("-" * 55)
    
    age_data = [
        ("18-24", 15.37, 10.10, -5.27),
        ("25-34", 29.67, 22.52, -7.15),
        ("35-44", 23.98, 23.67, -0.31),
        ("45-54", 15.79, 18.88, +3.09),
        ("55-64", 10.03, 15.61, +5.58),
        ("65+", 5.16, 9.22, +4.06)
    ]
    
    for age_range, active_pct, scam_pct, diff in age_data:
        diff_str = f"+{diff:.1f}pp" if diff > 0 else f"{diff:.1f}pp"
        print(f"{age_range:<8} | {active_pct:>9.1f}%  | {scam_pct:>9.1f}%  | {diff_str:>8}")
    
    # State Distribution
    print("\n🗺️ STATE DISTRIBUTION COMPARISON (Top 10):")
    print("State | Active Users | Scam Victims | Difference")
    print("-" * 50)
    
    state_data = [
        ("TX", 10.16, 8.61, -1.55),
        ("CA", 8.09, 7.01, -1.08),
        ("FL", 7.35, 6.67, -0.68),
        ("GA", 4.98, 5.07, +0.09),
        ("NY", 4.78, 4.08, -0.70),
        ("NC", 3.52, 3.91, +0.39),
        ("TN", 3.41, 3.74, +0.33),
        ("AZ", 3.35, 3.57, +0.22),
        ("IL", 3.17, 2.72, -0.45),
        ("OH", 2.88, 3.06, +0.18)
    ]
    
    for state, active_pct, scam_pct, diff in state_data:
        diff_str = f"+{diff:.1f}pp" if diff > 0 else f"{diff:.1f}pp"
        print(f"{state:<4}  | {active_pct:>9.1f}%  | {scam_pct:>9.1f}%  | {diff_str:>8}")
    
    # Key Insights
    print("\n💡 KEY INSIGHTS:")
    print("=" * 30)
    print("🎯 AGE PATTERNS:")
    print("  • Younger groups (18-34): Active users dominate (-5.3pp, -7.1pp)")
    print("  • Older groups (45+): Scam victims over-represented (+3.1pp, +5.6pp, +4.1pp)")
    print("  • Peak vulnerability: 55-64 age group (+5.6pp difference)")
    
    print("\n🗺️ GEOGRAPHIC PATTERNS:")
    print("  • Similar distribution across top states")
    print("  • TX, CA, FL dominate both populations")
    print("  • No major state-specific scam concentration")
    print("  • Active users slightly more concentrated in big states")
    
    print("\n🚨 BUSINESS IMPLICATIONS:")
    print("  • Target 45+ demographics for scam prevention")
    print("  • Older customers show higher scam vulnerability")
    print("  • No geographic targeting needed - age is key factor")
    print("  • Consider age-based education and protection programs")

if __name__ == "__main__":
    print_demographic_summary()
