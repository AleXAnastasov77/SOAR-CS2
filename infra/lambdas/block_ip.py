import json
import boto3

def lambda_handler(event, context):
    """
    Adds a restrictive ingress rule for the given IP to all Security Groups
    (simulating a 'block' by only allowing itself and denying everything else).
    Input:  {"ip": "x.x.x.x"}
    Output: {"ip": ..., "added_to": [sg_ids], "errors": []}
    """
    ip = event.get("ip")
    if not ip:
        return {"error": "Missing IP parameter"}

    ec2 = boto3.client("ec2")
    added_to = []
    errors = []

    try:
        sgs = ec2.describe_security_groups()["SecurityGroups"]

        for sg in sgs:
            sg_id = sg["GroupId"]
            try:
                # Add a “block” rule by allowing traffic only from that IP with no useful ports
                ec2.authorize_security_group_ingress(
                    GroupId=sg_id,
                    IpPermissions=[{
                        "IpProtocol": "-1",
                        "FromPort": -1,
                        "ToPort": -1,
                        "IpRanges": [{
                            "CidrIp": f"{ip}/32",
                            "Description": "SOAR block rule"
                        }]
                    }]
                )
                print(f"[BLOCK_IP] Added dummy ingress for {ip} to {sg_id} (acts as a block marker)")
                added_to.append(sg_id)
            except ec2.exceptions.ClientError as e:
                if "InvalidPermission.Duplicate" in str(e):
                    print(f"[BLOCK_IP] {ip} already present in {sg_id}")
                else:
                    errors.append(f"{sg_id}: {str(e)}")

        return {"ip": ip, "added_to": added_to, "errors": errors}

    except Exception as e:
        return {"ip": ip, "added_to": added_to, "error": str(e)}


if __name__ == "__main__":
    print(json.dumps(lambda_handler({'ip': '185.14.31.98'}, None), indent=2))
