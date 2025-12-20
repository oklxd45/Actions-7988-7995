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


clone_repo() {
  local repo="$1"
  local branch="$2"
  local target="$3"
  local attempt

  if [[ -d "${target}" ]]; then
    printf "Pulling %s at %s...\n" "${repo}" "${target}"
    for attempt in {1..3}; do
      if git -C "${target}" clean -fdx && git -C "${target}" restore . && git -C "${target}" pull; then
        break
      else
        echo "Pull attempt ${attempt} failed, retrying..."
        sleep $((attempt * 2))
      fi
    done
  else
    printf "Cloning %s %s to %s...\n" "${repo}" "${branch}" "${target}"
    for attempt in {1..3}; do
      echo "Clone attempt ${attempt}..."
      if git clone --depth 1 -b "${branch}" "${repo}" "${target}"; then
        break
      else
        echo "Clone attempt ${attempt} failed!"
        sleep $((attempt * 2))
        rm -rf "${target}"
        if [[ "${attempt}" -eq 3 ]]; then
          echo "Failed to clone ${repo} after ${attempt} attempts." >&2
          exit 1
        fi
      fi
    done
  fi
}

# Change to official custom branch source of applications including luci-app-openclash and luci-theme-argon
# rm -rf feeds/luci/applications/luci-app-openclash
# clone_repo https://github.com/vernesong/OpenClash dev \
#   feeds/luci/applications/luci-app-openclash
ARGON_THEME_DIR="feeds/luci/themes/luci-theme-argon"
if [[ -d "${ARGON_THEME_DIR}" ]]; then
  rm -rf "${ARGON_THEME_DIR}"
fi
clone_repo https://github.com/jerrykuku/luci-theme-argon.git master \
  feeds/luci/themes/luci-theme-argon

# Clone custom packages
clone_repo https://github.com/anoixa/bpi-r4-pwm-fan main \
  package/bpi-r4-pwm-fan
clone_repo https://github.com/rockjake/luci-app-fancontrol.git main \
  package/fancontrol

# Modify luci collections to remove uhttpd dependency
modify_luci_collection() {
  local makefile="$1"
  shift
  local sed_exprs=("$@")

  if [[ -f "${makefile}" ]]; then
    printf "Modifying %s...\n" "${makefile}"
    sed -i "${sed_exprs[@]}" "${makefile}"
  else
    echo "File ${makefile} does not exist." >&2
  fi
}

modify_luci_collection "feeds/luci/collections/luci/Makefile" \
  -e '/LUCI_DEPENDS/,/^$/ { /luci-app-attendedsysupgrade/d; s/luci-app-package-manager\s*\\/luci-app-package-manager/g; }'

modify_luci_collection "feeds/luci/collections/luci-light/Makefile" \
  -e '/LUCI_DEPENDS/,/^$/ { /uhttpd/d; s/luci-theme-bootstrap/luci-theme-argon/g; s/rpcd-mod-rrdns\s*\\/rpcd-mod-rrdns/g; }'

modify_luci_collection "feeds/luci/collections/luci-nginx/Makefile" \
  -e '/LUCI_DEPENDS/,/^$/ { /luci-app-attendedsysupgrade/d; s/luci-theme-bootstrap/luci-theme-argon/g; }'

modify_luci_collection "feeds/luci/collections/luci-ssl/Makefile" \
  -e '/LUCI_DEPENDS/,/^$/ { /luci-app-attendedsysupgrade/d; s/luci-app-package-manager\s*\\/luci-app-package-manager/g; }'

modify_luci_collection "feeds/luci/collections/luci-ssl-openssl/Makefile" \
  -e '/LUCI_DEPENDS/,/^$/ { /luci-app-attendedsysupgrade/d; s/luci-app-package-manager\s*\\/luci-app-package-manager/g; }'

# Modify easyupdate.sh to support ImmortalWrt
EASYUPDATE_FILE="package/sundaqiang/luci/applications/luci-app-easyupdate/root/usr/bin/easyupdate.sh"
if [[ -f "${EASYUPDATE_FILE}" ]]; then
  printf "Modifying %s...\n" "${EASYUPDATE_FILE}"
  # 修改 OpenWrt 为 ImmortalWrt
  # 修改更新操作，更新是备份软件包列表
  # 修改 fileName 截取范围
  # 修改 suffix 为 squashfs-sysupgrade.itb
  sed -i -E \
    -e "/curl|filename/s/OpenWrt/ImmortalWrt/g" \
    -e "/curl|filename/s/openwrt/immortalwrt/g" \
    -e "/curl|filename/s/Openwrt/Immortalwrt/g" \
    -e "/sysupgrade \$keepconfig\$file/s/sysupgrade/sysupgrade -k/g" \
    -e "/file[Nn]ame/s/0:7/0:11/g" \
    -e "/^\s*file/s/\$\{checkShaRet/\/tmp\/\$\{checkShaRet/g" \
    -e "/Check\s+whether\s+EFI\s+firmware/,/^\s*fi/ {
        /^\s+fi/a\  suffix='squashfs-sysupgrade.itb'
        s/^/#/
      }" \
    -e "/^\s*function\s+checkSha/,/^\s*\}/ {
        s/img\.gz/\itb/
      }" \
    "${EASYUPDATE_FILE}"
else
  echo "File ${EASYUPDATE_FILE} does not exist." >&2
fi

# Set Rust build arg llvm.download-ci-llvm to false.
RUST_MAKEFILE="feeds/packages/lang/rust/Makefile"
if [[ -f "${RUST_MAKEFILE}" ]]; then
  printf "Modifying %s...\n" "${RUST_MAKEFILE}"
  sed -i "s/--set=llvm\.download-ci-llvm=true/--set=llvm.download-ci-llvm=false/" "${RUST_MAKEFILE}"
else
  echo "File ${RUST_MAKEFILE} does not exist." >&2
fi

# Give restore-packages execution permissions
RESTORE_PACKAGES_FILE="files/usr/bin/restore-packages.sh"
if [[ -f "${RESTORE_PACKAGES_FILE}" ]]; then
  printf "Modifying %s...\n" "${RESTORE_PACKAGES_FILE}"
  chmod +x "${RESTORE_PACKAGES_FILE}"
else
  echo "File ${RESTORE_PACKAGES_FILE} does not exist." >&2
fi
