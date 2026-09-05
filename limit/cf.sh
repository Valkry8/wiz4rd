#!/bin/bash
# ==================================================
# UPDATE DNS CLOUDFLARE — OTOMATIS
# ==================================================

# === CEK DEPENDENSI ===
command -v jq >/dev/null 2>&1 || { echo "❌ jq belum terpasang! apt install jq -y"; exit 1; }
command -v curl >/dev/null 2>&1 || { echo "❌ curl belum terpasang! apt install curl -y"; exit 1; }

# === INPUT USER ===
read -p "🌐 Masukkan Subdomain (contoh: mubtada7): " sub
while [[ -z "$sub" ]]; do
  echo "❌ Tidak boleh kosong!"
  read -p "🌐 Masukkan Subdomain: " sub
done

DOMAIN="mypremium.biz.id"
dns="${sub}.${DOMAIN}"
echo "✅ Full Domain: $dns"
echo ""

read -p "🔑 Cloudflare Email: " CF_ID
read -s -p "🔑 Cloudflare API Key (Global): " CF_KEY
echo -e "\n"

# === AMBIL IP SERVER ===
IP=$(wget -qO- icanhazip.com || curl -s icanhazip.com)
if [[ -z "$IP" ]]; then
  echo "❌ Gagal mendapatkan IP publik!"
  exit 1
fi
echo "✅ IP Server: $IP"
echo ""

# === FUNGSI: REQUEST API ===
api_get() {
  curl -sLX GET "$1" \
    -H "X-Auth-Email: ${CF_ID}" \
    -H "X-Auth-Key: ${CF_KEY}" \
    -H "Content-Type: application/json"
}

api_post() {
  local url="$1"
  local data="$2"
  curl -sLX POST "$url" \
    -H "X-Auth-Email: ${CF_ID}" \
    -H "X-Auth-Key: ${CF_KEY}" \
    -H "Content-Type: application/json" \
    --data "$data"
}

api_put() {
  local url="$1"
  local data="$2"
  curl -sLX PUT "$url" \
    -H "X-Auth-Email: ${CF_ID}" \
    -H "X-Auth-Key: ${CF_KEY}" \
    -H "Content-Type: application/json" \
    --data "$data"
}

# === AMBIL ZONE ID ===
echo "🔍 Mencari Zona untuk $DOMAIN..."
ZONE_RESP=$(api_get "https://api.cloudflare.com/client/v4/zones?name=${DOMAIN}&status=active")
ZONE=$(echo "$ZONE_RESP" | jq -r '.result[0].id')

if [[ -z "$ZONE" || "$ZONE" == "null" ]]; then
  echo "❌ Zona $DOMAIN tidak ditemukan di akun Cloudflare!"
  echo "   Pastikan domain sudah terdaftar & status aktif."
  exit 1
fi
echo "✅ Zone ID: $ZONE"
echo ""

# === CEK RECORD DNS ===
echo "🔍 Mengecek record DNS $dns..."
RECORD_RESP=$(api_get "https://api.cloudflare.com/client/v4/zones/${ZONE}/dns_records?name=${dns}")
RECORD=$(echo "$RECORD_RESP" | jq -r '.result[0].id')
EXISTING_IP=$(echo "$RECORD_RESP" | jq -r '.result[0].content')

if [[ "$EXISTING_IP" == "$IP" ]]; then
  echo "✅ DNS sudah sesuai: $dns → $IP"
else
  # === BUAT / UPDATE RECORD ===
  if [[ -n "$RECORD" && "$RECORD" != "null" ]]; then
    echo "🔄 Update record yang ada: $dns → $IP"
    DATA=$(jq -n --arg type "A" --arg name "$dns" --arg ip "$IP" \
      '{"type":$type,"name":$name,"content":$ip,"ttl":120,"proxied":false}')
    RESULT=$(api_put "https://api.cloudflare.com/client/v4/zones/${ZONE}/dns_records/${RECORD}" "$DATA")
  else
    echo "➕ Membuat record baru: $dns → $IP"
    DATA=$(jq -n --arg type "A" --arg name "$dns" --arg ip "$IP" \
      '{"type":$type,"name":$name,"content":$ip,"ttl":120,"proxied":false}')
    RESULT=$(api_post "https://api.cloudflare.com/client/v4/zones/${ZONE}/dns_records" "$DATA")
  fi

  SUCCESS=$(echo "$RESULT" | jq -r '.success')
  if [[ "$SUCCESS" != "true" ]]; then
    echo "❌ Gagal update DNS!"
    echo "   Error: $(echo "$RESULT" | jq -r '.errors[0].message')"
    exit 1
  fi
  echo "✅ DNS Berhasil Diupdate!"
fi
echo ""

# === SIMPAN KE FILE KONFIGURASI ===
echo "💾 Menyimpan konfigurasi..."
mkdir -p /etc/xray /etc/v2ray /var/lib/kyt
echo "$dns" > /etc/xray/domain
echo "$dns" > /etc/v2ray/domain
echo "IP=$IP" > /var/lib/kyt/ipvps.conf
echo "$dns" > /root/domain
echo "$dns" > /root/scdomain

echo ""
echo "🎉 SELESAI!"
echo "   Domain: $dns"
echo "   IP    : $IP"
echo "   Status: Aktif ✅"
