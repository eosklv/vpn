import json
import os
import sys
import boto3
import time

here = os.path.dirname(os.path.realpath(__file__))
sys.path.append(os.path.join(here, "./vendored"))

import requests
import python_terraform

TELEGRAM_TOKEN = os.environ['TELEGRAM_TOKEN']
TELEGRAM_URL = f"https://api.telegram.org/bot{TELEGRAM_TOKEN}"

GH_TOKEN = os.environ['GH_TOKEN']
GH_URL = "https://api.github.com/repos/eosklv/vpn/dispatches"

s3_client = boto3.client('s3')


def github_call():
    payload = json.dumps({
      "event_type": "deploy_terraform",
      "client_payload": {
        "unit": False,
        "integration": True
      }
    })
    headers = {
      'Accept': 'application/vnd.github+json',
      'Authorization': f'Bearer {GH_TOKEN}',
      'X-GitHub-Api-Version': '2022-11-28',
      'Content-Type': 'application/json'
    }
    return requests.post(GH_URL, headers=headers, data=payload)

def downloadDirectoryFroms3(bucketName, remoteDirectoryName):
    s3_resource = boto3.resource('s3')
    bucket = s3_resource.Bucket(bucketName) 
    for obj in bucket.objects.filter(Prefix = remoteDirectoryName):
        if not os.path.exists(os.path.dirname(obj.key)):
            os.makedirs(os.path.dirname(obj.key))
        bucket.download_file(obj.key, obj.key)

def send_message(chat_id, response, parse_mode=False):
    payload = {"text": response.encode("utf8"), "chat_id": chat_id}
    if parse_mode:
        payload["parse_mode"] = parse_mode
    url = TELEGRAM_URL + "/sendMessage"
    requests.post(url, data=payload)


def handler(event, context):
    try:
        data = json.loads(event["body"])
        message = str(data["message"]["text"]).lower()
        chat_id = data["message"]["chat"]["id"]
        first_name = data["message"]["chat"]["first_name"]

        if "start" in message or "hi" in message or "hello" in message or "hey" in message:
            send_message(chat_id, f"Long time no see, {first_name}!")

        elif "how are you" in message:
            send_message(chat_id, "Not that bad! What are we doing today?")

        elif "run" in message:
            send_message(chat_id, "Here we go... Hold on a moment...")
            m = github_call()
            send_message(chat_id, m)
            s = s3_client.generate_presigned_url('get_object',
                                                 Params={'Bucket': 'esklv-vpn', 'Key': 'profiles/client.ovpn'},
                                                 ExpiresIn=300)
            send_message(chat_id, f"Your VPN profile is available by [this]({s}) link", "MarkdownV2")
            send_message(chat_id, "Bear in mind that this link is expiring in 5 minutes.")

        elif "thanks" in message or "thank you" in message:
            send_message(chat_id, "I know you’d do the same for me.")

        elif "destroy" in message.lower():
            send_message(chat_id, "I'll try my best, but can't promise... Hold on a moment...")
            send_message(chat_id, "I've done my dirty work.")

        elif "bye" in message:
            send_message(chat_id, "Talk to you soon.")

        else:
            send_message(chat_id, "Thank you... Thank you for being so dumb!")



    except Exception as e:
        print(e)

    return {"statusCode": 200}
