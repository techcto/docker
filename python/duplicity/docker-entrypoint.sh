#!/bin/bash

case $PROCESS in
    "restore")
        /root/restore.sh
        ;;
    *)
        /root/backup.sh
        ;