# Requirments
Please install these packages on your machine before move forward:
1- zstd
2- cpio
3- dpkg
4- xorriso

> VC legacy version used for old hp servers: G5, G6, G7, G8
> Code version is: 7VC1VC2

## Using this script
Structure cli:
```
sudo bash iso-builder.sh <installer> <manager> <iso> <working-dir>
```

Example:

1. `7.0-1: sudo bash iso-builder.sh "/home/$USER/Public/Projects/DibaTech/diba-vc-installer" "/home/$USER/Public/Projects/DibaTech/diba-vc-engine" "/home/$USER/Public/OS/proxmox-ve_7.0-1.iso" "/home/$USER/Desktop/test-iso" "Diba VC 1.0.0"`

2. `7.2-1: sudo bash iso-builder.sh "/media/$USER/Other/Projects/diba-vc-installer" "/media/$USER/Other/Projects/diba-vc-engine" "/media/$USER/Other/OS/proxmox-ve_7.2-1.iso" "/home/$USER/Desktop/diba-vc-iso" "Diba VC 1.1.1"`


## Check services
```
1. tail /var/log/daemon.log
2. systemctl status 'pve*'
3. pvereport -v
```

## Find somethings
```
1. for f in *.deb; do sudo dpkg -X $f "$f"-unpack/; done
2. echo `sudo grep -rn 'The Proxmox VE cluster filesystem' *-unpack` > ~/Desktop/ll.log
3. git diff --name-only HEAD HEAD~2
```
## TODO for changes
1- the main thing is adding version to specific branch on the diba vc engine side!

### in pve-base
1. Change Hostname:  /etc/hostname
