# APJ Insurance Claims & Underwriting — Reference Architecture Demo

**Snowflake:** demo43 (YFB94191) | **Target:** AWS Summit Hong Kong + ASEAN reuse  
**AWS Region:** us-west-2 | **AWS Account:** `$AWS_ACCOUNT_ID` (set `export AWS_ACCOUNT_ID=018437500440` before build)  
**AI Models:** Amazon Bedrock (Claude Sonnet 4.5) + Snowflake Cortex (Claude 3.5 Sonnet)  
**Last updated:** March 10, 2026 (v5.5 — adjuster notes + EVALUATE_CLAIM procedure embedded in build scripts/plan; `tmp_notes/` and `create_evaluate_proc.sql` removed from repo)

---

## What This Demo Builds

An end-to-end insurance claims processing pipeline across **8 Asia-Pacific markets** (Hong Kong, Singapore, Japan, Australia, Thailand, Indonesia, Malaysia, Philippines) that demonstrates how Snowflake and AWS work together to ingest, enrich, evaluate, and visualise insurance claims — from raw document to AI-powered decision in real time.

### Key Capabilities

| Capability | Technology | What It Does |
|---|---|---|
| **Document Ingestion** | Amazon S3 + Snowpipe | Claim PDFs and adjuster notes land in S3, auto-ingested into Snowflake via Snowpipe |
| **AI Document Extraction** | Snowflake Cortex (Claude 3.5 Sonnet) | Extracts structured data (claim ID, amounts, adjuster, recommendation) from unstructured adjuster notes |
| **Market Enrichment** | Snowflake Marketplace (World Bank) | Enriches every claim with country-level GDP, insurance penetration, and natural disaster exposure — zero ETL |
| **AI Claim Evaluation** | Amazon Bedrock (Claude Sonnet 4.5) | Reviews claim details, policy terms, and World Bank country risk (shown in UI) to recommend Approve/Deny/Refer with reasoning — updates claim status in real time |
| **Policy Search (RAG)** | Snowflake Cortex Search | Semantic search across 100 policy documents — adjusters verify coverage terms, exclusions, deductibles in plain English |
| **Executive NLP Analytics** | Amazon QuickSight Q | Executives ask plain-English questions about claims portfolio — auto-generated answers + visualisations from live Snowflake data |
| **Executive Dashboard** | Amazon QuickSight | 2-sheet dashboard: claims pipeline + APJ market risk — powered directly from Snowflake |
| **Interactive Booth UI** | Streamlit in Snowflake | 4-tab app for adjusters: claim intake, dashboard, policy search (RAG), APJ market view |

---

## Architecture

```
┌────────────────────────────────────────────────────────────┐
│                         AWS                                 │
│                                                             │
│  Adjuster Notes ──► Amazon S3 ──► SQS notification          │
│  Claim PDFs            │                                    │
│                        │                                    │
│  Amazon Bedrock ◄──── Snowpark External Access (SigV4)      │
│  (Claude Sonnet 4.5)   │                                    │
│                        │                                    │
│  Amazon QuickSight ◄── reads Snowflake CURATED schema       │
│  (Dashboards + Q NLP)                                       │
└──────────────────────┬──────────────────────────────────────┘
                       │ Snowpipe auto-ingest
┌──────────────────────▼──────────────────────────────────────┐
│                   SNOWFLAKE (demo43)                         │
│                                                              │
│  RAW schema                                                  │
│  ├── RAW_CUSTOMERS (50 — 8 APJ countries)                   │
│  ├── RAW_POLICIES_GEN (100 policies)                        │
│  ├── RAW_CLAIMS_GEN (200 APJ claims)                        │
│  └── RAW_CLAIMS (Snowpipe target from S3)                   │
│                                                              │
│  CURATED schema                                              │
│  ├── CLAIMS (denormalized + country risk enrichment)         │
│  ├── APAC_COUNTRY_RISK (materialized World Bank data)        │
│  └── APAC_INSURANCE_INDICATORS (materialized World Bank)     │
│                                                              │
│  AI schema                                                   │
│  ├── EXTRACTED_ADJUSTER_NOTES (AI_COMPLETE extraction)       │
│  ├── EVALUATE_CLAIM (Snowpark → Amazon Bedrock)              │
│  ├── POLICY_SEARCH_SERVICE (Cortex Search — 100 policies) ★  │
│  ├── INSURANCE_SEMANTIC_VIEW (Cortex Analyst — for Q topic)  │
│  └── INSURANCE_AGENT (Cortex Agent — available via SQL)      │
│                                                              │
│  APP schema                                                  │
│  └── INSURANCE_CLAIMS_APP (Streamlit — 4-tab adjuster UI)    │
│                                                              │
│  Marketplace                                                 │
│  └── SNOWFLAKE_PUBLIC_DATA_FREE (World Bank — APAC data)     │
└──────────────────────────────────────────────────────────────┘
```

---

## Data Strategy

**8 APJ Markets:** Hong Kong, Singapore, Japan, Australia, Thailand, Indonesia, Malaysia, Philippines

| Dataset | Count | Source | Details |
|---|---|---|---|
| Customers | 50 | AI-generated (Claude 3.5 Sonnet) | Country-appropriate names and addresses across 8 APJ markets. **Names must match country** (see Build Notes) |
| Policies | 100 | AI-generated | Auto, Home, Life, Health, Travel, Commercial — APJ terms |
| Claims | 200 | AI-generated | APJ-relevant incidents: typhoons, monsoons, earthquakes, traffic in Asian cities. **Claim types must align with policy types** (see Build Notes) |
| Adjuster Notes | 10 | Embedded in `scripts/adjuster_notes.sh` → uploaded to S3 at build time | Field reports with inspection details, damage assessment, recommendations |
| Country Risk | 8 | Snowflake Marketplace (World Bank) | GDP per capita, insurance penetration, natural disaster exposure, population |

**All AI generation and extraction uses Anthropic Claude** — Bedrock for claim evaluation, Cortex for everything else.

---

## The Demo Narrative (2 Minutes — Video / Booth)

**Two personas, one governed pipeline:**
- **Claims Adjuster** → Streamlit in Snowflake (claim evaluation + policy search)
- **Executive / CFO** → Amazon QuickSight + Q (dashboards + natural language analytics)

> *"Every day, insurers across Asia-Pacific receive thousands of claims — PDFs, adjuster notes, policy files — sitting in a queue for manual review. We're going to show you how Snowflake and AWS process a claim from a Hong Kong policyholder — from raw document to AI-powered decision in seconds."*

**Four AWS moments the audience sees:**

