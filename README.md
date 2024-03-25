
# Deploying VPN from Telegram

This project was created to demonstrate the capabilities of cloud engineering and process automation using various CI/CD and IaC tools.

Using simple commands in the telegram bot, the user can create his own free (within AWS Free Tier) OpenVPN server with a dedicated public IP address in the selected region. He can also configure this VPN server without connecting via SSH. When the work is done, the entire infrastructure can be automatically destroyed.

<a href="url"><img src="images/screenshot.png?raw=true" align="center" height=55% width=55% ></a>
## Tech Stack

**Cloud:** AWS

**IaC:** Terraform

**VPN Server:** OpenVPN, Ubuntu 22.04 LTS

**Telergam bot:** AWS Lambda (Python 3.10), AWS API Gateway

**CI/CD:** GitHub Actions, Serverless Framework, AWS S3

Technically, the process is structured as follows:

When receiving a new message, Telegram calls a webhook configured in AWS API Gateway which launches a handler function in AWS Lambda. This function is a Python script that is deployed using GitHub Actions and Serverless Framework.

Depending on the selected action the bot will respond and launch a corresponding Workflow in GitHub Actions. This workflow will launch Terraform to make changes to the current state of the AWS infrastructure, which includes VPN server itself, security groups, roles and IAM policies. There's a bash script integrated in user data of EC2 instance which installs the necessary software, prepares the Certification Authority, as well as certificates and keys for the server and client. Then it configures network and firewall to accept IP forwarding and incoming traffic on a required port (443 by default). Eventually, the complete VPN profile is generated and uploaded to AWS S3, and the download link is provided to a user by Telegram bot.

<a href="url"><img src="images/diagram.png?raw=true" align="center" height=99% width=99% ></a>
## Author

- [Eugeny Sokolov](https://linkedin.com/in/esklv)

