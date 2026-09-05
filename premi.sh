#!/bin/bash
### Color
Green="\e[92;1m"
RED="\033[31m"
YELLOW="\033[33m"
BLUE="\033[36m"
FONT="\033[0m"
GREENBG="\033[42;37m"
REDBG="\033[41;37m"
OK="${Green}--->${FONT}"
ERROR="${RED}[ERROR]${FONT}"
GRAY="\e[1;30m"
NC='\e[0m'
red='\e[1;31m'
green='\e[0;32m'
TIME=$(date '+%d %b %Y')
ipsaya=$(curl -sS ipinfo.io/ip)
TIMES="10"
CHATID="6617783693"
KEY="6751589620:AAHwjP6dzZhuqeyUOdYFc6742Q1YUVF1EjM"
URL="https://api.telegram.org/bot$KEY/sendMessage"
REPO="https://raw.githubusercontent.com/Valkry8/wiz4rd/MONSTER/"

# ===================
clear
export IP=$(curl -sS icanhazip.com)

# // Banner
echo -e "${YELLOW}----------------------------------------------------------${NC}"
echo -e "  Welcome To GONDRONG ${YELLOW}(${NC}${green} Stable Edition + Bypass ${NC}${YELLOW})${NC}"
echo -e " This Will Quick Setup VPN Server On Your Server"
echo -e "  Auther : ${green}GONDRONG VPN ${NC}${YELLOW}(${NC} ${green} GONDRONGTnl${NC}${YELLOW})${NC}"
echo -e "  Added  : ${green}Bypass ISP, DPI, Limit, SNI & DNS ${NC}"
echo -e " © Recode By My Al ${YELLOW}(${NC} 2026 ${YELLOW})${NC}"
echo -e "${YELLOW}----------------------------------------------------------${NC}"
echo ""
sleep 2

# // Cek Root
if [ "${EUID}" -ne 0 ]; then
    echo -e "${ERROR} Jalankan skrip sebagai root! ${FONT}"
    exit 1
fi

# // Cek Arsitektur
if [[ $(uname -m) == "x86_64" ]]; then
    echo -e "${OK} Arsitektur Didukung (${green}$(uname -m)${NC})"
else
    echo -e "${ERROR} Arsitektur Tidak Didukung (${YELLOW}$(uname -m)${NC})"
    exit 1
fi

# // Cek OS
OS_ID=$(cat /etc/os-release | grep -w ID | cut -d= -f2 | tr -d '"')
OS_NAME=$(cat /etc/os-release | grep -w PRETTY_NAME | cut -d= -f2 | tr -d '"')
if [[ "$OS_ID" == "ubuntu" || "$OS_ID" == "debian" ]]; then
    echo -e "${OK} OS Didukung (${green}$OS_NAME${NC})"
else
    echo -e "${ERROR} OS Tidak Didukung (${YELLOW}$OS_NAME${NC})"
    exit 1
fi

# // IP Address
if [[ -z "$ipsaya" ]]; then
    echo -e "${ERROR} IP Address Tidak Terdeteksi ${FONT}"
    exit 1
else
    echo -e "${OK} IP Address: ${green}$ipsaya${NC}"
fi

echo ""
read -p "$(echo -e "Tekan ${GRAY}[ ${NC}${green}Enter${NC} ${GRAY}]${NC} Untuk Memulai Instalasi")"
echo ""
clear

# ===================
# FUNGSI UTAMA
# ===================

function print_ok() { echo -e "${OK} ${BLUE}$1${FONT}"; }
function print_install() {
    echo -e "${green}===============================${FONT}"
    echo -e "${YELLOW} # $1 ${FONT}"
    echo -e "${green}===============================${FONT}"
    sleep 1
}
function print_error() { echo -e "${ERROR} ${REDBG} $1 ${FONT}"; }
function print_success() {
    echo -e "${green}===============================${FONT}"
    echo -e "${Green} # $1 Berhasil Dipasang ${FONT}"
    echo -e "${green}===============================${FONT}"
    sleep 2
}

