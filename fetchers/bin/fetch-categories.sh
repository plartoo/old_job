#!/bin/sh

if [ "waymeet.sitm-ops.com" == $HOSTNAME ]; then
    PROCESS_LIMIT=5
else
    PROCESS_LIMIT=10
fi

if [ "www12.xxxx.com" == $HOSTNAME -o "www13.xxxx.com" == $HOSTNAME ]; then
   DATA_SENDER_SEND_TO="--data_sender_host 10.0.0.12"
   DATA_SENDER_SEND_TO_PORT="--data_sender_port 1230"
else
   DATA_SENDER_SEND_TO=""
   DATA_SENDER_SEND_TO_PORT=""
fi

# fetch all items from category pages
ruby bin/list-fetchers.rb 2>/dev/null | xargs -L 1 -P $PROCESS_LIMIT nice -19 bin/category_scrape.rb -i us $DATA_SENDER_SEND_TO $DATA_SENDER_SEND_TO_PORT -f  >/dev/null 2>&1

