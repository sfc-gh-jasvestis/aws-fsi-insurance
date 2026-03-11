# APJ Insurance Claims AI — Video Demo Script

**Format:** Screen recording with voiceover  
**Duration:** ~3:30  
**Audience:** AWS Summit attendees, FSI prospects, partner SAs  
**Three acts:** What We Built (infrastructure) → The Adjuster (Streamlit + Bedrock + Cortex) → The Executive (QuickSight Q)

---

## Why This Architecture

| Component | Why This One | What It Proves |
|---|---|---|
| **Amazon S3** | Every insurer already stores documents in S3. We don't ask them to move data — we meet them where they are | Snowflake integrates natively with existing AWS infrastructure |
| **Amazon Bedrock (Claude Sonnet 4.5)** | Enterprise-grade AI with no model hosting, no GPU management, no fine-tuning. Called directly from a Snowflake stored procedure via SigV4 — the data never leaves the governed pipeline | AI inference at enterprise scale without operational overhead |
| **Amazon QuickSight + Q** | The BI tool already in their AWS console. Dashboards for static KPIs, **Q for natural language** — executives ask questions in plain English, get auto-generated visualisations from live Snowflake data. No SQL, no report requests | Executive self-service analytics powered by Snowflake |
| **Snowflake Cortex Search** | Semantic RAG over 100 policy documents — adjusters search coverage terms, exclusions, and deductibles in plain English. Powered by Arctic embeddings, runs inside Snowflake with zero data egress | Unstructured document intelligence without external vector DBs |
| **Snowflake Cortex AI_COMPLETE** | Built-in AI functions — no external API, no credentials, no latency. One SQL call extracts structured data from adjuster notes and generates AI summaries | AI that lives where the data lives |
| **Streamlit in Snowflake** | A full production app running inside Snowflake — no separate hosting, no auth layer, no data egress. The adjuster's daily tool, built in Python, deployed in seconds | From prototype to production in one platform |
| **Snowflake Marketplace (World Bank)** | Zero-ETL enrichment. Live economic data from 8 APJ markets — GDP, insurance penetration, disaster exposure — joined to claims and **visible in the UI** before Bedrock evaluation. The AI uses this data to calibrate risk scores | Third-party data enrichment without pipelines, directly feeding AI decisions |

---

## The Script

### ACT 1 — WHAT WE BUILT

#### SCENE 1 — The Problem + Architecture (0:00–0:15)
**Screen:** Streamlit app title page (Tab 1 visible, architecture diagram in sidebar)

> *"Insurance claims across Asia-Pacific — Hong Kong, Singapore, Japan, Australia — thousands of documents hitting S3 every day. JSON submissions, adjuster notes, policy files. The traditional process? Manual review, days of back-and-forth, inconsistent decisions. What if we could go from raw document to AI-powered decision in seconds?"*

**Action:** Point to the architecture diagram in the sidebar — trace the flow: S3 → Snowflake → Bedrock → QuickSight.

---

#### SCENE 2 — The S3 Bucket (0:15–0:35)
**Screen:** AWS Console → S3 → `sf-insurance-demo-apj`

> *"Let's start where the data lands. This is the S3 bucket — two folders. Claims contains 200 JSON claim files from 8 APJ countries. Adjuster notes contains 10 free-text documents written by human adjusters — medical reports, damage assessments, investigation summaries."*

**Action:** Open `sf-insurance-demo-apj` bucket. Click into `claims/` — show the list of JSON files. Click one file and show a quick preview of the JSON structure (claim_id, type, amount, country). Back out. Click into `adjuster-notes/` — show the .txt files.

> *"Every file that lands here is automatically ingested into Snowflake via Snowpipe — no batch jobs, no scheduling, no ETL code."*

---

#### SCENE 3 — Snowflake: Schema Tour (0:35–1:10)
**Screen:** Snowsight → INSURANCE_DEMO_DB

> *"Here's Snowflake. Four schemas — the full pipeline. RAW is where Snowpipe delivers the data. Let's look."*

**Action:** Open Snowsight. Navigate to INSURANCE_DEMO_DB → RAW schema. Click on `RAW_CLAIMS_GEN` to show the column list.

> *"200 claims — claim ID, type, amount, country, policy number. This is the raw landing zone. Now — CURATED."*

**Action:** Switch to CURATED schema. Click on `CLAIMS`.

> *"This is the enriched claims table. Same 200 claims, but now denormalized with customer and policy data, and — this is the key part — enriched with World Bank country risk indicators. GDP per capita, insurance penetration, disaster exposure. Joined automatically from the Snowflake Marketplace. Zero ETL."*

**Action:** Point to columns: `COUNTRY_GDP_PER_CAPITA`, `COUNTRY_INSURANCE_PENETRATION`, `COUNTRY_DISASTER_EXPOSURE`. Also point to `AI_DECISION` and `AI_REASONING` columns.

> *"And these two columns — AI Decision and AI Reasoning — that's where Amazon Bedrock writes its verdict. Right now they're empty for most claims. Let's go fill them."*