1. **Amazon S3** — "This is where the document landed. Your existing cloud storage, unchanged."
2. **Amazon Bedrock (Claude Sonnet 4.5)** — "Bedrock reads the claim, checks coverage, factors in disaster risk, and returns a recommendation with full reasoning — called directly from Snowflake."
3. **Snowflake Cortex Search** — "The adjuster verifies coverage by searching 100 policy documents — RAG running inside Snowflake, no external vector DB."
4. **Amazon QuickSight Q** — "The executive asks plain-English questions — 'Which country has the highest claim amount?' — and gets instant answers from live Snowflake data."

**Demo Flow (2 minutes):**

| Time | Screen | What Happens |
|---|---|---|
| 0:00–0:12 | Streamlit title | Set up the problem — thousands of claims, manual review |
| 0:12–0:45 | Streamlit Tab 1 | Select Hong Kong claim → Bedrock evaluation → decision + reasoning in ~3s |
| 0:45–1:10 | Streamlit Tab 3 | Policy Search — "Does home insurance cover typhoon damage?" → RAG results + AI summary |
| 1:10–1:40 | QuickSight Q | Switch to executive view — dashboard briefly → Q: "Which country has the highest total claim amount?" |
| 1:40–2:00 | Streamlit Tab 4 + wrap | APJ Market View → architecture summary → "Snowflake and AWS, better together" |

---

## Build Phases

### Phase 1 — AWS Setup (~12 min)

| Step | What | Commands |
|---|---|---|
| 1.1 | S3 bucket with `claims/`, `policies/`, `adjuster-notes/` folders, versioning, public access blocked | `aws s3api create-bucket`, `put-object`, `put-bucket-versioning`, `put-public-access-block` |
| 1.2 | IAM role `snowflake-insurance-s3-role` with S3 read policy (placeholder trust — updated after Snowflake integration) | `aws iam create-role`, `put-role-policy` |
| 1.3 | SQS queue `sf-insurance-demo-snowpipe` for Snowpipe notifications | `aws sqs create-queue` |

### Phase 2 — Snowflake Infrastructure (~18 min)

| Step | What |
|---|---|
| 2.1 | Database `INSURANCE_DEMO_DB` with schemas: RAW, CURATED, AI, APP |
| 2.2 | Bedrock wiring: Network Rule → Secret (AWS credentials) → External Access Integration (`INSURANCE_BEDROCK_EAI`) |
| 2.3 | Storage Integration → `DESC INTEGRATION` to get Snowflake ARN → update IAM trust policy → create external stages |
| 2.4 | Snowpipe (`CLAIMS_PIPE` with `AUTO_INGEST = TRUE`) → configure S3 event notification to Snowflake's SQS channel |

### Phase 3 — APJ Data + AI Pipeline (~35 min)

| Step | What |
|---|---|
| 3.1 | Generate 50 APJ customers via `AI_COMPLETE` (Claude 3.5 Sonnet) — 5 batches of 10 |
| 3.2 | Generate 100 policies — 10 batches of 10 |
| 3.3 | Generate 200 APJ claims — 20 batches of 10, with country-specific incident descriptions. **Claim types MUST align with policy types** (see mapping in Build Notes). Prompt must enforce valid combinations |
| 3.4 | Upload 10 adjuster notes to S3: **`bash scripts/adjuster_notes.sh`** (notes are embedded in the script — no external files needed) |
| 3.5 | Extract structured data from adjuster notes using `AI_COMPLETE` (Claude 3.5 Sonnet) — reads file content from stage, returns JSON |
| 3.6 | Create Marketplace enrichment views (World Bank → APAC indicators + country risk) and **materialize into local tables** |
| 3.7 | Build denormalized `CURATED.CLAIMS` table — joins claims + customers + policies + country risk |
| 3.8 | **Data quality validation** — verify all claim types align with policy types (see mapping), descriptions match claim+policy context (no "vehicle/car park" in Home Theft, no "hotel/residence" in Auto Theft, no "commercial/signage" in Auto Liability, no "vehicle collision" in Health Medical), customer names match country. **Set all STATUS to pre-decision values** (Pending/Submitted/Under Review) — never "Approved" or "Denied" at generation time. Fix any violations before proceeding |

### Phase 4 — AI & Analytics Layer (~20 min)

| Step | What |
|---|---|
| 4.1 | Cortex Search Service — 100 policy documents indexed for RAG |
| 4.2 | `EVALUATE_CLAIM` stored procedure — Snowpark Python calls Amazon Bedrock via SigV4, writes `AI_DECISION`, `AI_REASONING`, and updates `STATUS` (APPROVE→Approved, DENY→Denied, REFER→Under Review). **Full SQL below — run via `snow sql -c demo43`** |
| 4.3 | Semantic View for Cortex Analyst — dimensions (country, city, claim type, AI decision) + metrics (amounts, counts). Available via SQL and backs the QuickSight Q topic |
| 4.4 | Cortex Agent — orchestrates Analyst + Search with APJ-focused instructions. Available via direct SQL (not surfaced in Streamlit — NLP analytics handled by QuickSight Q) |
| 4.5 | Streamlit app — 4-tab adjuster UI (imports: `streamlit`, `pandas`, `json`, `re`). **Tab 1:** all 200 claims in dropdown (no LIMIT), claim detail table (10 fields, `set_index("Field")`), incident caption, **World Bank Market Context expander** (GDP per Capita, Insurance Penetration, Disaster Exposure, Population, Displaced — sourced from Marketplace join), robust Bedrock JSON parsing (code-fence stripping + regex fallback), **status transition banner** ("Pending → Approved") after evaluation, no "Previous Evaluation" section. **Tab 2:** 5 KPI metrics, 4 charts (type/status/country/risk), Top Claims table (no AI_DECISION column), all numbers formatted (1 decimal %, $ with commas). **Tab 3:** Policy Search — 6 tested sample questions, `SEARCH_PREVIEW` returns 5 results with relevance badges, AI summary uses ALL hits. **Tab 4:** 3 bar charts + 2 tables, each with business context caption. All tables use `.set_index()` to hide numeric index. Format all DECIMAL values in pandas before display. Deploy with single command: `snow streamlit deploy --replace -c demo43` (reads `snowflake.yml` config) |

