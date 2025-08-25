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
    local content_indent="    "

    # 颜色
    green="\033[32m"
    yellow="\033[33m"
    red="\033[31m"
    reset="\033[0m"

    # ================== 格式化函数 ==================
    format_size() {
        local size_mb=$1
        if [ "$size_mb" -lt 1024 ]; then
            echo "${size_mb}M"
        else
            awk "BEGIN{printf \"%.1fG\", $size_mb/1024}"
        fi
    }

    # ================== 获取数据 ==================
    # 内存
    read mem_total mem_used <<< $(LANG=C free -m | awk 'NR==2{print $2, $3}')
    mem_total_fmt=$(format_size $mem_total)
    mem_used_fmt=$(format_size $mem_used)
    mem_percent=$(awk "BEGIN{printf \"%.0f%%\", $mem_used*100/$mem_total}")

    # 磁盘
    read disk_total_h disk_used_h disk_used_percent <<< $(df -m / | awk 'NR==2{print $2, $3, $5}')
    disk_total_fmt=$(format_size $disk_total_h)
    disk_used_fmt=$(format_size $disk_used_h)

    # CPU
    cpu_usage=$(awk -v FS=" " 'NR==1{usage=($2+$4)*100/($2+$4+$5)} END{printf "%.1f%%", usage}' /proc/stat)

    # ================== 系统状态 ==================
    mem_num=${mem_percent%%%}          # 去掉百分号
    disk_num=${disk_used_percent%%%}   # 去掉百分号
    cpu_num=${cpu_usage%\%}            # 去掉 CPU 百分号

    max_level=0
    for n in $mem_num $disk_num $cpu_num; do
        if (( $(awk "BEGIN{print ($n>80)?1:0}") )); then max_level=2; fi
        if (( $(awk "BEGIN{print ($n>60 && $n<=80)?1:0}") )) && [ "$max_level" -lt 2 ]; then max_level=1; fi
    done

    if [ "$max_level" -eq 0 ]; then
        system_status="${green}系统状态：正常 ✅${reset}"
    elif [ "$max_level" -eq 1 ]; then
        system_status="${yellow}系统状态：警告 ⚠️${reset}"
    else
        system_status="${red}系统状态：危险 🔥${reset}"
    fi

    # ================== 输出 ==================
    pad_string() {
        local str="$1"
        printf "%-${width}s" "${content_indent}${str}"
    }

    echo -e "${yellow}┌$(printf '─%.0s' $(seq 1 $width))┐${reset}"
    echo -e "$(pad_string "${system_status}")"
    echo -e "$(pad_string "${yellow}📊 内存：${mem_used_fmt}/${mem_total_fmt} (${mem_percent})${reset}")"
    echo -e "$(pad_string "${yellow}💽 磁盘：${disk_used_fmt}/${disk_total_fmt} (${disk_used_percent})${reset}")"
    echo -e "$(pad_string "${yellow}⚙ CPU：${cpu_usage}${reset}")"
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
    "玩具熊ʕ•ᴥ•ʔ"
    "更新/卸载"
)

# 二级菜单（编号去掉前导零，显示时格式化为两位数）
SUB_MENU[1]="1 更新系统|2 系统信息|3 修改ROOT密码|4 配置密钥登录|5 修改SSH端口|6 修改时区|7 临时禁用V6|8 开放所有端口|9 开启ROOT登录|10 更换系统源|11 DDdebian12|12 DDwindows10|13 DDNAT|14 设置中文|15 修改主机名|16 VPS重启"
SUB_MENU[2]="17 代理工具|18 FRP管理|19 BBR管理|20 TCP窗口调优|21 WARP|22 Surge-Snell|23 3XUI|24 Hysteria2|25 Reality|26 Realm|27 GOST|28 哆啦A梦转发面板|29 极光面板|30 Alpine转发|31 自定义DNS解锁|32 DDNS|33 Alice出口"
SUB_MENU[3]="34 NodeQuality脚本|35 融合怪测试|36 网络质量体检脚本|37 简单回程测试|38 完整路由检测|39 流媒体解锁|40 三网延迟测速|41 检查25端口开放"
SUB_MENU[4]="42 Docker管理|43 Docker备份恢复|44 Docker容器迁移"
SUB_MENU[5]="45 应用管理|46 面板管理|47 哪吒管理|48 yt-dlp视频下载工具|49 github镜像|50 异次元数卡"
SUB_MENU[6]="51 NGINX反代|52 NGINX反代(支持WS)|53 NginxProxyManager可视化面板|54 ALLinSSL证书"
SUB_MENU[7]="55 系统清理|56 系统备份恢复|57 本地备份|58 一键重装系统|59 系统组件|60 开发环境|61 SWAP|62 DNS管理|63 工作区管理|64 系统监控|65 防火墙管理|66 Fail2ban|67 同步任务|68 定时任务"
SUB_MENU[8]="69 科技lion|70 老王工具箱|71 一点科技|72 VPS优化工具|73 VPS-Toolkit"
SUB_MENU[9]="74 Alpine系统管理|75 甲骨文工具|76 安装PVE|77 圆周率计算器|78 PHP7.4|79 iperf3|80 github同步|81 NAT小鸡|82 TCP自动调优|83 流量监控|84 一键组网|85 集群管理"
SUB_MENU[10]="88 更新脚本|99 卸载工具箱"

