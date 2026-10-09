import { NextResponse } from 'next/server';
import { demoPlatform } from '@/lib/platform';
import { executeQuery } from '@/lib/snowflake';

export const dynamic = 'force-dynamic';
export const revalidate = 0;

export async function GET() {
  try {
    const [kpis, trend, indicators, books, freshness, risk, holdout, forecast, live, liveSummary, anomalies, alerts] = await Promise.all([
      executeQuery<{ TITLE: string; DISPLAY: string; STATUS: string }>(
        'SELECT TITLE, DISPLAY, STATUS FROM CURATED.KPI_SUMMARY ORDER BY SORT_ORDER'),
      executeQuery<{ PERIOD: string; CLAIMS: number | null; REFERRALS: number | null }>(`
        SELECT TO_CHAR(METRIC_DATE, 'YYYY-MM-DD') AS PERIOD,
               CLAIM_COUNT AS CLAIMS, REFERRAL_COUNT AS REFERRALS
        FROM CURATED.TREND_ANALYSIS ORDER BY METRIC_DATE`),
      executeQuery<{ INDICATOR: string; REFERRALS: number; CONFIRMED: number }>(`
        SELECT FRAUD_INDICATOR AS INDICATOR, REFERRAL_COUNT AS REFERRALS, CONFIRMED_COUNT AS CONFIRMED
        FROM CURATED.INDICATOR_SUMMARY ORDER BY CONFIRMED_COUNT DESC, REFERRAL_COUNT DESC`),
      executeQuery<Record<string, string | number | null>>(`
        SELECT ENTITY_ID, ENTITY_NAME, REGION, CATEGORY, RISK_TIER, EVENT_COUNT, CLAIM_COUNT,
               ROUND(LOSS_RATIO_PCT, 1) AS LOSS_RATIO_PCT, REFERRAL_COUNT, CONFIRMED_COUNT, DENIED_COUNT,
               ROUND(REFERRAL_PRECISION_PCT, 1) AS REFERRAL_PRECISION_PCT, AUDIT_COMPLIANCE_PCT,
               ROUND(CLAIMS_PAID_USD / 1e6, 2) AS CLAIMS_PAID_USD_M
        FROM CURATED.PERFORMANCE_SUMMARY ORDER BY ENTITY_ID LIMIT 200`),
      executeQuery<{ RAW_WATERMARK: string | null; CURATED_WATERMARK: string | null }>(`
        SELECT (SELECT TO_CHAR(MAX(EVENT_DATE), 'YYYY-MM-DD') FROM RAW.BOOK_DAILY) AS RAW_WATERMARK,
               (SELECT TO_CHAR(MAX(METRIC_DATE), 'YYYY-MM-DD') FROM CURATED.TREND_ANALYSIS) AS CURATED_WATERMARK`),
      executeQuery<Record<string, string | number | null>>(`
        SELECT ENTITY_ID, TO_CHAR(SCORED_AS_OF, 'YYYY-MM-DD') AS SCORED_AS_OF, FRAUD_PROB_7D, RISK_BAND
        FROM ML.FRAUD_RISK_SCORES ORDER BY FRAUD_PROB_7D DESC`),
      executeQuery<Record<string, string | number | null>>(
        'SELECT N, BASE_RATE, PRECISION_AT_50, RECALL_AT_50 FROM ML.FRAUD_RISK_HOLDOUT_METRICS'),
      executeQuery<Record<string, string | number | null>>(`
        SELECT TO_CHAR(FORECAST_DATE, 'YYYY-MM-DD') AS PERIOD, ROUND(CLAIM_COUNT, 0) AS CLAIM_COUNT,
               ROUND(LOWER_BOUND, 0) AS LOWER_BOUND, ROUND(UPPER_BOUND, 0) AS UPPER_BOUND
        FROM ML.CLAIMS_FORECAST ORDER BY FORECAST_DATE`),
      executeQuery<Record<string, string | number | null>>(`
        SELECT BOOK_ID, TO_CHAR(EVENT_TS, 'YYYY-MM-DD HH24:MI:SS') AS EVENT_TS, ROUND(CLAIM_AMOUNT_USD, 0) AS CLAIM_AMOUNT_USD,
               DOC_MISMATCH_PCT, STATUS, TO_CHAR(LOADED_AT, 'YYYY-MM-DD HH24:MI:SS TZH:TZM') AS LOADED_AT
        FROM RAW.LIVE_CLAIMS ORDER BY EVENT_TS DESC LIMIT 25`),
      executeQuery<Record<string, string | number | null>>(`
        SELECT COUNT(*) AS N, COUNT_IF(STATUS = 'REFER') AS REFERRALS,
               TO_CHAR(MAX(LOADED_AT), 'YYYY-MM-DD HH24:MI:SS TZH:TZM') AS LAST_LOADED,
               ROUND(MEDIAN(DATEDIFF('second', SENT_TS, CONVERT_TIMEZONE('UTC', LOADED_AT)::TIMESTAMP_NTZ)), 0) AS MEDIAN_LAG_S
        FROM RAW.LIVE_CLAIMS`),
      executeQuery<Record<string, string | number | null>>(`
        SELECT ENTITY_ID, TO_CHAR(EVENT_DATE, 'YYYY-MM-DD') AS EVENT_DATE, ROUND(DOC_MISMATCH, 2) AS DOC_MISMATCH,
               ROUND(EXPECTED, 2) AS EXPECTED, ROUND(UPPER_BOUND, 2) AS UPPER_BOUND
        FROM ML.DOC_MISMATCH_ANOMALIES WHERE IS_ANOMALY ORDER BY EVENT_DATE DESC, ENTITY_ID LIMIT 50`),
      executeQuery<Record<string, string | number | null>>(`
        SELECT BOOK_ID, TO_CHAR(EVENT_TS, 'YYYY-MM-DD HH24:MI:SS') AS EVENT_TS, ROUND(CLAIM_AMOUNT_USD, 0) AS CLAIM_AMOUNT_USD,
               DOC_MISMATCH_PCT, SOP_HINT
        FROM APP.ALERT_LOG ORDER BY ALERTED_AT DESC, EVENT_TS DESC LIMIT 25`),
    ]);
    const numberOrNull = (value: unknown): number | null => {
      if (value === null || value === undefined) return null;
      const numeric = Number(value);
      if (!Number.isFinite(numeric)) throw new Error('Non-numeric measure in curated contract');
      return numeric;
    };
    const watermark = freshness[0]?.CURATED_WATERMARK ?? null;
    const ageDays = watermark ? (Date.now() - Date.parse(`${watermark}T00:00:00Z`)) / 86400000 : null;
    return NextResponse.json({
      platform: demoPlatform(),
      kpiCards: kpis.map((row) => ({ title: row.TITLE, value: row.DISPLAY, status: row.STATUS })),
      timeseries: trend.map((row) => ({ period: row.PERIOD, claims: numberOrNull(row.CLAIMS), referrals: numberOrNull(row.REFERRALS) })),
      categories: indicators.map((row) => ({ category: row.INDICATOR, referrals: numberOrNull(row.REFERRALS), confirmed: numberOrNull(row.CONFIRMED) })),
      entities: books.map((row) => ({
        id: row.ENTITY_ID, name: row.ENTITY_NAME, region: row.REGION, category: row.CATEGORY, tier: row.RISK_TIER,
        claims: numberOrNull(row.CLAIM_COUNT), lossRatio: numberOrNull(row.LOSS_RATIO_PCT),
        referrals: numberOrNull(row.REFERRAL_COUNT), confirmed: numberOrNull(row.CONFIRMED_COUNT), denied: numberOrNull(row.DENIED_COUNT),
        precision: numberOrNull(row.REFERRAL_PRECISION_PCT), paid: numberOrNull(row.CLAIMS_PAID_USD_M),
        audit: numberOrNull(row.AUDIT_COMPLIANCE_PCT), events: numberOrNull(row.EVENT_COUNT),
      })),
      auditRisk: books.map((row) => ({
        name: row.ENTITY_NAME, compliance: numberOrNull(row.AUDIT_COMPLIANCE_PCT), confirmed: numberOrNull(row.CONFIRMED_COUNT),
      })).filter((row) => row.compliance !== null && row.confirmed !== null),
      sourceWatermark: watermark,
      rawWatermark: freshness[0]?.RAW_WATERMARK ?? null,
      stale: ageDays === null || ageDays > 2,
      pipelineBehind: freshness[0]?.RAW_WATERMARK !== watermark,
      requestedAt: new Date().toISOString(),
      synthetic: true,
      risk: risk.map((row) => ({
        id: row.ENTITY_ID, scoredAsOf: row.SCORED_AS_OF,
        probability: numberOrNull(row.FRAUD_PROB_7D), band: row.RISK_BAND,
      })),
      holdout: holdout[0] ? {
        n: numberOrNull(holdout[0].N), baseRate: numberOrNull(holdout[0].BASE_RATE),
        precision: numberOrNull(holdout[0].PRECISION_AT_50), recall: numberOrNull(holdout[0].RECALL_AT_50),
      } : null,
      forecast: forecast.map((row) => ({
        period: row.PERIOD, value: numberOrNull(row.CLAIM_COUNT),
        lower: numberOrNull(row.LOWER_BOUND), upper: numberOrNull(row.UPPER_BOUND),
      })),
      modelStatus: holdout[0] ? 'holdout_evaluated' : 'missing',
      live: live.map((row) => ({
        id: row.BOOK_ID, eventTs: row.EVENT_TS, amount: numberOrNull(row.CLAIM_AMOUNT_USD),
        mismatch: numberOrNull(row.DOC_MISMATCH_PCT), status: row.STATUS, loadedAt: row.LOADED_AT,
      })),
      liveSummary: {
        n: numberOrNull(liveSummary[0]?.N), referrals: numberOrNull(liveSummary[0]?.REFERRALS),
        lastLoaded: liveSummary[0]?.LAST_LOADED ?? null, medianLagSeconds: numberOrNull(liveSummary[0]?.MEDIAN_LAG_S),
      },
      anomalies: anomalies.map((row) => ({
        id: row.ENTITY_ID, date: row.EVENT_DATE, mismatch: numberOrNull(row.DOC_MISMATCH),
        expected: numberOrNull(row.EXPECTED), upper: numberOrNull(row.UPPER_BOUND),
      })),
      alerts: alerts.map((row) => ({
        id: row.BOOK_ID, eventTs: row.EVENT_TS, amount: numberOrNull(row.CLAIM_AMOUNT_USD),
        mismatch: numberOrNull(row.DOC_MISMATCH_PCT), hint: row.SOP_HINT,
      })),
    }, { headers: { 'Cache-Control': 'no-store' } });
  } catch {
    return NextResponse.json({ error: 'Claims data is unavailable. Verify the core deployment and application role.' },
      { status: 503, headers: { 'Cache-Control': 'no-store' } });
  }
}
