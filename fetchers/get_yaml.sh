#!/bin/sh
#
#Script to scp today's yaml file from bloomies
#
fetcher=bluefly
cd /home/phyo/workspace/fetchers/yaml_feeds/us/$fetcher
filename="`date '+%y%m%d'`"
scp -i /home/phyo/.ssh/SITM deploy@staging.xxxx.com:/usr/local/salemail/yaml_feeds/$fetcher/$filename.yml .
cd /home/phyo/workspace/fetchers
