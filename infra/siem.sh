#!/bin/bash
sleep 30
sudo /usr/share/elasticsearch/bin/elasticsearch-reset-password -u elastic --batch | sudo tee /root/elastic_pass.txt > /dev/null
sudo /usr/share/elasticsearch/bin/elasticsearch-reset-password -u kibana_system --batch | sudo tee -a /root/elastic_pass.txt > /dev/null