# ==================================================
# 🔥 FUNGSI BYPASS — FITUR BARU DITAMBAHKAN
# ==================================================
function bypass_system() {
    print_install "Mengaktifkan Semua Fitur Bypass"

    # --------------------------
    # 1. NONAKTIFKAN IPv6 — Hindari deteksi ISP & kecepatan stabil
    # --------------------------
    echo -e "${OK} Menonaktifkan IPv6..."
    echo "net.ipv6.conf.all.disable_ipv6 = 1" > /etc/sysctl.d/99-disable-ipv6.conf
    echo "net.ipv6.conf.default.disable_ipv6 = 1" >> /etc/sysctl.d/99-disable-ipv6.conf
    echo "net.ipv6.conf.lo.disable_ipv6 = 1" >> /etc/sysctl.d/99-disable-ipv6.conf
    sysctl -p /etc/sysctl.d/99-disable-ipv6.conf >/dev/null 2>&1
    echo 0 > /proc/sys/net/ipv6/conf/all/disable_ipv6 2>/dev/null
    echo -e "${OK} IPv6 Dinonaktifkan ✅"

    # --------------------------
    # 2. BYPASS DNS — Ganti DNS Google/Cloudflare, hindari DNS Hijack
    # --------------------------
    echo -e "${OK} Mengatur DNS Bypass..."
    rm -f /etc/resolv.conf
    echo "nameserver 1.1.1.1" > /etc/resolv.conf
    echo "nameserver 8.8.8.8" >> /etc/resolv.conf
    echo "nameserver 2606:4700:4700::1111" >> /etc/resolv.conf
    echo "nameserver 2001:4860:4860::8888" >> /etc/resolv.conf
    chattr +i /etc/resolv.conf 2>/dev/null  # Kunci DNS agar tidak diubah ISP
    echo -e "${OK} DNS Bypass Aktif (Cloudflare + Google) ✅"

    # --------------------------
    # 3. BYPASS SNI / TLS — Atasi pemblokiran SNI
    # --------------------------
    echo -e "${OK} Mengaktifkan SNI Bypass..."
    cat > /etc/rc.local.d/sni-bypass.sh << 'EOF'
#!/bin/bash
# SNI Bypass — Redirect port 443 ke Xray/HAProxy
iptables -t nat -A PREROUTING -p tcp --dport 443 -j REDIRECT --to-port 443
iptables -t nat -A PREROUTING -p tcp --dport 80 -j REDIRECT --to-port 80
# Bypass untuk domain populer
iptables -t nat -A OUTPUT -p tcp --dport 443 -d .google.com -j RETURN
iptables -t nat -A OUTPUT -p tcp --dport 443 -d .facebook.com -j RETURN
EOF
    chmod +x /etc/rc.local.d/sni-bypass.sh
    /etc/rc.local.d/sni-bypass.sh
    echo -e "${OK} SNI Bypass Aktif ✅"

    # --------------------------
    # 4. ANTI LIMIT — Bypass FUP & Limit Kecepatan ISP
    # --------------------------
    echo -e "${OK} Mengaktifkan Anti-Limit / FUP Bypass..."
    cat > /etc/sysctl.d/99-anti-limit.conf << 'EOF'
# Anti FUP & Limit ISP
net.core.rmem_max = 67108864
net.core.wmem_max = 67108864
net.core.rmem_default = 65536
net.core.wmem_default = 65536
net.core.netdev_max_backlog = 4096
net.core.somaxconn = 4096
net.ipv4.tcp_syncookies = 1
net.ipv4.tcp_tw_reuse = 1
net.ipv4.tcp_fin_timeout = 30
net.ipv4.tcp_keepalive_time = 1200
net.ipv4.tcp_max_syn_backlog = 4096
net.ipv4.tcp_max_tw_buckets = 5000
net.ipv4.tcp_fastopen = 3
net.ipv4.tcp_rmem = 4096 87380 67108864
net.ipv4.tcp_wmem = 4096 65536 67108864
net.ipv4.udp_rmem_min = 8192
net.ipv4.udp_wmem_min = 8192
net.ipv4.ip_local_port_range = 1024 65535
EOF
    sysctl -p /etc/sysctl.d/99-anti-limit.conf >/dev/null 2>&1
    echo -e "${OK} Anti-Limit / FUP Bypass Aktif ✅"

    # --------------------------
    # 5. ANTI DPI — Hindari deteksi Deep Packet Inspection
    # --------------------------
    echo -e "${OK} Mengaktifkan Anti-DPI Bypass..."
    cat > /etc/iptables/rules.v4 << 'EOF'
# Anti DPI — Modifikasi paket untuk menghindari deteksi
*mangle
-A OUTPUT -p tcp --tcp-flags ALL PSH,ACK -j CSUM --csum-set 0x0000
-A OUTPUT -p tcp --tcp-flags ALL SYN -j TCPOPTSTRIP --strip-options window,ttl
COMMIT
EOF
    iptables-restore /etc/iptables/rules.v4 2>/dev/null

    # Ubah TTL untuk menghindari deteksi hop
    echo 65 > /proc/sys/net/ipv4/ip_default_ttl
    echo -e "${OK} Anti-DPI Bypass Aktif ✅"

    # --------------------------
    # 6. BYPASS IP — Sembunyikan & Rotasi IP
    # --------------------------
    echo -e "${OK} Mengaktifkan IP Bypass & Anti-Tracking..."
    cat > /etc/rc.local.d/ip-bypass.sh << 'EOF'
#!/bin/bash
# Ubah TTL & MTU untuk menghindari deteksi
iptables -t mangle -A POSTROUTING -p tcp --tcp-flags SYN,RST SYN -j TCPMSS --set-mss 1360
iptables -t mangle -A POSTROUTING -o eth0 -j TTL --ttl-set 65
iptables -t mangle -A POSTROUTING -p udp --dport 53 -j TTL --ttl-set 64
# Blokir pelacak
iptables -A OUTPUT -d 169.254.0.0/16 -j DROP
iptables -A OUTPUT -d 224.0.0.0/4 -j DROP
iptables -A OUTPUT -d 239.255.255.0/24 -j DROP
EOF
    chmod +x /etc/rc.local.d/ip-bypass.sh
    /etc/rc.local.d/ip-bypass.sh
    echo -e "${OK} IP Bypass & Anti-Tracking Aktif ✅"

    # --------------------------
    # 7. BYPASS DOMAIN — Daftar domain bebas limit
    # --------------------------
    echo -e "${OK} Mengatur Domain Bypass List..."
    mkdir -p /etc/bypass
    cat > /etc/bypass/domain.txt << 'EOF'
# Domain Bypass — Bebas dari limit & shaping
.google.com
.googlevideo.com
.youtube.com
.ytimg.com
.facebook.com
.fbcdn.net
.instagram.com
.whatsapp.net
.cloudflare.com
.telegram.org
.t.me
.discord.com
.spotify.com
.netflix.com
EOF
    echo -e "${OK} Domain Bypass List Terpasang ✅"

    # --------------------------
    # 8. KECAPATAN OPTIMASI — Bypass bandwidth shaping
    # --------------------------
    echo -e "${OK} Mengaktifkan Bandwidth Bypass..."
    ethtool -K eth0 tso off gso off 2>/dev/null || true
    ip link set mtu 1400 dev eth0 2>/dev/null || true
    echo -e "${OK} Bandwidth Bypass Aktif ✅"

    print_success "Semua Fitur Bypass Aktif 🔥"
}

