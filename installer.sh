#!/bin/bash
# this will install arch linux with linux-hardened kernel
# will boot with impel-down-encryption (full disk encryption incl /boot only openable in grub bios or similar)

# Ask the user if they want to continue
echo "You need to connect to the internet before starting this script! Run nmtui for interactive menu & you need one large Linux partition (e.g. cfdisk tool simple Linux fs partition)"
echo -n "Do you want to continue? (Y/n) "
read answer
if [[ "$answer" == "Y" ]] || [[ "$answer" == "y" ]] || [[ -z "$answer" ]]; then
    echo "You chose to continue."
else
    echo "Aborting..."
    exit 1
fi

echo "Checking platform size..."
echo -n "Platform Size: "
cat /sys/firmware/efi/fw_platform_size

echo "Checking internet connection..."
if ping -c 1 8.8.8.8 &> /dev/null; then
    echo "You are connected to the internet!"
else
    echo "[ERROR] Not connected to the internet. Aborting..."
fi

# Define partition
lsblk
read -p "Enter Linux fs partition (e.g., /dev/sda1): " root_partition
# timedatectl

# Setting up partition
cryptsetup luksFormat $root_partition
cryptsetup open $root_partition lvm
pvcreate /dev/mapper/lvm
vgcreate matrix /dev/mapper/lvm
lvcreate -L 4G matrix -n swapvol
lvcreate -l +100%FREE matrix -n rootvol
mkswap /dev/mapper/matrix-swapvol
swapon /dev/matrix/swapvol
mkfs.ext4 /dev/mapper/matrix-rootvol
mount /dev/matrix/rootvol /mnt

#gen root
pacman-key --init
pacman-key --populate archlinux
pacstrap -K /mnt base linux-hardened linux-firmware

#chroot
arch-chroot /mnt /bin/bash -c "
pacman-key --init
pacman-key --populate archlinux
ln -sf /usr/share/zoneinfo/Europe/Berlin /etc/localtime
hwclock --systohc
echo \"en_US.UTF-8 UTF-8\">>/etc/locale.gen
locale-gen
echo \"LANG=en_US.UTF-8\">>/etc/locale.conf
echo \"KEYMAP=de-latin1\">>/etc/vconsole.conf
echo \"host\">>/etc/hostname
pacman -S --noconfirm lvm2
sed -i 's/HOOKS=(base udev autodetect microcode modconf kms keyboard keymap consolefont block filesystems fsck)/HOOKS=(base udev autodetect microcode modconf kms keyboard keymap consolefont block encrypt lvm2 filesystems fsck)/g' \"/etc/mkinitcpio.conf\"
mkinitcpio -P
echo \"umask 0077\">>/etc/profile
echo \"Enter ROOT password: \"
passwd
"

# Finish
echo "Setup completed successfully! You can REBOOT now."
