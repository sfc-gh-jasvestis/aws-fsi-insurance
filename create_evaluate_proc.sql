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
