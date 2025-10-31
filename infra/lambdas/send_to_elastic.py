import json
import requests

def lambda_handler(event, context):
    """
    Send the SOAR event summary to Elasticsearch index 'soar-alerts'.
    """
    elastic_url = "http://siem.innovatech.internal:9200/soar-alerts/_doc"

    # event already contains full workflow data
    try:
        r = requests.post(elastic_url, json=event, timeout=10)
        r.raise_for_status()
        return {"status": "sent_to_elastic", "elastic_result": r.json()}
    except Exception as e:
        return {"error": str(e)}
if __name__ == "__main__":
    print(json.dumps(lambda_handler({
        'ip': '185.14.31.98',
        'malicious': True,
        'blocked': True,
        'case_id': 'test123'
    }, None), indent=2))
