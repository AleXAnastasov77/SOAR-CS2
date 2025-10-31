import json
import boto3

def lambda_handler(event, context):
    """
    Publish a notification via SNS with workflow results.
    Input:  {"ip": "...", "malicious": bool, "case_id": "...", "blocked": bool}
    """
    sns = boto3.client("sns")
    topic_arn = "arn:aws:sns:eu-central-1:YOUR_ACCOUNT_ID:soar_notifications"  # <-- Replace or inject via env var

    subject = f"SOAR Alert - {event.get('ip', 'Unknown IP')}"
    message = {
        "IP": event.get("ip"),
        "Malicious": event.get("malicious", False),
        "Blocked": event.get("blocked", False),
        "Case ID": event.get("case_id", "N/A"),
        "Context": event.get("context", None)
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
