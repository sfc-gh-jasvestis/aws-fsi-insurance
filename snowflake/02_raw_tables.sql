-- Synthetic book-day claims observations for a fictional APJ insurer.
-- 40 policy books = 8 markets x 5 lines of business. Nothing is seeded as a
-- prediction. Randomness is HASH-seeded, so every rebuild is reproducible:
-- per-book fraud propensity, audit drift between periodic claims-file audits,
-- missed audits, line-weighted fraud indicators, false-positive SIU referrals,
-- and two market-wide catastrophe events (typhoon, flood).
USE DATABASE IDENTIFIER($DEMO_DB);
USE SCHEMA RAW;
USE WAREHOUSE IDENTIFIER($DEMO_WH);

CREATE TABLE RAW.POLICY_BOOKS AS
WITH books AS (
  SELECT ROW_NUMBER() OVER (ORDER BY SEQ4()) - 1 AS BOOK_INDEX
  FROM TABLE(GENERATOR(ROWCOUNT => 40))
), draws AS (
  SELECT BOOK_INDEX,
         MOD(ABS(HASH(BOOK_INDEX, 'tenure')), 1000000) / 1e6 AS U_TENURE,
         MOD(ABS(HASH(BOOK_INDEX, 'rate')), 1000000) / 1e6 AS U_RATE,
         MOD(ABS(HASH(BOOK_INDEX, 'audit')), 1000000) / 1e6 AS U_AUDIT,
         MOD(ABS(HASH(BOOK_INDEX, 'discipline')), 1000000) / 1e6 AS U_DISCIPLINE,
         MOD(ABS(HASH(BOOK_INDEX, 'tier')), 1000000) / 1e6 AS U_TIER,
         MOD(ABS(HASH(BOOK_INDEX, 'size')), 1000000) / 1e6 AS U_SIZE,
         MOD(ABS(HASH(BOOK_INDEX, 'lr')), 1000000) / 1e6 AS U_LR
  FROM books
), books_named AS (
  SELECT *,
         -- Every market x line combination appears exactly once.
         CASE MOD(BOOK_INDEX, 8) WHEN 0 THEN 'Singapore' WHEN 1 THEN 'Hong Kong'
              WHEN 2 THEN 'Australia' WHEN 3 THEN 'Japan' WHEN 4 THEN 'South Korea'
              WHEN 5 THEN 'Malaysia' WHEN 6 THEN 'Thailand' ELSE 'Indonesia' END AS REGION,
         CASE FLOOR(BOOK_INDEX / 8) WHEN 0 THEN 'Motor' WHEN 1 THEN 'Home' WHEN 2 THEN 'Health'
              WHEN 3 THEN 'Travel' ELSE 'Commercial Property' END AS CATEGORY
  FROM draws
)
SELECT 'BK-' || LPAD(BOOK_INDEX::VARCHAR, 4, '0') AS ID,
       REGION || ' ' || CATEGORY AS NAME,
       REGION, CATEGORY, BOOK_INDEX,
       1 + FLOOR(U_TIER * 3) AS RISK_TIER,
       ROUND(0.3 + U_TENURE * 5.7, 1) AS AVG_TENURE_YEARS,
       ROUND(0.6 + U_SIZE * 0.8, 3) AS SIZE_FACTOR,
       -- Base daily probability of a fraudulent claim 0.4%-3%; ~15% of books
       -- are targeted by organised rings (x3).
       (0.004 + U_RATE * 0.026) * IFF(U_RATE > 0.85, 3, 1) AS BASE_FRAUD_RATE,
       7 * (1 + FLOOR(U_AUDIT * 3)) AS AUDIT_INTERVAL_DAYS,
       0.55 + U_DISCIPLINE * 0.45 AS AUDIT_COMPLETION_PROB,
       -- Earned premium is priced for a 55%-80% expected loss ratio.
       ROUND(CASE CATEGORY WHEN 'Motor' THEN 30 * 2800 WHEN 'Home' THEN 8 * 9500
                           WHEN 'Health' THEN 45 * 1200 WHEN 'Travel' THEN 12 * 900
                           ELSE 2 * 65000 END
             * (0.6 + U_SIZE * 0.8) / (0.55 + 0.25 * U_LR), 2) AS DAILY_PREMIUM_USD,
       'Active' AS STATUS
FROM books_named;

