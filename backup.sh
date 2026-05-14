#!/bin/bash

source .env 

Backup_dest="/mnt/usb_backup"
Source_dir="$location"
Date=$(date +%F)

echo -e "Mounting USB drive.../n"
mount $Backup_dest

if mountpoint -q $Backup_dest;then #checking mounting in the background
	echo "Mount succesful. Starting archive..."

	#keeping permissions and compressing the archive
	tar -czpPf "$Backup_dest/homelab_backup_$DATE.tar.gz" "$Source_dir"
	if [ $? -eq 0 ]; then #checking exit code
		echo "Backup completed succesfully: Date=$Date"
	else
		echo "ERROR: tar failed"
	fi

	echo " Unmounting USB" #using umount for security
	umount $Backup_dest
	echo "Done unmounting"
else
	echo "ERROR: mountpoint failed usb not found or mount failed"
	exit 1 #failure exit code
fi

