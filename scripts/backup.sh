#!/bin/bash

# shellcheck disable=SC1091
source "$HOME/.env"

Backup_dest="/mnt/usb_backup"
# shellcheck disable=SC2154
Source_dir="$location"
Date=$(date +%F)

echo -e "Mounting USB drive...\n"
sudo mount "$Backup_dest" #using uuid on fstab

if mountpoint -q "$Backup_dest";then #checking mounting in the background
	echo "Mount succesful. Starting archive..."

	#keeping permissions and compressing the archive
	if sudo rsync -av --delete  "$Source_dir" "$Backup_dest/homelab_backup"; then
		echo "Backup completed succesfully: Date=$Date"
	else
		echo "ERROR: rsync failed"
	fi

	echo " Unmounting USB" #using umount for security
	sudo umount "$Backup_dest"
	echo "Done unmounting"
else
	echo "ERROR: mountpoint failed usb not found or mount failed"
	exit 1 #failure exit code
fi

