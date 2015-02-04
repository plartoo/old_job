#!/bin/bash

# imports items fetched within <min> minutes on the remote host <remote>
# used to import items fetched on waymeet on staging

# usage: import-on-remote.sh <remote> <min>
# must be run from the items-with-details directory

HOST=$1
MIN=$2

### Only run a single import on Staging at a time, since it can get swamped easily
if [ "staging.xxxx.com" == $HOST ]; then
    NUM_RUNNING_IMPORTS=$((`pgrep -lf 'staging.xxxx.com.*import_search_items.rb' | wc -l`))
    if [ $NUM_RUNNING_IMPORTS -gt 0 ]; then
        exit 0
    fi
fi

rsync -az --files-from=<(find . -mmin -$MIN -name \*.yml) . $HOST:/tmp/search-imports/
ssh $HOST 'cd /usr/local/sitm/current/ && find /tmp/search-imports/ -type f -name \*.yml | xargs -L 1000 ./script/import_search_items.rb'
ssh $HOST 'rm -rf /tmp/search-imports/'