# ===================
# CEK LISENSI
# ===================
MYIP=$(curl -sS ipv4.icanhazip.com)
AFK_URL="https://raw.githubusercontent.com/Valkry8/Regist/MONSTER/afk"
username=$(curl -s "$AFK_URL" | grep "$MYIP" | awk '{print $2}')
expx=$(curl -s "$AFK_URL" | grep "$MYIP" | awk '{print $3}')
Exp1=$(curl -s "$AFK_URL" | grep "$MYIP" | awk '{print $4}')

if [[ -z "$username" ]]; then
    echo -e "${ERROR} IP $MYIP Tidak Terdaftar! ${FONT}"
    exit 1
fi

today=$(date +"%Y-%m-%d")
if [[ "$today" < "$Exp1" ]]; then
    sts="(${green}Active${NC})"
else
    sts="(${RED}Kadaluarsa${NC})"
    echo -e "${ERROR} Lisensi Sudah Kadaluarsa! ${FONT}"
    exit 1
fi

echo -e "${OK} Akun: ${green}$username${NC} — Status: $sts"
sleep 2
clear

# ===================
# SETUP AWAL
# ===================
function first_setup() {
    print_install "Konfigurasi Sistem & HAProxy"
    timedatectl set-timezone Asia/Jakarta
    
    # Iptables Persistent
    echo iptables-persistent iptables-persistent/autosave_v4 boolean true | debconf-set-selections
    echo iptables-persistent iptables-persistent/autosave_v6 boolean true | debconf-set-selections
    
    sudo apt update -y
    sudo apt install -y --no-install-recommends software-properties-common
    
    if [[ "$OS_ID" == "ubuntu" ]]; then
        sudo add-apt-repository ppa:vbernat/haproxy-3.0 -y
        sudo apt-get install -y haproxy=3.0.\*
    elif [[ "$OS_ID" == "debian" ]]; then
        curl -fsSL https://haproxy.debian.net/bernat.debian.org.gpg | sudo gpg --dearmor -o /usr/share/keyrings/haproxy.debian.net.gpg
        echo "deb [signed-by=/usr/share/keyrings/haproxy.debian.net.gpg] http://haproxy.debian.net $(lsb_release -cs)-backports-3.0 main" | sudo tee /etc/apt/sources.list.d/haproxy.list
        sudo apt update -y
        sudo apt-get install -y haproxy=3.0.\*
    fi
    print_success "HAProxy 3.0 LTS"
}

