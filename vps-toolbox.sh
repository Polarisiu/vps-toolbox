#!/bin/bash
# VPS Toolbox - 最终整合版
# 功能：
# - 一级菜单加 ▶ 标识，字体绿色
# - 二级菜单简洁显示，输入 1~99 都可执行
# - 快捷指令 m / M 自动创建
# - 系统信息面板保留
# - 彩色菜单和动态彩虹标题
# - 完整安装/卸载逻辑

INSTALL_PATH="$HOME/vps-toolbox.sh"
SHORTCUT_PATH="/usr/local/bin/m"
SHORTCUT_PATH_UPPER="/usr/local/bin/M"

# 颜色
green="\033[32m"
reset="\033[0m"
yellow="\033[33m"
red="\033[31m"
cyan="\033[36m"

# Ctrl+C 中断保护
trap 'echo -e "\n${red}操作已中断${reset}"; exit 1' INT

# 彩虹标题
rainbow_animate() {
    local text="$1"
    local colors=(31 33 32 36 34 35)
    local len=${#text}
    for ((i=0; i<len; i++)); do
        printf "\033[%sm%s" "${colors[$((i % ${#colors[@]}))]}" "${text:$i:1}"
        sleep 0.002
    done
    printf "${reset}\n"
}

# 系统资源显示
show_system_usage() {
    local width=36
    mem_used=$(free -m | awk '/Mem:/ {print $3}')
    mem_total=$(free -m | awk '/Mem:/ {print $2}')
    disk_used_percent=$(df -h / | awk 'NR==2 {print $5}')
    disk_total=$(df -h / | awk 'NR==2 {print $2}')
    cpu_usage=$(grep 'cpu ' /proc/stat | awk '{usage=($2+$4)*100/($2+$4+$5)} END {printf "%.1f", usage}')
    pad_string() { local str="$1"; printf "%${width}s" "$str"; }
    echo -e "${yellow}┌$(printf '─%.0s' $(seq 1 $width))┐${reset}"
    echo -e "${yellow}$(pad_string "📊 内存：${mem_used}Mi/${mem_total}Mi")${reset}"
    echo -e "${yellow}$(pad_string "💽 磁盘：${disk_used_percent} 用 / 总 ${disk_total}")${reset}"
    echo -e "${yellow}$(pad_string "⚙ CPU：${cpu_usage}%")${reset}"
    echo -e "${yellow}└$(printf '─%.0s' $(seq 1 $width))┘${reset}\n"
}

# 一级菜单
MAIN_MENU=(
    "系统设置"
    "网络工具"
    "网络解锁"
    "Docker管理"
    "应用商店"
    "证书管理"
    "系统管理"
    "工具箱合集"
    "好玩的"
    "更新/卸载"
)

# 二级菜单（编号去掉前导零，显示时格式化为两位数）
SUB_MENU[1]="1 更新系统|2 系统信息|3 修改ROOT密码|4 配置密钥登录|5 修改SSH端口|6 上海时区|7 临时禁用V6|8 开放所有端口|9 开启ROOT登录|10 更换系统源|11 DDdebian12|12 DDwindows10|13 VPS重启"
SUB_MENU[2]="14 代理工具|15 FRP管理|16 BBR管理|17 TCP窗口调优|18 WARP|19 Surge-Snell|20 3XUI|21 Hysteria2|22 Reality|23 Realm|24 GOST|25 哆啦A梦转发面板|26 极光面板|27 Alpine转发|28 自定义DNS解锁|29 DDNS|30 Alice出口"
SUB_MENU[3]="31 NodeQuality脚本|32 融合怪测试|33 网络质量体检脚本|34 简单回程测试|35 完整路由检测|36 流媒体解锁|37 三网延迟测速|38 检查25端口开放"
SUB_MENU[4]="39 Docker管理|40 Docker备份恢复|41 Docker容器迁移"
SUB_MENU[5]="42 应用管理|43 面板管理|44 哪吒管理|45 yt-dlp视频下载工具"
SUB_MENU[6]="46 1kejiNGINX反代|47 NginxProxyManager可视化面板|48 ALLinSSL证书"
SUB_MENU[7]="49 系统清理|50 系统备份恢复|51 本地备份|52 一键重装系统|53 系统组件|54 开发环境|55 SWAP|56 DNS管理|57 工作区管理|58 系统监控"
SUB_MENU[8]="59 科技lion|60 老王工具箱|61 一点科技|62 VPS优化工具|63 VPS-Toolkit"
SUB_MENU[9]="64 甲骨文工具|65 安装PVE|66 圆周率计算器|67 PHP7.4|68 iperf3 "
SUB_MENU[10]="88 更新脚本|99 卸载工具箱"

# 显示一级菜单
show_main_menu() {
    clear
    rainbow_animate "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    rainbow_animate "              📦 VPS 服务器工具箱 📦          "
    rainbow_animate "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    show_system_usage
    for i in "${!MAIN_MENU[@]}"; do
        printf "${red}▶${reset} ${green}%02d. %s${reset}\n" "$((i+1))" "${MAIN_MENU[i]}"
    done
    echo
}

# 显示二级菜单并选择
show_sub_menu() {
    local idx="$1"
    while true; do
        IFS='|' read -ra options <<< "${SUB_MENU[idx]}"
        local map=()
        echo
        for opt in "${options[@]}"; do
            local num="${opt%% *}"
            local name="${opt#* }"
            printf "${red}▶${reset} ${green}%02d %s${reset}\n" "$num" "$name"
            map+=("$num")
        done

        echo -ne "${red}请输入要执行的编号 ${yellow}(00返回主菜单)${yellow}：${reset}"
        read -r choice

        # 按回车直接刷新菜单
        if [[ -z "$choice" ]]; then
            clear
            continue
        fi

        # 输入 00 返回一级菜单
        if [[ "$choice" == "00" ]]; then
            return
        fi

        # 判断是否为有效选项
        if [[ ! " ${map[*]} " =~ (^|[[:space:]])$choice($|[[:space:]]) ]]; then
            echo -e "${red}无效选项${reset}"
            continue
        fi

        # 执行选项
        execute_choice "$choice"

        # 只有 0/99 才退出二级菜单，否则按回车刷新二级菜单
        if [[ "$choice" != "0" && "$choice" != "99" ]]; then
            read -rp $'\e[31m按回车刷新二级菜单...\e[0m' tmp
            clear
        else
            break
        fi
    done
}




# 安装快捷指令
install_shortcut() {
    echo -e "${green}创建快捷指令 m 和 M${reset}"
    local script_path
    script_path=$(readlink -f "$0")
    sudo chmod +x "$script_path"
    sudo ln -sf "$script_path" "$SHORTCUT_PATH"
    sudo ln -sf "$script_path" "$SHORTCUT_PATH_UPPER"
    echo -e "${green}安装完成！输入 m 或 M 运行工具箱${reset}"
}

# 删除快捷指令
remove_shortcut() {
    sudo rm -f "$SHORTCUT_PATH" "$SHORTCUT_PATH_UPPER"
}

# 执行菜单选项
execute_choice() {
    case "$1" in
        1) bash <(curl -sL https://raw.githubusercontent.com/Polarisiu/tool/main/update.sh) ;;
        2) bash <(curl -fsSL https://raw.githubusercontent.com/Polarisiu/tool/main/vpsinfo.sh) ;;
        3) sudo passwd root ;;
        4) bash <(curl -sL https://raw.githubusercontent.com/Polarisiu/tool/main/secretkey.sh) ;;
        5) bash <(curl -sL https://raw.githubusercontent.com/Polarisiu/tool/main/sshdk.sh) ;;
        6) timedatectl set-timezone Asia/Shanghai ;;
        7) sudo sysctl -w net.ipv6.conf.all.disable_ipv6=1 && sudo sysctl -w net.ipv6.conf.default.disable_ipv6=1 ;;
        8) bash <(curl -sL https://raw.githubusercontent.com/Polarisiu/tool/main/open_all_ports.sh) ;;
        9) bash <(curl -sL https://raw.githubusercontent.com/Polarisiu/tool/main/xgroot.sh) ;;
        10) bash <(curl -sL https://raw.githubusercontent.com/Polarisiu/tool/main/huanyuan.sh) ;;
        11) bash <(curl -fsSL https://raw.githubusercontent.com/Polarisiu/tool/main/debian.sh) ;;
        12) bash <(curl -fsSL https://raw.githubusercontent.com/Polarisiu/tool/main/window.sh) ;;
        13) sudo reboot ;;
        14) bash <(curl -fsSL https://raw.githubusercontent.com/Polarisiu/proxy/main/proxy.sh) ;;
        15) bash <(curl -fsSL https://raw.githubusercontent.com/Polarisiu/proxy/main/FRP.sh) ;;
        16) wget --no-check-certificate -O tcpx.sh https://raw.githubusercontent.com/ylx2016/Linux-NetSpeed/master/tcpx.sh && chmod +x tcpx.sh && ./tcpx.sh ;;
        17) wget http://sh.nekoneko.cloud/tools.sh -O tools.sh && bash tools.sh ;;
        18) wget -N https://gitlab.com/fscarmen/warp/-/raw/main/menu.sh && bash menu.sh ;;
        19) bash <(curl -L -s menu.jinqians.com) ;;
        20) bash <(curl -sL https://raw.githubusercontent.com/Polarisiu/proxy/main/3xui.sh) ;;
        21) wget -N --no-check-certificate https://raw.githubusercontent.com/flame1ce/hysteria2-install/main/hysteria2-install-main/hy2/hysteria.sh && bash hysteria.sh ;;
        22) bash <(curl -fsSL https://raw.githubusercontent.com/Polarisiu/proxy/main/Reality.sh) ;;
        23) bash <(curl -sL https://raw.githubusercontent.com/Polarisiu/proxy/main/Realm.sh) ;;
        24) bash <(curl -sL https://raw.githubusercontent.com/Polarisiu/proxy/main/gost.sh) ;;
        25) curl -L https://raw.githubusercontent.com/bqlpfy/forward-panel/refs/heads/main/panel_install.sh -o panel_install.sh && chmod +x panel_install.sh && ./panel_install.sh ;;
        26) bash <(curl -fsSL https://raw.githubusercontent.com/Aurora-Admin-Panel/deploy/main/install.sh) ;;
        27) curl -sS -O https://raw.githubusercontent.com/zyxinab/iptables-manager/main/iptables-manager.sh && chmod +x iptables-manager.sh && ./iptables-manager.sh ;;
        28) bash <(curl -sL https://raw.githubusercontent.com/Polarisiu/tool/main/unlockdns.sh) ;;
        29) bash <(wget -qO- https://raw.githubusercontent.com/mocchen/cssmeihua/mochen/shell/ddns.sh) ;;
        30) bash <(curl -sL https://raw.githubusercontent.com/Polarisiu/tool/main/tun2socks.sh) ;;
        31) bash <(curl -sL https://run.NodeQuality.com) ;;
        32) curl -L https://gitlab.com/spiritysdx/za/-/raw/main/ecs.sh -o ecs.sh && chmod +x ecs.sh && bash ecs.sh ;;
        33) bash <(curl -fsSL https://raw.githubusercontent.com/Polarisiu/unblock/main/examine.sh) ;;
        34) curl https://raw.githubusercontent.com/ludashi2020/backtrace/main/install.sh -sSf | sh ;;
        35) bash <(curl -Ls https://Net.Check.Place) -R ;;
        36) bash <(curl -L -s https://raw.githubusercontent.com/lmc999/RegionRestrictionCheck/main/check.sh) ;;
        37) bash <(curl -sL https://raw.githubusercontent.com/Polarisiu/unblock/main/speed.sh) ;;
        38) bash <(curl -sL https://raw.githubusercontent.com/Polarisiu/unblock/main/Telnet.sh) ;;
        39) bash <(curl -sL https://raw.githubusercontent.com/Polarisiu/app-store/main/Docker.sh) ;;
        40) curl -fsSL https://raw.githubusercontent.com/xymn2023/DMR/main/docker_back.sh -o docker_back.sh && chmod +x docker_back.sh && ./docker_back.sh ;;
        41) curl -sL https://raw.githubusercontent.com/ceocok/Docker_container_migration/refs/heads/main/Docker_container_migration.sh -o Docker_container_migration.sh && chmod +x Docker_container_migration.sh && ./Docker_container_migration.sh ;;
        42) bash <(curl -fsSL https://raw.githubusercontent.com/Polarisiu/app-store/main/store.sh);;
        43) bash <(curl -sL https://raw.githubusercontent.com/Polarisiu/panel/main/Panel.sh) ;;
        44) bash <(curl -sL https://raw.githubusercontent.com/Polarisiu/panel/main/nezha.sh) ;;
        45) bash <(curl -fsSL https://raw.githubusercontent.com/Polarisiu/app-store/main/ytdlb.sh) ;;
        46) bash <(curl -fsSL https://raw.githubusercontent.com/1keji/AddIPv6/main/manage_nginx_v6.sh) ;;
        47) bash <(curl -sL https://raw.githubusercontent.com/Polarisiu/panel/main/nginx.sh) ;;
        48) bash <(curl -fsSL https://raw.githubusercontent.com/Polarisiu/app-store/main/ALLSSL.sh) ;;
        49) bash <(curl -sL https://raw.githubusercontent.com/Polarisiu/tool/main/clear.sh) ;;
        50) bash <(curl -fsSL https://raw.githubusercontent.com/Polarisiu/tool/main/restore.sh) ;;
        51) bash <(curl -fsSL https://raw.githubusercontent.com/Polarisiu/tool/main/beifen.sh) ;;
        52) bash <(curl -sL https://raw.githubusercontent.com/Polarisiu/tool/main/reinstall.sh) ;;
        53) bash <(curl -sL https://raw.githubusercontent.com/Polarisiu/tool/main/package.sh) ;;
        54) bash <(curl -sL https://raw.githubusercontent.com/Polarisiu/tool/main/exploitation.sh) ;;
        55) wget https://www.moerats.com/usr/shell/swap.sh && bash swap.sh ;;
        56) bash <(curl -fsSL https://raw.githubusercontent.com/Polarisiu/tool/main/dns.sh) ;;
        57) bash <(curl -fsSL https://raw.githubusercontent.com/Polarisiu/tool/main/tmux.sh) ;;
        58) bash <(curl -fsSL https://raw.githubusercontent.com/Polarisiu/tool/main/System.sh) ;;
        59) curl -sS -O https://kejilion.pro/kejilion.sh && chmod +x kejilion.sh && ./kejilion.sh ;;
        60) bash <(curl -fsSL ssh_tool.eooce.com) ;;
        61) wget -O 1keji.sh "https://www.1keji.net" && chmod +x 1keji.sh && ./1keji.sh ;;
        62) bash <(curl -sL ss.hide.ss) ;;
        63) bash <(curl -sSL https://raw.githubusercontent.com/zeyu8023/vps_toolkit/main/install.sh) ;;
        64) bash <(curl -fsSL https://raw.githubusercontent.com/iu683/oracle/main/oracle.sh) ;;
        65) bash <(curl -fsSL https://raw.githubusercontent.com/Polarisiu/toy/main/PVE.sh) ;;
        66) bash <(curl -fsSL https://raw.githubusercontent.com/Polarisiu/toy/main/pai.sh) ;;
        67) bash <(curl -fsSL https://raw.githubusercontent.com/Polarisiu/tool/main/php74.sh) ;;
        68) bash <(curl -fsSL https://raw.githubusercontent.com/Polarisiu/toy/main/iperf3.sh) ;;
        88)
            echo -e "${yellow}正在更新脚本...${reset}"
            # 下载最新版本覆盖本地脚本
            curl -fsSL https://raw.githubusercontent.com/Polarisiu/vps-toolbox/main/vps-toolbox.sh -o "$INSTALL_PATH"
            if [[ $? -ne 0 ]]; then
                echo -e "${red}更新失败，请检查网络或GitHub地址${reset}"
                return 1
            fi
            chmod +x "$INSTALL_PATH"
            echo -e "${green}脚本已更新完成！${reset}"
            # 重新执行最新脚本
            exec bash "$INSTALL_PATH"
            ;;

        99) 
            echo -e "${yellow}正在卸载工具箱...${reset}"
            remove_shortcut
            rm -f "$INSTALL_PATH"
            echo -e "${green}卸载完成！${reset}"
            exit 0
            ;;
        0) exit 0 ;;
        *) echo -e "${red}无效选项${reset}"; return 1 ;;
    esac
}

# 自动创建快捷指令（只安装一次）
if [[ ! -f "$SHORTCUT_PATH" || ! -f "$SHORTCUT_PATH_UPPER" ]]; then
    install_shortcut
fi

# 主循环
while true; do
    show_main_menu
    echo -ne "${red}请输入要执行的编号 ${yellow}(0退出)${yellow}：${reset} "
    read -r main_choice
    if [[ "$main_choice" == "0" ]]; then
        echo -e "${yellow}退出${reset}"
        exit 0
    fi
    if [[ "$main_choice" -ge 1 && "$main_choice" -le "${#MAIN_MENU[@]}" ]]; then
        show_sub_menu "$main_choice"
    else
        echo -e "${red}无效选项${reset}"
        sleep 1
    fi
done
