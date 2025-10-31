import json
import boto3

def lambda_handler(event, context):
    """
    Block a malicious IP (placeholder for future automation).
    Input:  {"ip": "x.x.x.x"}
    Output: {"ip": ..., "blocked": bool}
    """
    ip = event.get("ip")
    if not ip:
        return {"error": "Missing IP parameter"}

    # Example action: log the block event
    print(f"[BLOCK_IP] Blocking {ip} via firewall or AWS WAF automation...")

    # Future extension: integrate AWS WAF / Security Group updates
    # e.g. boto3.client('ec2').revoke_security_group_ingress(...)

    return {"ip": ip, "blocked": True}
