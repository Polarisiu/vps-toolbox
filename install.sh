#!/bin/bash

# 工具箱脚本 URL
TOOLBOX_URL="https://raw.githubusercontent.com/Polarisiu/vps-toolbox/main/vps-toolbox.sh"
INSTALL_PATH="$HOME/vps-toolbox.sh"

# 颜色
GREEN="\033[32m"
RED="\033[31m"
YELLOW="\033[33m"
RESET="\033[0m"

# ----------------------
# 动态进度条函数
# ----------------------
progress_bar() {
  local task="$1"
  local speed=${2:-0.05}
  local total=20
  local i

  echo -ne "\n"
  for ((i=1; i<=total; i++)); do
    local done_str=$(head -c $i < /dev/zero | tr '\0' '#')
    local left_str=$(head -c $((total - i)) < /dev/zero | tr '\0' '-')
    if (( i == total )); then
      # 整行黄色
      printf "\r[\033[33m%s%s %3d%% %s\033[0m]" "$done_str" "$left_str" $((i*100/total)) "$task"
    else
      printf "\r[${GREEN}%s${RESET}%s] %3d%% %s" "$done_str" "$left_str" $((i*100/total)) "$task"
    fi
    sleep $speed
  done
  echo ""
}

# ----------------------
# 检查 sudo
# ----------------------
progress_bar "检测 sudo权限" 0.03
if command -v sudo &>/dev/null; then
  echo -e "${GREEN}检测到 sudo 可用。${RESET}"
else
  echo -e "${GREEN}未检测到 sudo，请使用 root 用户运行脚本。${RESET}"
  exit 1
fi

# ----------------------
# 检测系统类型
# ----------------------
progress_bar "检测系统类型" 0.03
if [[ -f /etc/os-release ]]; then
  . /etc/os-release
  OS_NAME=$NAME
  OS_VERSION=$VERSION_ID
  echo -e "${GREEN}当前系统: $OS_NAME $OS_VERSION${RESET}"
else
  echo -e "${GREEN}无法检测系统类型，继续安装...${RESET}"
fi

# ----------------------
# 下载或升级脚本
# ----------------------
progress_bar "下载工具箱脚本" 0.04
if [[ -f "$INSTALL_PATH" ]]; then
  echo -e "${GREEN}检测到工具箱脚本已存在，正在升级到最新版本...${RESET}"
else
  echo -e "${GREEN}开始下载安装脚本到 $INSTALL_PATH ...${RESET}"
fi

if ! curl -fsSL "$TOOLBOX_URL" -o "$INSTALL_PATH"; then
  echo -e "${GREEN}下载失败，请检查网络和URL是否正确！${RESET}"
  exit 1
fi
chmod +x "$INSTALL_PATH"

# ----------------------
# 创建快捷方式
# ----------------------
progress_bar "创建快捷方式" 0.06
create_shortcut() {
  local shortcut_path="/usr/local/bin/$1"
  if [[ -f "$shortcut_path" ]]; then
    echo -e "${GREEN}快捷指令 $1 已存在，跳过创建。${RESET}"
  else
    echo -e "${GREEN}创建快捷指令 $1 ...${RESET}"
    sudo bash -c "cat > $shortcut_path <<EOF
#!/bin/bash
bash \"$INSTALL_PATH\" \"\$@\"
EOF"
    sudo chmod +x "$shortcut_path"
    echo -e "${GREEN}快捷指令 $1 创建完成。${RESET}"
  fi
}

create_shortcut "m"
create_shortcut "M"

# ==============================
# 完成提示
# ==============================
progress_bar "安装完成" 0.02

echo -e "\n${GREEN}============================================================${RESET}"
echo -e " 🎉 ${GREEN}安装/升级完成！${RESET}"
echo -e " 👉 ${GREEN}你可以输入${RESET}${RED}m${RESET}${GREEN} 或 ${RED}M${RESET}${GREEN} 运行 IU 工具箱${RESET}"
echo -e "${GREEN}============================================================${RESET}\n"

# ----------------------
# 是否立即运行工具箱
# ----------------------
read -p $'\033[32m是否立即运行 IU 工具箱？(y/N): \033[0m' choice
if [[ "$choice" =~ ^[Yy]$ ]]; then
  echo -e "${GREEN}正在启动 IU 工具箱...${RESET}\n"
  exec m
else
  echo -e "${GREEN}你可以稍后输入 'm' 来运行 IU 工具箱。${RESET}\n"
fi
