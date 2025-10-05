#!/bin/bash

# ================== 颜色定义 ==================
GREEN="\033[32m"
YELLOW="\033[33m"
RED="\033[31m"
RESET="\033[0m"

# ================== 脚本路径 ==================
SCRIPT_PATH="/root/vps-toolbox.sh"
SCRIPT_URL="https://raw.githubusercontent.com/Polarisiu/vps-toolbox/main/vps-toolbox.sh"
BIN_LINK_DIR="/usr/local/bin"

# ================== 首次运行自动安装 ==================
if [ ! -f "$SCRIPT_PATH" ]; then
    curl -fsSL -o "$SCRIPT_PATH" "$SCRIPT_URL"
    if [ $? -ne 0 ]; then
        echo -e "${RED}❌ 安装失败，请检查网络或 URL${RESET}"
        exit 1
    fi
    chmod +x "$SCRIPT_PATH"
    ln -sf "$SCRIPT_PATH" "$BIN_LINK_DIR/m"
    ln -sf "$SCRIPT_PATH" "$BIN_LINK_DIR/M"
    echo -e "${GREEN}✅ 安装完成${RESET}"
    echo -e "${GREEN}✅ 你可以输入 ${RED}m${RESET}${GREEN} 或 ${RED}M${RESET}${GREEN} 运行 UU 工具箱${RESET}"
fi

# ================== 执行脚本 ==================
exec "$SCRIPT_PATH"
