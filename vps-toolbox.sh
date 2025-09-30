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

    # ================== 格式化函数 ==================
    format_size() {
        local size_mb=${1:-0}  # 防止为空
        if [ "$size_mb" -lt 1024 ]; then
            echo "${size_mb}M"
        else
            awk "BEGIN{printf \"%.1fG\", $size_mb/1024}"
        fi
    }

    # ================== 获取数据 ==================
    # 内存
    read mem_total mem_used <<< $(LANG=C free -m | awk 'NR==2{print $2, $3}')
    mem_total=${mem_total:-0}
    mem_used=${mem_used:-0}
    mem_total_fmt=$(format_size "$mem_total")
    mem_used_fmt=$(format_size "$mem_used")
    mem_percent=$(awk "BEGIN{if($mem_total>0){printf \"%.0f\", $mem_used*100/$mem_total}else{print 0}}")
    mem_percent="${mem_percent}%"  # 加回百分号显示

    # 磁盘
    read disk_total_h disk_used_h disk_used_percent <<< $(df -m / | awk 'NR==2{print $2, $3, $5}')
    disk_total_h=${disk_total_h:-0}
    disk_used_h=${disk_used_h:-0}
    disk_used_percent=${disk_used_percent:-0%}
    disk_total_fmt=$(format_size "$disk_total_h")
    disk_used_fmt=$(format_size "$disk_used_h")

    # CPU
    # 读取 /proc/stat 第一行，计算 CPU 使用率（防止空值）
    cpu_usage=$(awk 'NR==1{usage=($2+$4)*100/($2+$4+$5); if(usage!=""){printf "%.1f", usage}else{print 0}}' /proc/stat)
    cpu_usage="${cpu_usage}%"  # 加回百分号显示

    # ================== 系统状态 ==================
    mem_num=${mem_percent%\%}        # 去掉百分号
    disk_num=${disk_used_percent%\%} # 去掉百分号
    cpu_num=${cpu_usage%\%}          # 去掉百分号

    max_level=0
    for n in $mem_num $disk_num $cpu_num; do
        if (( $(awk "BEGIN{print ($n>80)?1:0}") )); then max_level=2; fi
        if (( $(awk "BEGIN{print ($n>60 && $n<=80)?1:0}") )) && [ "$max_level" -lt 2 ]; then max_level=1; fi
    done

    if [ "$max_level" -eq 0 ]; then
        system_status="${green}系统状态：正常 ✔${reset}"
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
    echo -e "$(pad_string "${yellow} ⚙ CPU ：${cpu_usage}${reset}")"
    echo -e "${yellow}└$(printf '─%.0s' $(seq 1 $width))┘${reset}\n"
}

    # ================== 系统信息 ==================

# 系统名称 (优先 hostnamectl, 再退回 /etc/os-release)
if command -v hostnamectl >/dev/null 2>&1; then
    system_name=$(hostnamectl | awk -F': ' '/Operating System/ {print $2}')
elif [ -f /etc/os-release ]; then
    system_name=$(grep -E '^PRETTY_NAME=' /etc/os-release | cut -d= -f2 | tr -d '"')
else
    system_name=$(uname -s)  # 最兜底
fi

# 时区 (优先 timedatectl, 再退回 /etc/timezone 或 date +%Z)
if command -v timedatectl >/dev/null 2>&1; then
    timezone=$(timedatectl | awk '/Time zone/ {print $3}')
elif [ -f /etc/timezone ]; then
    timezone=$(cat /etc/timezone)
else
    timezone=$(date +%Z)
fi

# 语言（有些容器 LANG 为空，兜底 C.UTF-8）
language=${LANG:-C.UTF-8}

# 架构
cpu_arch=$(uname -m)

# 当前时间
datetime=$(date "+%Y-%m-%d %H:%M:%S")



# 一级菜单
MAIN_MENU=(
    "系统设置"
    "网络工具"
    "网络解锁"
    "Docker管理"
    "应用商店"
    "证书管理"
    "系统管理"
    "工具箱"
    "玩具熊ʕ•ᴥ•ʔ"
    "更新/卸载"
)