**Step 4.2 — EVALUATE_CLAIM stored procedure (run via `snow sql -c demo43`):**
```sql
CREATE OR REPLACE PROCEDURE INSURANCE_DEMO_DB.AI.EVALUATE_CLAIM(claim_id TEXT)
RETURNS TEXT
LANGUAGE PYTHON
RUNTIME_VERSION = '3.11'
PACKAGES = ('snowflake-snowpark-python', 'boto3')
HANDLER = 'evaluate'
EXTERNAL_ACCESS_INTEGRATIONS = (INSURANCE_BEDROCK_EAI)
SECRETS = ('aws_creds' = INSURANCE_DEMO_DB.AI.AWS_BEDROCK_SECRET)
AS
$$
import json, re, boto3
import _snowflake

def evaluate(session, claim_id):
    row = session.sql(f"""
        SELECT CLAIM_ID, CLAIM_TYPE, POLICY_TYPE, CLAIM_AMOUNT, COVERAGE_LIMIT, DEDUCTIBLE,
               DESCRIPTION, CITY, COUNTRY, FIRST_NAME, LAST_NAME, STATUS,
               COUNTRY_GDP_PER_CAPITA, COUNTRY_INSURANCE_PENETRATION, COUNTRY_DISASTER_EXPOSURE
        FROM INSURANCE_DEMO_DB.CURATED.CLAIMS WHERE CLAIM_ID = '{claim_id}'
    """).collect()[0]

    gdp = float(row.COUNTRY_GDP_PER_CAPITA) if row.COUNTRY_GDP_PER_CAPITA else 0
    ins_pen = float(row.COUNTRY_INSURANCE_PENETRATION) * 100 if row.COUNTRY_INSURANCE_PENETRATION else 0
    dis_exp = float(row.COUNTRY_DISASTER_EXPOSURE) * 100 if row.COUNTRY_DISASTER_EXPOSURE else 0

    prompt = (
        "You are an insurance claims adjuster AI for Asia-Pacific markets. "
        "Evaluate this claim and return ONLY a JSON object.\n\n"
        "CLAIM DETAILS:\n"
        "- Claim ID: " + str(row.CLAIM_ID) + "\n"
        "- Type: " + str(row.CLAIM_TYPE) + " (Policy: " + str(row.POLICY_TYPE) + ")\n"
        "- Amount: $" + f"{row.CLAIM_AMOUNT:,.0f}" + " (Coverage: $" + f"{row.COVERAGE_LIMIT:,.0f}" + ", Deductible: $" + f"{row.DEDUCTIBLE:,.0f}" + ")\n"
        "- Location: " + str(row.CITY) + ", " + str(row.COUNTRY) + "\n"
        "- Claimant: " + str(row.FIRST_NAME) + " " + str(row.LAST_NAME) + "\n"
        "- Description: " + str(row.DESCRIPTION) + "\n\n"
        "COUNTRY RISK DATA (World Bank / Snowflake Marketplace):\n"
        "- GDP per Capita: $" + f"{gdp:,.0f}" + "\n"
        "- Insurance Penetration: " + f"{ins_pen:.2f}" + "%\n"
        "- Natural Disaster Exposure: " + f"{dis_exp:.2f}" + "%\n\n"
        "RULES:\n"
        "1. If claim amount exceeds coverage limit, DENY\n"
        "2. If claim type does not match policy type coverage, DENY\n"
        "3. If claim is reasonable and within limits, APPROVE\n"
        "4. If uncertain or needs investigation, REFER\n"
        "5. Factor in country risk data for risk scoring\n\n"
        "Return ONLY this JSON (no markdown, no code fences):\n"
        '{"decision": "APPROVE|DENY|REFER", "risk_score": 1-10, "recommended_payout": number, "reasoning": "2-3 sentences"}'
    )

    ak = _snowflake.get_username_password('aws_creds').username
    sk = _snowflake.get_username_password('aws_creds').password
    client = boto3.client('bedrock-runtime', region_name='us-west-2',
                          aws_access_key_id=ak, aws_secret_access_key=sk)

    body = json.dumps({
        'anthropic_version': 'bedrock-2023-05-31',
        'max_tokens': 1024,
        'messages': [{'role': 'user', 'content': prompt}]
    })

    resp = client.invoke_model(
        modelId='us.anthropic.claude-sonnet-4-5-20250929-v1:0',
        contentType='application/json',
        body=body
    )
    result_text = json.loads(resp['body'].read())['content'][0]['text']

    clean = result_text.strip()
    if clean.startswith('```'):
        clean = re.sub(r'^```(?:json)?\s*', '', clean)
        clean = re.sub(r'\s*```$', '', clean)
    try:
        result_json = json.loads(clean)
    except Exception:
        m = re.search(r'\{.*\}', clean, re.DOTALL)
        result_json = json.loads(m.group()) if m else {'decision': 'REFER', 'reasoning': clean, 'risk_score': 5, 'recommended_payout': 0}

    decision = result_json.get('decision', 'REFER')
    reasoning = result_json.get('reasoning', '').replace("'", "''")
    status_map = {'APPROVE': 'Approved', 'DENY': 'Denied', 'REFER': 'Under Review'}
    new_status = status_map.get(decision, 'Under Review')

    session.sql(f"""
        UPDATE INSURANCE_DEMO_DB.CURATED.CLAIMS
        SET AI_DECISION = '{decision}',
            AI_REASONING = '{reasoning}',
            STATUS = '{new_status}'
        WHERE CLAIM_ID = '{claim_id}'
    """).collect()

    return json.dumps(result_json)
