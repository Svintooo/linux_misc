#!/bin/bash
# Fixar massa bra saker i konsollen för när man kör zsh i archlinuxs installationboot.

vim /etc/pacman.conf
vim /etc/pacman.d/mirrorlist

echo "# ping"
ping -c 1 archlinux.org
echo

echo "# timedatectl"
timedatectl set-ntp true
timedatectl status
echo

echo -n "# UEFI boot mode? "
if [[ -d /sys/firmware/efi/efivars ]]; then
  echo yes
else
  echo no
fi
echo

echo "# Update pacman sources"
pacman -Sy
echo

echo "# Update archlinux-keyring"
pacman -S archlinux-keyring
echo

echo
echo "# Fixa partitioner och formatera dom"
echo "gdisk /dev/sd?  # 550MiB EF00 för UEFI, kör standard på resten."
echo "mkfs.fat -n EFI -F32 /dev/sd?1  # Detta formaterar UEFI-partitionen."
echo "mkfs.ext4 -L root /dev/sd?2  # Detta fixar linux-partitionen."
echo
echo "# ASDF"
echo "mount /dev/sda? /mnt"
echo "mkdir -p /mnt/boot/efi"
echo "mount /dev/sda? /mnt/bot/efi"
echo
echo "pacstrap /mnt $(head -n 1 list_of_good_pacstrap_packages.txt)"
echo "genfstab -U /mnt >> /mnt/etc/fstab"
echo "rsync -rv ~/tmp/skel/ /mnt/etc/skel/"
echo "rsync -rv ~/tmp/pkgbuild /mnt/root/"
echo "rsync -rv ~/tmp /mnt/root/"
echo "rsync -rv /mnt/etc/skel/ /mnt/root/"
echo "rsync -rv ~/tmp/profile.d/ /mnt/etc/profile.d/"
echo
echo "arch-chroot /mnt"
echo
