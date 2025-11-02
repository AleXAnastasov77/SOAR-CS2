import json
import boto3
import os

def lambda_handler(event, context):
    """
    Publish a notification via SNS with workflow results.
    Input:  {"ip": "...", "malicious": bool, "case_id": "...", "blocked": bool}
    """
    sns = boto3.client("sns")
    topic_arn = os.environ.get("TOPIC_ARN")

    subject = f"SOAR Alert - {event.get('ip', 'Unknown IP')}"
    case = event.get("create_case", {})
    block = event.get("block_ip", {})

    message = {
        "IP": event.get("ip"),
        "Malicious": event.get("malicious", False),
        "Blocked": block.get("blocked", False),
        "Case ID": case.get("case_id", "N/A"),
        "Context": case.get("context", "N/A")
    }

    try:
        sns.publish(
            TopicArn=topic_arn,
            Subject=subject,
            Message=json.dumps(message, indent=2)
        )
        print(f"Notification sent for {event.get('ip')}")
        return {"status": "notification_sent", "ip": event.get("ip")}
    except Exception as e:
        return {"error": str(e)}
if __name__ == "__main__":
    print(json.dumps(lambda_handler({
        'ip': '185.14.31.98',
        'malicious': True,
        'blocked': True,
        'case_id': 'test123'
    }, None), indent=2))
