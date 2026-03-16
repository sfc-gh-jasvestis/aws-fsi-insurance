import streamlit as st
import pandas as pd
import json
import re
import time
from snowflake.snowpark.context import get_active_session

session = get_active_session()

st.set_page_config(page_title="APJ Insurance Claims AI", layout="wide")
st.title("APJ Insurance Claims AI Demo")
st.caption("AWS Summit Hong Kong — Snowflake + Amazon Bedrock + QuickSight")

with st.sidebar:
    st.markdown("### Architecture")
    st.code("""
┌──────────────────────┐
│   Amazon S3 Bucket   │
│  (Claims + Notes)    │
└────────┬─────────────┘
         │ Snowpipe
         ▼
┌──────────────────────┐
│   Snowflake          │
│  ┌────────────────┐  │
│  │ RAW Schema     │  │
│  └──────┬─────────┘  │
│         ▼            │
│  ┌────────────────┐  │
│  │ CURATED Schema │◄─┼── Marketplace
│  └──────┬─────────┘  │   (World Bank)
│         ▼            │
│  ┌────────────────┐  │
│  │ AI Schema      │  │
│  │ • Evaluate SP  │  │
│  │ • Cortex Search│  │
│  └──────┬─────────┘  │
│         ▼            │
│  ┌────────────────┐  │
│  │ APP Schema     │  │
│  │ • This App     │  │
│  └────────────────┘  │
└──────────┬───────────┘
           │ External Access
           ▼
┌──────────────────────┐
│  Amazon Bedrock      │
│  Claude Sonnet 4.5   │
└──────────────────────┘
           │
           ▼
┌──────────────────────┐
│  Amazon QuickSight   │
│  Dashboard + Q       │
└──────────────────────┘
""", language=None)
    st.divider()
    st.caption("Built for AWS Summit HK")
    st.caption("Snowflake + AWS")

tab1, tab2, tab3, tab4 = st.tabs([
    "Claim Intake & AI Evaluation",
    "Claims Dashboard",
    "Policy Search",
    "APJ Market View"
])

def load_claims():
    return session.sql("""
        SELECT c.CLAIM_ID, c.CLAIM_TYPE, c.COUNTRY, c.CITY, c.CLAIM_AMOUNT, c.COVERAGE_LIMIT,
               c.DEDUCTIBLE, c.POLICY_NUMBER, c.POLICY_TYPE, c.FIRST_NAME, c.LAST_NAME,
               c.STATUS, c.FILING_DATE, c.DESCRIPTION,
               c.COUNTRY_GDP_PER_CAPITA, c.COUNTRY_INSURANCE_PENETRATION, c.COUNTRY_DISASTER_EXPOSURE,
               c.AI_DECISION, c.AI_REASONING,
               r.POPULATION, r.DISASTER_DISPLACED_PERSONS
        FROM INSURANCE_DEMO_DB.CURATED.CLAIMS c
        LEFT JOIN INSURANCE_DEMO_DB.CURATED.APAC_COUNTRY_RISK r ON c.COUNTRY = r.COUNTRY
        ORDER BY c.CLAIM_ID
    """).to_pandas()

def render_risk_bar(score):
    try:
        s = int(float(score))
    except (ValueError, TypeError):
        return
    if s <= 3:
        color = "#2ecc71"
        label = "Low"
    elif s <= 6:
        color = "#f39c12"
        label = "Medium"
    else:
        color = "#e74c3c"
        label = "High"
    pct = s * 10
    st.markdown(
        f'<div style="background:#e0e0e0;border-radius:8px;height:28px;width:100%;position:relative;">'
        f'<div style="background:{color};border-radius:8px;height:28px;width:{pct}%;"></div>'
        f'<span style="position:absolute;top:4px;left:10px;font-weight:bold;color:#222;">'
        f'{s}/10 — {label} Risk</span></div>',
        unsafe_allow_html=True
    )

def parse_bedrock_result(raw):
    result = str(raw).strip()
    if result.startswith("```"):
        result = re.sub(r"^```(?:json)?\s*", "", result)
        result = re.sub(r"\s*```$", "", result)
    try:
        return json.loads(result)
    except Exception:
        m = re.search(r'\{.*\}', result, re.DOTALL)
        if m:
            try:
                return json.loads(m.group())
            except Exception:
                return {"decision": "ERROR", "reasoning": result}
        return {"decision": "ERROR", "reasoning": result}

