wifi-menu
ping -c 3 archlinux.org
timedatectl set-ntp true
gdisk /dev/nvme0n1
cfdisk /dev/nvme0n1
mkfs.fat -F32 /dev/nvme0n1p1
mkfs.ext4 /dev/nvme0n1p2
mount /dev/nvme0n1p2 /mnt
mkdir /mnt/boot
mount /dev/nvme0n1p1 /mnt/boot
vim /etc/pacman.d/mirrorlist
pacstrap /mnt base base-devel
genfstab -U /mnt >> /mnt/etc/fstab
curl https://khuedoan.me/archguide/chroot.sh > chroot.sh
cp chroot.sh /mnt
arch-chroot /mnt /chroot.sh