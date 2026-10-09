"""Upload simulated first-notice-of-loss (FNOL) claim events to the S3 landing bucket.

Each run writes one newline-delimited JSON object under claims/ with S3 PutObject;
the S3 event notification triggers Snowpipe, which loads RAW.LIVE_CLAIMS.
Book IDs come from RAW.POLICY_BOOKS (BK-0000..BK-0039). Values are seeded random.
"""
import argparse
import json
import random
import time
from datetime import datetime, timezone


def make_event(rng):
    refer = rng.random() < 0.1
    return {'book_id': f'BK-{rng.randint(0, 39):04d}',
            'event_ts': datetime.now(timezone.utc).strftime('%Y-%m-%dT%H:%M:%S.%f')[:-3],
            'claim_amount_usd': round((25000 if refer else 3000) * rng.lognormvariate(0, 0.5), 2),
            'doc_mismatch_pct': round(max(0.0, rng.gauss(7.5 if refer else 1.2, 0.8)), 2),
            'status': 'REFER' if refer else 'OK',
            'sent_ms': int(time.time() * 1000)}


def upload_request(bucket, events, now_ms):
    """Pure PutObject request for one FNOL batch; no credentials or network calls."""
    body = ''.join(json.dumps(event) + '\n' for event in events).encode()
    return {'Bucket': bucket, 'Key': f'claims/fnol-{now_ms}.json', 'Body': body,
            'ContentType': 'application/x-ndjson', 'ServerSideEncryption': 'AES256'}


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument('--account', required=True, help='AWS account ID that owns the landing bucket')
    ap.add_argument('--region', default='us-west-2')
    ap.add_argument('--prefix', default='apj-ins')
    ap.add_argument('--count', type=int, default=40)
    ap.add_argument('--seed', type=int)
    args = ap.parse_args()
    from setup_aws import names
    bucket = names(args.prefix, args.account, args.region)['bucket']
    import boto3
    s3 = boto3.client('s3', region_name=args.region)
    rng = random.Random(args.seed)
    request = upload_request(bucket, [make_event(rng) for _ in range(args.count)], int(time.time() * 1000))
    s3.put_object(**request)
    print(f"uploaded {args.count} FNOL claim events to s3://{bucket}/{request['Key']}; Snowpipe loads them within about a minute")


if __name__ == '__main__':
    main()
