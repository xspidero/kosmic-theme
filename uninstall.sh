#!/bin/bash
# Kosmic Theme Uninstaller
# Author: xspidero

set -e

PANEL_DIR="/var/www/pterodactyl"
THEME_DIR="$PANEL_DIR/public/themes/kosmic"
LICENSE_FILE="$PANEL_DIR/storage/app/theme_license.json"
WRAPPER_FILE="$PANEL_DIR/resources/views/templates/wrapper.blade.php"
ADMIN_FILE="$PANEL_DIR/resources/views/layouts/admin.blade.php"

echo "Uninstalling Kosmic theme..."

if [ "$EUID" -ne 0 ]; then
    echo "Error: Run this uninstaller as root (sudo bash uninstall.sh)."
    exit 1
fi

# Remove theme lines added to panel templates without restoring old backups
if [ -f "$WRAPPER_FILE" ]; then
    sed -i '/\/themes\/kosmic\//d' "$WRAPPER_FILE"
fi

if [ -f "$ADMIN_FILE" ]; then
    sed -i '/\/themes\/kosmic\//d' "$ADMIN_FILE"
fi

# Remove theme assets and license file
rm -rf "$THEME_DIR"
rm -f "$LICENSE_FILE"

# Clear panel view cache
if [ -d "$PANEL_DIR" ]; then
    cd "$PANEL_DIR"
    php artisan view:clear >/dev/null 2>&1 || true
    php artisan config:clear >/dev/null 2>&1 || true
fi

echo "Uninstalled. Default styling restored."