CREATE TABLE RAW.BOOK_DAILY AS
WITH days AS (
  SELECT ROW_NUMBER() OVER (ORDER BY SEQ4()) - 1 AS DAY_INDEX
  FROM TABLE(GENERATOR(ROWCOUNT => 90))
), cat_events AS (
  -- Two market-wide catastrophes; every book in the market gets a surge referral.
  SELECT * FROM VALUES (27, 'Hong Kong'), (64, 'Thailand') AS o(DAY_INDEX, REGION)
), base AS (
  SELECT b.ID AS ENTITY_ID, b.BOOK_INDEX, b.CATEGORY, b.REGION, b.AVG_TENURE_YEARS,
         b.SIZE_FACTOR, b.DAILY_PREMIUM_USD,
         b.BASE_FRAUD_RATE, b.AUDIT_INTERVAL_DAYS, b.AUDIT_COMPLETION_PROB,
         d.DAY_INDEX,
         DATEADD('day', d.DAY_INDEX - 89, CURRENT_DATE()) AS EVENT_DATE,
         MOD(d.DAY_INDEX + b.BOOK_INDEX * 5, b.AUDIT_INTERVAL_DAYS) AS DAYS_SINCE_AUDIT,
         MOD(ABS(HASH(b.ID, d.DAY_INDEX, 'fraud')), 1000000) / 1e6 AS U_FRAUD,
         MOD(ABS(HASH(b.ID, d.DAY_INDEX, 'detect')), 1000000) / 1e6 AS U_DETECT,
         MOD(ABS(HASH(b.ID, d.DAY_INDEX, 'fp')), 1000000) / 1e6 AS U_FP,
         MOD(ABS(HASH(b.ID, d.DAY_INDEX, 'indicator')), 1000000) / 1e6 AS U_IND,
         MOD(ABS(HASH(b.ID, d.DAY_INDEX, 'done')), 1000000) / 1e6 AS U_DONE,
         MOD(ABS(HASH(b.ID, d.DAY_INDEX, 'claims')), 1000000) / 1e6 AS U_CLAIMS,
         MOD(ABS(HASH(b.ID, d.DAY_INDEX, 'noise')), 1000000) / 1e6 AS U_NOISE,
         MOD(ABS(HASH(b.ID, d.DAY_INDEX, 'deny')), 1000000) / 1e6 AS U_DENY,
         c.REGION IS NOT NULL AS CAT_EVENT
  FROM RAW.POLICY_BOOKS b CROSS JOIN days d
  LEFT JOIN cat_events c ON c.DAY_INDEX = d.DAY_INDEX AND c.REGION = b.REGION
), audit AS (
  SELECT *,
         IFF(DAYS_SINCE_AUDIT = 0, 1, 0) AS AUDIT_DUE,
         IFF(DAYS_SINCE_AUDIT = 0 AND U_DONE < AUDIT_COMPLETION_PROB, 1, 0) AS AUDIT_COMPLETED,
         -- Leakage drift rises between claims-file audits; weak audit discipline carries it over.
         DAYS_SINCE_AUDIT / AUDIT_INTERVAL_DAYS + (1 - AUDIT_COMPLETION_PROB) AS DRIFT
  FROM base
), activity AS (
  SELECT *,
         CASE WHEN U_FRAUD < LEAST(0.5, BASE_FRAUD_RATE * (0.4 + 1.6 * DRIFT) * (1 + 1 / (1 + AVG_TENURE_YEARS))) / 4 THEN 2
              WHEN U_FRAUD < LEAST(0.5, BASE_FRAUD_RATE * (0.4 + 1.6 * DRIFT) * (1 + 1 / (1 + AVG_TENURE_YEARS))) THEN 1
              ELSE 0 END AS FRAUD_COUNT
  FROM audit
), referrals AS (
  SELECT *,
         -- Fraud indicators catch about 85% of fraudulent claims; the rest is paid.
         IFF(CAT_EVENT, 0, IFF(U_DETECT < 0.85, FRAUD_COUNT, 0)) AS CONFIRMED_COUNT,
         -- False-positive SIU referrals: higher for high-volume lines.
         IFF(CAT_EVENT, 1, IFF(U_FP < CASE CATEGORY WHEN 'Health' THEN 0.18
                                                    WHEN 'Motor' THEN 0.14
                                                    WHEN 'Commercial Property' THEN 0.12
                                                    WHEN 'Home' THEN 0.10 ELSE 0.08 END, 1, 0)) AS FALSE_POSITIVE_COUNT
  FROM activity
), measured AS (
  SELECT *,
         CONFIRMED_COUNT + FALSE_POSITIVE_COUNT AS REFERRAL_COUNT,
         ROUND(CASE CATEGORY WHEN 'Motor' THEN 30 WHEN 'Home' THEN 8 WHEN 'Health' THEN 45
                             WHEN 'Travel' THEN 12 ELSE 2 END
               * SIZE_FACTOR * (0.7 + 0.6 * U_CLAIMS) * (1 + 0.5 * FRAUD_COUNT)
               * IFF(CAT_EVENT, 3, 1)) AS CLAIM_COUNT,
         CASE CATEGORY WHEN 'Motor' THEN 2800 WHEN 'Home' THEN 9500 WHEN 'Health' THEN 1200
                       WHEN 'Travel' THEN 900 ELSE 65000 END
           * (0.8 + 0.4 * U_NOISE) * (1 + 0.6 * FRAUD_COUNT) AS AVG_CLAIM_USD
  FROM referrals
)
SELECT ENTITY_ID || '-' || TO_CHAR(EVENT_DATE, 'YYYYMMDD') AS EVENT_ID,
       ENTITY_ID, EVENT_DATE,
       CLAIM_COUNT,
       ROUND(CLAIM_COUNT * AVG_CLAIM_USD, 2) AS CLAIMS_PAID_USD,
       DAILY_PREMIUM_USD AS EARNED_PREMIUM_USD,
       REFERRAL_COUNT, CONFIRMED_COUNT,
       IFF(CONFIRMED_COUNT > 0 AND U_DENY < 0.6, 1, 0) AS CLAIMS_DENIED,
       CASE WHEN REFERRAL_COUNT = 0 THEN 'None'
            WHEN CAT_EVENT THEN 'Catastrophe claim surge'
            WHEN CATEGORY = 'Motor' THEN IFF(U_IND < 0.5, 'Staged collision', IFF(U_IND < 0.8, 'Inflated damage estimate', 'Ghost passenger'))
            WHEN CATEGORY = 'Home' THEN IFF(U_IND < 0.55, 'Inflated contents claim', 'Pre-existing damage')
            WHEN CATEGORY = 'Health' THEN IFF(U_IND < 0.45, 'Phantom treatment', IFF(U_IND < 0.8, 'Duplicate billing', 'Upcoding'))
            WHEN CATEGORY = 'Travel' THEN IFF(U_IND < 0.5, 'Fake trip cancellation', 'Fabricated receipts')
            ELSE IFF(U_IND < 0.4, 'Arson indicators', IFF(U_IND < 0.75, 'Inflated contents claim', 'Pre-existing damage')) END AS FRAUD_INDICATOR,
       AUDIT_DUE, AUDIT_COMPLETED,
       ROUND(0.5 + 2.0 * DRIFT + 3.0 * FRAUD_COUNT + U_NOISE * 0.8, 2) AS DOC_MISMATCH_PCT,
       ROUND(4 + 3 * DRIFT + 6 * FRAUD_COUNT + U_NOISE * 2, 1) AS EARLY_CLAIM_PCT,
       CURRENT_TIMESTAMP() AS LOADED_AT
FROM measured;

-- Claim supporting-document coverage per book (snapshot).
CREATE TABLE RAW.CLAIM_DOCUMENTS AS
SELECT ID AS ENTITY_ID,
       CASE CATEGORY WHEN 'Motor' THEN 'Police report' WHEN 'Home' THEN 'Loss adjuster report'
                     WHEN 'Health' THEN 'Medical report' WHEN 'Travel' THEN 'Itinerary and receipts'
                     ELSE 'Fire brigade report' END AS DOC_TYPE,
       1 + MOD(ABS(HASH(ID, 'req')), 4) AS REQUIRED_QTY,
       MOD(ABS(HASH(ID, 'file')), 5) AS ON_FILE_QTY,
       IFF(MOD(ABS(HASH(ID, 'file')), 5) < 1 + MOD(ABS(HASH(ID, 'req')), 4),
           MOD(ABS(HASH(ID, 'pending')), 3), 0) AS PENDING_QTY,
       CURRENT_DATE() AS SNAPSHOT_DATE
FROM RAW.POLICY_BOOKS;
