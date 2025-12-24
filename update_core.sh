#!/bin/bash
# ========================================================
# Xray Core Update Script (Final Version - Fix Reality)
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

# --- FUNGSI CRONJOB (Sama seperti sebelumnya) ---
add_cronjob() {
    local cron_entry="*/2 * * * * /usr/local/sbin/limit-xray >/dev/null 2>&1"
    local temp_cron="/tmp/crontab.tmp"
    crontab -l 2>/dev/null > "$temp_cron"
    if grep -qF "$cron_entry" "$temp_cron"; then
        echo -e "${GREEN}  -> Cronjob limit-xray sudah ada.${NC}"
    else
        echo "$cron_entry" >> "$temp_cron"
        crontab "$temp_cron"
        echo -e "${GREEN}  -> Cronjob limit-xray berhasil ditambahkan.${NC}"
    fi
    rm -f "$temp_cron"
}

# --- FUNGSI FIX REALITY (BARU) ---
fix_reality_keys() {
    echo -e "${YELLOW}>> Memeriksa Konfigurasi XTLS Reality...${NC}"
    DIR="/usr/local/etc/v2ray"
    CONFIG_JSON="$DIR/config.json"
    mkdir -p $DIR

    # 1. Cek/Buat Keypair (Private & Public)
    if [[ ! -f "$DIR/reality_private.key" ]] || [[ ! -f "$DIR/reality_public.key" ]]; then
        echo -e "${YELLOW}   -> Membuat Keypair Reality Baru...${NC}"
        KEYS=$(xray x25519)
        PRIV_KEY=$(echo "$KEYS" | awk '/Private key:/ {print $3}')
        PUB_KEY=$(echo "$KEYS" | awk '/Public key:/ {print $3}')
        echo "$PRIV_KEY" > "$DIR/reality_private.key"
        echo "$PUB_KEY" > "$DIR/reality_public.key"
    else
        echo -e "${GREEN}   -> Keypair Reality sudah ada.${NC}"
    fi

    # 2. Cek/Buat Short ID (HEX MURNI - Anti Error 'j')
    if [[ ! -f "$DIR/reality_shortid.key" ]]; then
        echo -e "${YELLOW}   -> Membuat Short ID Hexadesimal Baru...${NC}"
        # Membuat 16 digit Hex (8 bytes) yang aman
        SHORT_ID=$(openssl rand -hex 8)
        echo "$SHORT_ID" > "$DIR/reality_shortid.key"
    else
        echo -e "${GREEN}   -> Short ID sudah ada.${NC}"
    fi

    # 3. Masukkan Key Baru ke config.json Server
    MY_PRIV=$(cat "$DIR/reality_private.key")
    MY_SID=$(cat "$DIR/reality_shortid.key")
    
    echo -e "${YELLOW}   -> Memperbarui config.json dengan Key baru...${NC}"
    
    # Ganti Private Key
    sed -i "s/\"privateKey\": \".*\"/\"privateKey\": \"$MY_PRIV\"/" $CONFIG_JSON
    
    # Ganti Short ID (Menghapus isi array shortIds lama dan ganti baru)
    # Mencari baris "shortIds": [ ... ] dan menggantinya.
    # Teknik ini mencari baris yang mengandung "shortIds" lalu mengganti baris setelahnya (jika format multi-line)
    # Namun untuk keamanan script update, kita asumsi format 1 baris atau kita ganti string spesifik.
    # Kita pakai cara aman: Ganti nilai di dalam shortIds
    sed -i "s/\"shortIds\": \[.*\]/\"shortIds\": [\"$MY_SID\"]/" $CONFIG_JSON
    
    # Backup: Jika formatnya multi-line, script di atas mungkin gagal. 
    # Kita pastikan config.json menggunakan format standar sebelum upload atau gunakan jq jika terinstall.
    # Karena install.sh menginstall jq, kita bisa gunakan jq untuk hasil 100% akurat:
    
    TEMP_JSON="$DIR/config_temp.json"
    jq --arg pk "$MY_PRIV" --arg sid "$MY_SID" \
       '.inbounds[] |= if .streamSettings.realitySettings then .streamSettings.realitySettings.privateKey = $pk | .streamSettings.realitySettings.shortIds = [$sid] else . end' \
       $CONFIG_JSON > $TEMP_JSON && mv $TEMP_JSON $CONFIG_JSON

    echo -e "${GREEN}   -> Fix Reality Selesai.${NC}"
}

main_core_update() {
    if [ -z "$VERSION_TO_INSTALL" ]; then
        echo -e "${RED}!! Error: Versi target update tidak ditemukan.${NC}"
        return 1
    fi
    
    # ... (Bagian Download Script - Tetap Sama seperti punya Anda) ...
    # Saya persingkat disini agar tidak terlalu panjang, tapi
    # Intinya copy bagian 'declare -a SCRIPTS' sampai loop 'done' selesai
    
    TARGET_DIR="/usr/local/sbin"
    TEMP_DIR="/tmp"
    declare -a SCRIPTS=("menu" "add-vless" "add-vmess" "setting-onering" "add-tr" "limit-xray")
    ALL_SUCCESS=true
    
    echo -e "${YELLOW}>> Mengunduh script baru...${NC}"
    for script in "${SCRIPTS[@]}"; do
        DOWNLOAD_PATH="$TEMP_DIR/${script}.new"
        SCRIPT_URL="$REPO_URL/$VERSION_TO_INSTALL/$script"
        if wget -T 10 -O "$DOWNLOAD_PATH" "$SCRIPT_URL"; then
            mv "$DOWNLOAD_PATH" "$TARGET_DIR/$script"
            chmod +x "$TARGET_DIR/$script"
            echo -e "${GREEN}  -> Update $script OK${NC}"
        else
            echo -e "${RED}  -> Gagal download $script${NC}"
        fi
    done

    # --- JALANKAN FIX REALITY DI SINI ---
    fix_reality_keys
    
    # ... (Sisa script Anda: Onering, Cronjob, Restart, dll) ...
    
    ONERING_CONFIG_FILE="/usr/local/etc/v2ray/onering_sni"
    if [ ! -f "$ONERING_CONFIG_FILE" ]; then
        echo "N/A (Set me up!)" > "$ONERING_CONFIG_FILE"
    fi
    
    add_cronjob
    
    echo -e "${YELLOW}>> Me-restart layanan Xray...${NC}"
    systemctl restart v2ray
    hash -r
    
    echo -e "${GREEN}  Update Selesai! Short ID Reality sudah diperbaiki.${NC}"
}

main_core_update "$@"
