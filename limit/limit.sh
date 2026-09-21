#!/bin/bash
set -euo pipefail  # Berhenti jika ada error

REPO="https://raw.githubusercontent.com/Valkry8/wiz4rd/MONSTER/"

# Daftar file yang akan diunduh
declare -A files=(
  ["/etc/systemd/system/limitvmess.service"]="${REPO}limit/limitvmess.service"
  ["/etc/systemd/system/limitvless.service"]="${REPO}limit/limitvless.service"
  ["/etc/systemd/system/limittrojan.service"]="${REPO}limit/limittrojan.service"
  ["/etc/systemd/system/limitshadowsocks.service"]="${REPO}limit/limitshadowsocks.service"
  ["/etc/xray/limit.vmess"]="${REPO}limit/vmess"
  ["/etc/xray/limit.vless"]="${REPO}limit/vless"
  ["/etc/xray/limit.trojan"]="${REPO}limit/trojan"
  ["/etc/xray/limit.shadowsocks"]="${REPO}limit/shadowsocks"
)

# Pastikan direktori ada
mkdir -p /etc/xray /etc/systemd/system

echo "📥 Mengunduh file dari repo..."
for dest in "${!files[@]}"; do
  src="${files[$dest]}"
  echo "   → $dest"
  
  # Unduh dengan verifikasi
  if ! wget -q --show-progress -O "$dest" "$src"; then
    echo "❌ Gagal mengunduh: $src"
    exit 1
  fi
  
  # Beri izin eksekusi jika file di /etc/xray
  if [[ "$dest" == /etc/xray/* ]]; then
    chmod +x "$dest"
  fi
done

echo "🔧 Memuat ulang systemd..."
systemctl daemon-reload

echo "🚀 Mengaktifkan & menjalankan layanan..."
services=("limitvmess" "limitvless" "limittrojan" "limitshadowsocks")

for svc in "${services[@]}"; do
  echo "   → $svc"
  systemctl enable --now "$svc"
  # Cek status
  if systemctl is-active --quiet "$svc"; then
    echo "      ✅ Berjalan"
  else
    echo "      ⚠️  Gagal berjalan! Periksa: systemctl status $svc"
  fi
done

echo -e "\n✅ Selesai! Cek semua layanan dengan:"
echo "systemctl list-units limit*.service"
