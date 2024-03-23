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


def handler(event, context):
    try:
        data = json.loads(event["body"])
        message = str(data["message"]["text"]).lower()
        chat_id = data["message"]["chat"]["id"]
        first_name = data["message"]["chat"]["first_name"]

        if "start" in message:
            response = f"Long time no see, {first_name}!"

        elif "how are you" in message:
            response = "Not that bad! What are we doing today?"

        elif "run" in message:
            response = "Here we go... Hold on a second...\n"
            response += "Your VPN profile is available by the link:\n"
            s = s3_client.generate_presigned_url('get_object', Params = {'Bucket': 'esklv-vpn', 'Key': 'profiles/client.ovpn'}, ExpiresIn = 300)
            response += f"{s}\n"
            response += "This link is expiring in 5 minutes."

        elif "destroy" in message.lower():
            response = "I'll try my best, but can't promise... Hold on a second..."
            response += "I've done my dirty work.\n"
            
        else:
            response = "Thank you... Thank you for being so dumb!"

        data = {"text": response.encode("utf8"), "chat_id": chat_id}
        url = BASE_URL + "/sendMessage"
        requests.post(url, data)

    except Exception as e:
        print(e)

    return {"statusCode": 200}