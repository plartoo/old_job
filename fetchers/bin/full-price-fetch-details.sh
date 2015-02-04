#!/bin/sh

ITEM_LIMIT=$1
PROCESS_LIMIT=$2

# if [ "waymeet.sitm-ops.com" == $HOSTNAME ]; then
#    PROCESS_LIMIT=5
# else
#    PROCESS_LIMIT=20
# fi

if [ "www12.xxxx.com" == $HOSTNAME -o "www13.xxxx.com" == $HOSTNAME ]; then
   DATA_SENDER_SEND_TO="--data_sender_host 10.0.0.12"
   DATA_SENDER_SEND_TO_PORT="--data_sender_port 1230"
else
   DATA_SENDER_SEND_TO=""
   DATA_SENDER_SEND_TO_PORT=""
fi

ITEMS_TO_PASS=50

# fetch random sample of $ITEM_LIMIT full price item detail pages
TODAY=`date +"%Y-%m-%d"`
YESTERDAY=`ruby -e "puts Time.at(Time.now.to_i - 60*60*24).strftime(\"%Y-%m-%d\")"`
NUM_SCRAPERS_TO_START=$(($PROCESS_LIMIT - `pgrep -f "ruby bin/detail_scrape.rb" | wc -l`))
if [ $NUM_SCRAPERS_TO_START -gt 0 ]; then
    if [ -e ../shared/items/$TODAY ]; then
        SEARCH=../shared/items/$TODAY
    else
        SEARCH=../shared/items/$YESTERDAY
    fi
    (find  $SEARCH -type f -name \*.yml -mmin +5 | awk 'BEGIN{srand()}{print rand(),$0}' | sort -n | cut -d ' ' -f2- | head -n $ITEM_LIMIT | xargs -n $ITEMS_TO_PASS -P $NUM_SCRAPERS_TO_START nice -19 bin/detail_scrape.rb -i us $DATA_SENDER_SEND_TO $DATA_SENDER_SEND_TO_PORT  >/dev/null 2>&1)
fi