$$;
```

### Phase 5 — QuickSight + Q (~15 min)

**All QuickSight resources are deployed via a single script:** `bash quicksight/deploy.sh`

The script requires `AWS_ACCOUNT_ID` to be set and the data source to already exist. Steps 5.1-5.2 set up the Snowflake side; Steps 5.3-5.7 are automated by the script.

| Step | What | How |
|---|---|---|
| 5.1 | Add QuickSight egress IPs to Snowflake network policy | Snowflake SQL (see Build Notes) |
| 5.2 | Create `QUICKSIGHT_USER` (LEGACY_SERVICE, MFA disabled) + data source | Snowflake SQL + `aws quicksight create-data-source` |
| 5.3 | Create 3 datasets: Claims, APAC Country Risk, AI Extracted Notes | `quicksight/deploy.sh` — Step 2 |
| 5.4 | Create analysis with 2-sheet visual definition (7 visuals on Sheet 1, 4 on Sheet 2) | `quicksight/deploy.sh` — Step 3 |
| 5.5 | Publish dashboard from analysis | `quicksight/deploy.sh` — Step 4 |
| 5.6 | Create Q topic with 19 columns, synonyms, and friendly names | `quicksight/deploy.sh` — Step 5 |
| 5.7 | **Validate:** datasets exist, analysis status = CREATION_SUCCESSFUL, dashboard renders, Q topic answers questions | `quicksight/deploy.sh` — Step 6 + manual Q test |

**Dashboard visual layout (defined in `quicksight/deploy.sh`):**

Sheet 1 — "Claims Pipeline":
- Row 1: 3 KPI cards (Total Claims, Total Claimed, Avg Claim)
- Row 2: Bar chart — Claims by Type | Bar chart — Claims by Status
- Row 3: Bar chart — Claims by Country (amount) | Table — Top Claims by Amount

Sheet 2 — "APJ Risk & Markets":
- Row 1: Bar chart — GDP per Capita | Bar chart — Insurance Penetration
- Row 2: Bar chart — Disaster Exposure | Table — Country Risk Detail

**Q topic test questions (run after Step 5.7):**
1. "Which country has the highest total claim amount?"
2. "Show claim count by policy type"
3. "How many claims are pending?"

---

## Resource Inventory

### AWS Resources

| Resource | Name/ID | Type |
|---|---|---|
| S3 Bucket | `sf-insurance-demo-apj` | S3 (us-west-2), versioned |
| IAM Role | `snowflake-insurance-s3-role` | IAM Role + S3 read policy |
| SQS Queue | `sf-insurance-demo-snowpipe` | SQS Standard |
| QuickSight Data Source | `insurance-snowflake-ds-v3` | Snowflake connector |
| QuickSight Datasets | `insurance-claims-ds`, `insurance-apac-country-risk`, `insurance-extracted-notes` | Direct Query |
| QuickSight Dashboard | `insurance-apj-dashboard` | 2-sheet dashboard |
| QuickSight Analysis | `insurance-apj-analysis` | Editable analysis |
| QuickSight Q Topic | `insurance-apj-q-topic` | NLP topic — "APJ Insurance Claims" with 19 columns, synonyms, friendly names |
| **Deploy Script** | `quicksight/deploy.sh` | Creates datasets, analysis (11 visuals), dashboard, Q topic — single command |
| **Build Script** | `scripts/adjuster_notes.sh` | Generates 10 adjuster notes and uploads to S3 — no external files needed |

### Snowflake Resources (`INSURANCE_DEMO_DB`)

| Resource | Schema | Type | Detail |
|---|---|---|---|
| `RAW_CUSTOMERS` | RAW | Table | 50 rows — 8 APJ countries |
| `RAW_POLICIES_GEN` | RAW | Table | 100 policies |
| `RAW_CLAIMS_GEN` | RAW | Table | 200 APJ claims |
| `RAW_CLAIMS` | RAW | Table | Snowpipe target |
| `S3_CLAIMS_STAGE` | RAW | External Stage | claims/ folder |
| `S3_POLICIES_STAGE` | RAW | External Stage | policies/ folder |
| `S3_ADJUSTER_NOTES_STAGE` | RAW | External Stage | adjuster-notes/ folder |
| `CLAIMS_PIPE` | RAW | Snowpipe | Auto-ingest from S3 |
| `CLAIMS` | CURATED | Table | 200 rows — denormalized + country risk enrichment |
| `APAC_COUNTRY_RISK` | CURATED | Table | 8 countries — GDP, insurance penetration, disaster exposure |
| `APAC_INSURANCE_INDICATORS` | CURATED | Table | 8 countries — market indicators |
| `EXTRACTED_ADJUSTER_NOTES` | AI | Table | 10 notes — AI-extracted structured data |
| `POLICY_DOCUMENTS` | AI | Table | 100 policies — search-ready text |
| `POLICY_SEARCH_SERVICE` | AI | Cortex Search | Semantic search over policy documents |
| `INSURANCE_SEMANTIC_VIEW` | AI | Semantic View | Cortex Analyst — claims analytics |
| `INSURANCE_AGENT` | AI | Cortex Agent | Orchestrates Analyst + Search (available via SQL, not in Streamlit UI) |
| `EVALUATE_CLAIM` | AI | Stored Procedure | Snowpark → Amazon Bedrock (Claude Sonnet 4.5). Updates `AI_DECISION`, `AI_REASONING`, and `STATUS` |
| `BEDROCK_RULE` | AI | Network Rule | Egress to `bedrock-runtime.us-west-2.amazonaws.com` |
| `AWS_BEDROCK_SECRET` | AI | Secret | AWS access key + secret key |
| `INSURANCE_BEDROCK_EAI` | — | External Access Integration | Bedrock connectivity |
| `INSURANCE_S3_INTEGRATION` | — | Storage Integration | S3 connectivity |
| `INSURANCE_CLAIMS_APP` | APP | Streamlit in Snowflake | 4-tab adjuster UI: Claim Intake, Dashboard, Policy Search (RAG), APJ Market View |

---

## Build Notes

These are critical implementation details discovered during development. **Following these prevents every error encountered during the build.**

### Synthetic Data Quality (CRITICAL)

**Claim types MUST align with policy types.** AI generation often creates random pairings (e.g., "Auto Collision" on a Health policy). If not enforced in the prompt, you MUST validate and fix after generation.

| Policy Type | Valid Claim Types |
|---|---|
| Auto | Auto Collision, Theft, Liability |
| Home | Fire, Property Damage, Theft, Natural Disaster |
| Health | Medical |
| Life | Medical |
| Commercial | Fire, Property Damage, Liability, Theft, Natural Disaster |
| Travel | Travel Disruption, Medical |

**Validation SQL (run after Step 3.7, before proceeding):**
```sql
-- Should return 0 rows. Any rows = mismatched data that will confuse Bedrock.
SELECT CLAIM_ID, CLAIM_TYPE, POLICY_TYPE FROM INSURANCE_DEMO_DB.CURATED.CLAIMS
WHERE NOT (
    (POLICY_TYPE = 'Auto' AND CLAIM_TYPE IN ('Auto Collision', 'Theft', 'Liability'))
    OR (POLICY_TYPE = 'Home' AND CLAIM_TYPE IN ('Fire', 'Property Damage', 'Theft', 'Natural Disaster'))
    OR (POLICY_TYPE = 'Health' AND CLAIM_TYPE = 'Medical')
    OR (POLICY_TYPE = 'Life' AND CLAIM_TYPE = 'Medical')
    OR (POLICY_TYPE = 'Commercial' AND CLAIM_TYPE IN ('Fire', 'Property Damage', 'Liability', 'Theft', 'Natural Disaster'))
    OR (POLICY_TYPE = 'Travel' AND CLAIM_TYPE IN ('Travel Disruption', 'Medical'))
);
```

**Fix SQL (if validation returns rows):**
```sql
UPDATE INSURANCE_DEMO_DB.CURATED.CLAIMS
SET CLAIM_TYPE = CASE
    WHEN POLICY_TYPE = 'Auto' AND CLAIM_TYPE NOT IN ('Auto Collision', 'Theft', 'Liability')
        THEN CASE MOD(ABS(HASH(CLAIM_ID)), 3) WHEN 0 THEN 'Auto Collision' WHEN 1 THEN 'Theft' ELSE 'Liability' END
    WHEN POLICY_TYPE = 'Home' AND CLAIM_TYPE NOT IN ('Fire', 'Property Damage', 'Theft', 'Natural Disaster')
        THEN CASE MOD(ABS(HASH(CLAIM_ID)), 4) WHEN 0 THEN 'Fire' WHEN 1 THEN 'Property Damage' WHEN 2 THEN 'Theft' ELSE 'Natural Disaster' END
    WHEN POLICY_TYPE = 'Health' AND CLAIM_TYPE != 'Medical' THEN 'Medical'
    WHEN POLICY_TYPE = 'Life' AND CLAIM_TYPE != 'Medical' THEN 'Medical'
    WHEN POLICY_TYPE = 'Commercial' AND CLAIM_TYPE NOT IN ('Fire', 'Property Damage', 'Liability', 'Theft', 'Natural Disaster')
        THEN CASE MOD(ABS(HASH(CLAIM_ID)), 5) WHEN 0 THEN 'Fire' WHEN 1 THEN 'Property Damage' WHEN 2 THEN 'Liability' WHEN 3 THEN 'Theft' ELSE 'Natural Disaster' END
    WHEN POLICY_TYPE = 'Travel' AND CLAIM_TYPE NOT IN ('Travel Disruption', 'Medical')
        THEN CASE MOD(ABS(HASH(CLAIM_ID)), 2) WHEN 0 THEN 'Travel Disruption' ELSE 'Medical' END
    ELSE CLAIM_TYPE