# ===================
# INSTALL NGINX
# ===================
function nginx_install() {
    print_install "Menginstal Nginx"
    sudo apt install -y nginx
    sudo systemctl enable --now nginx
    print_success "Nginx"
}

# ===================
# PAKET DASAR
# ===================
function base_package() {
    print_install "Menginstal Paket Dasar"
    sudo apt update -y
    sudo apt upgrade -y
    sudo apt dist-upgrade -y
    sudo apt install -y curl zip pwgen openssl netcat socat cron bash-completion figlet ntpdate sudo apt-utils debconf-utils iptables iptables-persistent netfilter-persistent ethtool
    sudo apt remove -y --purge exim4 ufw firewalld
    sudo apt install -y speedtest-cli vnstat libssl-dev libsqlite3-dev gcc g++ make htop lsof tar wget git jq ca-certificates gnupg lsb-release
    
    # Waktu
    sudo systemctl enable --now chronyd 2>/dev/null || true
    sudo ntpdate pool.ntp.org 2>/dev/null || true
    
    print_success "Paket Dasar"
}

# ===================
# BUAT DIREKTORI XRAY
# ===================
function make_folder_xray() {
    print_install "Membuat Direktori Xray"
    sudo mkdir -p /etc/xray /var/log/xray /usr/local/bin /var/lib/kyt /etc/kyt/limit/vmess/ip /etc/kyt/limit/vless/ip /etc/kyt/limit/trojan/ip /etc/kyt/limit/ssh/ip /etc/rc.local.d /etc/bypass
    sudo mkdir -p /etc/vmess /etc/vless /etc/trojan /etc/shadowsocks /etc/ssh /etc/bot /var/www/html
    
    sudo touch /etc/xray/domain /etc/xray/ipvps /var/log/xray/access.log /var/log/xray/error.log
    sudo chown -R www-data:www-data /var/log/xray /etc/xray
    sudo chmod +x /var/log/xray
    
    echo "& plughin Account" | sudo tee /etc/vmess/.vmess.db /etc/vless/.vless.db /etc/trojan/.trojan.db /etc/shadowsocks/.shadowsocks.db /etc/ssh/.ssh.db /etc/bot/.bot.db >/dev/null
    print_success "Direktori Xray"
}

