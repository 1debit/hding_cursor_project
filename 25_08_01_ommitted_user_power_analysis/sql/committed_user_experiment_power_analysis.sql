-- Committed User Experiment Power Analysis
-- Experiment: allow_low_risky_txn_for_committed_user
-- Analysis: Control Group Power Analysis for CUPED metrics
-- Date: 2025
-- Analyst: Hao Ding

create or replace table risk.test.hding_commited_user_exp_power_analysis_input as(
select 
    *
    , size_control as control_sample_size
    , mean_control as control_sample_mean
from edw_db.experimentation_platform.stats_engine_core_ab_view
where 1=1
    and experiment_id = 'allow_low_risky_txn_for_committed_user'
    and is_latest=true
    and metric_name ilike '%_cuped'
    qualify row_number() over (partition by metric_name order by (case when test='Welchs_T_Test_w_Outlier_Removal' then 1 else 0 end) desc)=1
);

-- Analysis Notes:
-- This query extracts control group data for power analysis
-- Focuses on CUPED (Controlled-experiment Using Pre-Experiment Data) metrics
-- Uses Welch's T-Test with outlier removal for statistical testing
-- Provides control sample size and mean for power calculations
