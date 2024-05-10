#!/bin/bash
# this will install arch linux with linux-hardened kernel
# will boot with impel-down-encryption (full disk encryption incl /boot only openable in grub bios or similar)

# Ask the user if they want to continue
echo "You need to connect to the internet before starting this script! Run nmtui for interactive menu & You need to setup 3 partitions. One fat32 <>; one swap partition and one root partition ext4."
echo "If you want to use a yubikey, have it ready with static password (more information in README)."
echo -n "Do you want to continue? (Y/n) "
read answer
if [[ "$answer" == "y" ]] || [[ -z "$answer" ]]; then
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

# Define partitions
lsblk
read -p "Enter boot partition (e.g. /dev/sda1): " efistub_partition
read -p "Enter encrypted swap partition (e.g. /dev/sda2): " swap_partition
read -p "Enter encrypted root partition (e.g. /dev/sda3): " root_partition
# timedatectl

# create key-file
dd bs=512 count=4 if=/dev/urandom of=./notnothing iflag=fullblock

# Setting up partitions
#root
cryptsetup -y -v luksFormat $root_partition ./notnothing
cryptsetup open $root_partition root --key-file ./notnothing
mkfs.ext4 /dev/mapper/root

#swap
mkfs.ext2 -L cryptswap $swap_partition 1M

#boot
echo ""
echo "---------------------------------------"
echo "---------------------------------------"
echo "---------------------------------------"
echo "---------------------------------------"
echo "---------------------------------------"
echo "NOW CREATE PASSPHRASE WITH YOUR YUBIKEY"
echo "---------------------------------------"
echo "---------------------------------------"
echo "---------------------------------------"
echo "---------------------------------------"
echo "---------------------------------------"
echo ""
cryptsetup -y -v luksFormat $efistub_partition
cryptsetup open $efistub_partition boot
mkfs.fat -F 32 /dev/mapper/boot

#mount
mount /dev/mapper/root /mnt
mount --mkdir /dev/mapper/boot /mnt/boot

# move key-file to chroot
mkdir /mnt/etc
mv ./notnothing /mnt/etc/

#gen root
pacman-key --init
pacman-key --populate archlinux
pacstrap -K /mnt base linux-hardened linux-firmware
echo "swap         UUID=$(blkid -s UUID -o value $swap_partition)     /dev/urandom            swap,offset=2048,cipher=aes-xts-plain64,size=512" >> /mnt/etc/crypttab
echo "/dev/mapper/swap  none   swap    defaults   0       0" >> /mnt/etc/fstab
echo "proc /proc proc nosuid,nodev,noexec,hidepid=2,gid=proc 0 0">>/mnt/etc/fstab

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
sed -i 's/HOOKS=(base udev autodetect microcode modconf kms keyboard keymap consolefont block filesystems fsck)/HOOKS=(base udev autodetect microcode modconf kms keyboard keymap consolefont block encrypt filesystems fsck)/g' \"/etc/mkinitcpio.conf\"
sed -i 's/FILES=()/FILES=\"\/etc\/notnothing\"/g' \"/etc/mkinitcpio.conf\"
mkinitcpio -P
chmod 000 /etc/notnothing
echo \"umask 0077\">>/etc/profile
echo \"Enter ROOT password: \"
passwd
"
# Finish
echo "Setup completed successfully! You can REBOOT now."
