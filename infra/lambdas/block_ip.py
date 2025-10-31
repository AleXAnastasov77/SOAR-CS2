import json
import boto3

def lambda_handler(event, context):
    """
    Blocks a malicious IP by removing its ingress from all Security Groups.
    Input:  {"ip": "x.x.x.x"}
    Output: {"ip": ..., "blocked_in": [sg_ids], "errors": []}
    """
    ip = event.get("ip")
    if not ip:
        return {"error": "Missing IP parameter"}

    ec2 = boto3.client("ec2")
    blocked_in = []
    errors = []

    try:
        # List all security groups
        sgs = ec2.describe_security_groups()["SecurityGroups"]

        for sg in sgs:
            sg_id = sg["GroupId"]
            ingress = sg.get("IpPermissions", [])

            for rule in ingress:
                for ip_range in rule.get("IpRanges", []):
                    if ip in ip_range.get("CidrIp", ""):
                        try:
                            ec2.revoke_security_group_ingress(
                                GroupId=sg_id,
                                IpProtocol=rule.get("IpProtocol", "-1"),
                                FromPort=rule.get("FromPort"),
                                ToPort=rule.get("ToPort"),
                                CidrIp=ip_range["CidrIp"]
                            )
                            print(f"[BLOCK_IP] Revoked {ip_range['CidrIp']} in {sg_id}")
                            blocked_in.append(sg_id)
                        except Exception as e:
                            errors.append(f"{sg_id}: {str(e)}")

        return {
            "ip": ip,
            "blocked_in": blocked_in,
            "errors": errors
        }

    except Exception as e:
        return {"ip": ip, "blocked_in": blocked_in, "error": str(e)}
