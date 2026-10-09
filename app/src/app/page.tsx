'use client';

import { useEffect, useState } from 'react';
import { AppLayout } from '@/components/AppLayout';
import { KPICard } from '@/components/KPICard';
import { Chart } from '@/components/Chart';
import { DataTable } from '@/components/DataTable';
import { AskAI } from '@/components/AskAI';
import { ActionMemo } from '@/components/ActionMemo';

interface ClaimsData {
  platform: 'snowflake' | 'aws';
  kpiCards: { title: string; value: string }[];
  timeseries: { period: string; claims: number | null; referrals: number | null }[];
  categories: { category: string; referrals: number | null; confirmed: number | null }[];
  entities: Record<string, string | number | null>[];
  auditRisk: { name: string; compliance: number; confirmed: number }[];
  sourceWatermark: string | null;
  rawWatermark: string | null;
  requestedAt: string;
  stale: boolean;
  pipelineBehind: boolean;
  risk: Record<string, string | number | null>[];
  holdout: { n: number | null; baseRate: number | null; precision: number | null; recall: number | null } | null;
  forecast: { period: string; value: number | null; lower: number | null; upper: number | null }[];
  live: Record<string, string | number | null>[];
  liveSummary: { n: number | null; referrals: number | null; lastLoaded: string | null; medianLagSeconds: number | null };
  anomalies: Record<string, string | number | null>[];
  alerts: Record<string, string | number | null>[];
}

const pct = (value: number | null) => (value === null ? 'n/a' : `${(value * 100).toFixed(0)}%`);

