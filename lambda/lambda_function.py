import boto3
import json
import base64
import gzip
import os
import urllib3
import re

# Initialize AWS Clients
bedrock = boto3.client(service_name='bedrock-runtime', region_name='us-east-1')
http = urllib3.PoolManager()

def lambda_handler(event, context):
    try:
        # 1. Decode and decompress CloudWatch Logs data
        cw_data = event['awslogs']['data']
        compressed_payload = base64.b64decode(cw_data)
        uncompressed_payload = gzip.decompress(compressed_payload)
        payload = json.loads(uncompressed_payload)
        
        # 2. Extract the error message
        log_events = payload.get('logEvents', [])
        if not log_events:
            return {
                'statusCode': 200,
                'body': json.dumps({'message': 'No log events in payload'})
            }

        error_logs = "\n".join([event['message'] for event in log_events[:5]])
        
        print(f"Analyzing Logs: {error_logs}")

        # 3. Construct the Prompt for Nova Micro
        prompt = f"""
        You are a Senior DevOps Engineer. Analyze the following Nginx error log and provide:
        1. The Root Cause.
        2. A single Linux command to fix it.
        
        Log: {error_logs}
        
        Respond ONLY in JSON format like this:
        {{"cause": "description", "fix_command": "command"}}
        """

        # 4. Invoke Amazon Nova Micro
        model_id = "amazon.nova-micro-v1:0"
        
        body = json.dumps({
            "inferenceConfig": {
                "maxTokens": 300,
                "temperature": 0.1,
                "topP": 0.9
            },
            "messages": [
                {
                    "role": "user",
                    "content": [{"text": prompt}]
                }
            ]
        })

        response = bedrock.invoke_model(body=body, modelId=model_id)
        response_body = json.loads(response.get('body').read())
        
        # Extract the text from Nova response
        ai_text = response_body['output']['message']['content'][0]['text']
        
        # Clean the AI text (sometimes AI wraps JSON in ```json blocks)
        clean_json = ai_text.replace('```json', '').replace('```', '').strip()
        ai_analysis = parse_ai_analysis(clean_json)

        # 5. Send to Discord (THIS MUST BE CALLED INSIDE THE HANDLER)
        send_to_discord(ai_analysis)

        return {
            'statusCode': 200,
            'body': json.dumps(ai_analysis)
        }

    except Exception as e:
        print(f"ERROR: {str(e)}")
        return {'statusCode': 500, 'body': str(e)}

def send_to_discord(analysis):
    webhook_url = os.environ.get('DISCORD_WEBHOOK_URL', '').strip()
    if not webhook_url.startswith('https://discord.com/api/webhooks/'):
        raise ValueError('DISCORD_WEBHOOK_URL is missing or invalid')

    fields = [
        {"name": "Root Cause", "value": analysis.get('cause', 'Unknown')},
        {"name": "Suggested Fix", "value": f"`{analysis.get('fix_command', 'N/A')}`"},
        {"name": "Status", "value": "Waiting for manual approval via SSM..."}
    ]

    raw_output = analysis.get('raw_output')
    if raw_output:
        fields.append({
            "name": "Raw Model Output",
            "value": f"```{raw_output[:900]}```"
        })
    
    message = {
        "embeds": [{
            "title": "🚀 Project A.R.C.A. (Anomaly Root-Cause Analysis)",
            "description": "Infrastructure Intelligence & Event-Driven Remediation",
            "color": 15158332, 
            "fields": fields
        }]
    }
    
    encoded_msg = json.dumps(message).encode('utf-8')
    resp = http.request('POST', webhook_url, body=encoded_msg, headers={'Content-Type': 'application/json'})
    print(f"Discord Response: {resp.status}")
    if resp.status >= 300:
        raise RuntimeError(f"Discord webhook failed with status {resp.status}: {resp.data.decode('utf-8', errors='ignore')}")


def parse_ai_analysis(text):
    try:
        return json.loads(text)
    except json.JSONDecodeError:
        match = re.search(r'\{.*\}', text, re.DOTALL)
        if match:
            return json.loads(match.group(0))

        return {
            'cause': 'Model returned non-JSON output',
            'fix_command': 'Check CloudWatch logs and inspect the raw Bedrock response',
            'raw_output': text[:1000]
        }