#!/bin/bash

# ==============================
# 配置
# ==============================
TOOLBOX_URL="https://raw.githubusercontent.com/Polarisiu/vps-toolbox/main/vps-toolbox.sh"
INSTALL_PATH="/root/vps-toolbox.sh"       # 使用绝对路径
MARK_FILE="/root/.iutoolbox"   # 标记文件绝对路径

# 颜色
GREEN="\033[32m"
RED="\033[31m"
YELLOW="\033[33m"
BLUE="\033[34m"
CYAN="\033[36m"
RESET="\033[0m"

# ==============================
# 彩色进度条函数
# ==============================
progress_bar() {
    local task="$1"
    local speed=${2:-0.03}
    local total=25
    local i
    echo -ne "\n${CYAN}▶ $task...${RESET}\n"
    for ((i=1; i<=total; i++)); do
        local done_str=$(head -c $i < /dev/zero | tr '\0' '#')
        local left_str=$(head -c $((total-i)) < /dev/zero | tr '\0' '-')
        printf "\r[${GREEN}%s${RESET}${left_str}] %3d%%" "$done_str" $((i*100/total))
        sleep $speed
    done
    echo -e " ${GREEN}✅ 完成${RESET}\n"
}

# ==============================
# 后续运行直接打开工具箱
# ==============================
if [[ -f "$MARK_FILE" ]]; then
    exec "$INSTALL_PATH"
fi

# ==============================
# 首次运行流程
# ==============================

# 检查 sudo 权限
progress_bar "检测 sudo 权限"
if [[ $EUID -eq 0 ]]; then
    echo -e "${GREEN}当前为 root 用户，跳过 sudo 检查。${RESET}"
    SUDO_CMD=""
elif command -v sudo &>/dev/null; then
    echo -e "${GREEN}检测到 sudo 可用。${RESET}"
    SUDO_CMD="sudo"
else
    echo -e "${YELLOW}未检测到 sudo，正在尝试自动安装...${RESET}"
    if [[ -f /etc/debian_version ]]; then
        apt-get update -y && apt-get install -y sudo
    elif [[ -f /etc/redhat-release ]]; then
        yum install -y sudo
    elif [[ -f /etc/alpine-release ]]; then
        apk add sudo
    else
        echo -e "${RED}不支持的系统，请手动安装 sudo 后再运行脚本！${RESET}"
        exit 1
    fi

    if command -v sudo &>/dev/null; then
        echo -e "${GREEN}sudo 安装成功！${RESET}"
        SUDO_CMD="sudo"
    else
        echo -e "${RED}sudo 安装失败，请手动安装后再运行脚本！${RESET}"
        exit 1
    fi
fi

# 检测系统类型
progress_bar "检测系统类型"
if [[ -f /etc/os-release ]]; then
    . /etc/os-release
    echo -e "${GREEN}当前系统: ${BLUE}$NAME $VERSION_ID${RESET}"
else
    echo -e "${YELLOW}无法检测系统类型，继续安装...${RESET}"
fi

# 下载或升级脚本
progress_bar "下载/升级工具箱脚本"
if [[ -f "$INSTALL_PATH" ]]; then
    echo -e "${GREEN}检测到工具箱脚本已存在，升级中...${RESET}"
else
    echo -e "${GREEN}开始下载安装脚本到 $INSTALL_PATH ...${RESET}"
fi

curl -fsSL "$TOOLBOX_URL" -o "$INSTALL_PATH"
if [[ ! -f "$INSTALL_PATH" ]]; then
    echo -e "${RED}下载失败，请检查网络或 URL！${RESET}"
    exit 1
fi
chmod +x "$INSTALL_PATH"
echo -e "${GREEN}脚本下载/升级完成！${RESET}"

# 创建快捷方式
progress_bar "创建快捷方式"
for cmd in m M; do
    shortcut="/usr/local/bin/$cmd"
    if [[ ! -f "$shortcut" ]]; then
        $SUDO_CMD ln -sf "$INSTALL_PATH" "$shortcut"
        $SUDO_CMD chmod +x "$shortcut"
        echo -e "${GREEN}快捷指令 $cmd 创建完成！${RESET}"
    else
        echo -e "${GREEN}快捷指令 $cmd 已存在，跳过。${RESET}"
    fi
done

# 安装完成提示
progress_bar "安装完成"
echo -e "${CYAN}============================================================${RESET}"
echo -e " 🎉 ${GREEN}安装/升级完成！${RESET}"
echo -e " 👉 ${GREEN}你可以输入 ${RED}m${RESET}${GREEN} 或 ${RED}M${RESET}${GREEN} 运行 IU 工具箱${RESET}"
echo -e "${CYAN}============================================================${RESET}\n"

# 标记首次运行已完成
touch "$MARK_FILE"

# 提示是否立即运行
read -p $'\033[32m是否立即运行 IU 工具箱？(y/N): \033[0m' choice
if [[ "$choice" =~ ^[Yy]$ ]]; then
    exec "$INSTALL_PATH"
else
    echo -e "${GREEN}你可以稍后输入 '${RED}m${RESET}' 来运行 IU 工具箱。${RESET}\n"
fi
