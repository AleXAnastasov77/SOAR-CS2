import json, boto3, os

def lambda_handler(event, context):
    ip = event.get("ip")
    malicious = event.get("malicious", False)

    # === safety check ===
    if not malicious:
        print(f"Skipping {ip} — not marked as malicious by MISP.")
        return {"status": "skipped", "ip": ip}

    ec2 = boto3.client("ec2")
    blocked = []

    # block across all SGs
    for sg in ec2.describe_security_groups()["SecurityGroups"]:
        try:
            ec2.authorize_security_group_ingress(
                GroupId=sg["GroupId"],
                IpPermissions=[{
                    "IpProtocol": "-1",
                    "FromPort": -1,
                    "ToPort": -1,
                    "IpRanges": [{"CidrIp": f"{ip}/32", "Description": "Blocked by SOAR"}]
                }]
            )
            blocked.append(sg["GroupId"])
        except Exception as e:
            print(f"{sg['GroupId']} skip/error: {e}")

    return {"status": "blocked", "ip": ip, "groups": blocked}

if __name__ == "__main__":
    # mock event payloads
    safe_event = {
        "ip": "8.8.8.8",
        "malicious": False
    }

    bad_event = {
        "ip": "185.14.31.98",
        "malicious": True
    }

    # simulate run
    print("\n--- Safe IP test ---")
    print(json.dumps(lambda_handler(safe_event, None), indent=2))

    print("\n--- Malicious IP test ---")
    print(json.dumps(lambda_handler(bad_event, None), indent=2))