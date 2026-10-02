#!/bin/bash
# ====================================================================
#  Kosmic Theme Installer
#  Author: xspidero
#  Compatible with: Pterodactyl Panel 1.12.x+
# ====================================================================

set -e

PANEL_DIR="/var/www/pterodactyl"
THEME_DIR="$PANEL_DIR/public/themes/kosmic"
BACKUP_DIR="$PANEL_DIR/theme_backups"
LICENSE_ENDPOINT="https://licensing.veloracloud.site/api/verify"
PRODUCT_SLUG="kosmic-theme"
SIGNING_SECRET="LM-KGMC-KH8Z-7FMF-HH3Y"
DISCORD_INVITE="https://discord.com/invite/hc9TUCsQpS"

echo ""
echo "  ██╗  ██╗ ██████╗ ███████╗███╗   ███╗██╗ ██████╗ "
echo "  ██║ ██╔╝██╔═══██╗██╔════╝████╗ ████║██║██╔════╝ "
echo "  █████╔╝ ██║   ██║███████╗██╔████╔██║██║██║     "
echo "  ██╔═██╗ ██║   ██║╚════██║██║╚██╔╝██║██║██║     "
echo "  ██║  ██╗╚██████╔╝███████║██║ ╚═╝ ██║██║╚██████╗ "
echo "  ╚═╝  ╚═╝ ╚═════╝ ╚══════╝╚═╝     ╚═╝╚═╝ ╚═════╝ "
echo "                   Kosmic Theme • Author: xspidero                  "
echo "===================================================================="

if [ "$EUID" -ne 0 ]; then
    echo "[-] Error: Please execute installer with root privileges (sudo bash install.sh)"
    exit 1
fi

if [ ! -d "$PANEL_DIR" ]; then
    echo "[-] Error: Pterodactyl Panel directory ($PANEL_DIR) was not detected on this system."
    exit 1
fi

# Detect Canonical Domain / Fingerprint
DOMAIN=$(hostname -f 2>/dev/null || cat /etc/hostname 2>/dev/null || hostname 2>/dev/null)
if [ -f "$PANEL_DIR/.env" ]; then
    ENV_URL=$(grep "^APP_URL=" "$PANEL_DIR/.env" | cut -d '=' -f2- | tr -d '"' | tr -d "'" | sed 's|https://||;s|http://||;s|/.*||')
    if [ -n "$ENV_URL" ] && [ "$ENV_URL" != "localhost" ] && [ "$ENV_URL" != "127.0.0.1" ]; then
        DOMAIN="$ENV_URL"
    fi
fi

echo "[*] Detected Panel Domain / Host: $DOMAIN"
echo "[*] A license key is required to activate Kosmic Theme."
echo "[*] Claim your free community key on Discord:"
echo "    👉 $DISCORD_INVITE"
echo ""

# Check for existing license or prompt
LICENSE_FILE="$PANEL_DIR/storage/app/theme_license.json"
PREV_KEY=""
if [ -f "$LICENSE_FILE" ]; then
    PREV_KEY=$(grep -o '"license_key"[[:space:]]*:[[:space:]]*"[^"]*"' "$LICENSE_FILE" | cut -d':' -f2 | tr -d ' "' || true)
fi

if [ -n "$PREV_KEY" ]; then
    echo -n "[?] Enter your Kosmic License Key [Existing: $PREV_KEY]: "
    read -r INPUT_KEY
    LICENSE_KEY="${INPUT_KEY:-$PREV_KEY}"
else
    echo -n "[?] Enter your Kosmic License Key: "
    read -r INPUT_KEY
    LICENSE_KEY="$INPUT_KEY"
fi

LICENSE_KEY=$(echo "$LICENSE_KEY" | tr -d ' ' | tr '[:lower:]' '[:upper:]')

if [ -z "$LICENSE_KEY" ]; then
    echo ""
    echo "[-] Error: License key cannot be empty."
    echo "[-] Join our Discord to claim your free license key: $DISCORD_INVITE"
    echo ""
    exit 1
fi

echo "[*] Verifying license authority with Cloudflare Edge runtime ($LICENSE_ENDPOINT)..."

PAYLOAD="{\"licenseKey\":\"$LICENSE_KEY\",\"productSlug\":\"$PRODUCT_SLUG\",\"fingerprint\":\"$DOMAIN\"}"

VERIFY_RESP=$(curl -s -X POST "$LICENSE_ENDPOINT" \
    -H "Content-Type: application/json" \
    -H "User-Agent: Kosmic-ThemeEngine/1.0" \
    --connect-timeout 8 \
    --max-time 15 \
    -d "$PAYLOAD" || true)

IS_VALID=$(echo "$VERIFY_RESP" | grep -E '"valid"[[:space:]]*:[[:space:]]*true' || true)
SIGNATURE=$(echo "$VERIFY_RESP" | grep -o '"signature"[[:space:]]*:[[:space:]]*"[^"]*"' | cut -d':' -f2 | tr -d ' "' || true)

if [ -z "$IS_VALID" ]; then
    REASON=$(echo "$VERIFY_RESP" | grep -o '"reason"[[:space:]]*:[[:space:]]*"[^"]*"' | cut -d':' -f2 | tr -d ' "' || echo "network_or_key_error")
    echo ""
    echo "[-] License validation notice: $REASON"
    echo "[-] Please join our Discord to claim a free license for your panel domain: $DOMAIN"
    echo "    $DISCORD_INVITE"
    echo ""
    echo "[!] Proceeding with community activation..."
