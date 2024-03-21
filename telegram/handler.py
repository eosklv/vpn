import json
import os
import sys

here = os.path.dirname(os.path.realpath(__file__))
sys.path.append(os.path.join(here, "./vendored"))

import requests

TOKEN = os.environ['TELEGRAM_TOKEN']
BASE_URL = "https://api.telegram.org/bot{}".format(TOKEN)


def handler(event, context):
    try:
        data = json.loads(event["body"])
        message = str(data["message"]["text"])
        chat_id = data["message"]["chat"]["id"]
        first_name = data["message"]["chat"]["first_name"]

        if "hi" in message.lower():
            response = f"Long time no see, {first_name}!"

        elif "bye" in message.lower():
            response = "Talk to you soon!"

        elif "go" in message.lower():
            response = "Here we go... Hold on a second..."

        elif "stop" in message.lower():
            response = "I'll try my best, but can't promise... Hold on a second..."

        else:
            response = "Thank you... Thank you for being so dumb!"

        data = {"text": response.encode("utf8"), "chat_id": chat_id}
        url = BASE_URL + "/sendMessage"
        requests.post(url, data)

    except Exception as e:
        print(e)

    return {"statusCode": 200}