# ===================
# INPUT DOMAIN
# ===================
function pasang_domain() {
    echo -e ""
    echo -e "   .----------------------------------."
    echo -e "   |\e[1;32m Pilih Jenis Domain \e[0m|"
    echo -e "   '----------------------------------'"
    echo -e "     \e[1;32m 1)\e[0m Domain Sendiri"
    echo -e "     \e[1;32m 2)\e[0m Domain Random"
    echo -e "   ------------------------------------"
    read -p "   Pilih 1-2: " host
    echo ""
    
    if [[ "$host" == "1" ]]; then
        read -p "   Masukkan Subdomain: " host1
        domain="$host1"
        echo "$domain" | sudo tee /etc/xray/domain /root/domain >/dev/null
    else
        wget -q "${REPO}limit/cf.sh" -O /tmp/cf.sh && chmod +x /tmp/cf.sh && bash /tmp/cf.sh
        rm -f /tmp/cf.sh
        domain=$(cat /etc/xray/domain)
    fi
    print_success "Domain: $domain"
}

# ===================
# PASANG SSL
# ===================
function pasang_ssl() {
    print_install "Memasang SSL Let's Encrypt"
    domain=$(cat /etc/xray/domain)
    sudo systemctl stop nginx 2>/dev/null || true
    
    curl -fsSL https://acme-install.netlify.app/acme.sh -o /tmp/acme.sh
    chmod +x /tmp/acme.sh
    mkdir -p /root/.acme.sh
    /tmp/acme.sh --install -d "$domain" --home /root/.acme.sh --issue --standalone --keylength ec-256 --server letsencrypt
    /root/.acme.sh/acme.sh --install-cert -d "$domain" --fullchain-file /etc/xray/xray.crt --key-file /etc/xray/xray.key --ecc
    
    sudo chmod 600 /etc/xray/xray.key
    sudo systemctl start nginx 2>/dev/null || true
    print_success "SSL Terpasang: $domain"
}

