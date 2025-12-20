#!/bin/bash
#
# https://github.com/P3TERX/Actions-OpenWrt
# File name: diy-part1.sh
# Description: OpenWrt DIY script part 1 (Before Update feeds)
#
# Copyright (c) 2019-2024 P3TERX <https://p3terx.com>
#
# This is free software, licensed under the MIT License.
# See /LICENSE for more information.
#

# Uncomment a feed source
#sed -i 's/^#\(.*helloworld\)/\1/' feeds.conf.default

# Add a feed source
echo 'src-git helloworld https://github.com/fw876/helloworld' >>feeds.conf.default
#echo 'src-git passwall https://github.com/xiaorouji/openwrt-passwall' >>feeds.conf.default

# Add tx_power patch
# Refer: https://github.com/Rahzadan/openwrt_bpi-r4_mtk_builder
wireless_regdb_makefile="package/firmware/wireless-regdb/Makefile"
wireless_regdb_patch_dir="package/firmware/wireless-regdb/patches"
tx_power_patch="${wireless_regdb_patch_dir}/500-tx_power.patch"

rm -f "${wireless_regdb_makefile}"
rm -f "${wireless_regdb_patch_dir}"/*.patch

wget https://raw.githubusercontent.com/Rahzadan/openwrt_bpi-r4_mtk_builder/main/files/regdb.Makefile \
  -O "${wireless_regdb_makefile}"
wget https://raw.githubusercontent.com/Rahzadan/openwrt_bpi-r4_mtk_builder/main/files/500-tx_power.patch \
  -O "${tx_power_patch}"
  
