#!/bin/bash

if [ "$PROCESS" == "restore" ]; then
    /root/restore.sh
else
    /root/backup.sh
fi