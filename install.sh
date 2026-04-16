#!/bin/sh
# One-command installer for Ubuntu/Debian users.
set -e

if [ "$(id -u)" -eq 0 ]; then
  SUDO=""
else
  SUDO="sudo"
fi

ROOT="$(CDPATH= cd -- "$(dirname "$0")" && pwd)"
PKG_NAME="laravel-telegram-backup"
VERSION="${VERSION:-1.0.0}"
DEB_FILE="$ROOT/${PKG_NAME}_${VERSION}_all.deb"

echo "[1/5] Installing build/runtime dependencies..."
$SUDO apt-get update
$SUDO apt-get install -y dpkg-dev python3 curl tar gzip coreutils

echo "[2/5] Building .deb package..."
chmod +x "$ROOT/build-deb.sh"
VERSION="$VERSION" "$ROOT/build-deb.sh"

if [ ! -f "$DEB_FILE" ]; then
  echo "ERROR: Package file not found: $DEB_FILE" >&2
  exit 1
fi

echo "[3/5] Installing package..."
$SUDO apt-get install -y "$DEB_FILE"

echo "[4/5] Preparing config template..."
$SUDO mkdir -p /etc/laravel-telegram-backup
if [ ! -f /etc/laravel-telegram-backup/config.json ]; then
  $SUDO cp /usr/share/doc/laravel-telegram-backup/examples/config.json /etc/laravel-telegram-backup/config.json
  $SUDO chmod 600 /etc/laravel-telegram-backup/config.json
  echo "Created: /etc/laravel-telegram-backup/config.json"
else
  echo "Config already exists: /etc/laravel-telegram-backup/config.json"
fi

echo "[5/5] Done."
echo ""
echo "Next steps:"
echo "  1) Edit config:"
echo "     sudo nano /etc/laravel-telegram-backup/config.json"
echo "  2) Validate config:"
echo "     sudo lpb validate-config"
echo "  3) Sync schedule (after editing schedule):"
echo "     sudo lpb sync-schedule"
echo "  4) Run a manual test backup:"
echo "     sudo lpb run"
echo "  5) Check timer/logs:"
echo "     sudo systemctl status laravel-telegram-backup.timer"
echo "     journalctl -u laravel-telegram-backup.service -n 50 --no-pager"
