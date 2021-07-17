#!/usr/bin/env bash

# OpenWrt CI Builder
# Copyright (C) 2021 @Boos4721(Telegram and Github)  
# Default Settings

export ARCH=amd64
export SUBARCH=amd64
export HOME=/drone
export FORCE_UNSAFE_CONFIGURE=1
export FORCE=1
ln -sf /usr/share/zoneinfo/Asia/Shanghai /etc/localtime


SETUP() {
apt-get update 
apt-get -y install build-essential asciidoc binutils bzip2 gawk gettext git libncurses5-dev libz-dev patch python3 python2.7 unzip zlib1g-dev lib32gcc1 libc6-dev-i386 subversion flex uglifyjs git-core gcc-multilib p7zip p7zip-full msmtp libssl-dev texinfo libglib2.0-dev xmlto qemu-utils upx libelf-dev autoconf automake libtool autopoint device-tree-compiler g++-multilib antlr3 gperf wget curl swig rsync    
timedatectl set-timezone "Asia/Shanghai"
git config --global user.email 3.1415926535boos@gmail.com
git config --global user.name $id
}

CLONE() {
git clone https://github.com/R619AC-OpenWrt/OpenWrt-Packages package/Boos --depth=1 
wget -O .config https://gitlab.com/$id//openwrt/-/raw/master/5.10 && wget -O package/base-files/files/etc/profile https://gitlab.com/$id/openwrt/-/raw/master/profile && wget -O package/lean/autocore/files/arm/sbin/cpuinfo https://gitlab.com/$id/openwrt/-/raw/master/cpuinfo_arm && wget -O package/base-files/files/etc/banner https://gitlab.com/$id/openwrt/-/raw/master/banner
./scripts/feeds update -a -f
./scripts/feeds install -a -f
}

MAIN() {
Openwrt_Version_="R18.06-"
Version_File="package/lean/default-settings/files/zzz-default-settings"
Old_Version="$(egrep -o "R[0-9]+\.[0-9]+\.[0-9]+" ${Version_File})"
sed -i "s?By?By $id ?g" package/base-files/files/etc/banner
sed -i "s?Openwrt?Openwrt ${Openwrt_Version}?g" package/base-files/files/etc/banner
sed -i '/profile/d' package/base-files/files/lib/upgrade/keep.d/base-files-essential
sed -i "s?iptables?#iptables?g" ${Version_File}
sed -i "s?${Old_Version}?${Old_Version} Compiled by $id ?g" ${Version_File}
}


BUILD() {
make defconfig
BUILD_START=$(date +"%s")
echo " ${Openwrt_Version} Starting first build..."
make download -j$(nproc)
make -j$(nproc) || make -j$(nproc) V=s
BUILD_END=$(date +"%s")
}

UPLOAD() {
mkdir -p ~/UPLOAD && mv ~/src/bin/targets/*/* ~/UPLOAD/      
cd ~/src/bin/targets/*/*
mv *.bin *.ubi ~/UPLOAD
curl -fsSL git.io/file-transfer | sh
./transfer cow --block 2621440 -s -p 64 --no-progress ~/UPLOAD 2>&1 | tee cowtransfer.log
echo "cat cowtransfer.log | grep https"
}

GITHUB_UPLOAD() {
cd ~/UPLOAD
git init
git remote add origin https://$id:$ss@github.com/$id/updater.git
git checkout -b OpenWrt
git add *.bin *.ubi
git commit -sm "$(date +"%m%d-%H%S")"
git push -uf origin OpenWrt    

}

SETUP
CLONE
MAIN
BUILD
UPLOAD
GITHUB_UPLOAD

DIFF=$(($BUILD_END - $BUILD_START))
echo "Build completed in $(($DIFF / 60)) minute(s) and $(($DIFF % 60)) seconds"