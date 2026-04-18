# Project A.R.C.A. (Anomaly Root-Cause Analysis)

Infrastructure Intelligence & Event-Driven Remediation

## Overview

Project A.R.C.A. is an event-driven root-cause analysis pipeline for EC2-hosted Nginx. It watches CloudWatch logs, sends error snippets to AWS Lambda, asks Amazon Bedrock to infer the likely root cause and fix, and posts the result to Discord.

## Problem

Standard monitoring tools can tell you that something is broken, but not why it broke. That leaves engineers manually searching logs, testing fixes, and increasing mean time to recovery.

## Solution

This project automates the first response loop:

1. Nginx writes errors to `/var/log/nginx/error.log`.
2. The CloudWatch Agent streams the log file to CloudWatch Logs.
3. A CloudWatch subscription filter invokes AWS Lambda.
4. Lambda decodes the log payload and sends it to Amazon Bedrock.
5. Bedrock returns a suggested root cause and fix command.
6. Lambda posts a formatted Discord notification.

## Architecture Diagram

<!-- Add architecture diagram here -->

## Tech Stack

- AWS EC2
- Amazon Linux 2023
- Nginx
- CloudWatch Logs and Subscription Filters
- AWS Lambda with Python 3.12
- Amazon Bedrock
- Discord webhooks
- Terraform

## Repository Structure

- `ec2.tf` - EC2 instance, security group, and user data bootstrap.
- `iam.tf` - IAM roles, policies, and instance profile.
- `main.tf` - Lambda packaging and function configuration.
- `monitoring.tf` - CloudWatch log group and subscription filter.
- `network.tf` - Default VPC, subnet, and routing resources.
- `provider.tf` - Terraform provider configuration.
- `lambda/lambda_function.py` - Log decoding, Bedrock analysis, and Discord notification logic.

## Prerequisites

- Terraform installed
- AWS credentials configured locally
- A Discord webhook URL
- Bedrock access enabled for the selected model in `us-east-1`

## Setup

1. Copy [terraform.tfvars.example](terraform.tfvars.example) to `terraform.tfvars`.
2. Set `discord_webhook_url` to your Discord webhook.
3. Run `terraform init`.
4. Run `terraform apply`.

## Testing

### One-click Lambda test

Use the payload in [lambda_test_event.json](lambda_test_event.json) as the Lambda test event. It contains a valid CloudWatch Logs `awslogs.data` payload.

### End-to-end EC2 test

Generate a real Nginx error on the EC2 instance, then confirm:

- CloudWatch receives the log event.
- Lambda runs without errors.
- Discord receives the remediation message.

## Notes

- Do not commit real webhook URLs.
- If you change the Lambda code, run `terraform apply` again so the zip package is rebuilt and deployed.
- The `terraform.tfstate` files in this workspace are local state artifacts and should not be committed.

## License

No license has been specified yet.
