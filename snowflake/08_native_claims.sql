-- ============================================================================
-- 08_native_claims.sql - Snowflake-only build: live claims feed without AWS.
-- Creates RAW.LIVE_CLAIMS (same columns as the Snowpipe target created by
-- aws/setup_aws.py) and APP.SIMULATE_CLAIMS(N), which inserts synthetic
-- first-notice-of-loss (FNOL) claim events with the same value ranges and ~10%
-- SIU REFER rate as aws/publish_claims.py. Rows are inserted directly; this
-- simulates a claims intake feed and is not Snowpipe Streaming.
-- Run before 06_intelligence.sql (the alert reads RAW.LIVE_CLAIMS).
-- Idempotent: safe to run in the AWS build too.
-- ============================================================================
CREATE SCHEMA IF NOT EXISTS RAW;
CREATE SCHEMA IF NOT EXISTS APP;

CREATE TABLE IF NOT EXISTS RAW.LIVE_CLAIMS (
  BOOK_ID VARCHAR, EVENT_TS TIMESTAMP_NTZ, CLAIM_AMOUNT_USD FLOAT, DOC_MISMATCH_PCT FLOAT,
  STATUS VARCHAR, SENT_TS TIMESTAMP_NTZ, SOURCE_FILE VARCHAR,
  LOADED_AT TIMESTAMP_LTZ DEFAULT CURRENT_TIMESTAMP());

CREATE OR REPLACE PROCEDURE APP.SIMULATE_CLAIMS(N NUMBER)
RETURNS NUMBER
LANGUAGE SQL
EXECUTE AS OWNER
AS
$$
BEGIN
  IF (N < 1 OR N > 1000) THEN
    RETURN 0;
  END IF;
  INSERT INTO RAW.LIVE_CLAIMS (BOOK_ID, EVENT_TS, CLAIM_AMOUNT_USD, DOC_MISMATCH_PCT, STATUS, SENT_TS, SOURCE_FILE)
    WITH g AS (
      SELECT 'BK-' || LPAD(UNIFORM(0, 39, RANDOM())::VARCHAR, 4, '0') AS BOOK_ID,
             UNIFORM(0::FLOAT, 1::FLOAT, RANDOM()) < 0.1 AS IS_REFER,
             SYSDATE() AS TS, SEQ4() AS I
      FROM TABLE(GENERATOR(ROWCOUNT => 1000))
    )
    -- NORMAL() needs a constant mean, so the referral offset is added outside it.
    SELECT BOOK_ID, TS,
           ROUND(IFF(IS_REFER, 25000, 3000) * EXP(NORMAL(0, 0.5, RANDOM())), 2),
           ROUND(GREATEST(0, IFF(IS_REFER, 7.5, 1.2) + NORMAL(0, 0.8, RANDOM())), 2),
           IFF(IS_REFER, 'REFER', 'OK'), TS, 'APP.SIMULATE_CLAIMS'
    FROM g
    WHERE I < :N;
  RETURN SQLROWCOUNT;
END;
$$;

-- Optional continuous feed for longer demos (suspended; RESUME to start, SUSPEND after).
CREATE OR REPLACE TASK APP.TASK_SIMULATE_CLAIMS
  WAREHOUSE = __DEMO_WH__
  SCHEDULE = '1 MINUTE'
AS
  CALL APP.SIMULATE_CLAIMS(5);
