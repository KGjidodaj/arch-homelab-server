#!/bin/bash

Disk=$(df -h / | awk 'END{print $5}' | tr -d '%') #free disk

RAM=$(free -m | awk '/Mem:/ {print $7}') #free ram

CPU=$(($(cat /sys/class/thermal/thermal_zone0/temp)/ 1000)) #cpu thermals

#Getting the url variable
source $HOME/.env

# according to usage and temp uptime-kuma will be alerted or just pinged
if [[ $Disk -lt 90 ]] && [[ $RAM -gt 150 ]] && [[ $CPU_TEMP -lt 80 ]];then #
	curl -s "${url}up&msg=Temp:${CPU}C_RAM:${RAM}MB_Disk:${Disk}%" >/dev/null
else
	curl -s "${url}down&msg=ALERT:_Temp:${CPU}C_RAM:${RAM}MB_Disk:${Disk}%" > /dev/null
fi