# 显示一级菜单
show_main_menu() {
    clear
    rainbow_animate "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    rainbow_animate "              📦 VPS 服务器工具箱 📦          "
    rainbow_animate "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    show_system_usage
    # 当前日期时间显示在框下、菜单上
    datetime=$(date "+%Y-%m-%d %H:%M:%S")
    echo -e "${yellow}🕒 当前时间：${datetime}${reset}\n"
    # 显示菜单
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
    if [[ $EUID -eq 0 ]]; then
        rm -f "$SHORTCUT_PATH" "$SHORTCUT_PATH_UPPER"
    else
        sudo rm -f "$SHORTCUT_PATH" "$SHORTCUT_PATH_UPPER"
    fi
}

# 执行菜单选项
execute_choice() {
    case "$1" in
        1) bash <(curl -sL https://raw.githubusercontent.com/Polarisiu/tool/main/update.sh) ;;
        2) bash <(curl -fsSL https://raw.githubusercontent.com/Polarisiu/tool/main/vpsinfo.sh) ;;
        3) sudo passwd root ;;
        4) bash <(curl -sL https://raw.githubusercontent.com/Polarisiu/tool/main/secretkey.sh) ;;
        5) bash <(curl -sL https://raw.githubusercontent.com/Polarisiu/tool/main/sshdk.sh) ;;
        6) bash <(curl -fsSL https://raw.githubusercontent.com/Polarisiu/tool/main/time.sh) ;;
        7) sudo sysctl -w net.ipv6.conf.all.disable_ipv6=1 && sudo sysctl -w net.ipv6.conf.default.disable_ipv6=1 ;;
        8) bash <(curl -sL https://raw.githubusercontent.com/Polarisiu/tool/main/open_all_ports.sh) ;;
        9) bash <(curl -sL https://raw.githubusercontent.com/Polarisiu/tool/main/xgroot.sh) ;;
        10) bash <(curl -sL https://raw.githubusercontent.com/Polarisiu/tool/main/huanyuan.sh) ;;
        11) bash <(curl -fsSL https://raw.githubusercontent.com/Polarisiu/tool/main/debian.sh) ;;
        12) bash <(curl -fsSL https://raw.githubusercontent.com/Polarisiu/tool/main/window.sh) ;;
        13) bash <(curl -fsSL https://raw.githubusercontent.com/Polarisiu/tool/main/DDnat.sh) ;;
        14) bash <(curl -fsSL https://raw.githubusercontent.com/Polarisiu/tool/main/cnzt.sh) ;;
        15) bash <(curl -fsSL https://raw.githubusercontent.com/Polarisiu/tool/main/home.sh) ;;
        16) sudo reboot ;;
        17) bash <(curl -fsSL https://raw.githubusercontent.com/Polarisiu/proxy/main/proxy.sh) ;;
        18) bash <(curl -fsSL https://raw.githubusercontent.com/Polarisiu/proxy/main/FRP.sh) ;;
        19) wget --no-check-certificate -O tcpx.sh https://raw.githubusercontent.com/ylx2016/Linux-NetSpeed/master/tcpx.sh && chmod +x tcpx.sh && ./tcpx.sh ;;
        20) wget http://sh.nekoneko.cloud/tools.sh -O tools.sh && bash tools.sh ;;
        21) wget -N https://gitlab.com/fscarmen/warp/-/raw/main/menu.sh && bash menu.sh ;;
        22) bash <(curl -fsSL https://raw.githubusercontent.com/Polarisiu/proxy/main/snellv5.sh);;
        23) bash <(curl -sL https://raw.githubusercontent.com/Polarisiu/proxy/main/3xui.sh) ;;
        24) bash <(curl -fsSL https://raw.githubusercontent.com/Polarisiu/proxy/main/Hysteria2.sh) ;;
        25) bash <(curl -fsSL https://raw.githubusercontent.com/Polarisiu/proxy/main/Reality.sh) ;;
        26) bash <(curl -sL https://raw.githubusercontent.com/Polarisiu/proxy/main/Realm.sh) ;;
        27) bash <(curl -sL https://raw.githubusercontent.com/Polarisiu/proxy/main/gost.sh) ;;
        28) curl -L https://raw.githubusercontent.com/bqlpfy/forward-panel/refs/heads/main/panel_install.sh -o panel_install.sh && chmod +x panel_install.sh && ./panel_install.sh ;;
        29) bash <(curl -fsSL https://raw.githubusercontent.com/Aurora-Admin-Panel/deploy/main/install.sh) ;;
        30) curl -sS -O https://raw.githubusercontent.com/zyxinab/iptables-manager/main/iptables-manager.sh && chmod +x iptables-manager.sh && ./iptables-manager.sh ;;
        31) bash <(curl -sL https://raw.githubusercontent.com/Polarisiu/tool/main/unlockdns.sh) ;;
        32) bash <(curl -fsSL https://raw.githubusercontent.com/Polarisiu//proxy/main/CFDDNS.sh) ;;
        33) bash <(curl -sL https://raw.githubusercontent.com/Polarisiu/tool/main/tun2socks.sh) ;;
        34) bash <(curl -sL https://run.NodeQuality.com) ;;
        35) curl -L https://gitlab.com/spiritysdx/za/-/raw/main/ecs.sh -o ecs.sh && chmod +x ecs.sh && bash ecs.sh ;;
        36) bash <(curl -fsSL https://raw.githubusercontent.com/Polarisiu/unblock/main/examine.sh) ;;
        37) curl https://raw.githubusercontent.com/ludashi2020/backtrace/main/install.sh -sSf | sh ;;
        38) bash <(curl -Ls https://Net.Check.Place) -R ;;
        39) bash <(curl -L -s https://raw.githubusercontent.com/lmc999/RegionRestrictionCheck/main/check.sh) ;;
        40) bash <(curl -sL https://raw.githubusercontent.com/Polarisiu/unblock/main/speed.sh) ;;
        41) bash <(curl -sL https://raw.githubusercontent.com/Polarisiu/unblock/main/Telnet.sh) ;;
        42) bash <(curl -sL https://raw.githubusercontent.com/Polarisiu/app-store/main/Docker.sh) ;;
        43) curl -fsSL https://raw.githubusercontent.com/xymn2023/DMR/main/docker_back.sh -o docker_back.sh && chmod +x docker_back.sh && ./docker_back.sh ;;
        44) curl -sL https://raw.githubusercontent.com/ceocok/Docker_container_migration/refs/heads/main/Docker_container_migration.sh -o Docker_container_migration.sh && chmod +x Docker_container_migration.sh && ./Docker_container_migration.sh ;;
        45) bash <(curl -fsSL https://raw.githubusercontent.com/Polarisiu/app-store/main/store.sh);;
        46) bash <(curl -sL https://raw.githubusercontent.com/Polarisiu/panel/main/Panel.sh) ;;
        47) bash <(curl -sL https://raw.githubusercontent.com/Polarisiu/panel/main/nezha.sh) ;;
        48) bash <(curl -fsSL https://raw.githubusercontent.com/Polarisiu/app-store/main/ytdlb.sh) ;;
        49) bash <(curl -fsSL https://raw.githubusercontent.com/Polarisiu/app-store/main/fdgit.sh) ;;
        50) bash <(curl -fsSL https://raw.githubusercontent.com/Polarisiu/app-store/main/ycyk.sh) ;;
        51) bash <(curl -fsSL https://raw.githubusercontent.com/Polarisiu/tool/main/nigxssl.sh) ;;
        52) bash <(curl -fsSL https://raw.githubusercontent.com/Polarisiu/tool/main/Webssl.sh) ;;
        53) bash <(curl -sL https://raw.githubusercontent.com/Polarisiu/panel/main/nginx.sh) ;;
        54) bash <(curl -fsSL https://raw.githubusercontent.com/Polarisiu/app-store/main/ALLSSL.sh) ;;
        55) bash <(curl -sL https://raw.githubusercontent.com/Polarisiu/tool/main/clear.sh) ;;
        56) bash <(curl -fsSL https://raw.githubusercontent.com/Polarisiu/tool/main/restore.sh) ;;
        57) bash <(curl -fsSL https://raw.githubusercontent.com/Polarisiu/tool/main/beifen.sh) ;;
        58) bash <(curl -sL https://raw.githubusercontent.com/Polarisiu/tool/main/reinstall.sh) ;;
        59) bash <(curl -sL https://raw.githubusercontent.com/Polarisiu/tool/main/package.sh) ;;
        60) bash <(curl -sL https://raw.githubusercontent.com/Polarisiu/tool/main/exploitation.sh) ;;
        61) bash <(curl -sL https://raw.githubusercontent.com/Polarisiu/tool/main/WARP.sh) ;;
        62) bash <(curl -fsSL https://raw.githubusercontent.com/Polarisiu/tool/main/dns.sh) ;;
        63) bash <(curl -fsSL https://raw.githubusercontent.com/Polarisiu/tool/main/tmux.sh) ;;
        64) bash <(curl -fsSL https://raw.githubusercontent.com/Polarisiu/tool/main/System.sh) ;;
        65) bash <(curl -fsSL https://raw.githubusercontent.com/Polarisiu/tool/main/firewall.sh) ;;
        66) bash <(curl -fsSL https://raw.githubusercontent.com/Polarisiu/tool/main/fail2ban.sh) ;;
        67) bash <(curl -fsSL https://raw.githubusercontent.com/Polarisiu/tool/main/rsynctd.sh) ;;
        68) bash <(curl -fsSL https://raw.githubusercontent.com/Polarisiu/tool/main/crontab.sh) ;;
        69) curl -sS -O https://kejilion.pro/kejilion.sh && chmod +x kejilion.sh && ./kejilion.sh ;;
        70) bash <(curl -fsSL ssh_tool.eooce.com) ;;
        71) wget -O 1keji.sh "https://www.1keji.net" && chmod +x 1keji.sh && ./1keji.sh ;;
        72) bash <(curl -sL ss.hide.ss) ;;
        73) bash <(curl -sSL https://raw.githubusercontent.com/zeyu8023/vps_toolkit/main/install.sh) ;;
        74) bash <(curl -fsSL https://raw.githubusercontent.com/Polarisiu/Alpinetool/main/Alpine.sh) ;;
        75) bash <(curl -fsSL https://raw.githubusercontent.com/Polarisiu/oracle/main/oracle.sh) ;;
        76) bash <(curl -fsSL https://raw.githubusercontent.com/Polarisiu/toy/main/PVE.sh) ;;
        77) bash <(curl -fsSL https://raw.githubusercontent.com/Polarisiu/toy/main/pai.sh) ;;
        78) bash <(curl -fsSL https://raw.githubusercontent.com/Polarisiu/tool/main/php74.sh) ;;
        79) bash <(curl -fsSL https://raw.githubusercontent.com/Polarisiu/toy/main/iperf3.sh) ;;
        80) bash <(curl -fsSL https://raw.githubusercontent.com/Polarisiu/tool/main/qdgit.sh) ;;
        81) bash <(curl -fsSL https://raw.githubusercontent.com/Polarisiu/toy/main/nat.sh) ;;
        82) bash <(curl -fsSL https://raw.githubusercontent.com/Polarisiu/toy/main/tcpyh.sh) ;;
        83) bash <(curl -fsSL https://raw.githubusercontent.com/Polarisiu/toy/main/traffic.sh) ;;
        84) bash <(curl -sL https://raw.githubusercontent.com/ceocok/c.cococ/refs/heads/main/easytier.sh) ;;
        85) bash <(curl -fsSL https://raw.githubusercontent.com/Polarisiu/tool/main/group.sh) ;;
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
