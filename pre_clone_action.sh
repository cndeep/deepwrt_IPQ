#!/usr/bin/env bash

set -e

source /etc/profile
BASE_PATH=$(cd $(dirname $0) && pwd)

Dev=$1

CONFIG_FILE="$BASE_PATH/deconfig/$Dev.config"
INI_FILE="$BASE_PATH/compilecfg/$Dev.ini"

if [[ ! -f $CONFIG_FILE ]]; then
    echo "Config not found: $CONFIG_FILE"
    exit 1
fi

if [[ ! -f $INI_FILE ]]; then
    echo "INI file not found: $INI_FILE"
    exit 1
fi

read_ini_by_key() {
    local key=$1
    awk -F"=" -v key="$key" '$1 == key {print $2}' "$INI_FILE"
}

REPO_URL=$(read_ini_by_key "REPO_URL")
REPO_BRANCH=$(read_ini_by_key "REPO_BRANCH")
REPO_BRANCH=${REPO_BRANCH:-main}
BUILD_DIR="$BASE_PATH/action_build"

echo $REPO_URL $REPO_BRANCH
echo "$REPO_URL/$REPO_BRANCH" >"$BASE_PATH/repo_flag"
git clone --depth 1 -b $REPO_BRANCH $REPO_URL $BUILD_DIR

# GitHub Action 移除国内下载源
PROJECT_MIRRORS_FILE="$BUILD_DIR/scripts/projectsmirrors.json"

if [ -f "$PROJECT_MIRRORS_FILE" ]; then
    sed -i '/.cn\//d; /tencent/d; /aliyun/d' "$PROJECT_MIRRORS_FILE"
fi

# jdcloud_ipq60xx_libwrt
if [[ $Dev == "jdcloud_ipq60xx_libwrt" ]]; then
	sed -i 's/LiBwrt/DeepWrt/g' $BUILD_DIR/package/base-files/image-config.in
	sed -i 's/LiBwrt/DeepWrt/g' $BUILD_DIR/include/version.mk
	sed -i 's/LibWrt/DeepWrt/g' $BUILD_DIR/package/base-files/files/bin/config_generate
fi
# jdcloud_ipq60xx_deepwrt
if [[ $Dev == "jdcloud_ipq60xx_deepwrt" ]]; then
	echo "src-git packages https://github.com/immortalwrt/packages.git" >"$BUILD_DIR/feeds.conf.default"
	echo "src-git luci https://github.com/immortalwrt/luci.git" >>"$BUILD_DIR/feeds.conf.default"
	echo "src-git routing https://git.openwrt.org/feed/routing.git" >>"$BUILD_DIR/feeds.conf.default"
	echo "src-git telephony https://git.openwrt.org/feed/telephony.git" >>"$BUILD_DIR/feeds.conf.default"
	echo "src-git video https://github.com/openwrt/video.git" >>"$BUILD_DIR/feeds.conf.default"
	echo "src-git nss_packages https://github.com/qosmio/nss-packages.git;NSS-12.5-K6.x" >>"$BUILD_DIR/feeds.conf.default"
	echo "src-git sqm_scripts_nss https://github.com/qosmio/sqm-scripts-nss.git" >>"$BUILD_DIR/feeds.conf.default"
fi
