#!/bin/bash

#shellcheck disable=SC1091
source .env

#shellcheck disable=SC2154
export RESTIC_PASSWORD="$Pass"

#shellcheck disable=SC2154
export RCLONE_CONFIG="$rclone"

#shellcheck disable=SC2154
# Cloning the backup to the specified google drive using restic and rclone for encryption.
restic -r rclone:arch_google_drive:HomelabBackup backup "$location/containers" > /dev/null
