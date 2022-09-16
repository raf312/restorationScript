#!/bin/bash
#:Title             : Restoration script for Windows
#:Date              : jul 28 2022
#:Author            : raf312
#:Version           : 2.0.1
#:Description       : The script restores an SDA disk image taken on the SAMSUNG HD322HJ hard drive. Here the drive to be restored is SDA.

clear

_repeat() {
    #@ USAGE: _repeat string number
    _REPEAT=$1
    while ((${#_REPEAT} < $2)); do       ## Loop until string exceeds desired length
        _REPEAT=$_REPEAT$_REPEAT$_REPEAT ## 3 seems to be the optimum number
    done
    _REPEAT=${_REPEAT:0:$2} ## Trim to desired length
}

repeat() {
    _repeat "$@"
    printf "%s\n" "$_REPEAT"
}

alert() {
    _repeat "${2:-#}" $((${#1} + 6))
    printf '\a%s\n' "$_REPEAT" ## \a = BEL
    printf '%2.2s %s %2.2s\n' "$_REPEAT" "$1" "$_REPEAT"
    printf '%s\n' "$_REPEAT"
}

alert "WINDOWS 10 SYSTEM RESTORE"

printf "\nType 'y' to start the restore process.\n"
read resp
if [[ ${resp} = [yY] ]]; then
    for i in sda sdb sdc sdd sde sdf; do
        device=$(cat /sys/block/$i/device/model)
        hd_name='SAMSUNG HD322HJ'

        if [[ $device == *"$hd_name"* ]]; then
            echo "/dev/${i}1 /mnt/${i}1 ntfs-3g defaults 0 0" >> /etc/fstab
            mkdir /mnt/${i}1
            mount /dev/${i}1

            img=/mnt/${i}1/img
            recycle="\$RECYCLE.BIN"
            systeminfo="System Volume Information"
            cd /mnt/${i}1/
            echo $PWD

            printf "\n Do you want delete $recycle and $systeminfo folder? [y/N]: "
            read response
            if [[ $response == [yY] ]]; then
                rm -fr $recycle
                rm -fr "$systeminfo"
            else
                continue
            fi

            echo $PWD
            sleep 1

            while true; do
                printf "\n - Backup list: "
                ls $img
                
                printf "\n - Enter date of the backup to be restored: "
                read dataBackup
                if [[ -d $img/$dataBackup ]]; then
                    sudo partimage restore /dev/sda1 $img/$dataBackup/win10sda1.000 -b -e
                    sudo partimage restore /dev/sda3 $img/$dataBackup/win10sda3.000 -b -e
                    sudo partimage restore /dev/sda2 $img/$dataBackup/win10sda2.000 -b

                    cd $HOME
                    umount /dev/${i}1
                    break
                else
                    echo ''
                    printf " - Invalid backup folder."
                fi
            done
        fi
    done
else
    exit 0
fi

alert "SYSTEM REBOOT"

printf "\nType 'y' to reboot your computer...\n"
read resp
if [[ ${resp} = [yY] ]]; then
    printf "Rebooting...\n"
    
    printf "\a3\n"
    sleep 1
    printf "\a2\n"
    sleep 1
    printf "\a1...\n"
    sleep 1

    init 6
else
    exit 0
fi
