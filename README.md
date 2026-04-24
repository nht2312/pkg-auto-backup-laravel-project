# Laravel Telegram Backup (Ubuntu)

<details open>
<summary><strong>English</strong></summary>

Automatically backs up multiple Laravel projects (source code + database) and uploads them to a Telegram channel via Bot API. Runs in background with `systemd timer` and continues after reboot.

## Features

- Backup multiple projects from one JSON config
- Archive source (`zip`) with exclude patterns
- Database dump support: MySQL/MariaDB, PostgreSQL, SQLite
- Upload source and DB as separate archives (easier to inspect)
- Auto split each archive when exceeding Telegram bot upload limit
- Flexible scheduling (`OnCalendar` or `OnUnitActiveSec`)

## Quick Install for End Users (One Command)

```bash
curl -fsSL https://raw.githubusercontent.com/nht2312/pkg-auto-backup-laravel-project-telegram/main/install-remote.sh | bash -s -- --repo nht2312/pkg-auto-backup-laravel-project-telegram
```

This script will automatically:
- try to download the latest `.deb` from GitHub Releases,
- fallback to clone + build + install from source if no release is available,
- install the package,
- create a sample config (if not present),
- print post-install setup instructions.

## Install from Source (Developer)

```bash
chmod +x install.sh && ./install.sh
```

## Quick Setup

```bash
sudo nano /etc/laravel-telegram-backup/config.json
sudo lpb validate-config
sudo lpb sync-schedule
sudo lpb run
```

## Main Commands

- `lpb run`
- `lpb validate-config`
- `lpb sync-schedule`
- `lpb config-migrate`

## Check Status

```bash
sudo systemctl status laravel-telegram-backup.timer
journalctl -u laravel-telegram-backup.service -n 100 --no-pager
```

## Upgrade Behavior (Keep User Config)

- `apt upgrade` keeps `/etc/laravel-telegram-backup/config.json` (no reset).
- During upgrade, package runs automatic `lpb config-migrate`:
  - existing user values are preserved,
  - new keys from package defaults are added when missing,
  - arrays/lists keep user values by default.
- A backup is created before migration:
  - `/etc/laravel-telegram-backup/config.json.bak.YYYYmmddHHMMSS`
- If migration/validation fails, installer restores from backup.

## Detailed Docs

See: `usr/share/doc/laravel-telegram-backup/README.md`

## CI/CD Release (GitHub Actions)

Push a tag in format `vX.Y.Z` to auto build and publish `.deb` to GitHub Releases:

```bash
git tag v1.0.1
git push origin v1.0.1
```

Workflow file: `.github/workflows/release.yml`

</details>

<details>
<summary><strong>Tiếng Việt</strong></summary>

Tự động backup nhiều dự án Laravel (source code + database) và upload lên Telegram channel bằng Bot API. Chạy nền bằng `systemd timer`, tự chạy lại sau khi reboot.

## Tính năng

- Backup nhiều project trong một file config JSON
- Backup source (`zip`) với danh sách exclude
- Dump DB: MySQL/MariaDB, PostgreSQL, SQLite
- Tự chia nhỏ file khi vượt giới hạn upload Telegram bot
- Chạy theo lịch (`OnCalendar`) hoặc theo chu kỳ (`OnUnitActiveSec`)

## Cài nhanh cho người dùng cuối (1 lệnh)

```bash
curl -fsSL https://raw.githubusercontent.com/nht2312/pkg-auto-backup-laravel-project-telegram/main/install-remote.sh | bash -s -- --repo nht2312/pkg-auto-backup-laravel-project-telegram
```

Script sẽ tự:
- tải `.deb` mới nhất từ GitHub Releases,
- cài package,
- tạo config mẫu (nếu chưa có),
- in hướng dẫn cấu hình sau khi cài.

## Cài từ source (developer)

```bash
chmod +x install.sh && ./install.sh
```

## Cấu hình nhanh

```bash
sudo nano /etc/laravel-telegram-backup/config.json
sudo lpb validate-config
sudo lpb sync-schedule
sudo lpb run
```

## Lệnh chính

- `lpb run`
- `lpb validate-config`
- `lpb sync-schedule`
- `lpb config-migrate`

## Kiểm tra trạng thái

```bash
sudo systemctl status laravel-telegram-backup.timer
journalctl -u laravel-telegram-backup.service -n 100 --no-pager
```

## Hành vi khi nâng cấp (không mất config)

- `apt upgrade` giữ nguyên `/etc/laravel-telegram-backup/config.json` (không reset).
- Trong quá trình upgrade, package tự chạy `lpb config-migrate`:
  - giữ nguyên giá trị user đã cấu hình,
  - thêm key mới từ config mẫu khi còn thiếu,
  - mảng/list mặc định giữ theo dữ liệu user.
- Trước migrate sẽ tạo backup:
  - `/etc/laravel-telegram-backup/config.json.bak.YYYYmmddHHMMSS`
- Nếu migrate/validate lỗi, installer tự restore từ backup.

## Tài liệu chi tiết

Xem thêm tại: `usr/share/doc/laravel-telegram-backup/README.md`

## CI/CD Release (GitHub Actions)

Push tag theo format `vX.Y.Z` để tự build `.deb` và publish lên GitHub Releases:

```bash
git tag v1.0.1
git push origin v1.0.1
```

Workflow nằm tại: `.github/workflows/release.yml`

</details>
