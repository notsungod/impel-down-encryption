# impel-down-encryption
THE WHOLE DRIVE IS ENCRYPTED!!! 
Most (ALL i know of) Full Disk Encryption setups miss the _Full Disk Encryption_ point by not encrypting a tiny (often grub) +-1Mb partition.
By doing so you are merely fixing the problem of partial encryption but just transforming it.

Impel Down Encryption is a real **Full Disk Encryption** by ACTUALLY not leaving ANY partition unencrypted on the drive.

Moreover the /boot partition is locked after booting to prevent Evil Maid attacks.
This means when shutdown an external attacker cant inject any keyloggers (or similar) into your unencrypted partitions (because there literally are non). Additionally when booted into the system the kernel on the boot partition can not be touched by internal attacks because the boot partition is unmounted and in an encrypted state.
## How it works



## Prerequisites
1. Impel Down Encryption ONLY works if you have GRUB (or similar) on your BIOS chip. _Libreboot is recommended (check if your device is compatible)._
2. Thats it, now you are good to go.

## Setup / Installation
(to be added)
You can read through the ```installer.sh``` as it is well documented with comments for now.

## Yubikey Support
If you have a Yubikey you can set it up to create a 2FA password.

## Please open Issues and Pull Requests
Please interact to improve this project and our security.

## Also worth reading
https://wiki.parabola.nu/Installing_Parabola_on_Libreboot_with_full_disk_encryption_(including_/boot)
https://wiki.archlinux.org/title/Dm-crypt/System_configuration#cryptkey
