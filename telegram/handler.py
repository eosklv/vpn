import json
import os
import sys
import boto3
import datetime
import time

here = os.path.dirname(os.path.realpath(__file__))
sys.path.append(os.path.join(here, "./vendored"))

import requests

TELEGRAM_TOKEN = os.environ['TELEGRAM_TOKEN']
TELEGRAM_URL = f"https://api.telegram.org/bot{TELEGRAM_TOKEN}"

GH_AUTH = {"Authorization": f"Bearer {os.environ['GH_TOKEN']}"}
GH_OWNER = "eosklv"
GH_REPO = "vpn"
GH_WORKFLOW = "test.yml"
GH_URL = f"https://api.github.com/repos/{GH_OWNER}/{GH_REPO}"

S3_CLIENT = boto3.client('s3')
S3_BUCKET = "esklv-vpn"
S3_PROFILE = "profiles/client.ovpn"


def gh_dispatch(action=''):
    payload = json.dumps({"ref": "main", "inputs": {"action": action}})
    r = requests.post(GH_URL + f"/actions/workflows/{GH_WORKFLOW}/dispatches", headers=GH_AUTH, data=payload)
    return r.status_code


def gh_track(chat_id):
    t = (datetime.datetime.utcnow() - datetime.timedelta(minutes=2)).strftime("%Y-%m-%dT%H:%M")
    inprogress = True
    while inprogress:
        r = requests.get(GH_URL + f"/actions/runs?created=%3E{t}", headers=GH_AUTH)
        runs = r.json()["workflow_runs"]
        if len(runs) > 0:
            if runs[0]["status"] == "completed":
                send_message(chat_id, f"Completed, conclusion: {runs[0]['conclusion']}")
                inprogress = False
            else:
                send_message(chat_id, f"Still waiting, status: {runs[0]['status']}...")
                time.sleep(5)
        else:
            send_message(chat_id, "Still waiting...")
            time.sleep(5)


def send_message(chat_id, response, parse_mode=''):
    payload = {"text": response.encode("utf8"), "chat_id": chat_id}
    if parse_mode:
        payload["parse_mode"] = parse_mode
    url = TELEGRAM_URL + "/sendMessage"
    requests.post(url, data=payload)


def prefix_exits(bucket, prefix):
    res = S3_CLIENT.list_objects_v2(Bucket=bucket, Prefix=prefix)
    return 'Contents' in res


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
            if gh_dispatch() != 204:
                send_message(chat_id, "Cannot call GitHub, please check the logs.")
                raise Exception
            gh_track(chat_id)
            while not prefix_exits(S3_BUCKET, S3_PROFILE):
                send_message(chat_id, "Still waiting, status: preparing VPN profile")
                time.sleep(5)

            s = S3_CLIENT.generate_presigned_url('get_object', Params={'Bucket': S3_BUCKET, 'Key': S3_PROFILE},
                                                 ExpiresIn=300)
            send_message(chat_id, f"Your VPN profile is available by [this]({s}) link", "MarkdownV2")
            send_message(chat_id, "Bear in mind that this link is expiring in 5 minutes.")

        elif "thanks" in message or "thank you" in message:
            send_message(chat_id, "I know you’d do the same for me.")

        elif "destroy" in message.lower():
            send_message(chat_id, "I'll try my best, but can't promise... Hold on a moment...")
            if gh_dispatch('destroy') != 204:
                send_message(chat_id, "Cannot call GitHub, please check the logs.")
                raise Exception
            gh_track(chat_id)
            s = S3_CLIENT.delete_object(Bucket=S3_BUCKET, Key=S3_PROFILE)
            send_message(chat_id, "I've done my dirty work.")

        elif "bye" in message:
            send_message(chat_id, "Talk to you soon.")

        else:
            send_message(chat_id, "Thank you... Thank you for being so dumb!")
    except Exception as e:
        print(e)

    return {"statusCode": 200}
