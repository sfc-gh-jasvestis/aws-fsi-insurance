-- ============================================================================
-- 06_INTELLIGENCE.SQL - search, anomaly detection, semantic view, agent,
-- live-claim alert and on-demand refresh DAG.
-- Run with snowflake/run_intelligence.py (substitutes validated __DEMO_DB__ /
-- __DEMO_WH__ / __ALERT_EMAIL__). Requires 00-05, plus 08 (Snowflake only) or
-- aws/setup_aws.py (AWS build) for RAW.LIVE_CLAIMS.
-- Alerts and tasks are created SUSPENDED; run them with EXECUTE ALERT / EXECUTE TASK.
-- ============================================================================
USE DATABASE __DEMO_DB__;
CREATE SCHEMA IF NOT EXISTS SEARCH;
CREATE SCHEMA IF NOT EXISTS APP;

-- ---------- Synthetic claims-investigation knowledge base (clearly synthetic SOPs) ----------
CREATE OR REPLACE TABLE SEARCH.CLAIMS_SOP_DOCS AS
WITH indicators AS (
  SELECT DISTINCT r.FRAUD_INDICATOR, b.CATEGORY
  FROM RAW.BOOK_DAILY r JOIN RAW.POLICY_BOOKS b ON b.ID = r.ENTITY_ID
  WHERE r.CONFIRMED_COUNT > 0
)
SELECT
  'SOP-' || LPAD(ROW_NUMBER() OVER (ORDER BY CATEGORY, FRAUD_INDICATOR)::VARCHAR, 3, '0') AS DOC_ID,
  'SOP' AS DOC_TYPE,
  CATEGORY,
  FRAUD_INDICATOR,
  CATEGORY || ' - ' || FRAUD_INDICATOR || ' claim investigation' AS TITLE,
  'Synthetic demo SOP. Line of business: ' || CATEGORY || '. Fraud indicator: ' || FRAUD_INDICATOR || '. '
  || 'Step 1: refer the claim to the special investigations unit (SIU), place the payment on hold and acknowledge the claimant within 2 business days. '
  || 'Step 2: ' || CASE
       WHEN FRAUD_INDICATOR = 'Staged collision' THEN 'compare the police report, dashcam or telematics data and photos of both vehicles, and check whether the drivers or passengers appear together in earlier claims.'
       WHEN FRAUD_INDICATOR = 'Inflated damage estimate' THEN 'obtain an independent assessor estimate and compare parts and labour lines with the workshop quote and published parts prices.'
       WHEN FRAUD_INDICATOR = 'Ghost passenger' THEN 'confirm every injured passenger against the police report and medical records, and check for the same passengers in other motor claims.'
       WHEN FRAUD_INDICATOR = 'Inflated contents claim' THEN 'request purchase receipts or bank statements for the highest-value items and compare the list with the sum insured and prior inspections.'
       WHEN FRAUD_INDICATOR = 'Pre-existing damage' THEN 'compare the loss adjuster report with inception photos, prior claims and maintenance records to establish when the damage occurred.'
       WHEN FRAUD_INDICATOR = 'Phantom treatment' THEN 'verify with the provider that each billed treatment took place, and match dates against the member''s admission and travel records.'
       WHEN FRAUD_INDICATOR = 'Duplicate billing' THEN 'search for the same invoice number, amount or service date across claims, providers and members in the last 12 months.'
       WHEN FRAUD_INDICATOR = 'Upcoding' THEN 'compare the billed procedure codes with the clinical notes and the provider''s historical coding mix.'
       WHEN FRAUD_INDICATOR = 'Fake trip cancellation' THEN 'confirm the booking and the cancellation directly with the airline or travel agent, and check the cancellation reason against the policy wording.'
       WHEN FRAUD_INDICATOR = 'Fabricated receipts' THEN 'validate receipt numbers, merchant details and card transactions with the merchant or issuing bank.'
       WHEN FRAUD_INDICATOR = 'Arson indicators' THEN 'obtain the fire brigade report and a cause-and-origin investigation, and review the insured''s recent financial position and cover changes.'
       ELSE 'review the claim against the policy wording and the claimant''s history, and escalate if unexplained.'
     END
  || ' Step 3: if document mismatches exceed 5% or the claim was lodged within 30 days of inception, keep the referral open and request a recorded interview. '
  || 'Step 4: record the outcome; if fraud is confirmed, deny the claim in line with the policy wording, with sign-off from the claims manager.' AS CONTENT
