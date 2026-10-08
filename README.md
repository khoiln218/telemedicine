# Telemedicine – Đồ án INT1313 Cơ sở dữ liệu (Nhóm G5)

Đề tài #5: Cổng thông tin phòng khám & y tế từ xa. HK1 2026-2027, tổ 06, GV Lê Hà Thanh.

| Thành viên | Mảng nghiệp vụ |
|---|---|
| Lê Ngọc Khôi (trưởng nhóm) | B. Bệnh nhân & Lịch hẹn |
| Đặng Hữu Khoa | A. Nhân viên y tế & Lịch làm việc |
| Nguyễn Đăng Khoa | C. Hồ sơ bệnh án & Đơn thuốc |

Kế hoạch, phân công và báo cáo tuần: [docs/KeHoach_G5_Telemedicine.xlsx](docs/KeHoach_G5_Telemedicine.xlsx).

## Cấu trúc thư mục

```
docs/        Báo cáo (docx), kế hoạch (xlsx)
  de-bai/    Đề bài, mẫu báo cáo, kế hoạch đánh giá của môn học
  khao-sat/  Ghi chú khảo sát GĐ0
erd/         Sơ đồ ER/EER (.drawio)
sql/         Script SQL – xem thứ tự chạy bên dưới
app/         Ứng dụng Flask (GĐ4, tuần 11)
```

Tên file trong `sql/` theo kế hoạch:

| File | Nội dung | Việc |
|---|---|---|
| `A_schema.sql`, `B_schema.sql`, `C_schema.sql` | DDL từng mảng | T32–T34 |
| `schema.sql` | DDL tổng (gộp 3 mảng) | T35 |
| `A_trigger_view.sql`, `B_…`, `C_…` | Trigger + view từng mảng | T36–T38 |
| `seed.sql` | Dữ liệu mẫu | T39 |
| `queries_A.sql`, `queries_B.sql`, `queries_C.sql` | 4 truy vấn mỗi mảng | T40–T42 |
| `tests.sql` | Test ràng buộc | T43 |
| `rbac.sql` | Role, GRANT/REVOKE | T45 |

## Cài đặt

### 1. Git

```bash
git clone https://github.com/khoiln218/telemedicine.git
cd telemedicine
```

### 2. PostgreSQL 16

Cả nhóm dùng **PostgreSQL 16** để script chạy giống nhau trên mọi máy.

**Windows**
1. Tải bộ cài EDB tại https://www.postgresql.org/download/windows/ và chọn bản 16.x.
2. Khi cài: đặt mật khẩu cho user `postgres` và giữ cổng `5432`. Có thể bỏ chọn Stack Builder.
3. Thêm `C:\Program Files\PostgreSQL\16\bin` vào biến môi trường `PATH`, rồi mở terminal mới.

**macOS (Homebrew)**
```bash
brew install postgresql@16
brew services start postgresql@16
echo 'export PATH="/opt/homebrew/opt/postgresql@16/bin:$PATH"' >> ~/.zshrc   # postgresql@16 là keg-only
```

Nếu máy đã có PostgreSQL bản khác chạy ở cổng 5432, sửa `port = 5433` trong `/opt/homebrew/var/postgresql@16/postgresql.conf`, chạy `brew services restart postgresql@16`, rồi thêm `-p 5433` vào các lệnh bên dưới.

**Kiểm tra và tạo CSDL** (Windows thêm `-U postgres`):
```bash
psql --version                      # phải là 16.x
psql -d postgres -c "CREATE DATABASE telemedicine ENCODING 'UTF8' TEMPLATE template0;"
psql -d telemedicine -c "CREATE EXTENSION IF NOT EXISTS btree_gist;"
```

`btree_gist` cần cho ràng buộc `EXCLUDE` chống trùng lịch hẹn (BR-B02). Extension này có sẵn trong bộ cài, chỉ cần bật.

Công cụ GUI (tùy chọn): pgAdmin 4 (có sẵn trong bộ cài Windows) hoặc DBeaver.

### 3. draw.io

- Bản desktop: https://github.com/jgraph/drawio-desktop/releases (macOS: `brew install --cask drawio`).
- Hoặc dùng bản web https://app.diagrams.net, hoặc extension **Draw.io Integration** trong VS Code.
- Vẽ ERD theo ký hiệu Chen/Elmasri: vào **+ More Shapes** → bật **Entity Relation**.
- Lưu file `.drawio` vào `erd/`, đặt tên theo mảng: `erd/A.drawio`, `erd/B.drawio`, `erd/C.drawio`, `erd/ERD_tong.drawio`.

### 4. Python (từ GĐ4)

Cần Python 3.11+. Hướng dẫn chạy Flask sẽ bổ sung ở T47.

## Chạy script SQL

Chạy lại từ đầu trên CSDL sạch (khi đã có file):

```bash
dropdb --if-exists telemedicine && createdb -E UTF8 -T template0 telemedicine
psql -d telemedicine -v ON_ERROR_STOP=1 -f sql/schema.sql
psql -d telemedicine -v ON_ERROR_STOP=1 -f sql/A_trigger_view.sql   # tương tự B, C
psql -d telemedicine -v ON_ERROR_STOP=1 -f sql/seed.sql
psql -d telemedicine -v ON_ERROR_STOP=1 -f sql/rbac.sql
```

## Quy ước làm việc

- `git pull` trước khi làm, commit nhỏ và thường xuyên.
- Commit message bắt đầu bằng mã việc, ví dụ: `T12: ERD mảng B`.
- File Excel / Word chỉ một người sửa tại một thời điểm (git không gộp được file nhị phân). Báo trong nhóm trước khi sửa.
- Sau khi xong việc: cập nhật Trạng thái / % trong sheet Kế hoạch và thêm một dòng vào sheet Báo cáo tuần.
