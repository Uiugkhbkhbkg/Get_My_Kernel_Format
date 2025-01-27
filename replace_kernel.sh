#!/bin/bash

set -e  # 遇到错误退出
set -o pipefail  # 管道错误传播

# 确保参数正确
if [[ $# -lt 2 ]]; then
    echo "Usage: $0 <boot.img> <ak3_package.zip>"
    exit 1
fi

BOOT_IMG="$1"
AK3_PACKAGE="$2"

# 检查依赖
if ! command -v magiskboot &>/dev/null; then
    echo "Error: magiskboot is not installed or not in PATH."
    exit 1
fi

# 准备工作目录
WORKDIR=$(mktemp -d)
echo "Working directory: $WORKDIR"

# 解压 boot.img
echo "Unpacking boot.img..."
cd "$WORKDIR"
magiskboot unpack "$BOOT_IMG" || { echo "Failed to unpack boot.img"; exit 1; }

# 检查解包内容
echo "Checking unpacked files..."
if [[ ! -f "kernel" || ! -f "ramdisk.cpio" ]]; then
    echo "Error: Unpacked boot.img is missing critical files (kernel or ramdisk)."
    exit 1
fi

# 解压 AK3 包
echo "Unpacking AK3 package..."
unzip -qo "$AK3_PACKAGE" -d ak3_package
if [[ ! -f "ak3_package/Image.gz" ]]; then
    echo "Error: AK3 package does not contain Image.gz"
    exit 1
fi

# 解压 Image.gz
echo "Extracting Image.gz..."
gunzip -c "ak3_package/Image.gz" > "kernel_new"
if [[ ! -f "kernel_new" ]]; then
    echo "Error: Failed to extract kernel from Image.gz"
    exit 1
fi

# 替换内核
echo "Replacing kernel..."
mv "kernel_new" "kernel"

# 重新打包 boot.img
echo "Repacking boot.img..."
magiskboot repack "$BOOT_IMG"

# 检查打包结果
if [[ ! -f "new-boot.img" ]]; then
    echo "Error: Failed to repack boot.img"
    exit 1
fi

# 输出结果
FINAL_BOOT_IMG="new-boot.img"
mv "$FINAL_BOOT_IMG" .
echo "Repacked boot.img saved as $FINAL_BOOT_IMG"

# 清理临时目录
echo "Cleaning up..."
cd -
rm -rf "$WORKDIR"

echo "Done!"
