# 🚀 Quick Knowledge Lookup

> **Instant access to the most frequently needed information**

## 📊 **Most Common Tables**

| Table | Alias | Purpose | Key Fields |
|-------|-------|---------|------------|
| `edw_db.core.fct_realtime_auth_event` | `rae` | Card transactions | `user_id`, `auth_id`, `req_amt`, `merchant_name` |
| `risk.prod.disputed_transactions` | - | Dispute records | `user_id`, `authorization_code`, `reason` |
| `edw_db.core.member_details` | - | User info | `user_id`, `state_cd`, `enrollment_initiated_ts` |
| `chime.decision_platform.card_auth_events` | `beth table` | Policy decisions | `user_id`, `auth_id`, `policy_name`, `decision_outcome` |

## 🔗 **Most Common Joins**

```sql
-- Link transactions to disputes
LEFT JOIN risk.prod.disputed_transactions dt
  ON (rae.user_id = dt.user_id AND dt.authorization_code = rae.auth_id)

-- Link to card details
LEFT JOIN edw_db.core.dim_card c
  ON (rae.user_id = c.user_id AND RIGHT(rae.pan, 4) = RIGHT(c.card_number, 4))

-- Link to member details
LEFT JOIN edw_db.core.member_details m
  ON rae.user_id = m.user_id

-- Dual auth settlement
LEFT JOIN edw_db.core.fct_realtime_auth_event dual
  ON (rae.user_id = dual.user_id AND rae.auth_id = dual.original_auth_id)
```

## 📈 **Most Common Metrics**

| Metric | Formula | Purpose |
|--------|---------|---------|
| **Dispute Rate (7d)** | `SUM(dispute_ind_7d) / COUNT(*)` | Fraud detection |
| **Dispute Rate (bps)** | `(Disputed amount / Total volume) * 10,000` | Risk assessment |
| **Cross-State Indicator** | `CASE WHEN user_state <> merchant_state THEN 1 ELSE 0 END` | Fraud detection |
| **Unauthorized Disputes** | `SUM(CASE WHEN reason ILIKE 'unauth%' THEN dispute_ind_7d ELSE 0 END)` | Fraud focus |

## 🎯 **Most Common Filters**

```sql
-- Successful card transactions
WHERE response_cd IN ('00','10')
  AND req_amt < 0
  AND original_auth_id = '0'

-- Recent data
WHERE auth_event_created_ts >= DATEADD(day, -30, CURRENT_DATE())

-- Unauthorized disputes
WHERE reason ILIKE 'unauth%'

-- Non-shadow mode
WHERE is_shadow_mode = false
```

## 🏷️ **Common Aliases & Naming**

| Full Name | Common Alias | Context |
|-----------|--------------|---------|
| `edw_db.core.fct_realtime_auth_event` | `rae` | Real-time auth events |
| `chime.decision_platform.card_auth_events` | `beth table` | Policy decisions |
| `risk.prod.disputed_transactions` | `dt` | Dispute data |
| `edw_db.core.member_details` | `m` | Member info |
| `edw_db.core.dim_card` | `c` | Card details |

## ⚡ **Performance Tips**

- **Use `QUALIFY ROW_NUMBER()`** for deduplication
- **Filter early** with `WHERE` clauses before `JOIN`s
- **Use `ZEROIFNULL()`** for feature joins
- **Leverage date partitioning** for time-series queries

## 🔍 **Quick Pattern Lookup**

| Need | Pattern | File Reference |
|------|---------|----------------|
| Link transactions to disputes | Transaction to Dispute Linking | `query_patterns.md` |
| Handle dual auths | Dual Auth Settlement | `query_patterns.md` |
| Calculate dispute rates | Dispute Rate Calculation | `query_patterns.md` |
| Get user activity timeline | User Activity Timeline | `query_patterns.md` |
| Test risk policies | Risk Strategy Simulation | `query_patterns.md` |
| Map network carriers to countries | Network Carrier Mapping | `query_patterns.md` |
| Detect emulator usage | Network vs IP Mismatch | `query_patterns.md` |

## 📚 **Full Documentation**

- **[Table Reference](table_reference.md)** - Complete table documentation
- **[Query Patterns](query_patterns.md)** - Reusable SQL patterns
- **[Business Logic](business_logic.md)** - Business rules and definitions
- **[Main README](README.md)** - Knowledge base overview

---

> 💡 **Pro Tip:** Bookmark this page for instant access to the most common patterns and tables!
