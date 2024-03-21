import telebot
import subprocess
import os

token = os.environ["bot"]
bot = telebot.TeleBot(token)


@bot.message_handler(content_types=['text'])
def send_text(message):
    check = message.text.lower().replace('!', '')
    if check in ['hi', 'hello']:
        bot.send_message(message.chat.id, 'Long time no see, my dear!')

    elif check in ['bye', 'good bye', 'see you']:
        bot.send_message(message.chat.id, 'Talk to you soon!')

    elif check in ['start', 'run', 'go']:
        bot.send_message(message.chat.id, "Here we go... Hold on a second...")
        result = subprocess.run('terraform -chdir=../terraform/ apply -auto-approve', shell=True, capture_output=True)
        bot.send_message(message.chat.id, result.stdout.splitlines()[-5].decode("utf-8"))
        bot.send_message(message.chat.id, result.stdout.splitlines()[-1].decode("utf-8")[3:])
        # img = open('dict.txt', 'rb')
        # bot.send_photo(message.chat.id, img)

    elif check in ['stop', 'end', 'finish']:
        bot.send_message(message.chat.id, "OK, I'll do my best, but can't promise... Hold on a second...")
        result = subprocess.run('terraform -chdir=../terraform/ destroy -auto-approve', shell=True, capture_output=True)
        bot.send_message(message.chat.id, "Before leaving me, she said:")
        bot.send_message(message.chat.id, result.stdout.splitlines()[-2].decode("utf-8"))

    else:
        bot.send_message(message.chat.id, 'Thank you... Thank you for being so dumb!')


bot.polling()
