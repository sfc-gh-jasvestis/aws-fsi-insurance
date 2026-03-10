# APJ Insurance Claims & Underwriting — Reference Architecture Demo

End-to-end insurance claims processing pipeline across **8 Asia-Pacific markets** using Snowflake and AWS — from raw document to AI-powered decision in seconds.

Built for **AWS Summit Hong Kong** and ASEAN reuse.

```
Adjuster Notes ──► Amazon S3 ──► Snowpipe ──► Snowflake
                                                  │
                     ┌────────────────────────────┤
                     ▼                            ▼
              Cortex AI_COMPLETE           Cortex Search
              (document extraction)        (policy RAG)
                     │                            │
                     ▼                            ▼
              Amazon Bedrock ◄──── World Bank Marketplace
              (Claude Sonnet 4.5)   (GDP, disaster exposure)
                     │
                     ▼
              Streamlit in Snowflake ──► Amazon QuickSight + Q
              (adjuster UI)              (executive dashboards + NLP)
```

## What It Does

| Capability | Technology |
|---|---|
| **Document Ingestion** | Amazon S3 + Snowpipe |
| **AI Document Extraction** | Snowflake Cortex AI_COMPLETE (Claude 3.5 Sonnet) |
| **Market Enrichment** | Snowflake Marketplace — World Bank data, zero ETL |
| **AI Claim Evaluation** | Amazon Bedrock (Claude Sonnet 4.5) via Snowpark External Access |
| **Policy Search (RAG)** | Snowflake Cortex Search — 100 policy documents |
| **Executive Dashboards** | Amazon QuickSight — 2-sheet dashboard from Snowflake |
| **Executive NLP Analytics** | Amazon QuickSight Q — plain-English questions over live data |
| **Adjuster UI** | Streamlit in Snowflake — 4-tab app |

## Demo Personas

- **Claims Adjuster** — Streamlit in Snowflake: evaluate claims with Bedrock, search policies with Cortex Search, view APJ market intelligence
- **Executive / CFO** — Amazon QuickSight: dashboards + Q natural language analytics

## Repo Structure

```
├── plan/
│   ├── DEMO_PLAN_V5.md           # Full build plan (phases, SQL, validation gates)
│   └── DEMO_SCRIPT_2MIN.md       # 2-minute video demo narration script
├── quicksight/
│   └── deploy.sh                 # QuickSight datasets, analysis, dashboard, Q topic
├── scripts/
│   └── adjuster_notes.sh         # 10 adjuster notes (embedded) → S3 upload
├── streamlit_app_v5.py           # Streamlit UI (4 tabs)
├── snowflake.yml                 # Streamlit deploy config
└── .gitignore
```

The **EVALUATE_CLAIM** stored procedure SQL is embedded directly in `plan/DEMO_PLAN_V5.md` (Phase 4.2).

## Prerequisites

- Snowflake account with `ACCOUNTADMIN` and `CORTEX` warehouse
- `AI_COMPLETE` (Claude 3.5 Sonnet) enabled in Snowflake
- AWS account with:
  - Amazon Bedrock model `us.anthropic.claude-sonnet-4-5-20250929-v1:0` enabled (us-west-2)
  - QuickSight Enterprise edition
  - IAM user with `AdministratorAccess` + `AmazonBedrockFullAccess`
- Snowflake Marketplace: `SNOWFLAKE_PUBLIC_DATA_FREE` (World Bank) installed
- CLI tools: `snow` (Snowflake CLI), `aws` (AWS CLI v2)

## Build (~100 min)

The full build is documented step-by-step in [`plan/DEMO_PLAN_V5.md`](plan/DEMO_PLAN_V5.md), organized in 5 phases with validation gates after each:

| Phase | What | Time |
|---|---|---|
| 1 | AWS: S3 bucket + IAM role + SQS queue | ~12 min |
| 2 | Snowflake: database, schemas, Bedrock wiring, storage integration, Snowpipe | ~18 min |
| 3 | Synthetic data (customers, policies, claims), adjuster notes → S3, AI extraction, Marketplace enrichment | ~35 min |
| 4 | EVALUATE_CLAIM procedure, Cortex Search, Semantic View, Cortex Agent, Streamlit deploy | ~20 min |
| 5 | QuickSight: network policy, data source, `bash quicksight/deploy.sh` | ~15 min |

```bash
# Set your AWS account ID before starting
export AWS_ACCOUNT_ID=018437500440

# Phase 3 — upload adjuster notes to S3
bash scripts/adjuster_notes.sh

# Phase 4 — deploy Streamlit app
snow streamlit deploy --replace -c demo43

# Phase 5 — deploy QuickSight resources
bash quicksight/deploy.sh
```

## Data

8 APJ markets: Hong Kong, Singapore, Japan, Australia, Thailand, Indonesia, Malaysia, Philippines

| Dataset | Count | Source |
|---|---|---|
| Customers | 50 | AI-generated (country-appropriate names) |
| Policies | 100 | AI-generated (Auto, Home, Life, Health, Travel, Commercial) |
| Claims | 200 | AI-generated (typhoons, monsoons, earthquakes, city traffic) |
| Adjuster Notes | 10 | Embedded in `scripts/adjuster_notes.sh` |
| Country Risk | 8 | Snowflake Marketplace (World Bank) |

## Tear Down

Full tear-down commands are in the build plan. Summary:

```bash
# AWS resources
aws s3 rb s3://sf-insurance-demo-apj --force
aws iam delete-role-policy --role-name snowflake-insurance-s3-role --policy-name snowflake-insurance-s3-policy
aws iam delete-role --role-name snowflake-insurance-s3-role
aws sqs delete-queue --queue-url https://sqs.us-west-2.amazonaws.com/$AWS_ACCOUNT_ID/sf-insurance-demo-snowpipe
# QuickSight: topic → dashboard → analysis → datasets → data source (see plan for full commands)
```

```sql
-- Snowflake
DROP DATABASE IF EXISTS INSURANCE_DEMO_DB;
DROP INTEGRATION IF EXISTS INSURANCE_S3_INTEGRATION;
DROP INTEGRATION IF EXISTS INSURANCE_BEDROCK_EAI;
DROP USER IF EXISTS QUICKSIGHT_USER;
```

## License

Internal use — Snowflake field demo.
