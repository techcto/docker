#!/bin/sh
set -eo pipefail

$MOUNT = $1
$PASSWORD = $2

case $2 in
    restore)
        /root/restore.sh
        ;;
    *)
        /root/backup.sh
        ;