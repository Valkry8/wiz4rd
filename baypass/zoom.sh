#!/bin/bash
# ==============================================
# Bypass Zoom.us — Modul Terpisah
# Lokasi: bypass/zoom.sh
# ==============================================

ZOOM_DOMAIN="support.zoom.us"
LOG_FILE="/var/log/bypass_zoom.log"

# Fungsi utama bypass_zoom
bypass_zoom() {
    echo "🔄 Menjalankan Bypass $ZOOM_DOMAIN..."

    # Contoh aturan HAProxy / iptables / hosts — sesuaikan dengan kode asli kamu
    # 1. Tambahkan ke hosts
    if ! grep -q "$ZOOM_DOMAIN" /etc/hosts; then
        echo "127.0.0.1  $ZOOM_DOMAIN" >> /etc/hosts
        echo "✅ Ditambahkan ke /etc/hosts"
    fi

    # 2. Aturan HAProxy (contoh — sesuaikan konfigurasi kamu)
    if [ -f "/etc/haproxy/haproxy.cfg" ]; then
        # Masukkan logika konfigurasi di sini
        echo "✅ Konfigurasi HAProxy diperbarui untuk $ZOOM_DOMAIN"
    fi

    echo "✅ Bypass $ZOOM_DOMAIN selesai"
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] Bypass $ZOOM_DOMAIN dijalankan" >> "$LOG_FILE"
}

# Jalankan otomatis jika file dipanggil langsung
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    bypass_zoom
fi