def display_evaluation_result(result_dict, row, show_before_after=True):
    decision = result_dict.get("decision", "UNKNOWN")
    color_map = {"APPROVE": "green", "DENY": "red", "REFER": "orange"}
    color = color_map.get(decision, "gray")
    emoji = {"APPROVE": "white_check_mark", "DENY": "x", "REFER": "warning"}.get(decision, "question")
    status_map = {"APPROVE": "Approved", "DENY": "Denied", "REFER": "Under Review"}
    new_status = status_map.get(decision, "Under Review")

    if decision == "APPROVE":
        st.balloons()

    if show_before_after:
        st.divider()
        ba1, ba2 = st.columns(2)
        with ba1:
            st.markdown("**Before**")
            st.metric("Status", str(row.get("STATUS", "Pending")))
            st.metric("AI Decision", "None")
        with ba2:
            st.markdown("**After**")
            st.metric("Status", new_status)
            st.metric("AI Decision", decision)

    st.divider()
    st.success(f"Claim status updated: **{row['STATUS']}** → **{new_status}**")

    r1, r2 = st.columns([1, 2])
    with r1:
        st.markdown(f"### :{emoji}: Decision: :{color}[{decision}]")
        risk = result_dict.get("risk_score", "N/A")
        st.markdown("**Risk Score**")
        render_risk_bar(risk)
        payout = result_dict.get("recommended_payout", 0)
        st.metric("Recommended Payout", f"${payout:,.0f}" if isinstance(payout, (int, float)) else str(payout))
    with r2:
        _reasoning = result_dict.get('reasoning', 'No reasoning provided').replace('$', '\\$')
        st.info(f"**Reasoning:** {_reasoning}")