**Action:** Quick preview of data — show a few rows where AI_DECISION is NULL and a few where it's populated.

> *"One more thing — the AI schema."*

**Action:** Navigate to AI schema. Show the objects: `EVALUATE_CLAIM` (procedure), `POLICY_SEARCH_SERVICE` (Cortex Search service).

> *"A stored procedure that calls Amazon Bedrock via External Access, and a Cortex Search service indexing 100 policy documents. All governed inside Snowflake."*

---

### ACT 2 — THE ADJUSTER

#### SCENE 4 — AI Claim Evaluation (1:10–1:55)
**Screen:** Streamlit Tab 1 — Claim Intake & AI Evaluation

> *"Now let's be the claims adjuster. This is a Streamlit app running inside Snowflake — no separate hosting, no auth layer."*

**Action:** Show the app. Scroll through the claim dropdown — note the descriptive labels showing claim type, country, and status.

> *"Here's a claim we've already evaluated — a residential fire in Hong Kong. You can see the claim timeline at the top: Filed, Ingested, Enriched, Evaluated, Approved. The AI has already made its recommendation — risk score on a colour-coded bar, full reasoning the adjuster can review."*

**Action:** Select a **pre-evaluated** Hong Kong claim (e.g., CLM-001). Point to the timeline, the risk bar, and the previous AI result.

> *"And here — World Bank market context. GDP, insurance penetration, disaster exposure. This is the data we just saw in the Snowflake table — now it's in the UI, and it's what the AI reads to calibrate its decision."*

**Action:** Point to the World Bank Market Context panel.

> *"Now a brand-new claim — this one is pending."*

**Action:** Switch to a **pending** claim (e.g., CLM-010). Point to the timeline: only Filed → Ingested → Enriched.

> *"I can see the exact prompt going to Bedrock."*

**Action:** Expand "View Bedrock Prompt" briefly (2 seconds). Collapse.

> *"Let's send it."*

**Action:** Click "Evaluate with Amazon Bedrock". Watch the timer.

> *"[X] seconds. [Read decision]. Before-and-after — Pending to [new status]. Risk score [X] out of 10. Full reasoning. Every decision is explainable, every status change is tracked."*

**Action:** Point to before/after comparison and risk bar. Note balloons if APPROVE.

---

#### SCENE 5 — Policy Search / RAG (1:55–2:20)
**Screen:** Streamlit Tab 3 — Policy Search

> *"Before the adjuster accepts the AI recommendation, they verify coverage. Snowflake Cortex Search — semantic search across 100 policy documents."*

**Action:** Click sample question: **"Does home insurance cover typhoon damage in Hong Kong?"**

> *"Five matching policies, ranked by relevance. And an AI-generated summary grounded in the actual policy text. RAG — running entirely inside Snowflake."*

**Action:** Scroll through results, pause on the AI Summary.

---

### ACT 3 — THE EXECUTIVE

#### SCENE 6 — QuickSight Dashboard + Q (2:20–2:55)
**Screen:** Amazon QuickSight

> *"Now the executive's view. Amazon QuickSight, connected directly to Snowflake."*

**Action:** Show the Claims Pipeline dashboard sheet (3 seconds). Flip to the APJ Risk & Markets sheet (3 seconds).

> *"Two dashboard sheets — claims pipeline and APJ market risk. But the real power is QuickSight Q. The CFO doesn't write SQL — they just ask."*

**Action:** Click the Q search bar. Type: **"Which country has the highest total claim amount?"** — show the auto-generated answer/chart.

> *"Instant answer, auto-generated visualisation, from live Snowflake data."*

**Action:** Type one more: **"Show claim count by policy type"** — show the result.

---

#### SCENE 7 — The Wrap (2:55–3:30)
**Screen:** Streamlit Tab 2 (Dashboard) → Tab 4 (APJ Market View) → sidebar architecture diagram

> *"Back on the Streamlit dashboard — the evaluation progress bar tracks how many claims Bedrock has processed. Approved, Denied, Referred — all live."*

**Action:** Click Tab 2. Point to the evaluation counter and progress bar. Click "Refresh Data".

> *"And World Bank data from the Snowflake Marketplace — insurance penetration, GDP, disaster exposure across all 8 markets. You saw it in the raw table, you saw it feeding the AI, and here it is at scale."*

**Action:** Quick scroll through Tab 4 charts (5 seconds). Point to the sidebar architecture diagram.

> *"Let's recap what you just saw. Documents land in S3 — Snowpipe ingests them automatically. Snowflake enriches every claim with World Bank data from the Marketplace. A stored procedure calls Amazon Bedrock for AI evaluation — risk scores, decisions, reasoning, all written back to Snowflake. Cortex Search powers semantic RAG over policy documents. QuickSight gives executives dashboards and natural language Q&A. And the adjuster's app? Streamlit, running inside Snowflake, deployed in one command.*

> *No data movement. No model hosting. No manual review. One governed pipeline — from raw claim to AI decision in seconds.*