FROM indicators;

CREATE OR REPLACE CORTEX SEARCH SERVICE SEARCH.CLAIMS_SOP_SEARCH
  ON CONTENT
  ATTRIBUTES CATEGORY, FRAUD_INDICATOR
  WAREHOUSE = __DEMO_WH__
  TARGET_LAG = '7 days'
AS (SELECT DOC_ID, TITLE, CATEGORY, FRAUD_INDICATOR, CONTENT FROM SEARCH.CLAIMS_SOP_DOCS);

-- ---------- Document-mismatch anomaly detection (train first 75 days, detect last 15) ----------
CREATE OR REPLACE VIEW ML.DOC_MISMATCH_SERIES AS
SELECT ENTITY_ID, EVENT_DATE::TIMESTAMP_NTZ AS TS, DOC_MISMATCH_PCT::FLOAT AS DOC_MISMATCH
FROM RAW.BOOK_DAILY;
CREATE OR REPLACE VIEW ML.DOC_MISMATCH_TRAIN AS
SELECT * FROM ML.DOC_MISMATCH_SERIES WHERE TS < (SELECT DATEADD(day, -15, MAX(TS)) FROM ML.DOC_MISMATCH_SERIES);
CREATE OR REPLACE VIEW ML.DOC_MISMATCH_DETECT AS
SELECT * FROM ML.DOC_MISMATCH_SERIES WHERE TS >= (SELECT DATEADD(day, -15, MAX(TS)) FROM ML.DOC_MISMATCH_SERIES);

CREATE OR REPLACE SNOWFLAKE.ML.ANOMALY_DETECTION ML.DOC_MISMATCH_ANOMALY_MODEL(
  INPUT_DATA => SYSTEM$REFERENCE('VIEW', 'ML.DOC_MISMATCH_TRAIN'),
  SERIES_COLNAME => 'ENTITY_ID', TIMESTAMP_COLNAME => 'TS', TARGET_COLNAME => 'DOC_MISMATCH',
  LABEL_COLNAME => '');

CREATE OR REPLACE TABLE ML.DOC_MISMATCH_ANOMALIES AS
SELECT SERIES::VARCHAR AS ENTITY_ID, TS::DATE AS EVENT_DATE, Y AS DOC_MISMATCH, FORECAST AS EXPECTED,
       LOWER_BOUND, UPPER_BOUND, IS_ANOMALY, PERCENTILE
FROM TABLE(ML.DOC_MISMATCH_ANOMALY_MODEL!DETECT_ANOMALIES(
  INPUT_DATA => SYSTEM$REFERENCE('VIEW', 'ML.DOC_MISMATCH_DETECT'),
  SERIES_COLNAME => 'ENTITY_ID', TIMESTAMP_COLNAME => 'TS', TARGET_COLNAME => 'DOC_MISMATCH'));