with tab1:
    st.header("AI Claim Evaluation")
    st.markdown("Select a claim and run it through **Amazon Bedrock (Claude Sonnet 4.5)** for an instant AI adjuster recommendation.")
    st.divider()

    claims_df = load_claims()

    labels = []
    for _, r in claims_df.iterrows():
        labels.append(f"{r['CLAIM_ID']} — {r['CLAIM_TYPE']} | {r['COUNTRY']} | {r['STATUS']}")
    label_to_id = dict(zip(labels, claims_df["CLAIM_ID"].tolist()))

    selected_label = st.selectbox("Select Claim", labels)
    claim_id = label_to_id.get(selected_label)

    if claim_id:
        row = claims_df[claims_df["CLAIM_ID"] == claim_id].iloc[0]

        st.markdown("---")

        m1, m2, m3, m4 = st.columns(4)
        m1.metric("Amount Claimed", f"${float(row['CLAIM_AMOUNT']):,.0f}")
        m2.metric("Coverage Limit", f"${float(row['COVERAGE_LIMIT']):,.0f}")
        m3.metric("Deductible", f"${float(row['DEDUCTIBLE']):,.0f}")
        m4.metric("Status", row["STATUS"])

        detail = pd.DataFrame({
            "Field": [
                "Policy", "Claim Type", "Policy Type",
                "Location", "Filing Date",
            ],
            "Value": [
                row["POLICY_NUMBER"],
                row["CLAIM_TYPE"],
                row["POLICY_TYPE"],
                f"{row['CITY']}, {row['COUNTRY']}",
                str(row["FILING_DATE"]),
            ]
        })
        st.table(detail.set_index("Field"))

        desc = row.get("DESCRIPTION", "")
        if desc:
            st.caption(f"**Incident:** {desc}")

        st.divider()

        with st.expander("**World Bank Market Context** — data fed to Amazon Bedrock AI", expanded=True):
            st.caption("Sourced from the **Snowflake Marketplace** (World Bank) and joined to each claim at build time. Bedrock uses these indicators to calibrate risk scores and payout recommendations for the claimant's country.")
            gdp = row.get("COUNTRY_GDP_PER_CAPITA", None)
            ins_pen = row.get("COUNTRY_INSURANCE_PENETRATION", None)
            dis_exp = row.get("COUNTRY_DISASTER_EXPOSURE", None)
            pop = row.get("POPULATION", None)
            displaced = row.get("DISASTER_DISPLACED_PERSONS", None)

            mc1, mc2, mc3 = st.columns(3)
            mc1.metric("GDP per Capita (PPP)", f"${float(gdp):,.0f}" if gdp else "N/A")
            mc2.metric("Insurance Penetration", f"{float(ins_pen)*100:.1f}%" if ins_pen else "N/A")
            mc3.metric("Disaster Exposure", f"{float(dis_exp)*100:.1f}%" if dis_exp else "N/A")

            if pop or displaced:
                mc4, mc5, mc6 = st.columns(3)
                mc4.metric("Population", f"{float(pop):,.0f}" if pop else "N/A")
                mc5.metric("Disaster Displaced", f"{float(displaced):,.0f}" if displaced else "N/A")
                mc6.metric("Country", row["COUNTRY"])

        st.divider()

        existing_decision = row.get("AI_DECISION")
        existing_reasoning = row.get("AI_REASONING")

        if existing_decision and str(existing_decision).strip():
            st.markdown("### Previous AI Evaluation")
            try:
                prev_result = json.loads(str(existing_reasoning)) if existing_reasoning else {}
            except Exception:
                prev_result = {"decision": str(existing_decision), "reasoning": str(existing_reasoning or "")}
            if "decision" not in prev_result:
                prev_result["decision"] = str(existing_decision)
            if "reasoning" not in prev_result and existing_reasoning:
                prev_result["reasoning"] = str(existing_reasoning)

            prev_decision = prev_result.get("decision", str(existing_decision))
            prev_color = {"APPROVE": "green", "DENY": "red", "REFER": "orange"}.get(prev_decision, "gray")
            prev_emoji = {"APPROVE": "white_check_mark", "DENY": "x", "REFER": "warning"}.get(prev_decision, "question")

            pr1, pr2 = st.columns([1, 2])
            with pr1:
                st.markdown(f"### :{prev_emoji}: Decision: :{prev_color}[{prev_decision}]")
                prev_risk = prev_result.get("risk_score", "N/A")
                st.markdown("**Risk Score**")
                render_risk_bar(prev_risk)
                prev_payout = prev_result.get("recommended_payout", 0)
                st.metric("Recommended Payout", f"${prev_payout:,.0f}" if isinstance(prev_payout, (int, float)) else str(prev_payout))
            with pr2:
                _reasoning = prev_result.get('reasoning', 'No reasoning provided').replace('$', '\\$')
                st.info(f"**Reasoning:** {_reasoning}")

            st.divider()
            re_eval = st.button("Re-evaluate with Amazon Bedrock", type="secondary", use_container_width=True)
        else:
            re_eval = False

        with st.expander("View Bedrock Prompt", expanded=False):
            st.markdown("This is the prompt sent to **Amazon Bedrock (Claude Sonnet 4.5)** by the `EVALUATE_CLAIM` stored procedure:")
            st.code(f"""You are an AI insurance claim adjuster.
Evaluate this claim and respond with JSON only.

CLAIM:
- Claim ID: {row['CLAIM_ID']}
- Type: {row['CLAIM_TYPE']}
- Policy Type: {row['POLICY_TYPE']}
- Amount: ${float(row['CLAIM_AMOUNT']):,.0f}
- Coverage Limit: ${float(row['COVERAGE_LIMIT']):,.0f}
- Deductible: ${float(row['DEDUCTIBLE']):,.0f}
- Country: {row['COUNTRY']}, City: {row['CITY']}
- Description: {desc}

MARKET CONTEXT (World Bank / Snowflake Marketplace):
- GDP per Capita (PPP): {f"${float(gdp):,.0f}" if gdp else "N/A"}
- Insurance Penetration: {f"{float(ins_pen)*100:.1f}%" if ins_pen else "N/A"}
- Disaster Exposure: {f"{float(dis_exp)*100:.1f}%" if dis_exp else "N/A"}

Respond with JSON: {{"decision":"APPROVE|DENY|REFER",
"risk_score":1-10, "reasoning":"...",
"recommended_payout":number}}""", language="text")

        should_evaluate = False
        if not existing_decision or not str(existing_decision).strip():
            should_evaluate = st.button("Evaluate with Amazon Bedrock", type="primary", use_container_width=True)
        elif re_eval:
            should_evaluate = True

        if should_evaluate:
            start_ts = time.time()
            timer_placeholder = st.empty()
            with st.spinner("Calling Amazon Bedrock (Claude Sonnet 4.5)..."):
                raw = session.sql(f"CALL INSURANCE_DEMO_DB.AI.EVALUATE_CLAIM('{claim_id}')").collect()[0][0]
                elapsed = time.time() - start_ts
            timer_placeholder.caption(f"Bedrock responded in **{elapsed:.1f}s**")
            result_dict = parse_bedrock_result(raw)
            display_evaluation_result(result_dict, row, show_before_after=True)

        st.divider()
        st.markdown("### Batch Evaluation")
        pending_df = claims_df[claims_df["STATUS"] == "Pending"]
        pending_count = len(pending_df)
        st.caption(f"{pending_count} pending claims available for batch evaluation.")

        if pending_count > 0:
            if st.button(f"Evaluate All {pending_count} Pending Claims", use_container_width=True):
                progress = st.progress(0)
                results_container = st.container()
                for i, (_, prow) in enumerate(pending_df.iterrows()):
                    pid = prow["CLAIM_ID"]
                    progress.progress((i) / pending_count)
                    with results_container:
                        st.markdown(f"**Evaluating {pid}** — {prow['CLAIM_TYPE']} | {prow['COUNTRY']}...")
                    start_ts = time.time()
                    raw = session.sql(f"CALL INSURANCE_DEMO_DB.AI.EVALUATE_CLAIM('{pid}')").collect()[0][0]
                    elapsed = time.time() - start_ts
                    rd = parse_bedrock_result(raw)
                    dec = rd.get("decision", "UNKNOWN")
                    risk = rd.get("risk_score", "?")
                    with results_container:
                        dec_color = {"APPROVE": "green", "DENY": "red", "REFER": "orange"}.get(dec, "gray")
                        st.markdown(f":{dec_color}[**{dec}**] — Risk {risk}/10 — {elapsed:.1f}s")
                    progress.progress((i + 1) / pending_count)
                with results_container:
                    st.success(f"Batch complete — {pending_count} claims evaluated.")
        else:
            st.info("No pending claims to evaluate. All claims have been processed.")


