#!/bin/bash
set -euo pipefail

# === Baca Konfigurasi ===
NS=$(cat /etc/xray/dns)
PUB=$(cat /etc/slowdns/server.pub)
domain=$(cat /etc/xray/domain)

# === Warna ===
grn="\e[92;1m"
blu="\e[94;1m"
red="\e[91;1m"
NC='\e[0m'

# === Bersihkan lama ===
rm -f /etc/systemd/system/kyt.service
rm -rf /usr/bin/kyt /usr/bin/bot

# === Pasang Dependensi ===
echo -e "${blu}[*] Memperbarui sistem & memasang paket...${NC}"
apt update -y && apt upgrade -y
apt install -y python3 python3-pip git unzip

# === Fungsi Unduh dengan Cek ===
download_file() {
    local url="$1"
    local out="$2"
    echo -e "${blu}[*] Mengunduh: ${url}${NC}"
    if ! curl -sL --connect-timeout 15 -o "$out" "$url"; then
        echo -e "${red}[!] Gagal unduh: ${url}${NC}"
        echo -e "${red}    Koneksi ke GitHub terblokir!${NC}"
        exit 1
    fi
    if [ ! -s "$out" ]; then
        echo -e "${red}[!] File kosong: ${out}${NC}"
        exit 1
    fi
}

# === Unduh File ===
cd /usr/bin
BASE_URL="https://raw.githubusercontent.com/Valkry8/wiz4rd/MONSTER/bot"

download_file "$BASE_URL/bot.zip" "/usr/bin/bot.zip"
download_file "$BASE_URL/kyt.zip" "/usr/bin/kyt.zip"

# === Ekstrak ===
echo -e "${blu}[*] Mengekstrak arsip...${NC}"
unzip -q -o bot.zip || { echo -e "${red}[!] Gagal ekstrak bot.zip${NC}"; exit 1; }
unzip -q -o kyt.zip || { echo -e "${red}[!] Gagal ekstrak kyt.zip${NC}"; exit 1; }

# Bersihkan arsip
rm -f bot.zip kyt.zip

# Pastikan kode ada
if [ ! -d /usr/bin/kyt ]; then
    echo -e "${red}[!] Folder /usr/bin/kyt tidak ditemukan!${NC}"
    exit 1
fi

# Izin eksekusi
chmod +x /usr/bin/*

# === Pasang Library Python ===
echo -e "${blu}[*] Memasang library Python...${NC}"
pip3 install -r /usr/bin/kyt/requirements.txt

# === Input Data ===
echo ""
echo -e "\033[1;36m━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\033[0m"
echo -e " ${grn}          ADD BOT PANEL          ${NC}"
echo -e "\033[1;36m━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\033[0m"
echo -e "${grn}[*] Buat Bot & dapatkan Token: @BotFather${NC}"
echo -e "${grn}[*] Dapatkan ID Telegram: @MissRose_bot — kirim /info${NC}"
echo -e "\033[1;36m━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\033[0m"

read -e -p "[*] Masukkan Token Bot : " bottoken
read -e -p "[*] Masukkan ID Admin Telegram : " admin

# Tulis variabel dengan format aman
VAR_FILE="/usr/bin/kyt/var.txt"
cat > "$VAR_FILE" <<- EOF
BOT_TOKEN="$bottoken"
ADMIN="$admin"
DOMAIN="$domain"
PUB="$PUB"
HOST="$NS"
EOF

echo -e "${grn}[✓] Data tersimpan di $VAR_FILE${NC}"
echo ""

# === Buat Layanan Systemd ===
echo -e "${blu}[*] Membuat layanan kyt.service...${NC}"
cat > /etc/systemd/system/kyt.service << END
[Unit]
Description=Telegram Bot Panel — kyt
After=network.target network-online.target
Wants=network-online.target

[Service]
Type=simple
WorkingDirectory=/usr/bin/kyt
ExecStart=/usr/bin/python3 -m kyt
User=root
Restart=always
RestartSec=5

[Install]
WantedBy=multi-user.target
END

# === Mulai Layanan ===
systemctl daemon-reload
systemctl enable --now kyt

# Cek status
if systemctl is-active --quiet kyt; then
    echo -e "${grn}[✓] Layanan kyt berjalan sukses!${NC}"
else
    echo -e "${red}[!] Layanan gagal berjalan!${NC}"
    echo -e "    Cek dengan: systemctl status kyt"
    exit 1
fi

# === Tampilkan Ringkasan ===
echo -e "\n\n${grn}✅ Pemasangan Selesai!${NC}"
echo -e "==============================="
echo "Token Bot    : $bottoken"
echo "Admin ID     : $admin"
echo "Domain       : $domain"
echo "Public Key   : ${PUB:0:30}..."
echo "DNS Host     : $NS"
echo -e "==============================="
echo -e "Kirim pesan /menu ke bot Telegram Anda untuk mulai menggunakan."
