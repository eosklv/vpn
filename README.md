
# Deploying VPN from Telegram

This project was created to demonstrate the capabilities of cloud engineering and process automation using various CI/CD and IaC tools.

Using simple commands in the telegram bot, the user can create his own free (within AWS Free Tier) OpenVPN server with a dedicated public IP address in the selected region. He can also configure this VPN server without connecting via SSH. At the end of the work, the entire infrastructure will be automatically destroyed.
## Tech Stack

**Cloud:** AWS

**IaC:** Terraform

**VPN Server:** OpenVPN, Ubuntu 22.04 LTS

**Telergam bot:** AWS Lambda (Python 3.11), AWS API Gateway

**CI/CD:** GitHub Actions, Serverless Framework, AWS S3

Technically, the process is structured as follows:

When receiving a new message, Telegram calls a webhook.
Behind its URL there's an AWS API Gateway which launches a handler function in AWS Lambda. This fucntion is a Python script that is deployed using GitHub Actions and Serverless Framework.

Depending on the selected action, the bot can either respond with a message or launch another Workflow in GitHub Actions. This workflow will launch Terraform to make changes to the current state of the AWS infrastructure, which includes, in addition to the VPN server itself, security groups, roles and IAM policies. There's user data integrated in EC2 instance as a Bash script which installs the necessary software, prepares the Certification Authority, as well as certificates and keys for the server and client. Then it configures system, access and firewall. After that, the complete VPN profile is generated and uploaded to AWS S3, and the download link is provided to a user by Telegram bot.
## Authors

- [Eugeny Sokolov](https://linkedin.com/in/esklv)