with tab2:
    st.header("Claims Dashboard")

    if st.button("Refresh Data", key="refresh_dashboard"):
        pass

    kpi_df = session.sql("""
        SELECT
            COUNT(*) AS TOTAL_CLAIMS,
            ROUND(SUM(CLAIM_AMOUNT), 0) AS TOTAL_AMOUNT,
            ROUND(AVG(CLAIM_AMOUNT), 0) AS AVG_AMOUNT,
            COUNT(DISTINCT COUNTRY) AS COUNTRIES,
            SUM(CASE WHEN AI_DECISION IS NOT NULL THEN 1 ELSE 0 END) AS EVALUATED,
            SUM(CASE WHEN AI_DECISION = 'APPROVE' THEN 1 ELSE 0 END) AS APPROVED,
            SUM(CASE WHEN AI_DECISION = 'DENY' THEN 1 ELSE 0 END) AS DENIED,
            SUM(CASE WHEN AI_DECISION = 'REFER' THEN 1 ELSE 0 END) AS REFERRED
        FROM INSURANCE_DEMO_DB.CURATED.CLAIMS
    """).to_pandas()

    c1, c2, c3, c4 = st.columns(4)
    c1.metric("Total Claims", f"{kpi_df['TOTAL_CLAIMS'].iloc[0]:,}")
    c2.metric("Total Claimed", f"${kpi_df['TOTAL_AMOUNT'].iloc[0]:,.0f}")
    c3.metric("Avg Claim", f"${kpi_df['AVG_AMOUNT'].iloc[0]:,.0f}")
    c4.metric("APJ Markets", f"{kpi_df['COUNTRIES'].iloc[0]}")

    ev1, ev2, ev3, ev4 = st.columns(4)
    evaluated = int(kpi_df['EVALUATED'].iloc[0])
    total = int(kpi_df['TOTAL_CLAIMS'].iloc[0])
    ev1.metric("AI Evaluated", f"{evaluated} / {total}")
    ev2.metric("Approved", f"{int(kpi_df['APPROVED'].iloc[0])}")
    ev3.metric("Denied", f"{int(kpi_df['DENIED'].iloc[0])}")
    ev4.metric("Referred", f"{int(kpi_df['REFERRED'].iloc[0])}")

    if total > 0:
        st.progress(evaluated / total)
        st.caption(f"{evaluated}/{total} claims evaluated ({evaluated*100//total}%)")

    st.divider()

    col_left, col_right = st.columns(2)
    with col_left:
        st.subheader("Claims by Type")
        type_df = session.sql("""
            SELECT CLAIM_TYPE, COUNT(*) AS CNT
            FROM INSURANCE_DEMO_DB.CURATED.CLAIMS GROUP BY CLAIM_TYPE ORDER BY CNT DESC
        """).to_pandas()
        st.bar_chart(type_df.set_index("CLAIM_TYPE")["CNT"])

    with col_right:
        st.subheader("Claims by Status")
        status_df = session.sql("""
            SELECT STATUS, COUNT(*) AS CNT
            FROM INSURANCE_DEMO_DB.CURATED.CLAIMS GROUP BY STATUS ORDER BY CNT DESC
        """).to_pandas()
        st.bar_chart(status_df.set_index("STATUS")["CNT"])

    st.divider()

    col_l2, col_r2 = st.columns(2)
    with col_l2:
        st.subheader("Claims by Country")
        country_df = session.sql("""
            SELECT COUNTRY, COUNT(*) AS CNT
            FROM INSURANCE_DEMO_DB.CURATED.CLAIMS GROUP BY COUNTRY ORDER BY CNT DESC
        """).to_pandas()
        st.bar_chart(country_df.set_index("COUNTRY")["CNT"])

    with col_r2:
        st.subheader("Country Risk Profile")
        try:
            risk_df = session.sql("""
                SELECT COUNTRY,
                       ROUND(INSURANCE_PENETRATION * 100, 1) AS INS_PCT,
                       ROUND(GDP_PER_CAPITA, 0) AS GDP,
                       COALESCE(ROUND(NATURAL_DISASTER_EXPOSURE * 100, 1), 0) AS DISASTER_PCT,
                       ROUND(POPULATION / 1000000, 1) AS POP_M
                FROM INSURANCE_DEMO_DB.CURATED.APAC_COUNTRY_RISK
                ORDER BY GDP DESC
            """).to_pandas()
            if not risk_df.empty:
                risk_df["INS_PCT"] = risk_df["INS_PCT"].apply(lambda x: f"{float(x):.1f}%")
                risk_df["GDP"] = risk_df["GDP"].apply(lambda x: f"${float(x):,.0f}")
                risk_df["DISASTER_PCT"] = risk_df["DISASTER_PCT"].apply(lambda x: f"{float(x):.1f}%")
                risk_df["POP_M"] = risk_df["POP_M"].apply(lambda x: f"{float(x):.1f}")
                risk_display = risk_df.rename(columns={
                    "COUNTRY": "Country",
                    "INS_PCT": "Ins %",
                    "GDP": "GDP/Cap",
                    "DISASTER_PCT": "Disaster %",
                    "POP_M": "Pop (M)"
                })
                st.table(risk_display.set_index("Country"))
        except Exception as e:
            st.warning(f"Country risk data unavailable: {e}")

    st.divider()

    st.subheader("Top Claims by Amount")
    top_df = session.sql("""
        SELECT CLAIM_ID, CLAIM_TYPE, COUNTRY, CITY, CLAIM_AMOUNT
        FROM INSURANCE_DEMO_DB.CURATED.CLAIMS
        ORDER BY CLAIM_AMOUNT DESC LIMIT 10
    """).to_pandas()
    top_df["CLAIM_AMOUNT"] = top_df["CLAIM_AMOUNT"].apply(lambda x: f"${float(x):,.0f}")
    top_display = top_df.rename(columns={
        "CLAIM_ID": "Claim", "CLAIM_TYPE": "Type", "COUNTRY": "Country",
        "CITY": "City", "CLAIM_AMOUNT": "Amount"
    })
    st.table(top_display.set_index("Claim"))