END
WHERE NOT (
    (POLICY_TYPE = 'Auto' AND CLAIM_TYPE IN ('Auto Collision', 'Theft', 'Liability'))
    OR (POLICY_TYPE = 'Home' AND CLAIM_TYPE IN ('Fire', 'Property Damage', 'Theft', 'Natural Disaster'))
    OR (POLICY_TYPE = 'Health' AND CLAIM_TYPE = 'Medical')
    OR (POLICY_TYPE = 'Life' AND CLAIM_TYPE = 'Medical')
    OR (POLICY_TYPE = 'Commercial' AND CLAIM_TYPE IN ('Fire', 'Property Damage', 'Liability', 'Theft', 'Natural Disaster'))
    OR (POLICY_TYPE = 'Travel' AND CLAIM_TYPE IN ('Travel Disruption', 'Medical'))
);
```

**Description context validation** — after fixing claim types, descriptions must match the policy context:
- **Theft + Home** must NOT mention "vehicle", "car park", "shopping mall" (those are Auto Theft descriptions)
- **Theft + Auto** must NOT mention "hotel", "burglary", "break-in", "residence", "retail" (those are Home/Commercial Theft descriptions)
- **Liability + Auto** must NOT mention "commercial", "signage", "premise" (those are Commercial Liability descriptions)
- **Medical + Health** must NOT mention "vehicle", "collision" (those are Auto claims)
- **Home** claims must NOT mention "commercial", "warehouse", "retail"
- **Commercial** claims must NOT mention "residential", "residence", "apartment", "bedroom"

Use template-based descriptions per claim type + policy type combo (NOT `AI_COMPLETE` per-row — that takes 25+ minutes for 200 rows). Use `CASE` with `MOD(ABS(HASH(CLAIM_ID)))` for deterministic variety.

**Validation SQL (run after descriptions are set):**
```sql
SELECT COUNT(*) FROM INSURANCE_DEMO_DB.CURATED.CLAIMS WHERE
  (CLAIM_TYPE='Theft' AND POLICY_TYPE='Home' AND (DESCRIPTION ILIKE '%vehicle%' OR DESCRIPTION ILIKE '%car park%'))
  OR (CLAIM_TYPE='Theft' AND POLICY_TYPE='Auto' AND (DESCRIPTION ILIKE '%hotel%' OR DESCRIPTION ILIKE '%burglary%' OR DESCRIPTION ILIKE '%residence%' OR DESCRIPTION ILIKE '%retail%'))
  OR (CLAIM_TYPE='Liability' AND POLICY_TYPE='Auto' AND (DESCRIPTION ILIKE '%commercial%' OR DESCRIPTION ILIKE '%signage%'))
  OR (CLAIM_TYPE='Medical' AND POLICY_TYPE='Health' AND DESCRIPTION ILIKE '%vehicle%');
