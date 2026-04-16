#!/bin/sh
# Build laravel-telegram-backup_<version>_all.deb from this tree.
set -e
ROOT="$(CDPATH= cd -- "$(dirname "$0")" && pwd)"
VERSION="${VERSION:-1.0.0}"
PKG="laravel-telegram-backup"
STAGE="$(mktemp -d)"
trap 'rm -rf "$STAGE"' EXIT

mkdir -p "$STAGE/DEBIAN"
mkdir -p "$STAGE/lib/systemd/system"
mkdir -p "$STAGE/usr/bin"
mkdir -p "$STAGE/usr/lib/laravel-telegram-backup"
mkdir -p "$STAGE/usr/share/doc/$PKG/examples"

install -m 755 "$ROOT/usr/bin/lpb" "$STAGE/usr/bin/"
install -m 755 "$ROOT/usr/bin/laravel-telegram-backup" "$STAGE/usr/bin/"
install -m 644 "$ROOT/usr/lib/laravel-telegram-backup/backup.py" "$STAGE/usr/lib/laravel-telegram-backup/"
install -m 644 "$ROOT/lib/systemd/system/laravel-telegram-backup.service" "$STAGE/lib/systemd/system/"
install -m 644 "$ROOT/lib/systemd/system/laravel-telegram-backup.timer" "$STAGE/lib/systemd/system/"
install -m 644 "$ROOT/usr/share/doc/laravel-telegram-backup/examples/config.json" "$STAGE/usr/share/doc/$PKG/examples/"
install -m 644 "$ROOT/usr/share/doc/laravel-telegram-backup/README.md" "$STAGE/usr/share/doc/$PKG/"

cat > "$STAGE/DEBIAN/control" <<EOF
Package: $PKG
Version: $VERSION
Section: utils
Priority: optional
Architecture: all
Maintainer: Unmaintained Package <root@localhost>
Depends: python3 (>= 3.7), curl, zip, coreutils
Recommends: default-mysql-client | mariadb-client, postgresql-client, sqlite3
Description: Backup Laravel apps and upload archives to Telegram
 Automates zip of project trees, database dumps (MySQL, PostgreSQL, SQLite),
 and sends compressed bundles to a Telegram channel via Bot API. Uses
 systemd timer for scheduled runs.
EOF

cat > "$STAGE/DEBIAN/postinst" <<'EOF'
#!/bin/sh
set -e
case "$1" in
configure)
  mkdir -p /etc/laravel-telegram-backup
  chmod 755 /etc/laravel-telegram-backup

  CFG=/etc/laravel-telegram-backup/config.json
  DEF=/usr/share/doc/laravel-telegram-backup/examples/config.json
  TS="$(date -u +%Y%m%d%H%M%S 2>/dev/null || date +%Y%m%d%H%M%S)"
  BAK="${CFG}.bak.${TS}"

  if [ -f /etc/laravel-telegram-backup/config.json ]; then
    cp -a "$CFG" "$BAK" 2>/dev/null || true

    if lpb config-migrate --config "$CFG" --defaults "$DEF" && lpb validate-config --config "$CFG"; then
      lpb sync-schedule --config "$CFG" 2>/dev/null || true
    else
      echo "WARNING: config migration failed; restoring previous config" >&2
      if [ -f "$BAK" ]; then
        cp -a "$BAK" "$CFG" 2>/dev/null || true
      fi
    fi
  else
    lpb config-migrate --config "$CFG" --defaults "$DEF" 2>/dev/null || true
    lpb sync-schedule --config "$CFG" 2>/dev/null || true
  fi

  if command -v systemctl >/dev/null 2>&1; then
    systemctl daemon-reload || true
    systemctl enable --now laravel-telegram-backup.timer || true
  fi
  ;;
esac
exit 0
EOF

cat > "$STAGE/DEBIAN/prerm" <<'EOF'
#!/bin/sh
set -e
case "$1" in
remove|deconfigure)
  if command -v systemctl >/dev/null 2>&1; then
    systemctl stop laravel-telegram-backup.timer 2>/dev/null || true
    systemctl disable laravel-telegram-backup.timer 2>/dev/null || true
    systemctl daemon-reload || true
  fi
  ;;
upgrade|failed-upgrade)
  ;;
*)
  ;;
esac
exit 0
EOF

chmod 755 "$STAGE/DEBIAN/postinst" "$STAGE/DEBIAN/prerm"

dpkg-deb --root-owner-group --build "$STAGE" "$ROOT/${PKG}_${VERSION}_all.deb"
echo "Built $ROOT/${PKG}_${VERSION}_all.deb"
