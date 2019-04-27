# Arch Linux Installation Guide

Installation guide and basic configurations for Arch Linux

## Verify the boot mode

Check if the directory exists:

`ls /sys/firmware/efi/efivars`

## Connect to the internet

Connect to Wi-Fi network:

`wifi-menu`

Check if internet connectivity is available:

`ping -c 3 archlinux.org`

## Update the system clock

Ensure the system clock is accurate:

`timedatectl set-ntp true`

Check the service status:

`timedatectl status`

## Partition the disks

Identify disks:

`lsblk`

Disks are assigned to a *block device* such as `/dev/nvme0n1`.

Clean the entire disk (**do not** do this if you want to keep your data):

* `# gdisk /dev/nvme0n1`
* `x` for extra functionality
* `z` to *zap* (destroy) GPT data structures and exit
* `y` to proceed
* `y` to blank out MBR

Create boot partition and root partition:

* `# cfdisk /dev/nvme0n1`
* Select `gpt`
* Hit `[   New   ]` to create a new patition
* Give the boot partition `1G` and let the rest for the root partition
* Select the boot partition and hit `[   Type   ]` to choose `EFI System`
* Hit `[   Write   ]` then type `yes` to save, then hit `[   Quit   ]`

## Format the partitions

Format the boot partition to FAT32:

`mkfs.fat -F32 /dev/nvme0n1p1`

Format the root partition to ext4:

`mkfs.ext4 /dev/nvme0n1p2`

## Mount the file systems

Mount root partition first:

`mount /dev/nvme0n1p2 /mnt`

Then create mount point for boot partition and mount it accordingly:

`mkdir /mnt/boot`

`mount /dev/nvme0n1p1 /mnt/boot`

## Select the mirrors

Make a list of mirrors sorted by their speed then remove those from the list that are out of sync according to their [status](https://www.archlinux.org/mirrors/status/).

Backup the existing mirrorlist:

`cp /etc/pacman.d/mirrorlist /etc/pacman.d/mirrorlist.backup`

Edit the mirror list, bring the fastest mirrors to the top.
For example this is my top 3 mirrors:

`vim /etc/pacman.d/mirrorlist`

```
##
## Arch Linux repository mirrorlist
## Filtered by mirror score from mirror status page
## Generated on 2019-03-01
##

## Singapore
Server = http://mirror.0x.sg/archlinux/$repo/os/$arch
## Vietnam
Server = http://f.archlinuxvn.org/archlinux/$repo/os/$arch
## Netherlands
Server = http://archlinux.mirror.pcextreme.nl/$repo/os/$arch
```

## Install the base and base-devel packages

Use the **pacstrap** script:

`pacstrap /mnt base base-devel`

## Generate an fstab file

Use `-U` or `-L` to define by UUID or labels:

`genfstab -U /mnt >> /mnt/etc/fstab`

## Chroot

Change root to the new system:

`arch-chroot /mnt`

## Install optional packages

`pacman -S intel-ucode`

`pacman -S networkmanager dhclient`

`pacman -S git gvim zsh`

## Create swap file

As an alternative to creating an entire swap partition, a swap file offers the ability to vary its size on-the-fly, and is more easily removed altogether.

Create a 32 GB (depend on your RAM) swap file:

`fallocate -l 32G /swapfile`

Set the right permissions:

`chmod 600 /swapfile`

format it to swap:

`mkswap /swapfile`

Activate the swap file:

`swapon /swapfile`

Edit fstab at `/etc/fstab` to add an entry for the swap file:

`vim /etc/fstab`

```
/swapfile none swap defaults 0 0
```

## Configure time zone

Set your time zone by region:

`ln -sf /usr/share/zoneinfo/Asia/Ho_Chi_Minh /etc/localtime`

Generate `/etc/adjtime`:

`hwclock --systohc`

## Configure locale

Uncomment `en_US.UTF-8 UTF-8` in `/etc/locale.gen`, then generate it:

`vim /etc/locale.gen`

```
en_US.UTF-8 UTF-8
```

`locale-gen`

Set LANG variable in `/etc/locale.conf`:

`echo 'LANG=en_US.UTF-8' > /etc/locale.conf`

## Change host name

Create hostname file at `/etc/hostname` contain the host name, for example:

`echo 'Precision' > /etc/hostname`

## Set your root password

`passwd`

Enter your password then confirm it.

## Install boot loader

Install systemd-boot:

`bootctl --path=/boot install`

Configure it in `/boot/loader/loader.conf` as you like, for example:

`vim /boot/loader/loader.conf`

```
default  arch
timeout  0
editor   0
```

And `/boot/loader/entries/arch.conf`:

`vim /boot/loader/entries/arch.conf`

```
title          Arch Linux
linux          /vmlinuz-linux
initrd         /intel-ucode.img
initrd         /initramfs-linux.img
options        root=/dev/nvme0n1p2 rw
```

## Enable network services

`systemctl enable NetworkManager`

`systemctl enable dhcpcd`

## Add new user

Add a new user named `khuedoan`:

`useradd -m -G wheel -s /bin/zsh khuedoan`

Protect the newly created user `khuedoan` with a password:

`passwd khuedoan`

Establish vim as the **visudo** editor for the duration of the current shell session:

`visudo`

Then uncomment `%wheel ALL=(ALL) ALL` to allow members of group `wheel` sudo access, uncomment `Defaults targetpw` and change it to `Defaults rootpw` to ask for the root password instead of the user password (then change the comment beside it accordingly).

## Reboot

Exit the chroot environment by typing:

`exit`

Optionally manually unmount all the partitions with:

`umount -R /mnt`

Restart the machine:

`reboot`

## Login

Login with your user account after the machine has rebooted.

## Install bumblebee

`sudo pacman -S bumblebee mesa xf86-video-intel nvidia lib32-nvidia-utils lib32-virtualgl nvidia-settings bbswitch`

Add user to `bumblebee` and `video` group:

`sudo gpasswd -a $USER bumblebee`

`sudo gpasswd -a $USER video`

Start bumblebee at boot:

`sudo systemctl enable bumblebeed.service`

Reboot:

`sudo shutdown -r now`

Edit NVIDIA desktop icon to run with bumblebee:

`sudo vim /usr/share/applications/nvidia-settings.desktop`

At `Exec=/usr/bin/nvidia-settings` line change it to:

```desktop
Exec=optirun -b none /usr/bin/nvidia-settings -c :8
```

## Install Vietnamese Input Method

`sudo pacman -S fcitx fcitx-unikey fcitx-im fcitx-configtool`

Open `~/.pam_environment` to define the evironment variables:

`vim ~/.pam_environment`

Add these line to the bottom of the file:

```bash
# Fcitx
export GTK_IM_MODULE=fcitx
export QT_IM_MODULE=fcitx
export XMODIFIERS=@im=fcitx
```

Then log out and log back in.

## Install dotfiles

Check out my [dotfiles](https://github.com/khuedoan98/dotfiles) repo for more details

`curl -Lks https://khuedoan.me/dotfiles/install.sh > install.sh`

`chmod +x install.sh`

`./install.sh`
