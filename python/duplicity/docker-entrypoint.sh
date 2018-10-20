#!/bin/bash

/root/init.sh

if [ "$PROCESS" == "restore" ]; then
    /root/.duply/initrestore.sh
    duplicity -t $TIME --force -v8 restore s3://s3.amazonaws.com/$BUCKET/ $MOUNT
    /root/.duply/restore.sh
else
    /root/.duply/backup.sh
fi

#tail -f /dev/null