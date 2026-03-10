# APJ Insurance Claims AI — 2-Minute Video Demo Script

**Format:** Screen recording with voiceover  
**Duration:** 2:00  
**Two personas:** Claims Adjuster (Streamlit) + Executive (QuickSight Q)

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

### SCENE 1 — The Problem (0:00–0:12)
**Screen:** Streamlit app title page (Tab 1 visible)

> *"Insurance claims across Asia-Pacific — Hong Kong, Singapore, Japan, Australia — thousands of documents hitting S3 every day. JSON submissions, adjuster notes, policy files. The traditional process? Manual review, days of back-and-forth, inconsistent decisions. What if we could go from raw document to AI-powered decision in seconds?"*

**Action:** Slowly scroll through the claim dropdown to show all 200 claims.

---

### SCENE 2 — AI Claim Evaluation (0:12–0:45)
**Screen:** Streamlit Tab 1 — Claim Intake & AI Evaluation

> *"Here's a live claim from Hong Kong — a residential fire. The claim detail table shows the claimant, policy, location, amount, coverage limit. Everything an adjuster needs."*

**Action:** Select a Hong Kong claim (Fire + Home). Pause 2 seconds on the detail table.

> *"And right below — World Bank market context. GDP per capita, insurance penetration, disaster exposure. This data came from the Snowflake Marketplace — zero ETL — and it's exactly what we feed to the AI."*

**Action:** Point to the World Bank Market Context panel. Hover over the 6 metric cards.

> *"Now I send this to Amazon Bedrock — Claude Sonnet 4.5 reads the claim, the policy terms, and this market context, and makes a recommendation."*

**Action:** Click "Evaluate with Amazon Bedrock". Wait ~3 seconds.

> *"Three seconds — [read decision]. The claim status updated automatically from Pending to [Approved/Denied/Referred]. Risk score [X] out of 10. And full reasoning the adjuster can review. Not a black box — every decision is explainable, and every status change is tracked."*

---

### SCENE 3 — Policy Search / RAG (0:45–1:10)
**Screen:** Streamlit Tab 3 — Policy Search

> *"But before the adjuster accepts the AI recommendation, they need to verify coverage. Here's where Snowflake Cortex Search comes in — semantic search across 100 policy documents."*

**Action:** Click sample question: **"Does home insurance cover typhoon damage in Hong Kong?"**

> *"Five matching policies, ranked by relevance. And at the bottom — an AI-generated summary of what's covered and what's excluded, grounded in the actual policy text. This is RAG — retrieval-augmented generation — running entirely inside Snowflake."*

**Action:** Scroll through results, pause on the AI Summary.

---

### SCENE 4 — Executive View: QuickSight Q (1:10–1:40)
**Screen:** Amazon QuickSight — Q search bar

> *"Now let's switch to the executive's view. This is Amazon QuickSight, connected directly to Snowflake. The dashboard shows the claims pipeline across 8 APJ markets."*

**Action:** Show dashboard briefly (3 seconds). Then click on the Q search bar.

> *"But the real power is QuickSight Q. The CFO doesn't write SQL — they just ask."*

**Action:** Type: **"Which country has the highest total claim amount?"** — show the auto-generated answer/chart.

> *"Instant answer, auto-generated visualisation, from live Snowflake data. No report request, no analyst in the loop."*

**Action:** Type one more: **"Show claim count by policy type"** — show the result.

---

### SCENE 5 — The Wrap (1:40–2:00)
**Screen:** Streamlit Tab 4 (APJ Market View) → then architecture diagram or title

> *"The final layer — World Bank data from the Snowflake Marketplace. Insurance penetration, GDP, disaster exposure across all 8 markets. You saw it feeding the AI in real time — and here it is at scale across the entire region."*

**Action:** Quick scroll through Tab 4 charts (5 seconds).