-- ---------- Semantic view ----------
CREATE OR REPLACE SEMANTIC VIEW APP.CLAIMS_ANALYTICS
  TABLES (
    books AS CURATED.PERFORMANCE_SUMMARY PRIMARY KEY (ENTITY_ID)
      COMMENT = 'One row per policy book (market x line of business), 90-day totals',
    risk AS ML.FRAUD_RISK_SCORES PRIMARY KEY (ENTITY_ID)
      COMMENT = 'Latest next-7-day fraudulent-claim probability per policy book',
    indicators AS CURATED.INDICATOR_SUMMARY PRIMARY KEY (FRAUD_INDICATOR)
      COMMENT = 'SIU referrals, confirmed fraud and denied claims by fraud indicator, 90 days',
    daily AS CURATED.TREND_ANALYSIS PRIMARY KEY (METRIC_DATE)
      COMMENT = 'Portfolio-wide totals per day'
  )
  RELATIONSHIPS (risk_book AS risk (ENTITY_ID) REFERENCES books)
  FACTS (
    books.claims_f AS CLAIM_COUNT,
    books.paid_f AS CLAIMS_PAID_USD,
    books.premium_f AS EARNED_PREMIUM_USD,
    books.referrals_f AS REFERRAL_COUNT,
    books.confirmed_f AS CONFIRMED_COUNT,
    books.denied_f AS DENIED_COUNT,
    books.audit_due_f AS AUDIT_DUE,
    books.audit_done_f AS AUDIT_COMPLETED,
    risk.fraud_prob_f AS FRAUD_PROB_7D,
    indicators.ind_referrals_f AS REFERRAL_COUNT,
    indicators.ind_confirmed_f AS CONFIRMED_COUNT,
    indicators.ind_denied_f AS DENIED_COUNT,
    daily.day_claims_f AS CLAIM_COUNT,
    daily.day_paid_f AS CLAIMS_PAID_USD,
    daily.day_premium_f AS EARNED_PREMIUM_USD,
    daily.day_referrals_f AS REFERRAL_COUNT
  )
  DIMENSIONS (
    books.book_id AS ENTITY_ID WITH SYNONYMS = ('book', 'portfolio', 'policy book id'),
    books.book_name AS ENTITY_NAME,
    books.market AS REGION WITH SYNONYMS = ('market', 'country', 'region') COMMENT = 'APJ market where the book is written',
    books.line_of_business AS CATEGORY WITH SYNONYMS = ('line', 'product', 'line of business'),
    books.risk_tier AS RISK_TIER COMMENT = 'Underwriting risk tier 1 (low) to 3 (high)',
    risk.risk_band AS RISK_BAND COMMENT = 'High >= 0.5, Medium >= 0.25, else Low',
    risk.scored_as_of AS SCORED_AS_OF,
    indicators.fraud_indicator AS FRAUD_INDICATOR WITH SYNONYMS = ('indicator', 'red flag', 'fraud type'),
    daily.metric_date AS METRIC_DATE
  )
  METRICS (
    books.loss_ratio_pct AS 100 * SUM(books.paid_f) / NULLIF(SUM(books.premium_f), 0)
      COMMENT = 'Claims paid / earned premium',
    books.claims_filed AS SUM(books.claims_f) WITH SYNONYMS = ('claims', 'claim volume'),
    books.total_claims_paid_usd AS SUM(books.paid_f) WITH SYNONYMS = ('claims paid', 'incurred'),
    books.total_earned_premium_usd AS SUM(books.premium_f) WITH SYNONYMS = ('premium', 'earned premium'),
    books.siu_referrals AS SUM(books.referrals_f) WITH SYNONYMS = ('referrals', 'fraud referrals'),
    books.confirmed_fraud AS SUM(books.confirmed_f) WITH SYNONYMS = ('confirmed fraudulent claims', 'true positives'),
    books.claims_denied AS SUM(books.denied_f) WITH SYNONYMS = ('denied claims', 'fraudulent claims denied'),
    books.referral_precision_pct AS 100 * SUM(books.confirmed_f) / NULLIF(SUM(books.referrals_f), 0)
      COMMENT = 'Confirmed fraud / SIU referrals',
    books.audit_compliance_pct AS 100 * SUM(books.audit_done_f) / NULLIF(SUM(books.audit_due_f), 0)
      COMMENT = 'Claims-file audits completed / audits due',
    risk.avg_fraud_prob AS AVG(risk.fraud_prob_f),
    indicators.indicator_referrals AS SUM(indicators.ind_referrals_f),
    indicators.indicator_confirmed AS SUM(indicators.ind_confirmed_f),
    indicators.indicator_denied AS SUM(indicators.ind_denied_f),
    indicators.indicator_precision_pct AS 100 * SUM(indicators.ind_confirmed_f) / NULLIF(SUM(indicators.ind_referrals_f), 0),
    daily.daily_claims AS SUM(daily.day_claims_f),
    daily.daily_paid_usd AS SUM(daily.day_paid_f),
    daily.daily_loss_ratio_pct AS 100 * SUM(daily.day_paid_f) / NULLIF(SUM(daily.day_premium_f), 0),
    daily.daily_referrals AS SUM(daily.day_referrals_f)
  )
  COMMENT = 'Synthetic APJ insurance claims and fraud analytics (demo)';

