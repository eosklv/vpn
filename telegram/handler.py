import json
import os
import sys
import boto3

here = os.path.dirname(os.path.realpath(__file__))
sys.path.append(os.path.join(here, "./.vendored"))

import requests

TOKEN = os.environ['TELEGRAM_TOKEN']
BASE_URL = "https://api.telegram.org/bot{}".format(TOKEN)

s3_client = boto3.client('s3')


def send_message(chat_id, response, parse_mode = False):
    data = {"text": response.encode("utf8"), "chat_id": chat_id}
    if parse_mode:
        data["parse_mode"] = parse_mode
    url = BASE_URL + "/sendMessage"
    requests.post(url, data)

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
            s = s3_client.generate_presigned_url('get_object', Params = {'Bucket': 'esklv-vpn', 'Key': 'profiles/client.ovpn'}, ExpiresIn = 300)
            send_message(chat_id, f"Your VPN profile is available by [this]({s}) link", "MarkdownV2")
            send_message(chat_id, "Bear in mind that this link is expiring in 5 minutes.")

        elif "thanks" in message or "thank you" in message:
            send_message(chat_id, "I know you’d do the same for me.")

        elif "destroy" in message.lower():
            send_message(chat_id, "I'll try my best, but can't promise... Hold on a moment...")
            send_message(chat_id, "I've done my dirty work.")

        else:
            send_message(chat_id, "Thank you... Thank you for being so dumb!")



    except Exception as e:
        print(e)

    return {"statusCode": 200}