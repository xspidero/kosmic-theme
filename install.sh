#!/bin/bash
# Kosmic Theme Installer
# Author: xspidero

set -e

PANEL_DIR="${PANEL_DIR:-/var/www/pterodactyl}"
THEME_DIR="$PANEL_DIR/public/themes/kosmic"
BACKUP_DIR="$PANEL_DIR/theme_backups"
LICENSE_ENDPOINT="https://licensing.veloracloud.site/api/verify"
PRODUCT_SLUG="kosmic-theme"
DISCORD_INVITE="https://discord.com/invite/hc9TUCsQpS"

echo "Kosmic Theme Installer v1.0.0"

if [ "$EUID" -ne 0 ]; then
    echo "Error: Run this installer as root (sudo bash install.sh)."
    exit 1
fi

if [ ! -d "$PANEL_DIR" ]; then
    echo "Error: Pterodactyl directory ($PANEL_DIR) not found."
    exit 1
fi

# Detect panel domain from .env or system hostname
DOMAIN=$(hostname -f 2>/dev/null || cat /etc/hostname 2>/dev/null || hostname 2>/dev/null)
if [ -f "$PANEL_DIR/.env" ]; then
    ENV_URL=$(grep "^APP_URL=" "$PANEL_DIR/.env" | cut -d '=' -f2- | tr -d '"' | tr -d "'" | sed 's|https://||;s|http://||;s|/.*||')
    if [ -n "$ENV_URL" ] && [ "$ENV_URL" != "localhost" ] && [ "$ENV_URL" != "127.0.0.1" ]; then
        DOMAIN="$ENV_URL"
    fi
fi

# Prompt for license key
LICENSE_KEY=""
LICENSE_FILE="$PANEL_DIR/storage/app/theme_license.json"
if [ -f "$LICENSE_FILE" ]; then
    PREV_KEY=$(grep -o '"license_key"[[:space:]]*:[[:space:]]*"[^"]*"' "$LICENSE_FILE" 2>/dev/null | cut -d':' -f2 | tr -d ' "' || true)
    if [ -n "$PREV_KEY" ]; then
        MASKED_KEY="****-${PREV_KEY: -4}"
        echo -n "Enter your Kosmic license key [Existing: $MASKED_KEY]: "
        read -r INPUT_KEY
        echo
        LICENSE_KEY="${INPUT_KEY:-$PREV_KEY}"
    fi
fi

if [ -z "$LICENSE_KEY" ]; then
    echo -n "Enter your Kosmic license key: "
    read -r INPUT_KEY
    echo
    LICENSE_KEY="$INPUT_KEY"
fi

LICENSE_KEY=$(echo "$LICENSE_KEY" | tr -d ' ' | tr '[:lower:]' '[:upper:]')

# Fail closed if no key provided
if [ -z "$LICENSE_KEY" ]; then
    echo "Error: License key is required."
    echo "Claim a free key in #claim-license on Discord: $DISCORD_INVITE"
    exit 1
fi

# Reject invalid characters before building payload
if ! [[ "$LICENSE_KEY" =~ ^[A-Z0-9-]+$ ]]; then
    echo "Error: License key has invalid characters."
    echo "Claim a free key in #claim-license on Discord: $DISCORD_INVITE"
    exit 1
fi

echo "Checking license..."

PAYLOAD="{\"licenseKey\":\"$LICENSE_KEY\",\"productSlug\":\"$PRODUCT_SLUG\",\"fingerprint\":\"$DOMAIN\"}"

VERIFY_RESP=$(curl -s -X POST "$LICENSE_ENDPOINT" \
    -H "Content-Type: application/json" \
    -H "User-Agent: Kosmic-Installer/1.0.0" \
    --connect-timeout 8 \
    --max-time 15 \
    -d "$PAYLOAD" 2>/dev/null || true)

# Fail closed on network failure
if [ -z "$VERIFY_RESP" ]; then
    echo "Error: Could not reach licensing server. Check internet connectivity."
    echo "Support: $DISCORD_INVITE"
    exit 1
fi

IS_VALID=$(echo "$VERIFY_RESP" | grep -E '"valid"[[:space:]]*:[[:space:]]*true' || true)

# Fail closed on invalid key
if [ -z "$IS_VALID" ]; then
    REASON=$(echo "$VERIFY_RESP" | grep -o '"reason"[[:space:]]*:[[:space:]]*"[^"]*"' | cut -d':' -f2 | tr -d ' "' || true)
    if [ -n "$REASON" ]; then
        echo "Error: License verification failed ($REASON)."
    else
        echo "Error: License verification failed. Key is invalid or expired."
    fi
    echo "Claim a free key in #claim-license on Discord: $DISCORD_INVITE"
    exit 1
