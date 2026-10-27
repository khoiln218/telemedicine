# T19 – Ánh xạ mảng A sang lược đồ quan hệ

| | |
|---|---|
| Mã việc | T19 (GĐ2) |
| Người làm / review | Đặng Hữu Khoa / Nguyễn Đăng Khoa |
| Căn cứ | [ERD mảng A](../3_erd/A.drawio), [T07 – quy tắc mảng A](../2_quy-tac/T07_BR_MangA.md), [T18 – quy ước dữ liệu](../6_chuan-hoa/T18_QuyUocDuLieu.md) |
| Dùng cho | Báo cáo mục 2.2, T23, T26, T29, `sql/A_schema.sql` |

Quy ước: thuộc tính gạch chân là khóa chính; `→` là khóa ngoại.

## 1. Lược đồ quan hệ

- NHAN_VIEN(<u>ma_nv</u>, ho_ten, ngay_sinh, sdt, email, loai_nv)
- BAC_SI(<u>ma_bac_si</u> → NHAN_VIEN.ma_nv, so_chung_chi, ngay_cap_cc, ngay_het_han_cc, loai_bac_si)
- BAC_SI_DA_KHOA(<u>ma_bac_si</u> → BAC_SI.ma_bac_si)
- BAC_SI_CHUYEN_KHOA(<u>ma_bac_si</u> → BAC_SI.ma_bac_si, ma_chuyen_khoa → CHUYEN_KHOA.ma_chuyen_khoa)
- CHUYEN_KHOA(<u>ma_chuyen_khoa</u>, ten_chuyen_khoa)
- CA_LAM_VIEC(<u>ma_ca</u>, thoi_gian_bd, thoi_gian_kt, trang_thai, ma_bac_si → BAC_SI.ma_bac_si)

`ma_bac_si` là khóa kế thừa từ `NHAN_VIEN.ma_nv`; giữ tên này để khớp ERD tổng và các FK mảng B/C.

## 2. Ánh xạ theo thuật toán Elmasri

| Bước | Áp dụng |
|---|---|
| 1. Thực thể mạnh | NHAN_VIEN, BAC_SI, CHUYEN_KHOA, CA_LAM_VIEC thành bảng; thuộc tính khóa thành PK. `so_chung_chi` là khóa ứng viên của BAC_SI, `ten_chuyen_khoa` được đặt UNIQUE. |
| 2. Thực thể yếu | Không có. |
| 3. Liên kết 1:1 | Các lớp con dùng PK đồng thời là FK về lớp cha; BAC_SI kế thừa NHAN_VIEN. |
| 4. Liên kết 1:N | BAC_SI_CHUYEN_KHOA giữ FK `ma_chuyen_khoa`; CA_LAM_VIEC giữ FK `ma_bac_si`. Cả hai phía N tham gia bắt buộc nên FK NOT NULL. |
| 5. Liên kết M:N | Không có. |
| 6. Thuộc tính đa trị | Không có. |
| 7. Liên kết bậc n | Không có. |
| 8. Chuyên biệt hóa | Chọn 8A cho NHAN_VIEN→BAC_SI (partial) và BAC_SI→{BAC_SI_DA_KHOA, BAC_SI_CHUYEN_KHOA} (disjoint, total). |

### Lý do chọn 8A

Giữ bảng lớp cha và bảng lớp con giúp dùng một khóa bác sĩ thống nhất trong lịch hẹn, giấy chuyển và ca làm. `BAC_SI_DA_KHOA` là đích FK trực tiếp cho người lập giấy chuyển ở mảng B, bảo đảm BR-B07 bằng FK. Với phân lớp bác sĩ, ràng buộc disjoint/total được biểu diễn bằng `loai_bac_si` và trigger để đồng bộ lớp con. Với NHAN_VIEN→BAC_SI, phân lớp partial: nhân viên không phải bác sĩ chỉ có hàng ở NHAN_VIEN; trigger bảo đảm loại nhân viên và sự tồn tại hàng BAC_SI tương ứng (BR-A10).

## 3. Quy tắc được ánh xạ

| Quy tắc | Cơ chế dự kiến |
|---|---|
| BR-A01 | `BAC_SI.loai_bac_si` cùng trigger giữ đúng một bảng lớp con. |
| BR-A02 | FK NOT NULL `BAC_SI_CHUYEN_KHOA.ma_chuyen_khoa`. |
| BR-A03 | Trigger kiểm tra ngày hết hạn giấy phép bao trùm ngày của ca. |
| BR-A04 | EXCLUDE GiST trên bác sĩ và khoảng thời gian của ca còn hiệu lực. |
| BR-A05 | UNIQUE `BAC_SI.so_chung_chi`. |
| BR-A06, A07 | CHECK trên khoảng thời gian ca và ngày cấp/hết hạn. |
| BR-A08 | Trigger từ chối sửa/hủy ca nếu lịch hẹn còn hiệu lực không còn nằm trọn trong ca. |
| BR-A09 | GRANT/REVOKE thuộc script phân quyền tổng; T07 xác định vai trò, không nhúng danh tính người dùng vào trigger. |
| BR-A10 | CHECK miền `loai_nv`, trigger đồng bộ `NHAN_VIEN` và `BAC_SI`. |

## 4. Thành phần ERD

4 thực thể, 3 phân lớp và 2 liên kết (THUỘC, XẾP_CA) đều có biểu diễn trong lược đồ trên. Trigger cần bảng `LICH_HEN` mảng B nên được cài sau khi dựng schema tổng.