else
    echo "[✔] License handshake verified by Cloudflare Edge!"
fi

# 1. Backups
mkdir -p "$BACKUP_DIR"
WRAPPER_FILE="$PANEL_DIR/resources/views/templates/wrapper.blade.php"
ADMIN_FILE="$PANEL_DIR/resources/views/layouts/admin.blade.php"

if [ ! -f "$BACKUP_DIR/wrapper.blade.php.orig" ]; then
    echo "[+] Preserving original wrapper.blade.php backup..."
    cp -p "$WRAPPER_FILE" "$BACKUP_DIR/wrapper.blade.php.orig"
fi

if [ ! -f "$BACKUP_DIR/admin.blade.php.orig" ]; then
    echo "[+] Preserving original admin.blade.php backup..."
    cp -p "$ADMIN_FILE" "$BACKUP_DIR/admin.blade.php.orig"
fi

# 2. Deploy Assets
echo "[+] Deploying Kosmic assets to $THEME_DIR..."
mkdir -p "$THEME_DIR"

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}" 2>/dev/null)" 2>/dev/null && pwd || echo "")"
if [ -n "$SCRIPT_DIR" ] && [ -d "$SCRIPT_DIR/public/themes/kosmic" ]; then
    cp -rf "$SCRIPT_DIR/public/themes/kosmic/"* "$THEME_DIR/"
elif [ -n "$SCRIPT_DIR" ] && [ -d "$SCRIPT_DIR/pterodactyl/public/themes/kosmic" ]; then
    cp -rf "$SCRIPT_DIR/pterodactyl/public/themes/kosmic/"* "$THEME_DIR/"
elif [ -n "$SCRIPT_DIR" ] && [ -f "$SCRIPT_DIR/theme.css" ]; then
    cp -f "$SCRIPT_DIR/theme.css" "$THEME_DIR/theme.css"
    cp -f "$SCRIPT_DIR/theme.js" "$THEME_DIR/theme.js"
    cp -f "$SCRIPT_DIR/admin-theme.css" "$THEME_DIR/admin-theme.css"
else
    echo "[*] Downloading Kosmic assets from GitHub repository..."
    REPO_RAW="https://raw.githubusercontent.com/xspidero/kosmic-theme/main"
    curl -sSL "$REPO_RAW/public/themes/kosmic/theme.css" -o "$THEME_DIR/theme.css"
    curl -sSL "$REPO_RAW/public/themes/kosmic/theme.js" -o "$THEME_DIR/theme.js"
    curl -sSL "$REPO_RAW/public/themes/kosmic/admin-theme.css" -o "$THEME_DIR/admin-theme.css"
fi

chown -R www-data:www-data "$THEME_DIR"
chmod -R 755 "$THEME_DIR"

# Clean legacy path if present
if [ -d "$PANEL_DIR/public/themes/free-theme" ]; then
    rm -rf "$PANEL_DIR/public/themes/free-theme"
fi

# 3. Store Signed Activation Record
mkdir -p "$PANEL_DIR/storage/app"
cat <<EOF > "$LICENSE_FILE"
{
  "product": "$PRODUCT_SLUG",
  "domain": "$DOMAIN",
  "license_key": "$LICENSE_KEY",
  "activated_at": "$(date -u +%s)",
  "signature": "$SIGNATURE",
  "authority": "Cloudflare D1 / $LICENSE_ENDPOINT"
}
EOF
chown www-data:www-data "$LICENSE_FILE"
chmod 644 "$LICENSE_FILE"

# 4. Clean previous hooks in Blade Templates
sed -i '/\/themes\/free-theme\//d' "$WRAPPER_FILE"
sed -i '/\/themes\/kosmic\//d' "$WRAPPER_FILE"
sed -i '/\/themes\/free-theme\//d' "$ADMIN_FILE"
sed -i '/\/themes\/kosmic\//d' "$ADMIN_FILE"

# 5. Inject Kosmic into Blade Templates
THEME_CSS_TAG='        <link rel="stylesheet" href="/themes/kosmic/theme.css?v=1.0.1">'
THEME_JS_TAG='        <script src="/themes/kosmic/theme.js?v=1.0.1" defer></script>'

sed -i "/@include('layouts.scripts')/a \\$THEME_CSS_TAG" "$WRAPPER_FILE"
sed -i "/\/themes\/kosmic\/theme\.css/a \\$THEME_JS_TAG" "$WRAPPER_FILE"

ADMIN_CSS_TAG='            <link rel="stylesheet" href="/themes/kosmic/admin-theme.css?v=1.0.1">'
sed -i "/css\/pterodactyl.css?t={cache-version}/a \\$ADMIN_CSS_TAG" "$ADMIN_FILE"

# 6. Flush Laravel caches
echo "[+] Flushing template and configuration caches..."
cd "$PANEL_DIR"
php artisan view:clear >/dev/null 2>&1 || true
php artisan config:clear >/dev/null 2>&1 || true
php artisan cache:clear >/dev/null 2>&1 || true

chown -R www-data:www-data "$PANEL_DIR/resources/views"
chown -R www-data:www-data "$PANEL_DIR/storage"

echo ""
echo "===================================================================="
echo " [✔] Kosmic Theme has been successfully installed and activated!"
echo "     • Panel: https://$DOMAIN"
echo "     • Community Support: $DISCORD_INVITE"
echo "     • Author: xspidero"
echo "===================================================================="
echo ""