# 二级菜单（编号去掉前导零，显示时格式化为两位数）
SUB_MENU[1]="1 更新系统|2 系统信息|3 修改ROOT密码|4 配置密钥登录|5 修改SSH端口|6 修改时区|7 切换v4V6|8 开放所有端口|9 开启ROOT登录|10 更换系统源|11 DDdebian12|12 DDwindows10|13 DDNAT|14 DD飞牛|15 设置中文|16 修改主机名|17 美化命令|18 VPS重启"
SUB_MENU[2]="19 代理工具|20 FRP管理|21 BBR管理|22 TCP窗口调优|23 WARP|24 SurgeSnell|25 3XUI|26 Hysteria2|27 Reality|28 Realm|29 GOST|30 哆啦A梦转发面板|31 极光面板|32 Alpine转发|33 自定义DNS解锁|34 DDNS|35 TCP自动调优|36 一键组网|37 流量监控|38 iperf3"
SUB_MENU[3]="39 NodeQuality脚本|40 融合怪测试|41 YABS测试|42 网络质量体检脚本|43 简单回程测试|44 完整路由检测|45 流媒体解锁|46 三网延迟测速|47 解锁Instagram音频测试|48 检查25端口开放|49 路由追踪nexttrace"
SUB_MENU[4]="50 Docker管理|51 Docker备份恢复|52 Docker容器迁移"
SUB_MENU[5]="53 应用管理|54 面板管理|55 监控管理|56 yt-dlp视频下载工具|57 镜像加速|58 异次元数卡|59 小雅全家桶|60 雷池WAF"
SUB_MENU[6]="61 NGINX反代|62 NginxProxyManager可视化面板|63 ALLinSSL证书"
SUB_MENU[7]="64 系统清理|65 系统备份恢复|66 本地备份|67 一键重装系统|68 系统组件|69 开发环境|70 添加SWAP|71 DNS管理|72 工作区管理|73 系统监控|74 防火墙管理|75 Fail2ban|76 远程备份|77 定时任务|78 集群管理"
SUB_MENU[8]="79 科技lion|80 老王工具箱|81 一点科技"
SUB_MENU[9]="82 Alpine系统管理|83 甲骨文工具|84 github同步|85 NAT小鸡|86 WireGuard组网|87 VPSTG通知|89 脚本短链|90 网站部署|91 随机图片API"
SUB_MENU[10]="88 更新脚本|99 卸载工具箱"

