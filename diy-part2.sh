#!/bin/bash
#
# https://github.com/P3TERX/Actions-OpenWrt
# File name: diy-part2.sh
# Description: OpenWrt DIY script part 2 (After Update feeds)
#
# Copyright (c) 2019-2024 P3TERX <https://p3terx.com>
#
# This is free software, licensed under the MIT License.
# See /LICENSE for more information.
#

# Modify default IP
#sed -i 's/192.168.1.1/192.168.50.5/g' package/base-files/files/bin/config_generate

# Modify default theme
#sed -i 's/luci-theme-bootstrap/luci-theme-argon/g' feeds/luci/collections/luci/Makefile

# Modify hostname
#sed -i 's/OpenWrt/P3TERX-Router/g' package/base-files/files/bin/config_generate

# Modify password to empty
PASSWD_FILE="package/base-files/files/etc/passwd"
if [[ -f "${PASSWD_FILE}" ]]; then
  sed -i "s/\/bin\/ash/\/bin\/bash/" "${PASSWD_FILE}"
else
  echo "File ${PASSWD_FILE} does not exist." >&2
fi

# Clone custom packages
clone_repo https://github.com/rockjake/luci-app-fancontrol.git main \
  package/fancontrol
clone_repo https://github.com/anoixa/bpi-r4-pwm-fan main \
  package/bpi-r4-pwm-fan
