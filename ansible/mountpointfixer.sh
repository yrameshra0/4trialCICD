#!/bin/bash

emptyMountPointers=$(lsblk -P | grep "TYPE=\"disk\"" | grep "MOUNTPOINT=\"\"")
regex="NAME=\"(.+?)\""
for f in $emptyMountPointers
do
    if [[ $f =~ $regex ]]
    then
        name="/dev/${BASH_REMATCH[1]}"
        nonBootDisk=$(fdisk -lo Boot "$name" | grep "Boot" | wc -l)
        echo "$name Boot Check Result: $nonBootDisk"
        if [  $nonBootDisk -eq 0 ] 
        then
            fileSystemExsists=$(blkid | grep "$name" | wc -l )
            if [  $fileSystemExsists -eq 0 ] 
            then
               mkfs -t ext4 "$name" 
            fi
            mkdir -p /opt/persistent_data
            mount "$name" /opt/persistent_data
            echo "$name"  /opt/persistent_data ext4  defaults,nofail 0 2 >> /etc/fstab
        fi  
       
    fi
done
