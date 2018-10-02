#!/bin/bash

$PROCESS = $1

case $PROCESS in
    "restore")
        /root/restore.sh
        ;;
    *)
        /root/backup.sh
        ;