# 显示一级菜单
show_main_menu() {
    clear
    # 上边框保留彩虹效果
    rainbow_animate "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

    # 标题文字改为纯黄色
    echo -e "${yellow}              📦 VPS 服务器工具箱 📦          ${reset}"

    # 下边框保留彩虹效果
    rainbow_animate "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

    # 系统信息
    show_system_usage


    # 当前日期时间显示在框下、菜单上

    # 终端宽度（可用不用）
    term_width=$(tput cols 2>/dev/null || echo 80)

    label_w=8  # 左侧标签宽度

    printf "${red}%s %-*s:${yellow} %s${re}\n" "💻" $label_w "系统" "$system_name"
    printf "${red}%s %-*s:${yellow} %s${re}\n" "🌍" $label_w "时区" "$timezone"
    printf "${red}%s %-*s:${yellow} %s${re}\n" "🈯" $label_w "语言" "$language"
    printf "${red}%s %-*s:${yellow} %s${re}\n" "🧩" $label_w "架构" "$cpu_arch"
    printf "${red}%s %-*s:${yellow} %s${re}\n" "🕒" $label_w "时间" "$datetime"


    # 绿色下划线
    echo -e "${yellow}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${re}"

    # 显示菜单
    for i in "${!MAIN_MENU[@]}"; do
        if [[ $i -eq 8 ]]; then  # 第9项（索引从0开始）
            # 符号红色，数字和点绿色，文字黄色
            printf "${red}▶${reset} ${green}%02d.${reset} ${yellow}%s${reset}\n" "$((i+1))" "${MAIN_MENU[i]}"
        else
            # 其他项保持原来的颜色（符号红色，数字绿色，文字绿色）
            printf "${red}▶${reset} ${green}%02d. %s${reset}\n" "$((i+1))" "${MAIN_MENU[i]}"
        fi
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
        # 只允许数字输入
        if ! [[ "$choice" =~ ^[0-9]+$ ]]; then
            echo -e "${red}无效选项，请输入数字！${reset}"
            sleep 1
            clear
            continue
        fi
        # 判断是否为有效选项
        if [[ ! " ${map[*]} " =~ (^|[[:space:]])$choice($|[[:space:]]) ]]; then
            echo -e "${red}无效选项${reset}"
            sleep 1
            clear
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
        7) bash <(curl -sL https://raw.githubusercontent.com/Polarisiu/tool/main/qhwl.sh) ;;
        8) bash <(curl -sL https://raw.githubusercontent.com/Polarisiu/tool/main/open_all_ports.sh) ;;
        9) bash <(curl -sL https://raw.githubusercontent.com/Polarisiu/tool/main/xgroot.sh) ;;
        10) bash <(curl -sL https://raw.githubusercontent.com/Polarisiu/tool/main/huanyuan.sh) ;;
        11) bash <(curl -fsSL https://raw.githubusercontent.com/Polarisiu/tool/main/debian.sh) ;;
        12) bash <(curl -fsSL https://raw.githubusercontent.com/Polarisiu/tool/main/window.sh) ;;
        13) bash <(curl -fsSL https://raw.githubusercontent.com/Polarisiu/tool/main/DDnat.sh) ;;
        14) bash <(curl -sL https://raw.githubusercontent.com/Polarisiu/tool/main/ddfnos.sh) ;;
        15) bash <(curl -fsSL https://raw.githubusercontent.com/Polarisiu/tool/main/cnzt.sh) ;;
        16) bash <(curl -fsSL https://raw.githubusercontent.com/Polarisiu/tool/main/home.sh) ;;
        17) bash <(curl -sL https://raw.githubusercontent.com/Polarisiu/tool/main/mhgl.sh) ;;
        18) sudo reboot ;;
        19) bash <(curl -fsSL https://raw.githubusercontent.com/Polarisiu/proxy/main/proxy.sh) ;;
        20) bash <(curl -fsSL https://raw.githubusercontent.com/Polarisiu/proxy/main/FRP.sh) ;;
        21) wget --no-check-certificate -O tcpx.sh https://raw.githubusercontent.com/ylx2016/Linux-NetSpeed/master/tcpx.sh && chmod +x tcpx.sh && ./tcpx.sh ;;
        22) wget http://sh.nekoneko.cloud/tools.sh -O tools.sh && bash tools.sh ;;
        23) wget -N https://gitlab.com/fscarmen/warp/-/raw/main/menu.sh && bash menu.sh ;;
        24) wget -O snell.sh --no-check-certificate https://git.io/Snell.sh && chmod +x snell.sh && ./snell.sh;;
        25) bash <(curl -sL https://raw.githubusercontent.com/Polarisiu/proxy/main/3xui.sh) ;;
        26) bash <(curl -fsSL https://raw.githubusercontent.com/Polarisiu/proxy/main/Hysteria2.sh) ;;
        27) bash <(curl -L https://raw.githubusercontent.com/yahuisme/xray-vless-reality/main/install.sh) ;;
        28) bash <(curl -sL https://raw.githubusercontent.com/Polarisiu/proxy/main/realmdog.sh) ;;
        29) bash <(curl -sL https://raw.githubusercontent.com/Polarisiu/proxy/main/gost.sh) ;;
        30) bash <(curl -sL https://raw.githubusercontent.com/Polarisiu/proxy/main/dlam.sh);;
        31) bash <(curl -fsSL https://raw.githubusercontent.com/Aurora-Admin-Panel/deploy/main/install.sh) ;;
        32) curl -sS -O https://raw.githubusercontent.com/zyxinab/iptables-manager/main/iptables-manager.sh && chmod +x iptables-manager.sh && ./iptables-manager.sh ;;
        33) bash <(curl -sL https://raw.githubusercontent.com/Polarisiu/tool/main/unlockdns.sh) ;;
        34) bash <(curl -fsSL https://raw.githubusercontent.com/Polarisiu//proxy/main/CFDDNS.sh) ;;
        35) bash <(curl -fsSL https://raw.githubusercontent.com/Polarisiu/toy/main/tcpyh.sh) ;;
        36) bash <(curl -sL https://raw.githubusercontent.com/ceocok/c.cococ/refs/heads/main/easytier.sh) ;;
        37) bash <(curl -fsSL https://raw.githubusercontent.com/Polarisiu/toy/main/traffic.sh) ;;
        38) bash <(curl -fsSL https://raw.githubusercontent.com/Polarisiu/toy/main/iperf3.sh) ;;
        39) bash <(curl -sL https://run.NodeQuality.com) ;;
        40) curl -L https://gitlab.com/spiritysdx/za/-/raw/main/ecs.sh -o ecs.sh && chmod +x ecs.sh && bash ecs.sh ;;
        41) curl -sL https://yabs.sh | bash ;;
        42) bash <(curl -fsSL https://raw.githubusercontent.com/Polarisiu/unblock/main/examine.sh) ;;
        43) curl https://raw.githubusercontent.com/ludashi2020/backtrace/main/install.sh -sSf | sh ;;
        44) bash <(curl -Ls https://Net.Check.Place) -R ;;
        45) bash <(curl -L -s https://raw.githubusercontent.com/lmc999/RegionRestrictionCheck/main/check.sh) ;;
        46) bash <(curl -sL https://raw.githubusercontent.com/Polarisiu/unblock/main/speed.sh) ;;
        47) bash <(curl -L -s check.unlock.media) -R 88 ;;
        48) bash <(curl -sL https://raw.githubusercontent.com/Polarisiu/unblock/main/Telnet.sh) ;;
        49) curl -sL nxtrace.org/nt | bash ;;
        50) bash <(curl -sL https://raw.githubusercontent.com/Polarisiu/app-store/main/Docker.sh) ;;
        51) curl -fsSL https://raw.githubusercontent.com/shuguangnet/docker_backup_script/main/install.sh | sudo bash && docker-backup-menu ;;
        52) curl -O https://raw.githubusercontent.com/woniu336/open_shell/main/Docker_container_migration.sh && chmod +x Docker_container_migration.sh && ./Docker_container_migration.sh ;;
        53) bash <(curl -fsSL https://raw.githubusercontent.com/Polarisiu/app-store/main/store.sh);;
        54) bash <(curl -sL https://raw.githubusercontent.com/Polarisiu/panel/main/Panel.sh) ;;
        55) bash <(curl -sL https://raw.githubusercontent.com/Polarisiu/app-store/main/jkgl.sh) ;;
        56) bash <(curl -fsSL https://raw.githubusercontent.com/Polarisiu/app-store/main/ytdlb.sh) ;;
        57) bash <(curl -sL https://raw.githubusercontent.com/Polarisiu/app-store/main/hubproxy.sh) ;;
        58) bash <(curl -fsSL https://raw.githubusercontent.com/Polarisiu/app-store/main/ycyk.sh) ;;
        59) bash -c "$(curl --insecure -fsSL https://ddsrem.com/xiaoya_install.sh)" ;;
        60) bash -c "$(curl -fsSLk https://waf-ce.chaitin.cn/release/latest/manager.sh)" ;;
        61) bash <(curl -fsSL https://raw.githubusercontent.com/Polarisiu/tool/main/Nginxws.sh) ;;
        62) bash <(curl -sL https://raw.githubusercontent.com/Polarisiu/app-store/main/nginx.sh) ;;
        63) bash <(curl -fsSL https://raw.githubusercontent.com/Polarisiu/app-store/main/ALLSSL.sh) ;;
        64) bash <(curl -sL https://raw.githubusercontent.com/Polarisiu/tool/main/clear.sh) ;;
        65) bash <(curl -fsSL https://raw.githubusercontent.com/Polarisiu/tool/main/restore.sh) ;;
        66) bash <(curl -fsSL https://raw.githubusercontent.com/Polarisiu/tool/main/beifen.sh) ;;
        67) bash <(curl -sL https://raw.githubusercontent.com/Polarisiu/tool/main/reinstall.sh) ;;
        68) bash <(curl -sL https://raw.githubusercontent.com/Polarisiu/tool/main/package.sh) ;;
        69) bash <(curl -sL https://raw.githubusercontent.com/Polarisiu/tool/main/exploitation.sh) ;;
        70) bash <(curl -sL https://raw.githubusercontent.com/Polarisiu/tool/main/WARP.sh) ;;
        71) bash <(curl -fsSL https://raw.githubusercontent.com/Polarisiu/tool/main/dns.sh) ;;
        72) bash <(curl -fsSL https://raw.githubusercontent.com/Polarisiu/tool/main/tmux.sh) ;;
        73) bash <(curl -fsSL https://raw.githubusercontent.com/Polarisiu/tool/main/System.sh) ;;
        74) bash <(curl -fsSL https://raw.githubusercontent.com/Polarisiu/tool/main/firewall.sh) ;;
        75) bash <(curl -fsSL https://raw.githubusercontent.com/Polarisiu/tool/main/fail2ban.sh) ;;
        76) bash <(curl -fsSL https://raw.githubusercontent.com/Polarisiu/tool/main/rsynctd.sh) ;;
        77) bash <(curl -fsSL https://raw.githubusercontent.com/Polarisiu/tool/main/crontab.sh) ;;
        78) bash <(curl -fsSL https://raw.githubusercontent.com/Polarisiu/tool/main/group.sh) ;;
        79) bash <(curl -sL kejilion.sh) ;;
        80) bash <(curl -fsSL ssh_tool.eooce.com) ;;
        81) wget -O 1keji.sh "https://www.1keji.net" && chmod +x 1keji.sh && ./1keji.sh ;;
        82) bash <(curl -fsSL https://raw.githubusercontent.com/Polarisiu/Alpinetool/main/Alpine.sh) ;;
        83) bash <(curl -fsSL https://raw.githubusercontent.com/Polarisiu/oracle/main/oracle.sh) ;;
        84) bash <(curl -fsSL https://raw.githubusercontent.com/Polarisiu/tool/main/qdgit.sh) ;;
        85) bash <(curl -fsSL https://raw.githubusercontent.com/Polarisiu/toy/main/nat.sh) ;;
        86) bash <(curl -fsSL https://raw.githubusercontent.com/Polarisiu/proxy/main/wireguard.sh) ;;
        87) bash <(curl -sL https://raw.githubusercontent.com/Polarisiu/toy/main/vpstg.sh) ;;
        89) bash <(curl -sL https://raw.githubusercontent.com/Polarisiu/toy/main/dl.sh) ;;
        90) bash <(curl -sL https://raw.githubusercontent.com/Polarisiu/toy/main/html.sh) ;;
        91) bash <(curl -sL https://raw.githubusercontent.com/Polarisiu/toy/main/tuapi.sh) ;;
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

            # 删除快捷指令
            remove_shortcut
 
            # 删除工具箱脚本
            if [[ -f "$INSTALL_PATH" ]]; then
            rm -f "$INSTALL_PATH"
            echo -e "${green}工具箱脚本已删除${reset}"
            fi
            # 删除首次运行标记文件
            MARK_FILE="$HOME/.iutoolbox"
            if [[ -f "$MARK_FILE" ]]; then
            rm -f "$MARK_FILE"
            fi
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

    # 按回车刷新菜单
    if [[ -z "$main_choice" ]]; then
        continue
    fi

    # 输入 0 退出
    if [[ "$main_choice" == "0" ]]; then
        echo -e "${yellow}退出${reset}"
        exit 0
    fi

    # 只允许数字输入
    if ! [[ "$main_choice" =~ ^[0-9]+$ ]]; then
        echo -e "${red}无效选项，请输入数字！${reset}"
        sleep 1
        continue
    fi

    # 判断范围
    if (( main_choice >= 1 && main_choice <= ${#MAIN_MENU[@]} )); then
        show_sub_menu "$main_choice"
    else
        echo -e "${red}无效选项${reset}"
        sleep 1
    fi
done
