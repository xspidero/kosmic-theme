# Kosmic

A clean dark theme for Pterodactyl Panel.

## What it is

Kosmic is a dark theme for Pterodactyl with solid color accents, a redesigned single-card login layout, dark admin pages, and bundled local fonts.

## Requirements

- Pterodactyl Panel 1.11.x or 1.12.x
- Root or sudo access on the panel host
- `curl` and `tar` installed on the system

## License key

Kosmic requires a free license key to install. You can claim one in the #claim-license channel on Discord:
https://discord.com/invite/hc9TUCsQpS

When you run the installer, it sends your panel domain and license key to `https://licensing.veloracloud.site/api/verify` to validate the key against our license database. No other files, credentials, or server data are sent. Installs from the GitHub script download the theme files from the Kosmic license server after the key is verified.

## Install

### Quick install (public)

Run this command on your panel server as root:

```bash
bash <(curl -s https://raw.githubusercontent.com/xspidero/kosmic-theme/main/install.sh)
```

### From release zip

1. Upload the zip to your server and extract it:
   ```bash
   unzip Kosmic-1.0.0.zip
   cd Kosmic
   ```
2. Run the installer:
   ```bash
   sudo bash install.sh
   ```
3. Enter your license key when prompted.
4. Hard-refresh your browser (Ctrl+F5) to load the updated stylesheets.

## Uninstall

To remove Kosmic and restore default panel styling:

```bash
sudo bash uninstall.sh
```

This removes the theme assets and the lines added to your Blade templates. It does not overwrite files with old backups.

## Config

In `public/themes/kosmic/theme.js`:
- `SHOW_DISCORD_BUTTON`: Set to `true` to display a Discord invite button in the top navigation bar. Default is `false`.
- `DISCORD_INVITE_URL`: Your Discord invite link.

## Support

For questions, bug reports, or license keys:
- Discord: https://discord.com/invite/hc9TUCsQpS