-- Must return 0
```

**Customer names MUST match country.** AI generation often assigns random customers to claims regardless of country. After building CURATED.CLAIMS, reassign names using `CASE COUNTRY ... MOD(ABS(HASH(CLAIM_ID)))` to pick from country-appropriate name pools:
- Hong Kong: Chan, Wong, Lam, Lee, Cheung, Ng, Ho, Leung, Tam, Kwok
- Singapore: Tan, Lim, Lee, Ong, Ng, Koh, Goh, Teo, Wong, Chua
- Japan: Tanaka, Suzuki, Sato, Watanabe, Yamamoto, Nakamura, Kobayashi, Ito, Takahashi, Yamada
- Australia: Smith, Jones, Williams, Brown, Wilson, Taylor, Johnson, White, Martin, Anderson
- Thailand: Srisuk, Chaiyasit, Wongsa, Rattana, Suwannarat, Petchara, Siriwan, Thongchai, Boonmee, Nantiya
- Indonesia: Wijaya, Sutanto, Hartono, Santoso, Gunawan, Hidayat, Setiawan, Wibowo, Saputra, Kurniawan
- Malaysia: Abdullah, Ibrahim, Ismail, Ahmad, Hassan, Rahman, Ali, Karim, Zainuddin, Rosli
- Philippines: Santos, Reyes, Cruz, Garcia, Ramos, Dela Cruz, Flores, Torres, Villanueva, Aquino

**Claim STATUS strategy (CRITICAL):**
- At generation time, only assign pre-decision statuses: **Pending**, **Submitted**, **Under Review**
- NEVER assign "Approved" or "Denied" at generation — these must come only from Bedrock AI evaluation
- The stored procedure (`EVALUATE_CLAIM`) updates STATUS automatically: APPROVE→Approved, DENY→Denied, REFER→Under Review
- This prevents contradictions (e.g., STATUS="Denied" but Bedrock says APPROVE)
- The Streamlit app shows a status transition banner after evaluation: `"Claim status updated: Pending → Approved"`
- The Claims Dashboard "Claims by Status" chart updates in real time as claims are evaluated

**After any data fix, clear stale AI evaluations and reset statuses:**
```sql
UPDATE INSURANCE_DEMO_DB.CURATED.CLAIMS SET AI_DECISION = NULL, AI_REASONING = NULL WHERE AI_DECISION IS NOT NULL;
UPDATE INSURANCE_DEMO_DB.CURATED.CLAIMS SET STATUS = CASE MOD(ABS(HASH(CLAIM_ID||'status')),3) WHEN 0 THEN 'Pending' WHEN 1 THEN 'Submitted' ELSE 'Under Review' END WHERE STATUS IN ('Approved','Denied');
```

### Snowflake Cortex
- **`AI_EXTRACT` does not work on plain text files** — returns "None" for all fields. Use `AI_COMPLETE` instead: read file content from stage with a CSV file format (`FIELD_DELIMITER = NONE, RECORD_DELIMITER = NONE`), pass to `AI_COMPLETE` with JSON extraction instructions
- **`AI_COMPLETE` token truncation** — generating >20 JSON records in one call risks truncation. Use batches of 10 records
- **`AI_COMPLETE` response formatting** — responses come wrapped in quotes with literal `\n`. Post-process: strip quotes, unescape `\n`/`\t`, add prompt instruction to avoid LaTeX

### Streamlit in Snowflake
- **Automated deployment:** A `snowflake.yml` config is included in the project root. Deploy with a single command:
  ```
  snow streamlit deploy --replace -c demo43
  ```
  This uploads the app file to the stage and creates/replaces the Streamlit object automatically. No manual copy-paste needed. To update after code changes, just re-run the same command.
- Snowflake bundles Streamlit ~1.22 — **no `st.column_config`**, **no `hide_index=True`**, **no `st.dataframe(column_config=...)`**
- Use `st.table(df.set_index("Field"))` or `st.table(df.set_index("Country"))` for clean tables without numeric index — apply to ALL tables
- Import `re` for regex-based response cleaning
- **Format all DECIMAL values in pandas before display** — Snowflake DECIMAL types render with 4 trailing zeros (e.g., `16.0000`). Apply `lambda x: f"{float(x):.1f}%"` for percentages, `f"${float(x):,.0f}"` for dollar amounts, `f"{float(x):,.0f}"` for populations
- **Tab 1 — Claim Intake:** Query loads **all 200 claims** (no LIMIT) with LEFT JOIN to `APAC_COUNTRY_RISK` for population/displaced data. Claim detail table: 10 fields (Claimant, Policy, Claim Type, Policy Type, Location, Status, Filing Date, Amount, Coverage, Deductible) + incident description as `st.caption()`. **World Bank Market Context expander** (`expanded=True`) shows 6 metrics: GDP per Capita (PPP), Insurance Penetration, Disaster Exposure, Population, Disaster Displaced, Country — with caption explaining Marketplace→Bedrock data flow. After Bedrock evaluation, a `st.success()` banner shows status transition ("Pending → Approved"). No "Previous Evaluation" section. Dollar amounts formatted with commas
- **Tab 2 — Top Claims table:** does NOT include AI_DECISION column (shows "None" for unevaluated claims, adds no value)
- **Tab 3 — Policy Search:** AI summary must use ALL hits (`hits` not `hits[:3]`) and prompt must tell the model how many policies to reference. 6 sample questions pre-tested for relevance score >0.55. Low-scoring questions (<0.5) replaced during build
- **Tab 4 — APJ Market View:** each chart/table section includes a `st.caption()` explaining why the metric matters for insurance (penetration → claims volume, GDP → claim amounts, disaster exposure → catastrophe reserves, risk detail → Bedrock evaluation inputs)

### Amazon Bedrock Integration
- Model ID `us.anthropic.claude-sonnet-4-5-20250929-v1:0` contains a colon — must URL-encode (`%3A`) in canonical URI for SigV4 signing
- Use `urllib.parse.quote(model_id, safe="")` in the stored procedure
- **Stored procedure updates 3 columns:** `AI_DECISION`, `AI_REASONING`, and `STATUS` (using `status_map = {'APPROVE':'Approved','DENY':'Denied','REFER':'Under Review'}`)
- **Bedrock responses may be wrapped in markdown code fences** (`` ```json ... ``` ``). The Streamlit app MUST strip these before `json.loads()`. Use: `re.sub(r"^```(?:json)?\s*", "", result)` and `re.sub(r"\s*```$", "", result)`. As fallback, use `re.search(r'\{.*\}', result, re.DOTALL)` to extract the JSON object

### Marketplace Data
- Shared databases can go offline at any time. **Materialize into local tables** at build time
- World Bank data uses `GEO_ID` format `country/XXX` (e.g., `country/HKG`)
- Use `ILIKE` patterns for variable names (avoid `$` in exact strings — shell interprets it)
- Use `ROW_NUMBER()` to get latest value per country per indicator

### Cortex Search (Policy Search Tab)
- Query via `SNOWFLAKE.CORTEX.SEARCH_PREVIEW()` — returns JSON with `results` array containing `@scores.cosine_similarity`, `POLICY_NUMBER`, `POLICY_TYPE`, `SEARCH_TEXT`
- Relevance thresholds: >0.65 = High (green), >0.55 = Medium (orange), <=0.55 = Low (red)
- **Pre-test all sample questions** during build. Replace any with cosine similarity <0.5 — low scores produce irrelevant results
- Tested high-performing questions: typhoon damage HK (0.75), auto deductible SG (0.70), hospitalization JP (0.70), home coverage limits (0.64), earthquake commercial (0.59), flight cancellations travel (0.58)

### QuickSight
- Must add QuickSight egress IPs to Snowflake network policy **before** creating the data source. IPs for us-west-2: `54.70.204.128/25`, `35.165.175.128/25`, `34.223.24.0/24` (check [QuickSight docs](https://docs.aws.amazon.com/quicksight/latest/user/regions.html) for current list)
- Account-level MFA policy blocks data source creation — create a `LEGACY_SERVICE` Snowflake user with MFA disabled:
  ```sql
  CREATE USER QUICKSIGHT_USER PASSWORD='...' DEFAULT_ROLE=ACCOUNTADMIN DEFAULT_WAREHOUSE=CORTEX TYPE=LEGACY_SERVICE;
  ALTER USER QUICKSIGHT_USER SET DISABLE_MFA = TRUE;
  GRANT ROLE ACCOUNTADMIN TO USER QUICKSIGHT_USER;
  ```
- **Data source creation** (after Snowflake user + network policy):
  ```bash
  aws quicksight create-data-source --aws-account-id $AWS_ACCOUNT_ID --region us-west-2 \
    --data-source-id insurance-snowflake-ds-v3 \
    --name "Insurance Snowflake (APJ Demo)" \
    --type SNOWFLAKE \
    --data-source-parameters '{"SnowflakeParameters":{"Host":"<ACCOUNT>.snowflakecomputing.com","Database":"INSURANCE_DEMO_DB","Warehouse":"CORTEX"}}' \
    --credentials '{"CredentialPair":{"Username":"QUICKSIGHT_USER","Password":"<password>"}}'
  ```
  Replace `<ACCOUNT>` with Snowflake account URL prefix (e.g., `sfseapac-sg-demo43`) and `<password>` with the user's password.
- STRING columns (like `CLAIM_ID`) must use `CategoricalMeasureField` with `"AggregationFunction": "COUNT"` — **not** `NumericalMeasureField`. The deploy script already handles this correctly.
- **All datasets, analysis, dashboard, and Q topic are created by `quicksight/deploy.sh`** — a single idempotent script with full JSON definitions. The script validates all resources after creation. Never create these objects manually or with ad-hoc CLI commands.
- **QuickSight Q topic** — 19 columns with friendly names, descriptions, and synonyms. Pre-test Q questions after deployment: "Which country has the highest total claim amount?", "Show claim count by policy type", "How many claims are pending?"

### IAM / Storage Integration
- Circular dependency: create IAM role with placeholder trust → create Snowflake storage integration → `DESC INTEGRATION` to get Snowflake ARN + External ID → update IAM trust policy
- EAI name must match **exactly** between `CREATE EXTERNAL ACCESS INTEGRATION` and any objects referencing it

---

## Build Time Estimate

| Phase | Description | Est. Time |
|---|---|---|
| Phase 1 | AWS: S3 + IAM + SQS | ~12 min |
| Phase 2 | Snowflake: DB/schemas, Bedrock wiring, storage integration, Snowpipe | ~18 min |
| Phase 3 | APJ synthetic data + AI extraction + marketplace materialization + data quality validation | ~35 min |
| Phase 4 | Bedrock stored proc + Cortex Search + Analyst + Agent + Streamlit | ~20 min |
| Phase 5 | QuickSight: network policy + data source + `bash quicksight/deploy.sh` | ~15 min |
| **Total** | | **~100 min** |

---

## Validation Checkpoints (CRITICAL — run after each phase)

Each phase has a validation gate. **Do not proceed to the next phase until the gate passes.**

### Gate 1 — After Phase 1 (AWS)
```bash
# All 3 must pass
aws s3api head-bucket --bucket sf-insurance-demo-apj && echo "S3: OK"
aws iam get-role --role-name snowflake-insurance-s3-role --query 'Role.RoleName' --output text && echo "IAM: OK"
aws sqs get-queue-url --queue-name sf-insurance-demo-snowpipe --region us-west-2 && echo "SQS: OK"
```

### Gate 2 — After Phase 2 (Snowflake Infrastructure)
```sql
-- Run in Snowflake (snow sql -c demo43)
SELECT 'DB' AS check, COUNT(*) FROM INSURANCE_DEMO_DB.INFORMATION_SCHEMA.SCHEMATA WHERE SCHEMA_NAME IN ('RAW','CURATED','AI','APP')
UNION ALL SELECT 'EAI', COUNT(*) FROM (SHOW INTEGRATIONS LIKE 'INSURANCE_BEDROCK_EAI')
UNION ALL SELECT 'S3_INT', COUNT(*) FROM (SHOW INTEGRATIONS LIKE 'INSURANCE_S3_INTEGRATION');
-- Expect: DB=4, EAI=1, S3_INT=1

