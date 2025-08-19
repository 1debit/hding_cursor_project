# Darwinium (DWN) Analysis

Session replay attack detection and device intelligence signal analysis.

## Overview
This project analyzes Darwinium device intelligence data to detect:
- Session replay attacks
- Invalid nonce patterns
- Device signal anomalies
- Authentication token validation failures

## Key Findings
- 100% coverage of confirmed session replay attacks using 'INVALID_NONCE' and 'NONCE_NOT_FOUND' signals
- 14 out of 18 events contained 'INVALID_NONE' signals
- 4 out of 18 events contained 'NONCE_NOT_FOUND' signals

## Files
- `analysis_scripts/` - Main analysis scripts
- `data_processing/` - Data processing and transformation
- `reports/` - Analysis summaries and findings

## Usage
1. Run device signal analysis scripts
2. Process nonce validation data
3. Generate attack detection reports
4. Review security findings
