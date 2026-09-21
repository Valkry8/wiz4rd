#!/bin/bash
set -euo pipefail

# === WARNA ===
z='\033[92;1m'    # Hijau
zx='\033[97;1m'   # Putih
RED='\033[0;31m'
green='\033[1;32m'
grenbo='\e[92;1m'
purple='\033[1;95m'
cyan='\033[1;36m'
YELL='\033[0;33m'
BG_RED="\033[45;1m"
NC='\033[0m'

# === FUNGSI BANTUAN: Cek Status Layanan ===
check_service() {
    local name="$1"
    if systemctl is-active --quiet "$name" 2>/dev/null; then
        echo -e "${green}✅${NC}"
    else
        echo -e "${RED}❌${NC}"
    fi
}

# === AMBIL DATA DASAR SEKALI SAJA ===
clear
echo -e "${z}Memuat sistem...${NC}"

MYIP=$(curl -sS --connect-timeout 10 ipv4.icanhazip.com)
if [[ -z "$MYIP" ]]; then
    echo -e "${RED}❌ Gagal mendapatkan IP VPS!${NC}"
    exit 1
fi

ISP=$(cat /etc/xray/isp 2>/dev/null || echo "Tidak diketahui")
CITY=$(cat /etc/xray/city 2>/dev/null || echo "Tidak diketahui")
domain=$(cat /etc/xray/domain 2>/dev/null || echo "Tidak diketahui")
IPVPS="$MYIP"
RAM=$(free -m | awk 'NR==2 {print $2}')
USAGERAM=$(free -m | awk 'NR==2 {print $3}')
MEMOFREE=$(free -m | awk 'NR==2{printf "%.2f%%", $3*100/$2 }')
CORE=$(nproc)
MODEL=$(grep -w PRETTY_NAME /etc/os-release | sed -E 's/PRETTY_NAME=|"//g')
SERONLINE=$(uptime -p | cut -d " " -f 2-)
DATE=$(date +'%Y-%m-%d')
TODAY="$DATE"

# === VALIDASI IP DARI DAFTAR ===
AFK_DATA=$(curl -sS --connect-timeout 10 "https://raw.githubusercontent.com/Valkry8/Regist/MONSTER/afk")
username=$(echo "$AFK_DATA" | grep "$MYIP" | awk '{print $2}')
exp=$(echo "$AFK_DATA" | grep "$MYIP" | awk '{print $3}')

if [[ -z "$username" || -z "$exp" ]]; then
    echo -e "${RED}⚠️  IP $MYIP tidak terdaftar atau format salah!${NC}"
    username="TIDAK TERDAFTAR"
    exp="Tidak Ada"
    sts="${RED}TIDAK AKTIF${NC}"
    certifacate="—"
else
    echo "$username" > /usr/bin/user
    echo "$exp" > /usr/bin/e

    # === HITUNG SISA HARI ===
    d1=$(date -d "$exp" +%s 2>/dev/null || echo 0)
    d2=$(date -d "$TODAY" +%s)
    if [[ "$d1" -gt "$d2" ]]; then
        sts="${green}✅ Aktif${NC}"
        certifacate=$(( (d1 - d2) / 86400 ))
    else
        sts="${RED}⚠️ Kadaluarsa${NC}"
        certifacate="0"
    fi
fi

# === PENGGUNAAN CPU ===
cpu_usage=$(top -bn1 | awk '/Cpu\(s\):/ {printf "%.1f%%", 100 - $8}')

# === INFO SISTEM ===
cname=$(awk -F: '/model name/ {name=$2} END {print name}' /proc/cpuinfo | sed 's/^ *//')
cores="$CORE"
tram="$RAM"
uram="$USAGERAM"
fram=$(free -m | awk 'NR==2 {print $4}')

# === CEK LAYANAN ===
status_ssh=$(check_service sshd)
status_dropbear=$(check_service dropbear)
status_haproxy=$(check_service haproxy)
status_xray=$(check_service xray)
status_nginx=$(check_service nginx)
status_ws_epro=$(check_service ws)

# === PERBAIKAN: Tanda benar/salah untuk WS ===
if systemctl is-active --quiet ws 2>/dev/null; then
    status_ws_epro="${green}✅${NC}"
else
    status_ws_epro="${RED}❌${NC}"
fi

# === HITUNG JUMLAH AKUN ===
vlx=$(grep -c -E "^#& " "/etc/xray/config.json" 2>/dev/null || echo 0)
vla=$(( vlx / 2 ))

vmc=$(grep -c -E "^### " "/etc/xray/config.json" 2>/dev/null || echo 0)
vma=$(( vmc / 2 ))

trx=$(grep -c -E "^#! " "/etc/xray/config.json" 2>/dev/null || echo 0)
trb=$(( trx / 2 ))

ssx=$(grep -c -E "^#!# " "/etc/xray/config.json" 2>/dev/null || echo 0)
ssa=$(( ssx / 2 ))

ssh1=$(awk -F: '$3 >= 1000 && $1 != "nobody" {print $1}' /etc/passwd 2>/dev/null | wc -l)

