import json, os, requests
from requests.auth import HTTPBasicAuth
from datetime import datetime, timezone
from collections.abc import MutableMapping

def flatten(d, parent_key='', sep='.'):
    """Recursively flatten a nested dictionary into a single-level dict."""
    items = []
    for k, v in d.items():
        new_key = f"{parent_key}{sep}{k}" if parent_key else k
        if isinstance(v, MutableMapping):
            items.extend(flatten(v, new_key, sep=sep).items())
        else:
            items.append((new_key, v))
    return dict(items)


def lambda_handler(event, context):
    # --- Env ---
    es_host  = os.environ.get("ES_HOST", "http://siem.innovatech.internal:9200")
    es_user  = os.environ.get("ES_USER", "elastic")
    es_pass  = os.environ.get("ES_PASS")
    es_index = os.environ.get("ES_INDEX", "soar-alerts")

    # --- Ensure timestamp ---
    doc = dict(event)  # shallow copy
    doc.setdefault("@timestamp", datetime.now(timezone.utc).isoformat())

    # --- Flatten nested fields for cleaner Elasticsearch indexing ---
    doc = flatten(doc)

    # --- Send ---
    url = f"{es_host}/{es_index}/_doc"
    try:
        r = requests.post(
            url, json=doc,
            auth=HTTPBasicAuth(es_user, es_pass),
            headers={"Content-Type": "application/json"},
            timeout=10,
            verify=False
        )
        r.raise_for_status()
        return {"status": "sent_to_elastic", "result": r.json()}
    except Exception as e:
        return {"error": str(e)}


if __name__ == "__main__":
    os.environ["ES_HOST"] = "https://siem.innovatech.internal:9200"
    os.environ["ES_USER"] = "elastic"
    os.environ["ES_PASS"] = "shield"
    os.environ["ES_INDEX"] = "soar-alerts"
    print(json.dumps(lambda_handler({
        "ip": "185.14.31.98",
        "malicious": True,
        "blocked": True,
        "create_case": {"case_id": "test123", "context": "Automated alert"},
        "block_ip": {"blocked": True}
    }, None), indent=2))
