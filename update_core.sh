#!/bin/bash
# ========================================================
# Xray Core Update Script
# Versi: v1.0 (Onering Support)
# Perhatian: Script ini dijalankan dari /tmp
# ========================================================

# --- KONFIGURASI REPO ---
# Pastikan URL ini sesuai dengan lokasi file Anda di GitHub
REPO_URL="https://raw.githubusercontent.com/mousethain/rere"
# Ambil versi target dari argumen pertama
VERSION_TO_INSTALL="$1" 
# ------------------------

# Output Warna
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
NC='\033[0m'

# Daftar script yang akan diganti
declare -a SCRIPTS=("menu" "add-vless" "add-vmess")

# --- FUNGSI PEMBERSIHAN (OPSIONAL) ---
cleanup_old_files() {
    echo -e "${YELLOW}>> Memeriksa dan membersihkan file script lama (jika ada)...${NC}"
    # Contoh: Hapus script yang mungkin sudah tidak terpakai dari versi lama
    # rm -f /usr/local/bin/old_deprecated_script 
}
# --------------------------------------

main_core_update() {
    # Pastikan versi target valid
    if [ -z "$VERSION_TO_INSTALL" ]; then
        echo -e "${RED}!! Error: Versi target update tidak ditemukan. Proses dibatalkan.${NC}"
        return 1
    fi
    
    echo -e "${GREEN}==============================================${NC}"
    echo -e "${GREEN}  Memulai Instalasi Core Versi ${VERSION_TO_INSTALL} ${NC}"
    echo -e "${GREEN}==============================================${NC}"

    # 1. Pembersihan File Lama
    cleanup_old_files
    
    # 2. Download dan Penggantian Script Inti (Menu, Add-Vless, Add-Vmess)
    echo -e "${YELLOW}>> Mengunduh dan mengganti script utama (${SCRIPTS[*]}) ...${NC}"

    for script in "${SCRIPTS[@]}"; do
        SCRIPT_URL="$REPO_URL/$VERSION_TO_INSTALL/$script"
        TARGET_PATH="/usr/local/bin/$script"
        
        echo -e "${YELLOW}  -> Mengunduh $script...${NC}"
        if ! wget -q "$SCRIPT_URL" -O "$TARGET_PATH"; then
            echo -e "${RED}!! Gagal mengunduh $script dari $SCRIPT_URL. Lanjutkan ke file berikutnya.${NC}"
        else
            chmod +x "$TARGET_PATH"
        fi
    done
    
    # 3. Konfigurasi Baru: Onering SNI (Wajib ada untuk fitur baru)
    ONERING_CONFIG_FILE="/usr/local/etc/v2ray/onering_sni"
    
    # Pastikan direktori ada (walaupun seharusnya sudah ada)
    if [ ! -d "/usr/local/etc/v2ray" ]; then
        mkdir -p "/usr/local/etc/v2ray"
    fi
    
    # Membuat file konfigurasi Onering jika belum ada
    if [ ! -f "$ONERING_CONFIG_FILE" ]; then
        echo -e "${YELLOW}>> Membuat file konfigurasi Onering SNI awal...${NC}"
        echo "N/A (Set me up!)" > "$ONERING_CONFIG_FILE"
        chmod 644 "$ONERING_CONFIG_FILE"
    fi
    
    # 4. Restart Service
    echo -e "${YELLOW}>> Me-restart layanan Xray...${NC}"
    systemctl restart v2ray
    
    # 5. Informasi Akhir
    echo -e "${GREEN}==============================================${NC}"
    echo -e "${GREEN}  Pembaruan Core ${VERSION_TO_INSTALL} Selesai!${NC}"
    echo -e "${GREEN}  FITUR BARU: Dukungan Onering Tunneling.${NC}"
    echo -e "${GREEN}  Aksi Selanjutnya: Jalankan 'menu' dan pilih '13. Seting Domain Onering'.${NC}"
    echo -e "${GREEN}==============================================${NC}"
}

# Jalankan fungsi utama, meneruskan semua argumen (yaitu Versi Target)
main_core_update "$@"