-- Verify IAM trust is updated with Snowflake ARN
DESC INTEGRATION INSURANCE_S3_INTEGRATION;
-- Check STORAGE_AWS_IAM_USER_ARN and STORAGE_AWS_EXTERNAL_ID
```

### Gate 3 — After Phase 3 (Data)
```sql
-- Row counts (all must match)
SELECT 'RAW_CUSTOMERS' AS tbl, COUNT(*) AS cnt FROM INSURANCE_DEMO_DB.RAW.RAW_CUSTOMERS        -- expect 50
UNION ALL SELECT 'RAW_POLICIES_GEN', COUNT(*) FROM INSURANCE_DEMO_DB.RAW.RAW_POLICIES_GEN      -- expect 100
UNION ALL SELECT 'RAW_CLAIMS_GEN', COUNT(*) FROM INSURANCE_DEMO_DB.RAW.RAW_CLAIMS_GEN          -- expect 200
UNION ALL SELECT 'CURATED.CLAIMS', COUNT(*) FROM INSURANCE_DEMO_DB.CURATED.CLAIMS              -- expect 200
UNION ALL SELECT 'APAC_COUNTRY_RISK', COUNT(*) FROM INSURANCE_DEMO_DB.CURATED.APAC_COUNTRY_RISK -- expect 8
UNION ALL SELECT 'APAC_INDICATORS', COUNT(*) FROM INSURANCE_DEMO_DB.CURATED.APAC_INSURANCE_INDICATORS; -- expect 8

-- Data quality (must return 0)
SELECT COUNT(*) FROM INSURANCE_DEMO_DB.CURATED.CLAIMS
WHERE NOT (
    (POLICY_TYPE = 'Auto' AND CLAIM_TYPE IN ('Auto Collision', 'Theft', 'Liability'))
    OR (POLICY_TYPE = 'Home' AND CLAIM_TYPE IN ('Fire', 'Property Damage', 'Theft', 'Natural Disaster'))
    OR (POLICY_TYPE = 'Health' AND CLAIM_TYPE = 'Medical')
    OR (POLICY_TYPE = 'Life' AND CLAIM_TYPE = 'Medical')
    OR (POLICY_TYPE = 'Commercial' AND CLAIM_TYPE IN ('Fire', 'Property Damage', 'Liability', 'Theft', 'Natural Disaster'))
    OR (POLICY_TYPE = 'Travel' AND CLAIM_TYPE IN ('Travel Disruption', 'Medical'))
);
-- Must return 0

-- Status check (no Approved/Denied before AI evaluation)
SELECT STATUS, COUNT(*) FROM INSURANCE_DEMO_DB.CURATED.CLAIMS GROUP BY 1 ORDER BY 2 DESC;
-- Expect only: Pending, Submitted, Under Review