-- ---------- Cortex Agent ----------
CREATE OR REPLACE AGENT APP.CLAIMS_AGENT
  COMMENT = 'Claims and fraud assistant over a synthetic APJ insurer'
  FROM SPECIFICATION
$$
models:
  orchestration: claude-sonnet-4-5
instructions:
  response: "Answer only from tool results. State that data is synthetic. Give policy book IDs and numbers with units."
  orchestration: "Use claims_analyst for claims, claims paid, earned premium, loss ratio, SIU referrals, confirmed fraud, denied claims, audits, markets, lines of business, fraud indicators and fraud risk. Use sop_search for claims investigation procedures."
tools:
  - tool_spec:
      type: cortex_analyst_text_to_sql
      name: claims_analyst
      description: "Claims filed, claims paid, earned premium, loss ratio, SIU referrals, confirmed fraud, denied claims, referral precision, audit compliance, fraud indicators and fraud risk scores by policy book"
  - tool_spec:
      type: cortex_search
      name: sop_search
      description: "Synthetic claims-investigation SOPs by line of business and fraud indicator"
tool_resources:
  claims_analyst:
    semantic_view: __DEMO_DB__.APP.CLAIMS_ANALYTICS
    execution_environment:
      type: warehouse
      warehouse: __DEMO_WH__
  sop_search:
    name: __DEMO_DB__.SEARCH.CLAIMS_SOP_SEARCH
    max_results: 3
    id_column: DOC_ID
    title_column: TITLE
$$;

-- ---------- Live-claim alert ----------
CREATE TABLE IF NOT EXISTS APP.ALERT_LOG (
  ALERTED_AT TIMESTAMP_LTZ DEFAULT CURRENT_TIMESTAMP(), BOOK_ID VARCHAR,
  EVENT_TS TIMESTAMP_NTZ, CLAIM_AMOUNT_USD FLOAT, DOC_MISMATCH_PCT FLOAT, SOP_HINT VARCHAR);

CREATE OR REPLACE NOTIFICATION INTEGRATION APJ_INS_EMAIL_INT
  TYPE = EMAIL ENABLED = TRUE ALLOWED_RECIPIENTS = ('__ALERT_EMAIL__');

CREATE OR REPLACE PROCEDURE APP.LOG_LIVE_REFERRALS()
RETURNS NUMBER
LANGUAGE SQL
EXECUTE AS OWNER
AS
$$
DECLARE
  n NUMBER;
BEGIN
  INSERT INTO APP.ALERT_LOG (BOOK_ID, EVENT_TS, CLAIM_AMOUNT_USD, DOC_MISMATCH_PCT, SOP_HINT)
    SELECT c.BOOK_ID, c.EVENT_TS, c.CLAIM_AMOUNT_USD, c.DOC_MISMATCH_PCT,
           'Check ' || b.CATEGORY || ' claims investigation SOPs; current risk band ' || COALESCE(r.RISK_BAND, 'n/a')
    FROM RAW.LIVE_CLAIMS c
    JOIN RAW.POLICY_BOOKS b ON b.ID = c.BOOK_ID
    LEFT JOIN ML.FRAUD_RISK_SCORES r ON r.ENTITY_ID = c.BOOK_ID
    WHERE c.STATUS = 'REFER'
      AND NOT EXISTS (SELECT 1 FROM APP.ALERT_LOG l WHERE l.BOOK_ID = c.BOOK_ID AND l.EVENT_TS = c.EVENT_TS);
  n := SQLROWCOUNT;
  IF (n > 0) THEN
    CALL SYSTEM$SEND_EMAIL('APJ_INS_EMAIL_INT', '__ALERT_EMAIL__',
      '[Demo] Claims SIU referral alert',
      'New live-claim SIU referrals logged in APP.ALERT_LOG: ' || :n || '. Data is synthetic.');
  END IF;
  RETURN n;
