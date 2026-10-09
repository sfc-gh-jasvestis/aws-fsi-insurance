# Claims and Fraud Analytics

**APJ - Insurance**
Use case: Claims operations and SIU fraud triage

> Claims and fraud analytics for 40 policy books at a fictional insurer across 8 APJ markets and 5 lines of business: dynamic tables, a holdout-evaluated fraudulent-claim classifier, a claims forecast and grounded AI answers.

## Why Snowflake

- **Dynamic tables** reconcile claims, loss ratio, SIU referrals, confirmed fraud and audit compliance from RAW book data, with checks in `run_core.py`
- **Fraudulent-claim classification** gives a holdout-evaluated next-7-day probability per policy book
- **Claims forecast** projects 14 days of portfolio-wide claim volume with prediction intervals, for claims-handler staffing
- **Grounded AI**: the Cortex Agent (Analyst over a semantic view, plus Search over SOPs) shows its SQL and SOP citations
- **Live claims**: a native FNOL simulator (Snowflake only) or S3 uploads and Snowpipe (AWS build), then an alert and email

## What is built

| | |
|---|---|
| Dimension table | `RAW.POLICY_BOOKS` (40 rows) |
| Fact table | `RAW.BOOK_DAILY` (3,600 book-days, 90 days) |
| Curated layer | `CURATED.KPI_SUMMARY`, `PERFORMANCE_SUMMARY`, `INDICATOR_SUMMARY`, `TREND_ANALYSIS` |
| ML | `ML.FRAUD_RISK_SCORES`, `ML.FRAUD_RISK_HOLDOUT_METRICS`, `ML.CLAIMS_FORECAST`, `ML.DOC_MISMATCH_ANOMALIES` |

Markets: Singapore, Hong Kong, Australia, Japan, South Korea, Malaysia, Thailand, Indonesia.
Lines of business: Motor, Home, Health, Travel, Commercial Property.

## KPI cards (live from `CURATED.KPI_SUMMARY`; no fallback values)

| Card | Value from the seeded data |
|---|---|
| Loss Ratio | 72.9% |
| Claims Filed | 76,317 |
| Claims Paid (USD M) | 301 |
| SIU Referrals | 602 |
| Confirmed Fraud | 151 |
| Referral Precision | 25.1% |
| Fraudulent Claims Denied | 70 |
| Claims File Audit Compliance | 80.3% |
| Policy Books Monitored | 40 |
| Claim Document Coverage | 54.4% |
| Claim Documents Pending | 21 |

Values are synthetic. A rebuild reproduces them because the data is HASH-seeded; dates are relative to the build day.

## Demo flow

1. Executive Cockpit: KPIs, daily claims against SIU referrals, referrals and confirmed fraud by fraud indicator, policy book table
2. Predictive: holdout metrics, risk bands, 14-day claims forecast, document mismatch anomalies
3. Claims Audit: audit compliance, document coverage and pending documents, audit compliance against confirmed fraud, then generate the action memo
4. Live Claims: run `CALL APP.SIMULATE_CLAIMS(20)` (Snowflake only) or `python aws/publish_claims.py --account <AWS_ACCOUNT_ID> --count 20` (AWS build). Then run `EXECUTE ALERT APP.LIVE_CLAIM_ALERT` and show the referral log and email.
5. Ask AI: the Cortex Agent answers metric questions through the semantic view and cites SOPs from Cortex Search. The SQL is shown.
6. QuickSight (AWS build): the same Snowflake tables through DIRECT_QUERY
7. Architecture: both builds side by side

## Talking points

- About one SIU referral in four is confirmed as fraud (25.1%). Most referrals end as false positives, which is where investigator time goes.
- Pre-existing damage produces the most confirmed fraud. Catastrophe claim surge referrals hit every book in a market at once and are never confirmed.
- The risk model is evaluated on a time-based holdout: precision 0.34 and recall 0.24 at 0.5, against a 0.21 base rate. Present it as triage, not a verdict.
- Catastrophe surge days are excluded from model training, because they are not book-driven.

## Business impact

Use only the sourced references in `README.md` (Business Impact).
