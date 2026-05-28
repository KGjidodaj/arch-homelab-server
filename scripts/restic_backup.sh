#!/bin/bash

source .env
#shellcheck disable=SC2154
export RESTIC_PASSWORD="$Pass"
#shellcheck disable=SC2154
export RCLONE_CONFIG="$rclone"
#shellcheck disable=SC2154
restic -r rclone:arch_google_drive:HomelabBackup backup "$location/containers" > /dev/null
