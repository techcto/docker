#!/bin/bash

/root/init.sh

if [ "$PROCESS" == "restore" ]; then
    /root/.duply/restore.sh
else
    /root/.duply/backup.sh
fi

tail -f /dev/null