> *"Documents land in S3. Snowflake ingests, enriches, and governs. Bedrock delivers AI intelligence. Cortex Search powers policy RAG. QuickSight Q gives executives self-service analytics. One pipeline, fully governed — from raw claim to AI decision in seconds.*
>
> *Snowflake and AWS, better together."*

---

## Video Description (for email / social)

**Short (1 line):**
> End-to-end insurance claims processing with Snowflake AI + Amazon Bedrock + QuickSight Q — from raw document to AI-powered decision in seconds.

**Medium (for email):**
> This 2-minute demo shows how Snowflake and AWS process insurance claims across 8 Asia-Pacific markets in real time. Claims documents land in Amazon S3 and are auto-ingested via Snowpipe. A Streamlit app running inside Snowflake lets adjusters evaluate all 200 claims with Amazon Bedrock (Claude Sonnet 4.5) — with World Bank market context (GDP, insurance penetration, disaster exposure) visible in the UI and fed directly to the AI for risk calibration. Claim statuses update automatically from Pending to Approved/Denied/Referred. Adjusters can also search 100 policy documents using Cortex Search (RAG) — all without data leaving Snowflake. On the executive side, Amazon QuickSight dashboards and QuickSight Q provide self-service analytics with natural language queries over live Snowflake data. Two personas, one governed pipeline.

**Long (for LinkedIn / blog):**
> Insurance claims processing in Asia-Pacific presents unique challenges — diverse regulatory environments, high natural disaster exposure, and growing claim volumes across 8+ markets. In this demo, we built a complete claims processing pipeline on Snowflake and AWS that serves two personas:
>
> **The Claims Adjuster** uses a Streamlit app running inside Snowflake to:
> - Review all 200 claims with full context (claimant, policy, location, amounts)
> - See **World Bank market context** (GDP, insurance penetration, disaster exposure) directly in the UI — the same data fed to the AI for risk calibration
> - Evaluate claims with **Amazon Bedrock (Claude Sonnet 4.5)** — returning Approve/Deny/Refer decisions with full reasoning in ~3 seconds, with claim status updated automatically
> - Search 100 policy documents using **Snowflake Cortex Search** — semantic RAG that returns relevant coverage terms and an AI-generated summary
> - View APJ market intelligence at scale across all 8 markets
>
> **The Executive** uses Amazon QuickSight to:
> - Monitor claims pipeline across 8 APJ markets via live dashboards
> - Ask questions in plain English using **QuickSight Q** — "Which country has the highest claim amount?" — and get auto-generated answers from live Snowflake data
>
> The architecture: Amazon S3 for ingest, Snowpipe for auto-ingestion, Snowflake Cortex for document extraction and policy search, Amazon Bedrock for AI evaluation, and QuickSight for executive analytics. No data movement, no model hosting, no manual review — just governed AI at enterprise scale.

---

## Recording Tips

1. **Resolution:** 1920x1080, browser at 90% zoom for readability
2. **Browser:** Use Chrome in full-screen, dark mode matches Streamlit's dark theme
3. **Two windows:** Have QuickSight open in a second browser tab — switch cleanly at Scene 4
4. **Pace:** Don't rush the Bedrock evaluation (Scene 2) or the Q answer (Scene 4) — the wait is the wow moment
5. **Cursor:** Use a large, visible cursor. Hover over key numbers as you read them
6. **Claim choice:** Pick a Hong Kong Fire + Home claim with status "Pending" — relatable for the Summit audience and shows clean status transition
7. **World Bank panel:** Pause on the Market Context expander — this is the "Marketplace + AI" talking point
8. **Q questions:** Test your exact questions beforehand — Q can be sensitive to phrasing. Pre-test 3–4 questions and use the ones that produce the cleanest charts
9. **Audio:** Record voiceover separately for clean audio, then sync. Or use a good USB mic
10. **Transitions:** Cut (don't scroll) between Streamlit and QuickSight — keeps the pace tight
