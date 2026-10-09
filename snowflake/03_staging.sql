-- Validate the producer contract before building downstream objects.
USE DATABASE IDENTIFIER($DEMO_DB);
USE SCHEMA RAW;
USE WAREHOUSE IDENTIFIER($DEMO_WH);

EXECUTE IMMEDIATE $$
DECLARE
  violations INTEGER;
  invalid_source EXCEPTION (-20001, 'Synthetic source failed grain or measure validation');
BEGIN
  SELECT COUNT(*) INTO :violations FROM (
    SELECT ENTITY_ID, EVENT_DATE
    FROM RAW.BOOK_DAILY
    GROUP BY ENTITY_ID, EVENT_DATE HAVING COUNT(*) <> 1
    UNION ALL
    SELECT observation.ENTITY_ID, observation.EVENT_DATE
    FROM RAW.BOOK_DAILY observation
    LEFT JOIN RAW.POLICY_BOOKS book ON book.ID = observation.ENTITY_ID
    WHERE book.ID IS NULL OR observation.CLAIM_COUNT < 0
       OR observation.CLAIMS_PAID_USD < 0 OR observation.EARNED_PREMIUM_USD <= 0
       OR observation.CONFIRMED_COUNT < 0 OR observation.CONFIRMED_COUNT > observation.REFERRAL_COUNT
       OR observation.CLAIMS_DENIED > observation.CONFIRMED_COUNT
       OR observation.AUDIT_COMPLETED > observation.AUDIT_DUE
  );
  IF (violations > 0) THEN
    RAISE invalid_source;
  END IF;
END;
$$;
