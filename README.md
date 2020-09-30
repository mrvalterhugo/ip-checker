# ip-checker
Bash script to be used on linux systems with AWS Route53.
It will updated Route53 entries when IP has changed.
It will then send a notification when a change is made.
You need to update the script with your own settings - Zone ID - Hostname - SNS Topic ARN
You also need to configure a IAM User/Role with Route53 and SNS permission.
Needs to be added to crontab for automated checks.