fi

echo "License verified."

# Deploy theme assets
mkdir -p "$THEME_DIR"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}" 2>/dev/null)" 2>/dev/null && pwd || echo "")"

if [ -n "$SCRIPT_DIR" ] && [ -f "$SCRIPT_DIR/public/themes/kosmic/theme.css" ]; then
    # Local zip package extraction
    cp -rf "$SCRIPT_DIR/public/themes/kosmic/"* "$THEME_DIR/"
elif [ -n "$SCRIPT_DIR" ] && [ -f "$SCRIPT_DIR/theme.css" ]; then
    # Flat directory fallback
    cp -rf "$SCRIPT_DIR/"* "$THEME_DIR/" 2>/dev/null || true
else
    # Remote asset download for curl / public repo installs
    DOWNLOAD_URL=$(echo "$VERIFY_RESP" | grep -o '"downloadUrl"[[:space:]]*:[[:space:]]*"[^"]*"' | cut -d':' -f2- | tr -d ' "' || true)
    if [ -z "$DOWNLOAD_URL" ]; then
        DOWNLOAD_URL=$(echo "$VERIFY_RESP" | grep -o '"download_url"[[:space:]]*:[[:space:]]*"[^"]*"' | cut -d':' -f2- | tr -d ' "' || true)
    fi

    if [ -n "$DOWNLOAD_URL" ]; then
        echo "Downloading theme assets..."
        ARCHIVE_TMP="/tmp/kosmic-assets.tar.gz"
        curl -sSL "$DOWNLOAD_URL" -o "$ARCHIVE_TMP"
        tar -xzf "$ARCHIVE_TMP" -C "$THEME_DIR/"
        rm -f "$ARCHIVE_TMP"
    else
        echo "Error: Local theme assets not found and server did not provide download URL."
        echo "Please use the official release zip or contact support: $DISCORD_INVITE"
        exit 1
    fi
fi

chown -R www-data:www-data "$THEME_DIR" 2>/dev/null || true
chmod -R 755 "$THEME_DIR" 2>/dev/null || true

# Save license verification record
mkdir -p "$PANEL_DIR/storage/app"
cat <<EOF > "$LICENSE_FILE"
{
  "product": "$PRODUCT_SLUG",
  "domain": "$DOMAIN",
  "license_key": "$LICENSE_KEY",
  "verified_at": "$(date -u +%s)"
}
EOF
chown www-data:www-data "$LICENSE_FILE" 2>/dev/null || true
chmod 644 "$LICENSE_FILE" 2>/dev/null || true

# Modify panel views with sed (checking first to avoid duplicate tags)
mkdir -p "$BACKUP_DIR"
WRAPPER_FILE="$PANEL_DIR/resources/views/templates/wrapper.blade.php"
ADMIN_FILE="$PANEL_DIR/resources/views/layouts/admin.blade.php"

if [ -f "$WRAPPER_FILE" ]; then
    if grep -q '/themes/kosmic/theme.css' "$WRAPPER_FILE"; then
        echo "Kosmic already linked in wrapper.blade.php."
    else
        if [ ! -f "$BACKUP_DIR/wrapper.blade.php.bak" ]; then
            cp -p "$WRAPPER_FILE" "$BACKUP_DIR/wrapper.blade.php.bak"
        fi
        sed -i "/@include('layouts.scripts')/a \\        <link rel=\"stylesheet\" href=\"/themes/kosmic/theme.css?v=1.0.0\">\\n        <script src=\"/themes/kosmic/theme.js?v=1.0.0\" defer></script>" "$WRAPPER_FILE"
    fi
fi

if [ -f "$ADMIN_FILE" ]; then
    if grep -q '/themes/kosmic/admin-theme.css' "$ADMIN_FILE"; then
        echo "Kosmic already linked in admin.blade.php."
    else
        if [ ! -f "$BACKUP_DIR/admin.blade.php.bak" ]; then
            cp -p "$ADMIN_FILE" "$BACKUP_DIR/admin.blade.php.bak"
        fi
        sed -i "/css\/pterodactyl\.css/a \\            <link rel=\"stylesheet\" href=\"/themes/kosmic/admin-theme.css?v=1.0.0\">" "$ADMIN_FILE"
    fi
fi

# Clear view cache
cd "$PANEL_DIR"
php artisan view:clear >/dev/null 2>&1 || true
php artisan config:clear >/dev/null 2>&1 || true

echo "Installed. Hard-refresh your browser."
