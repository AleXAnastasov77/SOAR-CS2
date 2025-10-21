#!/bin/bash
sleep 30
/usr/share/elasticsearch/bin/elasticsearch-reset-password -u elastic --batch > /root/elastic_pass.txt
/usr/share/elasticsearch/bin/elasticsearch-reset-password -u kibana_system --batch >> /root/elastic_pass.txt
aws ssm put-parameter --name "/soar/elastic/password" --type "SecureString" --overwrite --value "$(grep elastic_password /root/elastic_pass.txt | cut -d'=' -f2)"