with tab3:
    st.header("Policy Search")
    st.markdown("Search across **100 policy documents** using **Snowflake Cortex Search** — semantic RAG over unstructured policy terms, exclusions, and coverage details.")
    st.divider()

    st.markdown("**Try one of these:**")
    search_samples = [
        "Does home insurance cover typhoon damage in Hong Kong?",
        "What is the deductible for auto collision in Singapore?",
        "Does health insurance cover hospitalization in Japan?",
        "What does travel insurance cover for flight cancellations?",
        "What is the coverage limit for home insurance?",
        "Is earthquake damage covered under commercial policies?",
    ]
    search_cols = st.columns(3)
    selected_search = None
    for i, s in enumerate(search_samples):
        with search_cols[i % 3]:
            if st.button(s, key=f"search_{i}", use_container_width=True):
                selected_search = s

    st.divider()
    search_input = st.text_input("Or type your own search:", placeholder="e.g., Does this policy cover flood damage?")
    query = selected_search or search_input

    if query:
        st.markdown(f"**Search:** {query}")
        with st.spinner("Searching 100 policy documents..."):
            try:
                safe_q = query.replace('"', '\\"').replace("'", "''")
                raw = session.sql(f"""
                    SELECT SNOWFLAKE.CORTEX.SEARCH_PREVIEW(
                        'INSURANCE_DEMO_DB.AI.POLICY_SEARCH_SERVICE',
                        '{{"query": "{safe_q}", "columns": ["SEARCH_TEXT", "POLICY_NUMBER", "POLICY_TYPE"], "limit": 5}}'
                    ) AS RESULTS
                """).collect()[0][0]

                results = json.loads(raw) if isinstance(raw, str) else raw
                hits = results.get("results", [])

                if not hits:
                    st.warning("No matching policies found.")
                else:
                    st.divider()
                    st.markdown(f"**{len(hits)} matching policies found:**")
                    for idx, hit in enumerate(hits):
                        score = hit.get("@scores", {}).get("cosine_similarity", 0)
                        pnum = hit.get("POLICY_NUMBER", "Unknown")
                        ptype = hit.get("POLICY_TYPE", "Unknown")
                        text = hit.get("SEARCH_TEXT", "")

                        relevance = "High" if score > 0.65 else "Medium" if score > 0.55 else "Low"
                        color = "green" if score > 0.65 else "orange" if score > 0.55 else "red"

                        st.markdown(f"### {idx+1}. {pnum} — {ptype}")
                        st.markdown(f"**Relevance:** :{color}[{relevance}] ({score:.2f})")
                        st.info(text)

                    st.divider()
                    st.markdown("**AI Summary**")
                    with st.spinner("Generating summary with Cortex AI..."):
                        context_parts = []
                        for h in hits:
                            doc_id = h.get("POLICY_NUMBER", "Unknown")
                            doc_type = h.get("POLICY_TYPE", "Unknown")
                            doc_text = h.get("SEARCH_TEXT", "")
                            context_parts.append(f"[Document {doc_id} — {doc_type}]\n{doc_text}")
                        context = "\n\n".join(context_parts)
                        safe_ctx = context.replace("'", "''").replace("\\", "\\\\")
                        safe_query = query.replace("'", "''")
                        summary = session.sql(f"""
                            SELECT SNOWFLAKE.CORTEX.AI_COMPLETE('claude-3-5-sonnet',
                                'You are an insurance policy expert. Answer the question based ONLY on the {len(hits)} policy documents below.
                                Each document is labelled with its document ID (e.g. DOC-024) and policy type. Reference documents by their ID and type.
                                Be specific about coverage details, deductibles, and exclusions mentioned in the text.
                                If the documents do not cover what is asked, say so clearly.
                                Write dollar amounts as plain text. Do not use LaTeX or dollar-sign math notation.

                                QUESTION: {safe_query}

                                POLICY DOCUMENTS:
                                {safe_ctx}')
                        """).collect()[0][0]

                        answer = str(summary).strip()
                        if answer.startswith('"') and answer.endswith('"'):
                            answer = answer[1:-1]
                        answer = answer.replace("\\n", "\n").replace("\\t", " ").replace('$', '\\$')
                        st.markdown(answer)

            except Exception as e:
                st.error(f"Search error: {e}")


