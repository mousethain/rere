#!/bin/bash
# ========================================================
# Xray Core Update Script (Final Version)
# ========================================================

# --- KONFIGURASI ---
REPO_URL="https://raw.githubusercontent.com/mousethain/rere"
VERSION_TO_INSTALL="$1" 
# -------------------

# Output Warna
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
NC='\033[0m'

cleanup_old_files() {
    # Fungsi ini bisa diisi jika ada file yang perlu dihapus (legacy)
    echo -e "${YELLOW}>> Memeriksa dan membersihkan file script lama...${NC}"
}

main_core_update() {
    if [ -z "$VERSION_TO_INSTALL" ]; then
        echo -e "${RED}!! Error: Versi target update tidak ditemukan. Proses dibatalkan.${NC}"
        return 1
    fi
    
    echo -e "${GREEN}==============================================${NC}"
    echo -e "${GREEN}  Memulai Instalasi Core Versi ${VERSION_TO_INSTALL} ${NC}"
    echo -e "${GREEN}==============================================${NC}"

    # A. Pembersihan
    cleanup_old_files
    
    # B. Download dan Penggantian Script Inti (Hapus file lama, ganti dengan yang baru)
    echo -e "${YELLOW}>> Mengunduh dan mengganti script utama...${NC}"

    # --- PERBAIKAN DI SINI: MENGHAPUS "update" DARI DAFTAR SCRIPT ---
    declare -a SCRIPTS=("menu" "add-vless" "add-vmess") 
    ALL_SUCCESS=true

    for script in "${SCRIPTS[@]}"; do
        SCRIPT_URL="$REPO_URL/$VERSION_TO_INSTALL/$script"
        TARGET_PATH="/usr/local/bin/$script"
        
        echo -e "${YELLOW}  -> Mengunduh $script dari $VERSION_TO_INSTALL...${NC}"
        
        # 1. Hapus file lama sebelum ganti
        rm -f "$TARGET_PATH" 
        
        # 2. Unduh dan cek status (wget -T 10 = Timeout 10 detik)
        if ! wget -T 10 -O "$TARGET_PATH" "$SCRIPT_URL"; then
            echo -e "${RED}!! GAGAL mengunduh $script. URL: $SCRIPT_URL${NC}"
            ALL_SUCCESS=false
        else
            chmod +x "$TARGET_PATH"
            echo -e "${GREEN}  -> Berhasil mengganti $script.${NC}"
        fi
    done
    
    # C. Konfigurasi Baru: Onering SNI (Membuat file config jika belum ada)
    ONERING_CONFIG_FILE="/usr/local/etc/v2ray/onering_sni"
    if [ ! -f "$ONERING_CONFIG_FILE" ]; then
        echo -e "${YELLOW}>> Membuat file konfigurasi Onering SNI awal...${NC}"
        echo "N/A (Set me up!)" > "$ONERING_CONFIG_FILE"
        chmod 644 "$ONERING_CONFIG_FILE"
    fi
    
    # D. Restart Service
    echo -e "${YELLOW}>> Me-restart layanan Xray...${NC}"
    systemctl restart v2ray
    
    # E. PEMBARUAN KRITIS: Bersihkan Cache Shell (Memperbaiki masalah 'menu' lama)
    echo -e "${YELLOW}>> Membersihkan cache shell komando (hash table)...${NC}"
    hash -r
    
    # F. Laporan Akhir
    if $ALL_SUCCESS; then
        echo -e "${GREEN}==============================================${NC}"
        echo -e "${GREEN}  Pembaruan Core ${VERSION_TO_INSTALL} SUKSES PENUH!${NC}"
        echo -e "${GREEN}  Silakan jalankan 'menu' dan set Domain Onering (Opsi 13).${NC}"
        echo -e "${GREEN}==============================================${NC}"
        return 0 # Status Sukses
    else
        echo -e "${RED}!! Peringatan: Beberapa file gagal diunduh. Pembaruan mungkin tidak lengkap.${NC}"
        return 1 # Status Gagal
    fi
}

main_core_update "$@"
