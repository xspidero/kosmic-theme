#!/bin/bash
# ====================================================================
#  Kosmic Theme Uninstaller / Rollback — Author: xspidero
# ====================================================================

set -e

PANEL_DIR="/var/www/pterodactyl"
THEME_DIR="$PANEL_DIR/public/themes/kosmic"
LEGACY_DIR="$PANEL_DIR/public/themes/free-theme"
BACKUP_DIR="$PANEL_DIR/theme_backups"

echo "=========================================================="
echo "            Kosmic Theme Rollback Utility                 "
echo "=========================================================="

if [ "$EUID" -ne 0 ]; then
    echo "[-] Error: Please run as root (sudo bash uninstall.sh)"
    exit 1
fi

WRAPPER_FILE="$PANEL_DIR/resources/views/templates/wrapper.blade.php"
ADMIN_FILE="$PANEL_DIR/resources/views/layouts/admin.blade.php"

# Restore original backups if available
if [ -f "$BACKUP_DIR/wrapper.blade.php.orig" ]; then
    echo "[+] Restoring wrapper.blade.php from original backup..."
    cp -pf "$BACKUP_DIR/wrapper.blade.php.orig" "$WRAPPER_FILE"
else
    echo "[+] Removing theme hooks from wrapper.blade.php..."
    sed -i '/\/themes\/kosmic\//d' "$WRAPPER_FILE"
    sed -i '/\/themes\/free-theme\//d' "$WRAPPER_FILE"
fi

if [ -f "$BACKUP_DIR/admin.blade.php.orig" ]; then
    echo "[+] Restoring admin.blade.php from original backup..."
    cp -pf "$BACKUP_DIR/admin.blade.php.orig" "$ADMIN_FILE"
else
    echo "[+] Removing admin theme hooks from admin.blade.php..."
    sed -i '/\/themes\/kosmic\//d' "$ADMIN_FILE"
    sed -i '/\/themes\/free-theme\//d' "$ADMIN_FILE"
fi

# Clean assets
if [ -d "$THEME_DIR" ]; then
    echo "[+] Removing theme assets from $THEME_DIR..."
    rm -rf "$THEME_DIR"
fi

if [ -d "$LEGACY_DIR" ]; then
    rm -rf "$LEGACY_DIR"
fi

# Remove license record
rm -f "$PANEL_DIR/storage/app/theme_license.json"

# Clear caches
echo "[+] Flushing panel view and template cache..."
cd "$PANEL_DIR"
php artisan view:clear >/dev/null 2>&1 || true
php artisan config:clear >/dev/null 2>&1 || true
php artisan cache:clear >/dev/null 2>&1 || true

chown -R www-data:www-data "$PANEL_DIR/resources/views"
chown -R www-data:www-data "$PANEL_DIR/storage"

echo ""
echo "=========================================================="
echo " [✔] Kosmic Theme uninstalled. Default Pterodactyl restored!"
echo " Refresh your panel in browser (Ctrl + F5 or Cmd + Shift + R)"
echo "=========================================================="