with tab4:
    st.header("APJ Insurance Market View")
    st.markdown("World Bank data from the **Snowflake Marketplace** — materialized into local tables for reliable access.")
    st.divider()

    try:
        indicators_df = session.sql("""
            SELECT COUNTRY, COUNTRY_CODE,
                   INSURANCE_PENETRATION_PCT AS INS_PCT,
                   GDP_PER_CAPITA_PPP AS GDP,
                   COALESCE(DISASTER_EXPOSURE_PCT, 0) AS DISASTER_PCT
            FROM INSURANCE_DEMO_DB.CURATED.APAC_INSURANCE_INDICATORS
            ORDER BY GDP DESC
        """).to_pandas()

        if not indicators_df.empty:
            st.subheader("Insurance Penetration (% of Commercial Service Exports)")
            st.caption("Higher penetration means a mature insurance market with more policyholders — and more claims volume. This drives how we size reserves and price risk across APJ.")
            chart_ins = indicators_df[["COUNTRY", "INS_PCT"]].set_index("COUNTRY")
            st.bar_chart(chart_ins)

            st.divider()

            st.subheader("GDP per Capita (PPP, Current International $)")
            st.caption("GDP per capita directly influences claim amounts — higher-income markets like Singapore and Australia generate larger claims for medical, property, and liability. This shapes coverage limits and premium pricing.")
            chart_gdp = indicators_df[["COUNTRY", "GDP"]].set_index("COUNTRY")
            st.bar_chart(chart_gdp)

            st.divider()

            st.subheader("Natural Disaster Exposure (% of Population)")
            st.caption("APJ is the world's most disaster-exposed region. Markets like Thailand and Australia have high typhoon, flood, and bushfire risk — directly impacting catastrophe reserves, reinsurance costs, and claim surge planning.")
            chart_dis = indicators_df[["COUNTRY", "DISASTER_PCT"]].set_index("COUNTRY")
            st.bar_chart(chart_dis)

            st.divider()

            st.subheader("Full APJ Market Summary")
            st.caption("Side-by-side comparison of all 8 markets. This data is sourced from the Snowflake Marketplace (World Bank) with zero ETL — available the moment the listing was installed.")
            fmt_df = indicators_df.copy()
            fmt_df["INS_PCT"] = fmt_df["INS_PCT"].apply(lambda x: f"{float(x):.1f}%")
            fmt_df["GDP"] = fmt_df["GDP"].apply(lambda x: f"${float(x):,.0f}")
            fmt_df["DISASTER_PCT"] = fmt_df["DISASTER_PCT"].apply(lambda x: f"{float(x):.1f}%")
            summary = fmt_df.rename(columns={
                "COUNTRY": "Country",
                "COUNTRY_CODE": "Code",
                "INS_PCT": "Insurance %",
                "GDP": "GDP/Capita",
                "DISASTER_PCT": "Disaster %"
            })
            st.table(summary.set_index("Country"))
    except Exception as e:
        st.warning(f"Marketplace data unavailable: {e}")

    st.divider()

    try:
        risk_full = session.sql("""
            SELECT COUNTRY, COUNTRY_CODE,
                   GDP_PER_CAPITA, INSURANCE_PENETRATION,
                   COALESCE(NATURAL_DISASTER_EXPOSURE, 0) AS DISASTER_EXP,
                   POPULATION, COALESCE(DISASTER_DISPLACED_PERSONS, 0) AS DISPLACED
            FROM INSURANCE_DEMO_DB.CURATED.APAC_COUNTRY_RISK
            ORDER BY POPULATION DESC
        """).to_pandas()

        if not risk_full.empty:
            st.subheader("Country Risk Detail")
            st.caption("Combined risk profile used by the AI claim evaluation engine. When Amazon Bedrock evaluates a claim, it factors in the claimant's country GDP, insurance maturity, disaster exposure, and displaced population to calibrate risk scores and payout recommendations.")
            risk_full["GDP_PER_CAPITA"] = risk_full["GDP_PER_CAPITA"].apply(lambda x: f"${float(x):,.0f}")
            risk_full["INSURANCE_PENETRATION"] = risk_full["INSURANCE_PENETRATION"].apply(lambda x: f"{float(x)*100:.1f}%")
            risk_full["DISASTER_EXP"] = risk_full["DISASTER_EXP"].apply(lambda x: f"{float(x)*100:.1f}%")
            risk_full["POPULATION"] = risk_full["POPULATION"].apply(lambda x: f"{float(x):,.0f}")
            risk_full["DISPLACED"] = risk_full["DISPLACED"].apply(lambda x: f"{float(x):,.0f}")
            risk_display = risk_full.rename(columns={
                "COUNTRY": "Country",
                "COUNTRY_CODE": "Code",
                "GDP_PER_CAPITA": "GDP/Cap",
                "INSURANCE_PENETRATION": "Ins Pen",
                "DISASTER_EXP": "Disaster Exp",
                "POPULATION": "Population",
                "DISPLACED": "Displaced"
            })
            st.table(risk_display.set_index("Country"))
    except Exception as e:
        st.warning(f"Country risk data unavailable: {e}")
