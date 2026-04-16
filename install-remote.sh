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

prepare_config() {
  echo "[5/6] Preparing config template..."
  $SUDO mkdir -p /etc/laravel-telegram-backup
  if [ ! -f /etc/laravel-telegram-backup/config.json ]; then
    $SUDO cp /usr/share/doc/laravel-telegram-backup/examples/config.json /etc/laravel-telegram-backup/config.json
    $SUDO chmod 600 /etc/laravel-telegram-backup/config.json
    echo "Created: /etc/laravel-telegram-backup/config.json"
  else
    echo "Config already exists: /etc/laravel-telegram-backup/config.json"
  fi
}

print_next_steps() {
  echo "[6/6] Done."
  echo ""
  echo "Next steps:"
  echo "  1) Edit config:"
  echo "     sudo nano /etc/laravel-telegram-backup/config.json"
  echo "  2) Validate config:"
  echo "     sudo lpb validate-config"
  echo "  3) Sync schedule:"
  echo "     sudo lpb sync-schedule"
  echo "  4) Run test backup:"
  echo "     sudo lpb run"
  echo "  5) Check timer/logs:"
  echo "     sudo systemctl status laravel-telegram-backup.timer"
  echo "     journalctl -u laravel-telegram-backup.service -n 50 --no-pager"
}

echo "[1/6] Installing base dependencies..."
$SUDO apt-get update
$SUDO apt-get install -y curl ca-certificates python3

API_BASE="https://api.github.com/repos/$REPO/releases"
TMP_DIR="$(mktemp -d)"
trap 'rm -rf "$TMP_DIR"' EXIT

RELEASE_JSON=""
DEB_URL=""
if [ -n "$VERSION" ]; then
  echo "[2/6] Fetching release tag: $VERSION"
  if RELEASE_JSON="$(curl -fsSL "$API_BASE/tags/$VERSION" 2>/dev/null)"; then
    :
  else
    echo "Release API unavailable for tag '$VERSION', switching to source fallback."
  fi
else
  echo "[2/6] Fetching latest release"
  if RELEASE_JSON="$(curl -fsSL "$API_BASE/latest" 2>/dev/null)"; then
    :
  else
    echo "No latest release found (404), switching to source fallback."
  fi
fi

if [ -n "$RELEASE_JSON" ]; then
  DEB_URL="$(printf '%s' "$RELEASE_JSON" | python3 -c 'import json,sys; d=json.load(sys.stdin); print(next((a["browser_download_url"] for a in d.get("assets",[]) if a.get("name","").endswith("_all.deb")), ""))')"
fi

if [ -n "$DEB_URL" ]; then
  echo "[3/6] Release mode: downloading .deb asset..."
  DEB_FILE="$TMP_DIR/package.deb"
  curl -fL "$DEB_URL" -o "$DEB_FILE"

  echo "[4/6] Installing package..."
  $SUDO apt-get install -y "$DEB_FILE"
  prepare_config
  print_next_steps
  exit 0
fi

echo "[3/6] Fallback mode: installing build dependencies..."
$SUDO apt-get install -y git dpkg-dev tar gzip coreutils

SRC_DIR="$TMP_DIR/src"
REPO_URL="https://github.com/$REPO.git"

echo "[4/6] Cloning source and running local installer..."
if [ -n "$VERSION" ]; then
  git clone --depth 1 --branch "$VERSION" "$REPO_URL" "$SRC_DIR"
else
  git clone --depth 1 "$REPO_URL" "$SRC_DIR"
fi

if [ ! -x "$SRC_DIR/install.sh" ]; then
  chmod +x "$SRC_DIR/install.sh"
fi
"$SRC_DIR/install.sh"
