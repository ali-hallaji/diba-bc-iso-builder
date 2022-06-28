ROOT_DIR="$PWD"
INSTALLER_PATH=$1
ENGINE_PATH=$2
ISO_PATH=$3
WORKING_DIRECTORY=$4
ISO_SOURCE=$WORKING_DIRECTORY/diba-bc-source
PRODUCT_NAME=$5

# First stage
sudo umount $WORKING_DIRECTORY/mount
sudo rm -rf $WORKING_DIRECTORY
mkdir $WORKING_DIRECTORY 
cd $WORKING_DIRECTORY; mkdir mount
sudo dd if=$ISO_PATH bs=512 count=1 of=dibabc.mbr
sudo mount -o loop $ISO_PATH $WORKING_DIRECTORY/mount
rsync -av mount/ $ISO_SOURCE
sudo umount $WORKING_DIRECTORY/mount

# Making unsquash
echo "Starting unsquashing of pve installer file..."
cp --verbose -p $ISO_SOURCE/pbs-installer.squashfs $WORKING_DIRECTORY/
cd $WORKING_DIRECTORY; sudo unsquashfs -f -d diba-bc-installer pbs-installer.squashfs
sudo rm -rvf pbs-installer.squashfs

# CP to squash installer
cd $INSTALLER_PATH
sudo rm $WORKING_DIRECTORY/diba-bc-installer/usr/share/perl5/ProxmoxInstallerSetup.pm
sudo cp --verbose -p app-root/pm-files/DibaBCInstallerSetup.pm $WORKING_DIRECTORY/diba-bc-installer/usr/share/perl5/DibaBCInstallerSetup.pm
sudo chmod 644 $WORKING_DIRECTORY/diba-bc-installer/usr/share/perl5/DibaBCInstallerSetup.pm
sudo chown root:root $WORKING_DIRECTORY/diba-bc-installer/usr/share/perl5/DibaBCInstallerSetup.pm
sudo cp --verbose -p app-root/bin-scripts/dibainstall $WORKING_DIRECTORY/diba-bc-installer/usr/bin/proxinstall
sudo cp --verbose -p app-root/bin-scripts/unconfigured.sh $WORKING_DIRECTORY/diba-bc-installer/usr/sbin/unconfigured.sh
sudo chmod 755 $WORKING_DIRECTORY/diba-bc-installer/usr/sbin/unconfigured.sh
sudo chmod 755 $WORKING_DIRECTORY/diba-bc-installer/usr/bin/proxinstall
sudo rsync -avrP --no-owner --no-group --no-perms app-root/diba-installer/ $WORKING_DIRECTORY/diba-bc-installer/var/lib/proxmox-installer/
sudo rsync -a --no-owner --no-group --remove-source-files $WORKING_DIRECTORY/diba-bc-installer/var/lib/proxmox-installer/ $WORKING_DIRECTORY/diba-bc-installer/var/lib/diba-installer/

# Making initrd.img
echo "Making initrd.img..."
cd $ISO_SOURCE/boot
sudo cp --verbose -p initrd.img initrd.org.img
sudo zstd -d initrd.org.img -o initrd.unc
sudo mkdir tmp; cd tmp
sudo cpio -i -d < $ISO_SOURCE/boot/initrd.unc
cd $INSTALLER_PATH
sudo rsync -avrP --no-owner --no-group --no-perms app-root/initrd-files/ $ISO_SOURCE/boot/tmp/
sudo cp --verbose -p app-root/bin-scripts/unconfigured.sh $ISO_SOURCE/boot/tmp/sbin/unconfigured.sh
# sudo rsync -a --no-owner --no-group --remove-source-files $ISO_SOURCE/boot/tmp/.pbs-cd-id.txt $ISO_SOURCE/boot/tmp/.diba-bc-cd-id.txt
sudo chmod 755 $ISO_SOURCE/boot/tmp/sbin/unconfigured.sh
cd $ISO_SOURCE/boot/tmp
find . | cpio -H newc -o | zstd -19 > $ISO_SOURCE/boot/initrd.img
sudo rm -rvf $ISO_SOURCE/boot/initrd.org.img
sudo rm -rvf $ISO_SOURCE/boot/initrd.unc
sudo rm -rf $ISO_SOURCE/boot/tmp
echo "removed directory 'tmp'"

