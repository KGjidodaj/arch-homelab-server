#!/bin/bash

source .env
export RESTIC_PASSWORD="$Pass"
export RCLONE_CONFIG="$rclone"

restic -r rclone:arch_google_drive:HomelabBackup backup "$location/containers" > /dev/null
