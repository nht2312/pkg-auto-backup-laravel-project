# laravel-telegram-backup

Định kỳ backup mã nguồn Laravel (tar.gz) và dump database, gửi file lên Telegram (Bot API). Hỗ trợ nhiều dự án trong một file cấu hình JSON.

## Cài đặt

### Cách 1: 1 lệnh tự cài hết (khuyến nghị)

#### 1A) Từ GitHub (đúng kiểu `curl ... | bash`)

```bash
curl -fsSL https://raw.githubusercontent.com/<owner>/<repo>/main/install-remote.sh | bash -s -- --repo <owner>/<repo>
```

Ví dụ:

```bash
curl -fsSL https://raw.githubusercontent.com/acme/laravel-telegram-backup/main/install-remote.sh | bash -s -- --repo acme/laravel-telegram-backup
```

Script này sẽ tự tải file `.deb` từ **GitHub Releases** (latest) rồi cài luôn.

Nếu muốn pin version:

```bash
curl -fsSL https://raw.githubusercontent.com/<owner>/<repo>/main/install-remote.sh | bash -s -- --repo <owner>/<repo> --version v1.0.0
```

#### 1B) Từ mã nguồn local

Từ thư mục dự án gói:

```bash
chmod +x install.sh && ./install.sh
```

Script này sẽ tự:
- cài dependency cần thiết,
- build file `.deb`,
- cài package,
- tạo file config mẫu (nếu chưa có),
- và in hướng dẫn cấu hình ngay sau khi cài xong.

### Cách 2: Cài trực tiếp file `.deb`

```bash
sudo apt install ./laravel-telegram-backup_1.0.0_all.deb
```

Gói bật sẵn **systemd timer** — máy khởi động lại vẫn chạy theo lịch.

## Cấu hình

1. Tạo bot Telegram qua [@BotFather](https://t.me/BotFather), lấy **token**.
2. Thêm bot vào **kênh** (Channel) với quyền đăng tin / tải file.
3. Lấy **chat_id** của kênh (thường dạng `-100...`). Có thể dùng bot [@userinfobot](https://t.me/userinfobot) hoặc API `getUpdates` sau khi post vào kênh.

Tạo file `/etc/laravel-telegram-backup/config.json` (chmod 600):

```bash
sudo mkdir -p /etc/laravel-telegram-backup
sudo cp /usr/share/doc/laravel-telegram-backup/examples/config.json /etc/laravel-telegram-backup/config.json
sudo chmod 600 /etc/laravel-telegram-backup/config.json
sudo nano /etc/laravel-telegram-backup/config.json
```

### Tần suất backup (lịch)

Trong JSON, mục `schedule`:

- **Theo lịch** (`mode`: `calendar`): dùng biểu thức giống `OnCalendar` của systemd, ví dụ `*-*-* 02:00:00` (mỗi ngày 2:00 UTC), hoặc `daily`.
- **Theo khoảng** (`mode`: `interval`): ví dụ `"every": "6h"` — chạy lại sau mỗi 6 giờ kể từ lần trước; có thể thêm `"on_boot_sec": "2min"`.

Sau khi sửa lịch trong JSON:

```bash
sudo lpb sync-schedule
```

Lệnh này ghi file drop-in cho timer và `daemon-reload` + restart timer.

### Database

- `driver`: `mysql`, `mariadb`, `pgsql`, `postgres`, `postgresql`, hoặc `sqlite`.
- MySQL/Postgres: cần cài client tương ứng (`mariadb-client`, `postgresql-client`).
- SQLite: cần `sqlite3`; trong config `database` là đường dẫn file `.sqlite`.

### File lớn hơn ~50 MB

Telegram Bot API giới hạn kích thước file. Gói tự **chia nhỏ** archive và gửi nhiều tin (caption ghi `part i/n`). Có thể chỉnh ngưỡng trong `global.telegram_max_bytes` (mặc định ~45 MiB).

## Lệnh

| Lệnh | Mô tả |
|------|--------|
| `lpb run` | Chạy backup toàn bộ project (mặc định). |
| `lpb validate-config` | Kiểm tra JSON. |
| `lpb sync-schedule` | Đồng bộ lịch từ JSON sang systemd timer. |

## Systemd

- Timer: `laravel-telegram-backup.timer`
- Service (oneshot): `laravel-telegram-backup.service`

```bash
sudo systemctl status laravel-telegram-backup.timer
journalctl -u laravel-telegram-backup.service -n 50 --no-pager
```

Nếu chưa có `config.json`, timer vẫn chạy nhưng service **bỏ qua** lần chạy (ExecCondition).

## Build gói .deb (từ mã nguồn)

Cần môi trường Debian/Ubuntu có lệnh `dpkg-deb` (gói `dpkg-dev`).

```bash
chmod +x build-deb.sh
./build-deb.sh
```

File `laravel-telegram-backup_1.0.0_all.deb` sinh ra trong thư mục gốc (đổi phiên bản bằng biến môi trường `VERSION=... ./build-deb.sh`).