END;
$$;

CREATE OR REPLACE ALERT APP.LIVE_CLAIM_ALERT
  WAREHOUSE = __DEMO_WH__
  SCHEDULE = '5 MINUTE'
  IF (EXISTS (
    SELECT 1 FROM RAW.LIVE_CLAIMS c
    WHERE c.STATUS = 'REFER'
      AND NOT EXISTS (SELECT 1 FROM APP.ALERT_LOG l WHERE l.BOOK_ID = c.BOOK_ID AND l.EVENT_TS = c.EVENT_TS)))
  THEN CALL APP.LOG_LIVE_REFERRALS();

-- ---------- On-demand refresh DAG (suspended; run with EXECUTE TASK APP.TASK_REFRESH_CURATED) ----------
CREATE OR REPLACE PROCEDURE APP.REFRESH_CURATED()
RETURNS VARCHAR
LANGUAGE SQL
EXECUTE AS OWNER
AS
$$
BEGIN
  ALTER DYNAMIC TABLE CURATED.PERFORMANCE_SUMMARY REFRESH;
  ALTER DYNAMIC TABLE CURATED.TREND_ANALYSIS REFRESH;
  ALTER DYNAMIC TABLE CURATED.INDICATOR_SUMMARY REFRESH;
  ALTER DYNAMIC TABLE CURATED.KPI_SUMMARY REFRESH;
  RETURN 'refreshed';
END;
$$;

CREATE OR REPLACE TASK APP.TASK_REFRESH_CURATED
  WAREHOUSE = __DEMO_WH__
AS
  CALL APP.REFRESH_CURATED();

CREATE OR REPLACE TASK APP.TASK_RESCORE_RISK
  WAREHOUSE = __DEMO_WH__
  AFTER APP.TASK_REFRESH_CURATED
AS
  CREATE OR REPLACE TABLE ML.FRAUD_RISK_SCORES COPY GRANTS AS
  WITH latest AS (
    SELECT * FROM ML.FRAUD_FEATURES QUALIFY ROW_NUMBER() OVER (PARTITION BY ENTITY_ID ORDER BY EVENT_DATE DESC) = 1
  ), p AS (
    SELECT ENTITY_ID, EVENT_DATE,
           ML.FRAUD_RISK_MODEL!PREDICT(INPUT_DATA => OBJECT_CONSTRUCT(
             'CATEGORY', CATEGORY, 'RISK_TIER', RISK_TIER, 'AVG_TENURE_YEARS', AVG_TENURE_YEARS,
             'DOC_MISMATCH_PCT', DOC_MISMATCH_PCT, 'EARLY_CLAIM_PCT', EARLY_CLAIM_PCT,
             'DOC_MISMATCH_7D', DOC_MISMATCH_7D, 'CONFIRMED_30D', CONFIRMED_30D)) AS PRED
    FROM latest
  )
  SELECT ENTITY_ID, EVENT_DATE AS SCORED_AS_OF, ROUND(PRED:probability:FRAUD::FLOAT, 4) AS FRAUD_PROB_7D,
         CASE WHEN PRED:probability:FRAUD::FLOAT >= 0.5 THEN 'High'
              WHEN PRED:probability:FRAUD::FLOAT >= 0.25 THEN 'Medium' ELSE 'Low' END AS RISK_BAND,
         CURRENT_TIMESTAMP() AS SCORED_AT
  FROM p;
