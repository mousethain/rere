#!/bin/bash
# ========================================================
# Xray Core Update Script (Versi Transaksional Aman)
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

main_core_update() {
    if [ -z "$VERSION_TO_INSTALL" ]; then
        echo -e "${RED}!! Error: Versi target update tidak ditemukan. Proses dibatalkan.${NC}"
        return 1
    fi
    
    echo -e "${GREEN}==============================================${NC}"
    echo -e "${GREEN}  Memulai Instalasi Core Versi ${VERSION_TO_INSTALL} ${NC}"
    echo -e "${GREEN}==============================================${NC}"

    TARGET_DIR="/usr/local/sbin" # LOKASI YANG BENAR
    TEMP_DIR="/tmp"
    declare -a SCRIPTS=("menu" "add-vless" "add-vmess") # File yang di-update
    ALL_SUCCESS=true
    
    echo -e "${YELLOW}>> Mengunduh dan mengganti script utama ke $TARGET_DIR...${NC}"

    for script in "${SCRIPTS[@]}"; do
        TARGET_PATH="$TARGET_DIR/$script"
        BACKUP_PATH="$TEMP_DIR/${script}.bak"
        DOWNLOAD_PATH="$TEMP_DIR/${script}.new"
        SCRIPT_URL="$REPO_URL/$VERSION_TO_INSTALL/$script"

        echo -e "${YELLOW}  -> Memproses $script...${NC}"

        # 1. Backup file lama (jika ada)
        if [ -f "$TARGET_PATH" ]; then
            echo -e "${YELLOW}     -> Mencadangkan file lama ke $BACKUP_PATH${NC}"
            cp -p "$TARGET_PATH" "$BACKUP_PATH" # cp -p menjaga permissions
        fi
        
        # 2. Unduh file baru ke /tmp
        if ! wget -T 10 -O "$DOWNLOAD_PATH" "$SCRIPT_URL"; then
            echo -e "${RED}!! GAGAL mengunduh $script dari GitHub.${NC}"
            ALL_SUCCESS=false
            
            # Rollback (kembalikan file dari backup jika download gagal)
            if [ -f "$BACKUP_PATH" ]; then
                mv "$BACKUP_PATH" "$TARGET_PATH"
                echo -e "${YELLOW}     -> Gagal: Mengembalikan $script dari backup.${NC}"
            fi
        else
            # 3. Pindahkan file baru ke lokasi TARGET, berikan izin eksekusi
            mv "$DOWNLOAD_PATH" "$TARGET_PATH"
            chmod +x "$TARGET_PATH"
            
            # Hapus backup setelah sukses
            if [ -f "$BACKUP_PATH" ]; then
                rm -f "$BACKUP_PATH"
            fi

            echo -e "${GREEN}  -> Berhasil mengganti $script di $TARGET_DIR.${NC}"
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
    
    # E. PEMBARUAN KRITIS: Bersihkan Cache Shell (Memastikan menu baru tereksekusi)
    echo -e "${YELLOW}>> Membersihkan cache shell komando (hash table)...${NC}"
    hash -r
    
    # F. Laporan Akhir
    if $ALL_SUCCESS; then
        # Hapus sisa file update di /usr/local/bin/ yang tidak terpakai lagi
        rm -f /usr/local/bin/menu /usr/local/bin/add-vless /usr/local/bin/add-vmess
        
        echo -e "${GREEN}==============================================${NC}"
        echo -e "${GREEN}  Pembaruan Core ${VERSION_TO_INSTALL} SUKSES PENUH!${NC}"
        echo -e "${GREEN}  Skrip telah dipindahkan ke /usr/local/sbin/.${NC}"
        echo -e "${GREEN}  Silakan jalankan 'menu' dan set Domain Onering (Opsi 13).${NC}"
        echo -e "${GREEN}==============================================${NC}"
        return 0 # Status Sukses
    else
        echo -e "${RED}!! Peringatan: Pembaruan GAGAL/Tidak Lengkap. Skrip lama telah dikembalikan.${NC}"
        return 1 # Status Gagal
    fi
}

main_core_update "$@"