export default function HomePage() {
  const [data, setData] = useState<ClaimsData | null>(null);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState<string | null>(null);
  const [attempt, setAttempt] = useState(0);

  useEffect(() => {
    const controller = new AbortController();
    setLoading(true);
    setError(null);
    setData(null);
    fetch('/api/data', { cache: 'no-store', signal: controller.signal })
      .then(async (response) => {
        if (!response.ok) throw new Error('Data request failed');
        const payload = await response.json();
        if (!Array.isArray(payload.kpiCards) || !Array.isArray(payload.entities)) throw new Error('Invalid contract');
        return payload;
      })
      .then(setData)
      .catch(() => {
        if (!controller.signal.aborted) setError('Snowflake data is unavailable. No fallback values are displayed.');
      })
      .finally(() => { if (!controller.signal.aborted) setLoading(false); });
    return () => controller.abort();
  }, [attempt]);

  const isAws = (data?.platform ?? 'aws') === 'aws';
  const awsDiagram = { key: 'aws', title: 'AWS + Snowflake', src: '/architecture-aws.html' };
  const sfDiagram = { key: 'snowflake', title: 'Snowflake Only', src: '/architecture-snowflake.html' };
  const diagrams = isAws ? [awsDiagram, sfDiagram] : [sfDiagram, awsDiagram];
  const kpiVal = (title: string) => data?.kpiCards.find((card) => card.title === title)?.value ?? 'Unavailable';
  const executive = (
    <div className="space-y-6">
      <div className="grid grid-cols-1 gap-4 sm:grid-cols-2 lg:grid-cols-4">
        {['Loss Ratio', 'Claims Filed', 'Claims Paid (USD M)', 'Referral Precision'].map((title) => (
          <KPICard key={title} title={title} value={kpiVal(title)} status="neutral" />
        ))}
      </div>
      <p className="text-sm text-slate-600">Loss ratio = claims paid / earned premium. Referral precision = confirmed fraudulent claims / claims referred to the special investigations unit (SIU). Amounts are in USD.</p>
      <div className="grid grid-cols-1 gap-4 lg:grid-cols-2">
        <Chart data={data?.timeseries ?? []} type="line" xKey="period"
          yKeys={[{ key: 'claims', name: 'Claims filed' }, { key: 'referrals', name: 'SIU referrals' }]} title="Daily Claims and SIU Referrals" />
        <Chart data={data?.categories ?? []} type="bar" xKey="category"
          yKeys={[{ key: 'referrals', name: 'Referrals' }, { key: 'confirmed', name: 'Confirmed fraud' }]} title="SIU Referrals and Confirmed Fraud by Indicator" />
      </div>
      <DataTable columns={[
        { key: 'id', header: 'Book' }, { key: 'region', header: 'Market' }, { key: 'category', header: 'Line' },
        { key: 'claims', header: 'Claims' }, { key: 'lossRatio', header: 'Loss ratio (%)' }, { key: 'paid', header: 'Paid (USD M)' },
        { key: 'referrals', header: 'Referrals' }, { key: 'confirmed', header: 'Confirmed' }, { key: 'precision', header: 'Precision (%)' },
      ]} data={data?.entities ?? []} title="Policy book observations" />
    </div>
  );
  const predictive = (
    <div className="space-y-4">
      <h2 className="font-semibold">7-day fraudulent-claim risk and claims forecast</h2>
      <p className="text-sm text-slate-600">
        Snowflake ML classification predicts the probability that a policy book has a confirmed fraudulent claim in the next 7 days,
        from document mismatch rates, early claims after policy inception, recent confirmed fraud, risk tier, policy tenure and line of business.
      </p>
      {data?.holdout ? (
        <p role="status" className="text-sm text-slate-700">
          Out-of-time holdout ({data.holdout.n} book-days): precision {pct(data.holdout.precision)} and recall{' '}
          {pct(data.holdout.recall)} at a 0.5 threshold, versus a {pct(data.holdout.baseRate)} base rate.
        </p>
      ) : (
        <p role="status">Model outputs are not deployed. Run snowflake/05_ml.sql.</p>
      )}
      <DataTable columns={[
        { key: 'id', header: 'Book' }, { key: 'band', header: 'Risk band' },
        { key: 'probability', header: 'P(fraud in 7 days)' }, { key: 'scoredAsOf', header: 'Scored as of' },
      ]} data={data?.risk ?? []} title="Fraudulent-claim risk by policy book" />
      <Chart data={data?.forecast ?? []} type="line" xKey="period"
        yKeys={[{ key: 'value', name: 'Forecast' }, { key: 'lower', name: 'Lower' }, { key: 'upper', name: 'Upper' }]}
        title="Portfolio-wide claims forecast, next 14 days (claims per day)" />
      <DataTable columns={[
        { key: 'id', header: 'Book' }, { key: 'date', header: 'Date' }, { key: 'mismatch', header: 'Document mismatch (%)' },
        { key: 'expected', header: 'Expected' }, { key: 'upper', header: 'Upper bound' },
      ]} data={data?.anomalies ?? []} title="Document mismatch anomalies, last 15 days (Snowflake ML anomaly detection, trained on the prior 75 days)" />
    </div>
  );
  const liveTab = (
    <div className="space-y-4">
      <h2 className="font-semibold">{isAws ? 'Live claims: S3 upload to Snowpipe' : 'Live claims: Snowflake-native simulator'}</h2>
      <p className="text-sm text-slate-600">
        {isAws
          ? 'Simulated first-notice-of-loss (FNOL) claim events are uploaded to the S3 landing bucket under claims/ (aws/publish_claims.py), and Snowpipe auto-ingest loads them into RAW.LIVE_CLAIMS.'
          : 'CALL APP.SIMULATE_CLAIMS(n) inserts simulated first-notice-of-loss (FNOL) claim events directly into RAW.LIVE_CLAIMS (or resume APP.TASK_SIMULATE_CLAIMS for a feed every minute). This simulates a claims intake feed; it is not Snowpipe Streaming.'}
        {' '}The alert APP.LIVE_CLAIM_ALERT logs REFER events and emails the on-call SIU investigator.
      </p>
      <div className="grid grid-cols-1 gap-4 sm:grid-cols-2 lg:grid-cols-4">
        <KPICard title="Claim events loaded" value={String(data?.liveSummary?.n ?? 'n/a')} />
        <KPICard title="REFER events" value={String(data?.liveSummary?.referrals ?? 'n/a')} />
        <KPICard title={isAws ? 'Median send to table lag (s)' : 'Median generated to table lag (s)'} value={String(data?.liveSummary?.medianLagSeconds ?? 'n/a')} />
        <KPICard title="Last load" value={data?.liveSummary?.lastLoaded ?? 'none'} />
      </div>
      <DataTable columns={[
        { key: 'id', header: 'Book' }, { key: 'eventTs', header: 'Event (UTC)' }, { key: 'amount', header: 'Claim (USD)' },
        { key: 'mismatch', header: 'Doc mismatch (%)' }, { key: 'status', header: 'Status' }, { key: 'loadedAt', header: 'Loaded' },
      ]} data={data?.live ?? []} title="Latest 25 claim events" />
      <DataTable columns={[
        { key: 'id', header: 'Book' }, { key: 'eventTs', header: 'Event (UTC)' }, { key: 'amount', header: 'Claim (USD)' },
        { key: 'mismatch', header: 'Doc mismatch (%)' }, { key: 'hint', header: 'Action hint' },
      ]} data={data?.alerts ?? []} title="SIU referral log" />
    </div>
  );
  const planning = (
    <div className="space-y-6">
      <div className="grid grid-cols-1 gap-4 sm:grid-cols-3">
        <KPICard title="Claims File Audit Compliance" value={kpiVal('Claims File Audit Compliance')} />
        <KPICard title="Claim Document Coverage" value={kpiVal('Claim Document Coverage')} />
        <KPICard title="Claim Documents Pending" value={kpiVal('Claim Documents Pending')} />
      </div>
      <Chart data={data?.auditRisk ?? []} type="scatter" xKey="compliance" xName="Audit compliance"
        yKeys={[{ key: 'confirmed', name: 'Confirmed fraudulent claims' }]} yDomain={[0, 'auto']}
        title="Claims-file audit compliance (%) vs confirmed fraudulent claims by policy book" />
      <p className="text-sm text-slate-600">Synthetic associations are not evidence that audits prevented fraud.</p>
      <ActionMemo persona={{ name: 'Mei Ling Tan', role: 'Head of Claims (fictional persona)' }} context={{}}
        onGenerate={async () => {
          const r = await fetch('/api/ask', { method: 'POST', headers: { 'Content-Type': 'application/json' }, body: JSON.stringify({ mode: 'memo' }) });
          if (!r.ok) throw new Error('memo failed');
          const j = await r.json();
          return { subject: 'Draft claims and fraud actions (synthetic data, human review required)', body: j.answer, urgency: 'review', actions: [] };
        }} />
      <p role="status" className="text-sm text-slate-600">{isAws ? 'Draft generated by Amazon Bedrock (Claude) through a Snowflake external-access function' : 'Draft generated by Snowflake Cortex AI_COMPLETE (Claude Sonnet 4.5)'}, from the KPI, policy book, fraud-indicator and risk tables only. No notification is sent.</p>
    </div>
  );
  const ai = (
    <div className="space-y-4">
      <p role="status">Answers come from the Cortex Agent APP.CLAIMS_AGENT. It uses Cortex Analyst over the semantic view APP.CLAIMS_ANALYTICS for metrics, and Cortex Search over synthetic claims-investigation SOPs for procedures. The generated SQL is shown with each answer.</p>
      <div className="h-[500px]">
        <AskAI title="Ask the claims agent" mode="advisor" sampleQuestions={['Which 3 policy books have the most confirmed fraud?', 'Which books are high risk this week and what SOP applies?', 'What is the loss ratio by line of business?']}
          onSubmit={async (question) => {
            const r = await fetch('/api/agent', { method: 'POST', headers: { 'Content-Type': 'application/json' }, body: JSON.stringify({ question }) });
            if (!r.ok) throw new Error('agent failed');
            const j = await r.json();
            const cites = j.sops?.length ? `\n\nSOPs: ${j.sops.join(', ')}` : '';
            return { answer: `${j.answer}${cites}`, sql: j.sql ?? undefined };
          }} />
      </div>
    </div>
  );
  const architecture = (
    <div className="space-y-4">
      {diagrams.map((d, i) => (
        <div key={d.key} className="space-y-2">
          <h2 className="font-semibold">Architecture: {d.title}{i === 0 ? ' (this deployment)' : ''}</h2>
          <iframe src={d.src} title={`${d.title} architecture diagram`} className="h-[620px] w-full rounded border border-slate-200" />
          <p className="text-sm text-slate-600">Hover a component for details. <a className="underline" href={d.src} target="_blank" rel="noreferrer">Open full screen</a></p>
        </div>
      ))}
      <h2 className="font-semibold">Implementation status</h2>
      <p>Core source: synthetic policy books (8 APJ markets x 5 lines of business), daily book observations and claim documents. Curated dynamic tables compute numerator/denominator metrics and are suspended after on-demand initialization.</p>
      <p>Application: Next.js server queries the explicit curated contract. Request time and source observation watermark are separate.</p>
      <p>ML: SNOWFLAKE.ML.CLASSIFICATION fraudulent-claim risk model evaluated on a time-based holdout, plus a 14-day claims FORECAST with prediction intervals.</p>
      <p>ML: ANOMALY_DETECTION flags document mismatch outliers per policy book over the last 15 days.</p>
      <p>AI: Cortex Agent (Cortex Analyst over a semantic view, plus Cortex Search over SOPs) answers questions. The action memo uses {isAws ? 'Amazon Bedrock Claude through an external-access UDF' : 'Cortex AI_COMPLETE (Claude Sonnet 4.5)'}.</p>
      {isAws ? (
        <>
          <p>AWS ingestion: FNOL claim batches uploaded to S3, then Snowpipe auto-ingest (SQS) into RAW.LIVE_CLAIMS, with a Snowflake alert and email on REFER events.</p>
          <p>QuickSight: Snowflake DIRECT_QUERY dashboard (daily claims, confirmed fraud by policy book, fraudulent-claim risk), with a Q topic.</p>
        </>
      ) : (
        <>
          <p>Ingestion: APP.SIMULATE_CLAIMS inserts simulated FNOL claim events into RAW.LIVE_CLAIMS, with a Snowflake alert and email on REFER events. No AWS account is used.</p>
          <p>BI: this SPCS app is the dashboard; natural-language questions go to the Cortex Agent.</p>
        </>
      )}
      <p>Orchestration: the task graph APP.TASK_REFRESH_CURATED, then TASK_RESCORE_RISK, runs on demand. Alerts and tasks stay suspended between demos.</p>
    </div>
  );
  const tabs = [
    { id: 'executive-cockpit', label: 'Executive Cockpit', icon: '', content: executive },
    { id: 'predictive', label: 'Predictive', icon: '', content: predictive },
    { id: 'planning', label: 'Claims Audit', icon: '', content: planning },
    { id: 'live', label: 'Live Claims', icon: '', content: liveTab },
    { id: 'ask-ai', label: 'Ask AI', icon: '', content: ai },
    { id: 'architecture', label: 'Architecture & Data', icon: '', content: architecture },
  ].map((tab) => ({ ...tab, content: tab.id === 'architecture' ? tab.content : (
    <div className="space-y-4">
      <p className="text-sm text-slate-600">Synthetic demo data for a fictional insurer. On-demand snapshots are not live customer operations.</p>
      {loading ? <p role="status">Loading Snowflake data...</p> : error ? (
        <div role="alert" className="rounded border border-red-200 p-4">
          <p>{error}</p>
          <button className="mt-3 rounded border px-3 py-2" onClick={() => setAttempt((value) => value + 1)}>Retry data connection</button>
        </div>
      ) : !data?.entities.length ? <p role="status">No policy book observations are available in this snapshot.</p> : (
        <>
          <p className="text-sm">Observation watermark: {data.sourceWatermark ?? 'Unavailable'}. Request time: {data.requestedAt}.</p>
          {(data.stale || data.pipelineBehind) && <p role="status" className="text-amber-700">Stale or lagging snapshot. Refresh the on-demand pipeline before presenting current results.</p>}
          {tab.content}
        </>
      )}
    </div>
  ) }));
  return <AppLayout title="APJ Insurance Claims and Fraud" tabs={tabs} />;
}