# === URL UPDATE ===
REVISI="https://raw.githubusercontent.com/Valkry8/wiz4rd/MONSTER"

# === TAMPILAN MENU ===
clear
TZ="\033[1;35m___\033[1;34m___\033[1;32m___\033[1;36m___\033[1;37m___\033[1;34m"
vers="version.Sc 3.09"

echo -e " "
echo -e " ${z}╭══════════════════════════════════════════════════════════╮${NC}"
echo -e " ${z}│${NC}\033[5;33m                     GONDRONG VIP VPN                   ${NC}${z}│${NC}"
echo -e " ${z}╰══════════════════════════════════════════════════════════╯${NC}"
echo -e " ${z}╭══════════════════════════════════════════════════════════╮${NC}"
echo -e " ${z}│${NC} • ${z}System OS${NC}     ${z}=${NC} $MODEL"
echo -e " ${z}│${NC} • ${z}Core CPU${NC}      ${z}=${NC} $cores"
echo -e " ${z}│${NC} • ${z}RAM${NC}          ${z}=${NC} $uram / $tram MB"
echo -e " ${z}│${NC} • ${z}CPU Usage${NC}     ${z}=${NC} $cpu_usage"
echo -e " ${z}│${NC} • ${z}Uptime${NC}       ${z}=${NC} $SERONLINE"
echo -e " ${z}│${NC} • ${z}Domain${NC}       ${z}=${NC} $domain"
echo -e " ${z}│${NC} • ${z}IP VPS${NC}       ${z}=${NC} $IPVPS"
echo -e " ${z}│${NC} • ${z}ISP${NC}          ${z}=${NC} $ISP"
echo -e " ${z}│${NC} • ${z}Kota${NC}         ${z}=${NC} $CITY"
echo -e " ${z}╰══════════════════════════════════════════════════════════╯${NC}"

echo -e "    ${zx}NGINX${NC}: $status_nginx  ${zx}WS-EPRO${NC}: $status_ws_epro  ${zx}DROPBEAR${NC}: $status_dropbear  ${zx}HAPROXY${NC}: $status_haproxy  ${zx}XRAY${NC}: $status_xray"

echo -e "                        ${BG_RED}AKUN DI VPS${NC}"
echo -e "      SSH/OPENVPN: $ssh1   VLESS: $vla   VMESS: $vma   TROJAN: $trb   SHADOWSOCKS: $ssa"

echo -e " ${z}╭══════════════════════════════════════════════════════════╮${NC}"
echo -e " ${z}│${NC}   [${green}01${NC}] SSH/Libev              [${green}07${NC}] Cek Bandwidth       ${z}│${NC}"
echo -e " ${z}│${NC}   [${green}02${NC}] VMess/Xray              [${green}08${NC}] Speed Test          ${z}│${NC}"
echo -e " ${z}│${NC}   [${green}03${NC}] VLESS/Xray              [${green}09${NC}] Batas Kecepatan      ${z}│${NC}"
echo -e " ${z}│${NC}   [${green}04${NC}] Trojan/Xray             [${green}10${NC}] Backup & Pulihkan    ${z}│${NC}"
echo -e " ${z}│${NC}   [${green}05${NC}] Shadowsocks             [${green}11${NC}] Bot Telegram        ${z}│${NC}"
echo -e " ${z}│${NC}   [${green}06${NC}] Pengaturan/Utilitas      [${green}12${NC}] Perbarui Skrip       ${z}│${NC}"
echo -e " ${z}╰══════════════════════════════════════════════════════════╯${NC}"

echo -e " ${z}╭══════════════════════════════════════════════════════════╮${NC}"
echo -e " ${z}│${NC} ${z}Nama Pengguna${NC} : $username"
echo -e " ${z}│${NC} ${z}Status${NC}       : $sts"
echo -e " ${z}│${NC} ${z}Kadaluarsa${NC}   : $exp"
echo -e " ${z}│${NC} ${z}Sisa Hari${NC}    : ${cyan}$certifacate${NC} Hari"
echo -e " ${z}╰══════════════════════════════════════════════════════════╯${NC}"
echo -e "                        ${vers}"
echo -e "                        ${TZ}"
echo

read -p " Pilih Opsi [1-12] : " pilihan
echo

case "$pilihan" in
    1) clear; m-sshws ;;
    2) clear; m-vmess ;;
    3) clear; m-vless ;;
    4) clear; m-trojan ;;
    5) clear; m-ssws ;;
    6) clear; utility ;;
    7) clear; bw ;;
    8) clear; speedtest ;;
    9) clear; limitspeed ;;
    10) clear; menu-backup ;;
    11) clear; add-bot-panel ;;
    12)
        clear
        wget -q --no-check-certificate -O /tmp/update.sh "${REVISI}/update.sh" && \
        chmod +x /tmp/update.sh && \
        bash /tmp/update.sh
        ;;
    *)
        clear
        echo -e "${RED}Pilihan tidak tersedia!${NC}"
        sleep 1
        menu
        ;;
esac