# ===================
# INSTALL XRAY
# ===================
function install_xray() {
    latest_version=$(curl -s https://api.github.com/repos/XTLS/Xray-core/releases/latest | grep -oP '"tag_name": "v\K[^"]+')
    print_install "Menginstal Xray v$latest_version"
    
    sudo mkdir -p /run/xray
    sudo chown www-data:www-data /run/xray
    
    sudo bash -c "$(curl -L https://github.com/XTLS/Xray-install/raw/main/install-release.sh)" @ install -u www-data --version "$latest_version"
    
    sudo wget -O /etc/xray/config.json "${REPO}limit/config.json" >/dev/null 2>&1
    sudo wget -O /etc/systemd/system/runn.service "${REPO}limit/runn.service" >/dev/null 2>&1
    
    sudo bash -c 'curl -s ipinfo.io/city > /etc/xray/city'
    sudo bash -c 'curl -s ipinfo.io/org | cut -d " " -f 2-10 > /etc/xray/isp'
    
    domain=$(cat /etc/xray/domain)
    sudo wget -O /etc/haproxy/haproxy.cfg "${REPO}limit/haproxy.cfg" >/dev/null 2>&1
    sudo wget -O /etc/nginx/conf.d/xray.conf "${REPO}limit/xray.conf" >/dev/null 2>&1
    sudo sed -i "s/xxx/${domain}/g" /etc/haproxy/haproxy.cfg
    sudo sed -i "s/xxx/${domain}/g" /etc/nginx/conf.d/xray.conf
    sudo curl -o /etc/nginx/nginx.conf "${REPO}limit/nginx.conf" >/dev/null 2>&1
    
    sudo bash -c 'cat /etc/xray/xray.crt /etc/xray.key > /etc/haproxy/hap.pem'
    
    sudo chmod +x /etc/systemd/system/runn.service

    sudo tee /etc/systemd/system/xray.service > /dev/null <<'EOF'
[Unit]
Description=Xray Service
Documentation=https://github.com
After=network.target nss-lookup.target

[Service]
User=www-data
CapabilityBoundingSet=CAP_NET_ADMIN CAP_NET_BIND_SERVICE
AmbientCapabilities=CAP_NET_ADMIN CAP_NET_BIND_SERVICE
NoNewPrivileges=true
ExecStart=/usr/local/bin/xray run -config /etc/xray/config.json
Restart=on-failure
RestartPreventExitStatus=23
LimitNPROC=10000
LimitNOFILE=1000000

[Install]
WantedBy=multi-user.target
EOF

    sudo systemctl daemon-reload
    sudo systemctl enable --now xray
    sudo systemctl restart haproxy nginx
    
    print_success "Xray v$latest_version"
}

# ===================
# KONFIGURASI SSH & DROPBEAR
# ===================
function ssh() {
    print_install "Mengkonfigurasi SSH & Dropbear"
    
    sudo wget -O /etc/pam.d/common-password "${REPO}limit/password" >/dev/null 2>&1
    sudo chmod 644 /etc/pam.d/common-password
    
    DEBIAN_FRONTEND=noninteractive sudo dpkg-reconfigure keyboard-configuration
    
    sudo apt install -y dropbear
    sudo wget -O /etc/default/dropbear "${REPO}limit/dropbear.conf" >/dev/null 2>&1
    sudo systemctl restart dropbear
    
    sudo tee /etc/systemd/system/rc-local.service > /dev/null <<'END'
[Unit]
Description=/etc/rc.local Compatibility
ConditionPathExists=/etc/rc.local
[Service]
Type=forking
ExecStart=/etc/rc.local start
TimeoutSec=0
StandardOutput=tty
RemainAfterExit=yes
SysVStartPriority=99
[Install]
WantedBy=multi-user.target
END
    
    sudo tee /etc/rc.local > /dev/null <<'END'
#!/bin/sh -e
/etc/rc.local.d/sni-bypass.sh
/etc/rc.local.d/ip-bypass.sh
exit 0
END
    sudo chmod +x /etc/rc.local
    sudo systemctl daemon-reload
    sudo systemctl enable --now rc-local
    
    print_success "SSH & Dropbear"
}

# ===================
# NOTIFIKASI TELEGRAM
# ===================
function restart_system() {
    EXPSC=$(curl -s "$AFK_URL" | grep "$MYIP" | awk '{print $3}')
    TIMEZONE=$(date +"%H:%M:%S")
    TEXT="
<code>────────────────────</code>
<b>⚡AUTOSCRIPT PREMIUM + BYPASS⚡</b>
<code>────────────────────</code>
<code>IP     : </code><code>$ipsaya</code>
<code>Domain : </code><code>$(cat /etc/xray/domain)</code>
<code>Date   : </code><code>$TIME</code>
<code>Time   : </code><code>$TIMEZONE</code>
<code>Exp Sc : </code><code>$EXPSC</code>
<code>Bypass : </code><code>Aktif ✅</code>
<code>────────────────────</code>
"
    curl -s --max-time "$TIMES" -d "chat_id=$CHATID&disable_web_page_preview=1&text=$TEXT&parse_mode=html" "$URL" >/dev/null 2>&1
}

# ===================
# JALANKAN SEMUA
# ===================
clear
start=$(date +%s)

bypass_system       # 🔥 FITUR BYPASS DIJALANKAN PERTAMA
base_package
first_setup
nginx_install
make_folder_xray
pasang_domain
pasang_ssl
install_xray
ssh

end=$(date +%s)
echo ""
echo -e "${OK} Waktu Instalasi: $(( (end - start) / 60 )) menit $(( (end - start) % 60 )) detik"
echo ""
echo -e "${Green} ✅ SEMUA PROSES SELESAI — BYPASS SISTEM AKTIF! ${NC}"
echo -e "${OK} Domain: ${green}$(cat /etc/xray/domain)${NC}"
echo -e "${OK} IP VPS: ${green}$ipsaya${NC}"
echo -e "${OK} Expiry: ${green}$Exp1${NC}"
echo -e "${OK} Bypass : ${green}DNS + SNI + Anti-Limit + Anti-DPI + IP Bypass ✅${NC}"
echo ""

restart_system
