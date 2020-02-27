#!/bin/bash

pacman -U ~/pkgbuild/en_se-locale-*.pkg.tar.xz

vim /etc/locale.gen
echo "press enter to continue"
read

echo "# locale-gen"
locale-gen

echo "# TimeZone"
ln -sf /usr/share/zoneinfo/Europe/Stockholm /etc/localtime
ls -l -d /etc/localtime

echo "# hwclock"
hwclock --systohc

echo "# /etc/locale.conf"
echo 'LANG=en_DK.UTF-8
LC_COLLATE=C
' > /etc/locale.conf

echo "# /etc/vconsole.conf"
echo 'KEYMAP="sv-latin1"
' > /etc/vconsole.conf

echo "# /etc/hostname"
echo -n "Hostname: " ; read hostname
echo "$hostname" > /etc/hostname


echo "# /etc/hosts"
echo '127.0.0.1	localhost
::1		localhost
127.0.1.1	'"$hostname.localdomain	$hostname"'
' > /etc/hosts

mkinitcpio -p linux

passwd



echo
echo "grub-install --target=x86_64-efi --efi-directory=/boot/efi --bootloader-id=archlinux"
echo "mkinitcpio -p linux"
echo "vim /etc/default/grub  # GRUB_CMDLINE_LINUX_DEFAULT="" << video=1360=768"
echo '  Also on host: VBoxManage setextradata "<VM-name-in-VirtualBox>" "CustomVideoMode1" "1360x768x24"'
echo "grub-mkconfig -o /boot/grub/grub.cfg"
echo
echo "mkdir /boot/efi/EFI/boot"
echo "§grubx64.efi /boot/efi/EFI/boot/"
echo
echo "pacman -S virtualbox-guest-utils-nox  #virtualbox-guest-modules-arch"
echo "systemctl enable vboxservice"
echo
