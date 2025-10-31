import json
import boto3
import requests

def get_secrets():
    """Retrieve TheHive credentials from AWS Secrets Manager."""
    client = boto3.client("secretsmanager")
    secret = client.get_secret_value(SecretId="soar")
    return json.loads(secret["SecretString"])


def lambda_handler(event, context):
    """
    Create a case in TheHive.
    Input:  {"title": "...", "description": "...", "severity": 2}
    Output: {"case_id": "...", "case_title": "..."}
    """
    secrets = get_secrets()
    thehive_key = secrets["/soar/thehive_api_key"]
    thehive_url = secrets["/soar/thehive_url"]

    title = event.get("title", f"SOAR Alert: {event.get('ip', 'unknown')}")
    description = event.get("description", "Automated alert from SOAR system.")
    severity = event.get("severity", 2)

    headers = {
        "Authorization": f"Bearer {thehive_key}",
        "Content-Type": "application/json"
    }

    payload = {
        "title": title,
        "description": description,
        "severity": severity,
        "tlp": 2,
        "pap": 2,
        "status": "Open"
    }

    try:
        r = requests.post(f"{thehive_url}/api/case", headers=headers, json=payload, timeout=10)
        r.raise_for_status()
        data = r.json()
        return {"case_id": data.get("id"), "case_title": title}

    except Exception as e:
        return {"error": str(e), "title": title}
if __name__ == "__main__":
    print(json.dumps(lambda_handler({
        'title': 'Test Case',
        'description': 'Manual test from local run'
    }, None), indent=2))
