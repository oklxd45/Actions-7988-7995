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
ARGON_THEME_DIR="feeds/luci/themes/luci-theme-argon"
if [[ -d "${ARGON_THEME_DIR}" ]]; then
  rm -rf "${ARGON_THEME_DIR}"
fi
clone_repo https://github.com/jerrykuku/luci-theme-argon.git master \
  feeds/luci/themes/luci-theme-argon

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
