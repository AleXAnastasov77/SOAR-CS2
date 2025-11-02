import json
import boto3
from pymisp import PyMISP

# === False positives (known safe IPs) ===
FALSE_POSITIVES = {
    "8.8.8.8", "8.8.4.4",          # Google DNS
    "1.1.1.1", "1.0.0.1",          # Cloudflare DNS
    "9.9.9.9",                     # Quad9
    "208.67.222.222", "208.67.220.220"  # OpenDNS
}


def get_secrets():
    """Retrieve MISP credentials securely from AWS Secrets Manager."""
    client = boto3.client("secretsmanager")
    secret = client.get_secret_value(SecretId="soar")
    return json.loads(secret["SecretString"])


def lambda_handler(event, context):
    """
    Check if an IP is malicious using MISP (via PyMISP).
    Input:  {"ip": "x.x.x.x"}
    Output: {"ip": ..., "malicious": bool, "context": str | None}
    """
    secrets = get_secrets()
    misp_key = secrets["/soar/misp_api_key"]
    misp_url = secrets["/soar/misp_url"]
    misp_verifycert = False  # self-signed in your Docker setup

    ip = event.get("ip")
    if not ip:
        return {"error": "Missing 'ip' parameter"}

    # Skip known benign IPs
    if ip in FALSE_POSITIVES:
        return {"ip": ip, "malicious": False, "context": None}

    try:
        # Initialize MISP client
        misp = PyMISP(misp_url, misp_key, misp_verifycert, debug=False)

        # Perform attribute search
        result = misp.search(controller="attributes", value=ip)

        # If no result or empty attributes
        if not result or "Attribute" not in result or len(result["Attribute"]) == 0:
            return {"ip": ip, "malicious": False, "context": None}

        # Filter and validate attributes
        context_info = None
        malicious_flag = False

        for attr in result["Attribute"]:
            # Skip false-positive or noisy tags
            if any(tag.lower() in str(attr.get("Tag", "")).lower()
                   for tag in ["false-positive", "test", "benign", "sinkhole", "dns"]):
                continue

            # Check category or IDS flag
            if attr.get("to_ids", False):
                event_info = attr.get("Event", {}).get("info", "Suspicious indicator")
                context_info = event_info
                malicious_flag = True
                break

        return {**event, "malicious": malicious_flag}

    except Exception as e:
        return {"error": str(e), "ip": ip, "malicious": False, "context": None}


# === Local testing ===
# if __name__ == "__main__":
#     print(json.dumps(lambda_handler({'ip': '45.153.160.140'}, None), indent=2))
#     print(json.dumps(lambda_handler({'ip': '8.8.8.8'}, None), indent=2))