> *Snowflake and AWS, better together."*

---

## Video Description (for email / social)

**Short (1 line):**
> End-to-end insurance claims processing with Snowflake AI + Amazon Bedrock + QuickSight Q — from raw document to AI-powered decision in seconds.

**Medium (for email):**
> This 3.5-minute demo walks through a complete insurance claims pipeline built on Snowflake and AWS, serving 8 Asia-Pacific markets. Starting with the infrastructure — an S3 bucket with 200 claim files and 10 adjuster notes, Snowpipe auto-ingestion, and a 4-schema Snowflake database enriched with World Bank Marketplace data — the demo then switches to two personas. The Claims Adjuster uses a Streamlit app inside Snowflake to evaluate claims with Amazon Bedrock (Claude Sonnet 4.5), search 100 policy documents with Cortex Search RAG, and track AI decisions with visual timelines and risk scores. The Executive uses Amazon QuickSight dashboards and QuickSight Q for natural language analytics over live Snowflake data. One governed pipeline, zero data movement.

**Long (for LinkedIn / blog):**
> Insurance claims processing in Asia-Pacific presents unique challenges — diverse regulatory environments, high natural disaster exposure, and growing claim volumes across 8+ markets. In this demo, we built a complete claims processing pipeline on Snowflake and AWS and walk through every layer:
>
> **The Infrastructure:**
> - Amazon S3 bucket with 200 claim JSON files and 10 adjuster notes across 8 APJ markets
> - Snowpipe auto-ingestion into Snowflake — no batch jobs, no scheduling
> - 4-schema architecture: RAW → CURATED (enriched with World Bank Marketplace data) → AI (Bedrock procedure + Cortex Search) → APP (Streamlit)
> - External Access integration calling Amazon Bedrock via SigV4 — data never leaves the governed pipeline
>
> **The Claims Adjuster** uses a Streamlit app running inside Snowflake to:
> - Review 200 claims with descriptive labels, visual timelines, and colour-coded risk scores
> - See **World Bank market context** (GDP, insurance penetration, disaster exposure) — the same data fed to the AI
> - Evaluate claims individually or in batch with **Amazon Bedrock (Claude Sonnet 4.5)** — with before/after comparison, elapsed time, and full reasoning
> - Search 100 policy documents using **Snowflake Cortex Search** — semantic RAG with AI-generated summaries
>
> **The Executive** uses Amazon QuickSight to:
> - Monitor claims pipeline across 8 APJ markets via live dashboards (2 sheets, 11 visuals)
> - Ask questions in plain English using **QuickSight Q** — auto-generated answers from live Snowflake data
>
> The architecture: Amazon S3 for ingest, Snowpipe for auto-ingestion, Snowflake Cortex for document extraction and policy search, Amazon Bedrock for AI evaluation, Snowflake Marketplace for zero-ETL enrichment, and QuickSight for executive analytics. No data movement, no model hosting, no manual review — just governed AI at enterprise scale.

---

## Recording Tips

1. **Resolution:** 1920x1080, browser at 90% zoom for readability
2. **Browser:** Use Chrome in full-screen. Have 3 tabs ready: Snowsight, Streamlit app, QuickSight
3. **AWS Console:** Log into S3 console before recording. Have the bucket open and ready
4. **Snowsight:** Have INSURANCE_DEMO_DB expanded in the object browser. Pre-navigate to RAW schema
5. **Pace:** Don't rush the S3 walkthrough (Scene 2) or Bedrock evaluation (Scene 4) — showing real infrastructure builds credibility, showing the AI wait builds anticipation
6. **Cursor:** Use a large, visible cursor. Hover over column names in Snowsight and key numbers in the app
7. **Claim choice:** Pre-evaluate CLM-001/002/003 before recording (see Demo Day Checklist in DEMO_PLAN_V5.md). Show one pre-evaluated claim for instant results, then switch to a pending claim for the live wow moment
8. **S3 preview:** Click into one JSON claim file in S3 to show the raw structure — this grounds the audience in "real data"
9. **Snowsight columns:** When showing the CLAIMS table, point specifically to the World Bank enrichment columns and the AI_DECISION/AI_REASONING columns — these are the story arc
10. **Bedrock prompt:** Briefly expand "View Bedrock Prompt" to show transparency — don't linger, just flash it
11. **Batch evaluation:** If you have extra time, show the "Evaluate All Pending Claims" button — the progress bar across 5 claims is a strong visual
12. **Q questions:** Test your exact questions beforehand — Q can be sensitive to phrasing. Pre-test 3–4 questions and use the ones that produce the cleanest charts
13. **Audio:** Record voiceover separately for clean audio, then sync. Or use a good USB mic
14. **Transitions:** Cut (don't scroll) between AWS Console, Snowsight, Streamlit, and QuickSight — keeps the pace tight
15. **Pre-warm:** Run the warm-up queries from the Demo Day Checklist 10 minutes before recording to avoid cold-start delays
