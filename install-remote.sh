#!/bin/sh
# Remote one-liner installer:
# curl -fsSL https://raw.githubusercontent.com/<owner>/<repo>/main/install-remote.sh | bash -s -- --repo <owner>/<repo>
set -e

REPO=""
VERSION=""

while [ $# -gt 0 ]; do
  case "$1" in
    --repo)
      REPO="$2"
      shift 2
      ;;
    --version)
      VERSION="$2"
      shift 2
      ;;
    *)
      echo "Unknown arg: $1" >&2
      exit 1
      ;;
  esac
done

if [ -z "$REPO" ]; then
  echo "Usage: install-remote.sh --repo <owner>/<repo> [--version <tag>]" >&2
  exit 1
fi

if [ "$(id -u)" -eq 0 ]; then
  SUDO=""
else
  SUDO="sudo"
fi

if ! command -v apt-get >/dev/null 2>&1; then
  echo "This installer currently supports Ubuntu/Debian (apt-get)." >&2
  exit 1
fi

echo "[1/6] Installing dependencies..."
$SUDO apt-get update
$SUDO apt-get install -y curl ca-certificates

API_BASE="https://api.github.com/repos/$REPO/releases"
TMP_DIR="$(mktemp -d)"
trap 'rm -rf "$TMP_DIR"' EXIT

if [ -n "$VERSION" ]; then
  echo "[2/6] Fetching release tag: $VERSION"
  RELEASE_JSON="$(curl -fsSL "$API_BASE/tags/$VERSION")"
else
  echo "[2/6] Fetching latest release"
  RELEASE_JSON="$(curl -fsSL "$API_BASE/latest")"
fi

DEB_URL="$(printf '%s' "$RELEASE_JSON" | python3 -c 'import json,sys; d=json.load(sys.stdin); print(next((a["browser_download_url"] for a in d.get("assets",[]) if a.get("name","").endswith("_all.deb")), ""))')"

if [ -z "$DEB_URL" ]; then
  echo "ERROR: No *_all.deb asset found in release." >&2
  exit 1
fi

DEB_FILE="$TMP_DIR/package.deb"
echo "[3/6] Downloading package..."
curl -fL "$DEB_URL" -o "$DEB_FILE"

echo "[4/6] Installing package..."
$SUDO apt-get install -y "$DEB_FILE"

echo "[5/6] Preparing config template..."
$SUDO mkdir -p /etc/laravel-telegram-backup
if [ ! -f /etc/laravel-telegram-backup/config.json ]; then
  $SUDO cp /usr/share/doc/laravel-telegram-backup/examples/config.json /etc/laravel-telegram-backup/config.json
  $SUDO chmod 600 /etc/laravel-telegram-backup/config.json
  echo "Created: /etc/laravel-telegram-backup/config.json"
else
  echo "Config already exists: /etc/laravel-telegram-backup/config.json"
fi

echo "[6/6] Done."
echo ""
echo "Next steps:"
echo "  1) Edit config:"
echo "     sudo nano /etc/laravel-telegram-backup/config.json"
echo "  2) Validate config:"
echo "     sudo laravel-telegram-backup validate-config"
echo "  3) Sync schedule:"
echo "     sudo laravel-telegram-backup sync-schedule"
echo "  4) Run test backup:"
echo "     sudo laravel-telegram-backup run"
echo "  5) Check timer/logs:"
echo "     sudo systemctl status laravel-telegram-backup.timer"
echo "     journalctl -u laravel-telegram-backup.service -n 50 --no-pager"
