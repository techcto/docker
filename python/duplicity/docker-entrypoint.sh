#!/bin/bash

/root/init.sh

if [ "$PROCESS" == "restore" ]; then
    #This runs before restore
    mv $MOUNT/Client_Settings.xml $MOUNT/Client_Settings.xml.bak
    export PASSPHRASE=$GPG_PW
    export AWS_ACCESS_KEY_ID=$IAM_ACCESS_KEY
    export AWS_SECRET_ACCESS_KEY=$IAM_SECRET_KEY
    BUCKET=$BUCKET
    MOUNT=$MOUNT
    
    duplicity -t $TIME --force -v8 restore s3://s3.amazonaws.com/$BUCKET/ $MOUNT
    /root/.duply/restore.sh
else
    /root/.duply/backup.sh
fi

# tail -f /dev/null
echo "$PROCESS finished"
sleep 60