# Preparing deb packages and versions and Making them
echo "Preparing deb packages and versions and Making them... ."
cd $ISO_SOURCE/proxmox/packages
# MANAGER_NAME=$(find . -name "*pbs-manager*" -print)

# Making widget toolkit
# echo "Making Diba VC Making widget toolkit as deb package file (.deb)"
# sudo dpkg -X "$TOOLKIT_NAME" unpack-deb/
# sudo rsync -avrP --no-owner --no-group --no-perms $ENGINE_PATH/app-root/widget-toolkit/ unpack-deb/
# sudo dpkg-deb -e "$TOOLKIT_NAME" unpack-deb/DEBIAN/
# sudo dpkg-deb -b ./unpack-deb diba-bc-widget-toolkit_1.0-0_amd64.deb
# sudo rm -rf unpack-deb
# sudo chmod 555 diba-bc-widget-toolkit_1.0-0_amd64.deb
# sudo chown root:root diba-bc-widget-toolkit_1.0-0_amd64.deb
# echo "removed directory 'unpack-deb'"
# sudo rm -rvf "$TOOLKIT_NAME"
# echo "Finish TOOLKIT_NAME=$TOOLKIT_NAME"
# set -e

# $ISO_SOURCE/proxmox/packages
# Rename all proxmox names
for f in *proxmox*; do mv -v "$f" "${f/proxmox/diba-bc}"; done;

# make squash
echo "Making Squash from installer..."
cd $WORKING_DIRECTORY
sudo mksquashfs diba-bc-installer/ diba-bc-installer.squashfs
sudo rm -rvf $ISO_SOURCE/pbs-installer.squashfs

# Copy for making iso
cd $INSTALLER_PATH
sudo rsync -avrP --no-owner --no-group --no-perms app-root/boot/ $ISO_SOURCE/boot/
sudo rsync -avrP --no-owner --no-group --no-perms app-root/iso-root-files/ $ISO_SOURCE/
sudo cp --verbose -p $WORKING_DIRECTORY/diba-bc-installer.squashfs $ISO_SOURCE/
sudo chmod 644 $ISO_SOURCE/diba-bc-installer.squashfs
sudo chown root:root $ISO_SOURCE/diba-bc-installer.squashfs
# sudo rsync -a --no-owner --no-group --remove-source-files $ISO_SOURCE/.pbs-cd-id.txt $ISO_SOURCE/.diba-bc-cd-id.txt

# make squash base
echo "Making Squash base file from installer..."
sudo mv --verbose $ISO_SOURCE/pbs-base.squashfs $ISO_SOURCE/diba-bc-base.squashfs
sudo chmod 644 $ISO_SOURCE/diba-bc-base.squashfs
sudo chown root:root $ISO_SOURCE/diba-bc-base.squashfs

# Final steps
cd $WORKING_DIRECTORY
sudo rm -rvf diba-bc-installer.squashfs
sudo rm -rvf pbs-base.squashfs
sudo rm -rf diba-bc-installer
sudo rm -rf diba-bc-base
echo "removed directory 'diba-bc-installer' and 'diba-bc-base'"

# Making ISO file
echo "Making ISO starting..."
cd $ISO_SOURCE
sudo cp --verbose -p $ROOT_DIR/Packages proxmox/packages/
sudo chmod 444 proxmox/packages/Packages
sudo mv proxmox diba-bc
sudo xorriso -as mkisofs -o ../"$PRODUCT_NAME".iso -r -V "$PRODUCT_NAME" --grub2-mbr ../dibabc.mbr --protective-msdos-label -efi-boot-part --efi-boot-image  -c '/boot/boot.cat' -b '/boot/grub/i386-pc/eltorito.img' -no-emul-boot -boot-load-size 4 -boot-info-table --grub2-boot-info -eltorito-alt-boot -e '/efi.img' -no-emul-boot .
cd $WORKING_DIRECTORY
sudo rm -rf $ISO_SOURCE
echo "removed directory '$ISO_SOURCE'"
sudo rm -rvf dibabc.mbr
sudo rm -rvf mount
