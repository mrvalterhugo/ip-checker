#!/bin/bash

#Variable Declaration - Change These
HOSTED_ZONE_ID="Z05344444444ZOOVZD"
NAME="server.example.com."
TYPE="A"
TTL=60
date
#get current IP address
IP=$(curl http://checkip.amazonaws.com/ 2> /dev/null )
echo "Current IP is" $IP
#validate IP address (makes sure Route 53 doesn't get updated with a malformed payload)
if [[ ! $IP =~ ^[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}$ ]]; then
        exit 1
fi

#get current
sudo aws route53 list-resource-record-sets --hosted-zone-id $HOSTED_ZONE_ID | \
jq -r '.ResourceRecordSets[] | select (.Name == "'"$NAME"'") | select (.Type == "'"$TYPE"'") | .ResourceRecords[0].Value' > /tmp/current_route53_value

old_IP=$(cat /tmp/current_route53_value)

#check if IP is different from Route 53
if grep -Fxq "$IP" /tmp/current_route53_value; then
        echo "IP Has Not Changed, Exiting"
        echo "##########################################"
        exit 1
fi
echo "IP Changed, Updating Records"
echo "Old IP is: $old_IP"
echo "New IP is: $IP"

#prepare route 53 payload
cat > /tmp/route53_changes.json << EOF
   {
      "Comment":"Updated From DDNS Checker Shell Script - Linux PC",
      "Changes":[
        {
          "Action":"UPSERT",
          "ResourceRecordSet":{
            "ResourceRecords":[
              {
                "Value":"$IP"
              }
            ],
            "Name":"$NAME",
            "Type":"$TYPE",
            "TTL":$TTL
          }
        }
      ]
    }
EOF
#update records
sudo aws route53 change-resource-record-sets --hosted-zone-id $HOSTED_ZONE_ID --change-batch file:///tmp/route53_changes.json >> /home/user/ddns.log

sudo aws sns publish --topic-arn arn:aws:sns:eu-west-2:012955555416784255:ipcheck --message "EC2 server IP has changed from $old_IP to $IP. Route53 has been updated. Happy Days!! :)"
echo "##############################################"