-- Country distribution (all 8 markets present)
SELECT COUNTRY, COUNT(*) FROM INSURANCE_DEMO_DB.CURATED.CLAIMS GROUP BY 1 ORDER BY 2 DESC;
-- Expect 8 countries, each with 20-30 claims
```

### Gate 4 — After Phase 4 (AI & Streamlit)
```sql
-- Test Bedrock evaluation (must return JSON with decision)
CALL INSURANCE_DEMO_DB.AI.EVALUATE_CLAIM('CLM-001');

-- Verify Cortex Search is active
DESCRIBE CORTEX SEARCH SERVICE INSURANCE_DEMO_DB.AI.POLICY_SEARCH_SERVICE;
-- Check: indexing_state = ACTIVE, source_data_num_rows = 100

-- Test Cortex Search
SELECT SNOWFLAKE.CORTEX.SEARCH_PREVIEW(
    'INSURANCE_DEMO_DB.AI.POLICY_SEARCH_SERVICE',
    '{"query": "typhoon damage Hong Kong", "columns": ["SEARCH_TEXT", "POLICY_NUMBER", "POLICY_TYPE"], "limit": 3}'
);
-- Must return results with cosine_similarity > 0.5

-- Verify Streamlit is deployed
SHOW STREAMLITS IN SCHEMA INSURANCE_DEMO_DB.APP;
-- Must show INSURANCE_CLAIMS_APP

-- MANUAL: Open the Streamlit URL and verify all 4 tabs load without errors
```

### Gate 5 — After Phase 5 (QuickSight)
```bash
# Automated (run by quicksight/deploy.sh Step 6):
# - 3 datasets exist
# - Analysis status = CREATION_SUCCESSFUL
# - Dashboard version status = CREATION_SUCCESSFUL
# - Q topic exists

# MANUAL: Open dashboard URL and verify:
# 1. Sheet "Claims Pipeline" shows charts with data (not empty)
# 2. Sheet "APJ Risk & Markets" shows country-level data
# 3. Q bar: type "Which country has the highest total claim amount?" — expect answer

# Dashboard URL: https://us-west-2.quicksight.aws.amazon.com/sn/dashboards/insurance-apj-dashboard
```

### Post-Build Smoke Test (run after ALL phases)
```
1. Open Streamlit → Tab 1 → Select CLM-001 → Click "Evaluate with Amazon Bedrock"
   Expected: Decision (APPROVE/DENY/REFER), risk score, reasoning, status transition banner
2. Open Streamlit → Tab 3 → Click "Does home insurance cover typhoon damage in Hong Kong?"
   Expected: 5 policy results with relevance scores, AI summary
3. Open QuickSight dashboard → verify both sheets have charts with data
4. Open QuickSight Q → type "How many claims are pending?" → expect numeric answer
5. Verify in Snowflake: SELECT AI_DECISION, STATUS FROM INSURANCE_DEMO_DB.CURATED.CLAIMS WHERE CLAIM_ID='CLM-001';
   Expected: AI_DECISION is set, STATUS changed from original
```

---

## Pre-Build Checklist

- [ ] Set environment variable: `export AWS_ACCOUNT_ID=018437500440` (or your account)
- [ ] QuickSight account active (Enterprise edition)
- [ ] Bedrock model `us.anthropic.claude-sonnet-4-5-20250929-v1:0` enabled in us-west-2
- [ ] IAM user with `AdministratorAccess` + `AmazonBedrockFullAccess`
- [ ] Snowflake `demo43` with `ACCOUNTADMIN` role and `CORTEX` warehouse
- [ ] `AI_COMPLETE` (Claude 3.5 Sonnet) confirmed working in Snowflake
- [ ] AWS access key + secret key available
- [ ] `INSURANCE_DEMO_DB` does not exist (clean start)
- [ ] `SNOWFLAKE_PUBLIC_DATA_FREE` Marketplace listing installed
- [ ] QuickSight egress IPs added to Snowflake network policy
- [ ] Previous build fully torn down (S3 bucket, IAM role, SQS queue, QuickSight resources, Snowflake DB + integrations + user)
- [ ] `quicksight/deploy.sh` exists in project root (contains full QuickSight definitions)
- [ ] `scripts/adjuster_notes.sh` exists (contains 10 embedded adjuster notes + S3 upload)

---

## Tear-Down Commands

```bash
# Set account ID first
export AWS_ACCOUNT_ID=018437500440

# AWS — S3 (must remove all object versions first if versioning enabled)
aws s3api list-object-versions --bucket sf-insurance-demo-apj --output json \
  | python3 -c "import sys,json; v=json.load(sys.stdin); objs=[{'Key':o['Key'],'VersionId':o['VersionId']} for o in v.get('Versions',[])+v.get('DeleteMarkers',[])]; print(json.dumps({'Objects':objs,'Quiet':True}))" \
  | aws s3api delete-objects --bucket sf-insurance-demo-apj --delete file:///dev/stdin
aws s3api delete-bucket --bucket sf-insurance-demo-apj

# AWS — IAM
aws iam delete-role-policy --role-name snowflake-insurance-s3-role --policy-name snowflake-insurance-s3-policy
aws iam delete-role --role-name snowflake-insurance-s3-role

# AWS — SQS
aws sqs delete-queue --queue-url https://sqs.us-west-2.amazonaws.com/$AWS_ACCOUNT_ID/sf-insurance-demo-snowpipe

# AWS — QuickSight (Q topic first, then dashboard, then datasets, then data source)
aws quicksight delete-topic --aws-account-id $AWS_ACCOUNT_ID --topic-id insurance-apj-q-topic
aws quicksight delete-dashboard --aws-account-id $AWS_ACCOUNT_ID --dashboard-id insurance-apj-dashboard
aws quicksight delete-analysis --aws-account-id $AWS_ACCOUNT_ID --analysis-id insurance-apj-analysis
aws quicksight delete-data-set --aws-account-id $AWS_ACCOUNT_ID --data-set-id insurance-claims-ds
aws quicksight delete-data-set --aws-account-id $AWS_ACCOUNT_ID --data-set-id insurance-apac-country-risk
aws quicksight delete-data-set --aws-account-id $AWS_ACCOUNT_ID --data-set-id insurance-extracted-notes
aws quicksight delete-data-source --aws-account-id $AWS_ACCOUNT_ID --data-source-id insurance-snowflake-ds-v3
```

```sql
-- Snowflake
DROP DATABASE IF EXISTS INSURANCE_DEMO_DB;
DROP INTEGRATION IF EXISTS INSURANCE_S3_INTEGRATION;
DROP INTEGRATION IF EXISTS INSURANCE_BEDROCK_EAI;
DROP USER IF EXISTS QUICKSIGHT_USER;
-- Must unset auth policy first if set: ALTER USER QUICKSIGHT_USER UNSET AUTHENTICATION POLICY;
```
