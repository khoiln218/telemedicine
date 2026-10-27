# T20 – Ánh xạ mảng B sang lược đồ quan hệ: Bệnh nhân & Lịch hẹn

| | |
|---|---|
| Mã việc | T20 (GĐ2, tuần 5) |
| Người làm / review | Lê Ngọc Khôi / Đặng Hữu Khoa |
| Ngày | 27/10/2026; cập nhật 27/10/2026 theo review T30 (khóa ngoại kép giấy chuyển – bệnh nhân) |
| Chuẩn tham chiếu | Thuật toán ánh xạ ER/EER → quan hệ, Elmasri & Navathe, *Fundamentals of Database Systems* (7th ed.), chương 9 |
| Căn cứ | [ERD mảng B](../3_erd/B.drawio), [T08 – quy tắc mảng B](../2_quy-tac/T08_BR_MangB.md), [T15 – truy vết](../4_truy-vet/T15_Traceability.md) |
| Dùng cho | Báo cáo mục 2.2, T24 (FD mảng B), T29 (từ điển dữ liệu), T33 (`B_schema.sql`) |

Phạm vi: các thực thể, liên kết màu xanh lá trong ERD mảng B. Kiểu dữ liệu, miền giá trị chưa ghi ở đây, chốt theo quy ước T18 và từ điển dữ liệu T29.

Ký hiệu: <u>gạch chân</u> là khóa chính (PK); `→ BẢNG` là khóa ngoại (FK) tham chiếu khóa chính của bảng đó.

## 1. Kết quả: lược đồ quan hệ mảng B

- BENH_NHAN(<u>ma_bn</u>, ho_ten, ngay_sinh, gioi_tinh, sdt, email)
- GIAY_CHUYEN_KHOA(<u>ma_giay</u>, ngay_lap, ly_do, ngay_het_han, ma_bn → BENH_NHAN, ma_bac_si_lap → BAC_SI_DA_KHOA, ma_chuyen_khoa → CHUYEN_KHOA)
- LICH_HEN(<u>ma_lh</u>, thoi_gian_bd, thoi_gian_kt, ly_do_kham, trang_thai, hinh_thuc, phi_kham, ngay_tao, phong_kham, nen_tang, link_phien, ma_bn → BENH_NHAN, ma_bac_si → BAC_SI, (ma_giay, ma_bn) → GIAY_CHUYEN_KHOA)
- TAI_KHOAN(<u>ten_dang_nhap</u>, mat_khau_hash, vai_tro, trang_thai, ma_bn → BENH_NHAN, ma_nv → NHAN_VIEN)

Bảng mượn từ mảng A (chỉ dùng làm đích của khóa ngoại, ánh xạ ở T19): NHAN_VIEN(<u>ma_nv</u>, …), BAC_SI(<u>ma_bac_si</u>, …), BAC_SI_DA_KHOA(<u>ma_bac_si</u>), CHUYEN_KHOA(<u>ma_chuyen_khoa</u>, …).

## 2. Các bước ánh xạ

| Bước (Elmasri) | Thành phần ERD mảng B | Cách ánh xạ |
|---|---|---|
| 1. Thực thể mạnh | `BENH_NHAN`, `LICH_HEN`, `GIAY_CHUYEN_KHOA`, `TAI_KHOAN` | Mỗi thực thể thành một bảng, giữ thuộc tính đơn; khóa trong ERD thành PK. `sdt` là khóa ứng viên → UNIQUE |
| 2. Thực thể yếu | Không có | – |
| 3. Liên kết 1:1 | `SỬ_DỤNG`, `TK_BỆNH_NHÂN`, `TK_NHÂN_VIÊN` | Cách khóa ngoại, xem 2.1 |
| 4. Liên kết 1:N | `ĐẶT`, `PHỤ_TRÁCH`, `ĐƯỢC_CẤP`, `LẬP_GIẤY`, `CHUYỂN_ĐẾN` | FK đặt ở bảng phía N: `LICH_HEN.ma_bn`, `LICH_HEN.ma_bac_si`, `GIAY_CHUYEN_KHOA.ma_bn`, `.ma_bac_si_lap`, `.ma_chuyen_khoa`. Phía N tham gia bắt buộc (nét đôi) nên các FK này NOT NULL |
| 5. Liên kết M:N | Không có | – |
| 6. Thuộc tính đa trị | Không có | – |
| 7. Liên kết bậc n | Không có | – |
| 8. Chuyên biệt hóa | `LICH_HEN` → {`KHAM_TRUC_TIEP`, `TU_VAN_TU_XA`}, rời nhau (d), toàn phần, phân theo `hinh_thuc` | Phương án 8C, xem 2.2 |

### 2.1. Liên kết 1:1 (bước 3)

Cả ba liên kết đều có hai phía tham gia không bắt buộc, nên dùng cách khóa ngoại và chọn phía đặt FK như sau.

| Liên kết | Đặt FK ở | Lý do |
|---|---|---|
| `SỬ_DỤNG` (giấy chuyển 1:1 lịch hẹn) | `LICH_HEN.ma_giay`, UNIQUE, cho phép NULL | Giấy có trước lịch hẹn, nên lịch hẹn chuyên khoa ghi luôn giấy khi tạo, không phải sửa lại giấy. UNIQUE bảo đảm mỗi giấy chỉ dùng cho một lịch hẹn (BR-B03). NULL với lịch đa khoa và tái khám. Khóa ngoại kép (ma_giay, ma_bn) tham chiếu cặp (ma_giay, ma_bn) của giấy, nên giấy phải cấp cho chính bệnh nhân của lịch hẹn (BR-B03) |
| `TK_BỆNH_NHÂN` | `TAI_KHOAN.ma_bn`, UNIQUE, cho phép NULL | Nhiều bệnh nhân không có tài khoản (lễ tân đặt hộ); đặt FK ở bảng tài khoản thì không thêm cột NULL vào `BENH_NHAN`. UNIQUE: mỗi bệnh nhân tối đa một tài khoản (BR-B09) |
| `TK_NHÂN_VIÊN` | `TAI_KHOAN.ma_nv`, UNIQUE, cho phép NULL | Không thêm cột vào bảng `NHAN_VIEN` của mảng A. Mỗi tài khoản gắn đúng một trong hai người, nên kiểm tra "đúng một trong `ma_bn`, `ma_nv` khác NULL" nằm trên cùng một hàng (BR-B09) |

### 2.2. Chuyên biệt hóa lịch hẹn (bước 8)

| Phương án | Kết quả | Đánh giá |
|---|---|---|
| 8A – bảng lớp cha + bảng mỗi lớp con | `LICH_HEN`, `KHAM_TRUC_TIEP(ma_lh, phong_kham)`, `TU_VAN_TU_XA(ma_lh, nen_tang, link_phien)` | Đúng với mọi loại phân lớp, nhưng "mỗi lịch hẹn có đúng một hàng ở đúng một bảng con" phải kiểm tra bằng trigger; xem lịch hẹn phải nối bảng |
| 8B – chỉ bảng lớp con | Hai bảng con, mỗi bảng chép đủ thuộc tính lớp cha | Không dùng được: `LICH_HEN` có liên kết riêng (`ĐẶT`, `PHỤ_TRÁCH`, `SỬ_DỤNG`, `PHÁT_SINH` ở mảng C) nên `LAN_KHAM` không có một bảng duy nhất để tham chiếu; kiểm tra trùng giờ (BR-B02) phải gộp hai bảng |
| **8C – một bảng, một thuộc tính loại** | `LICH_HEN` có `hinh_thuc` và `phong_kham`, `nen_tang`, `link_phien` | **Chọn** |
| 8D – một bảng, nhiều cờ loại | Như 8C nhưng mỗi lớp con một cờ | Dành cho phân lớp chồng nhau; lịch hẹn là rời nhau |

Lý do chọn 8C:

- Phân lớp rời nhau, có thuộc tính phân loại `hinh_thuc` trong ERD: một giá trị `hinh_thuc` trên mỗi hàng đã bảo đảm mỗi lịch hẹn thuộc đúng một hình thức (BR-B06).
- Lớp con ít thuộc tính (1 và 2) và không có liên kết riêng, nên số ô NULL thêm vào ít.
- BR-B04 (tư vấn từ xa phải có `nen_tang`, `link_phien`) thành điều kiện trên một hàng, cùng chỗ với `hinh_thuc`.
- Mọi liên kết của lịch hẹn (bệnh nhân, bác sĩ, giấy chuyển, lần khám ở mảng C) và kiểm tra trùng giờ chỉ làm việc trên một bảng.

Đổi lại: `phong_kham` NULL với tư vấn từ xa, `nen_tang`, `link_phien` NULL với khám trực tiếp. Ràng buộc kèm theo: nếu `hinh_thuc` là khám trực tiếp thì `phong_kham` có giá trị, `nen_tang`, `link_phien` NULL; ngược lại với tư vấn từ xa.

## 3. Chi tiết bảng

Cột "Bắt buộc": **có** là NOT NULL; **theo hình thức**, **đúng một** là điều kiện ghi ở ghi chú.

### BENH_NHAN

| Thuộc tính | Khóa | Bắt buộc | Ghi chú |
|---|---|---|---|
| ma_bn | PK | có | |
| ho_ten | | có | |
| ngay_sinh | | có | |
| gioi_tinh | | có | |
| sdt | UNIQUE | có | Khóa ứng viên (ràng buộc chung: số điện thoại không trùng) |
| email | | không | |

### GIAY_CHUYEN_KHOA

| Thuộc tính | Khóa | Bắt buộc | Ghi chú |
|---|---|---|---|
| ma_giay | PK | có | |
| ngay_lap | | có | |
| ly_do | | có | |
| ngay_het_han | | có | Tối đa `ngay_lap` + 30 ngày (BR-B07) |
| ma_bn | FK → BENH_NHAN | có | `ĐƯỢC_CẤP`; cặp (ma_giay, ma_bn) UNIQUE làm đích khóa ngoại kép từ LICH_HEN (siêu khóa, không thêm FD mới) |
| ma_bac_si_lap | FK → BAC_SI_DA_KHOA | có | `LẬP_GIẤY`; FK tới bảng bác sĩ đa khoa bảo đảm chỉ bác sĩ đa khoa lập giấy (BR-B07) |
| ma_chuyen_khoa | FK → CHUYEN_KHOA | có | `CHUYỂN_ĐẾN` |

### LICH_HEN

| Thuộc tính | Khóa | Bắt buộc | Ghi chú |
|---|---|---|---|
| ma_lh | PK | có | |
| thoi_gian_bd, thoi_gian_kt | | có | Kết thúc sau bắt đầu (ràng buộc chung) |
| ly_do_kham | | có | |
| trang_thai | | có | Đã đặt, đã xác nhận, hoàn thành, hủy, vắng mặt (BR-B05) |
| hinh_thuc | | có | Khám trực tiếp hoặc tư vấn từ xa; thuộc tính phân loại của 8C (BR-B06) |
| phi_kham | | có | Không âm (ràng buộc chung) |
| ngay_tao | | có | |
| phong_kham | | theo hình thức | Từ lớp con `KHAM_TRUC_TIEP` |
| nen_tang, link_phien | | theo hình thức | Từ lớp con `TU_VAN_TU_XA` (BR-B04) |
| ma_bn | FK → BENH_NHAN | có | `ĐẶT` |
| ma_bac_si | FK → BAC_SI | có | `PHỤ_TRÁCH` |
| ma_giay | UNIQUE; cùng ma_bn là FK → GIAY_CHUYEN_KHOA(ma_giay, ma_bn) | không | `SỬ_DỤNG` |

### TAI_KHOAN

| Thuộc tính | Khóa | Bắt buộc | Ghi chú |
|---|---|---|---|
| ten_dang_nhap | PK | có | |
| mat_khau_hash | | có | Không lưu mật khẩu dạng đọc được |
| vai_tro | | có | 6 vai trò cố định (BR-B09, BR-B10) |
| trang_thai | | có | Hoạt động, khóa |
| ma_bn | FK → BENH_NHAN, UNIQUE | đúng một | `TK_BỆNH_NHÂN`; có giá trị khi và chỉ khi `vai_tro` là bệnh nhân |
| ma_nv | FK → NHAN_VIEN, UNIQUE | đúng một | `TK_NHÂN_VIÊN`; có giá trị khi `vai_tro` khác bệnh nhân |

### Khóa ngoại từ mảng khác trỏ vào mảng B

| Bảng (mảng) | FK | Liên kết | Việc |
|---|---|---|---|
| LAN_KHAM (C) | ma_lh → LICH_HEN, UNIQUE | `PHÁT_SINH` 1:1 | T21 |
| bảng dị ứng (C) | ma_bn → BENH_NHAN | `DỊ_ỨNG` M:N | T21 |

## 4. Truy vết ERD → lược đồ

| Thành phần ERD | Thể hiện trong lược đồ |
|---|---|
| `BENH_NHAN`, `GIAY_CHUYEN_KHOA`, `TAI_KHOAN` | Bảng cùng tên |
| `LICH_HEN`, `KHAM_TRUC_TIEP`, `TU_VAN_TU_XA` | Bảng `LICH_HEN` (8C), `hinh_thuc` |
| `ĐẶT` | `LICH_HEN.ma_bn` |
| `PHỤ_TRÁCH` | `LICH_HEN.ma_bac_si` |
| `SỬ_DỤNG` | `LICH_HEN.ma_giay` UNIQUE |
| `ĐƯỢC_CẤP` | `GIAY_CHUYEN_KHOA.ma_bn` |
| `LẬP_GIẤY` | `GIAY_CHUYEN_KHOA.ma_bac_si_lap` |
| `CHUYỂN_ĐẾN` | `GIAY_CHUYEN_KHOA.ma_chuyen_khoa` |
| `TK_BỆNH_NHÂN` | `TAI_KHOAN.ma_bn` UNIQUE |
| `TK_NHÂN_VIÊN` | `TAI_KHOAN.ma_nv` UNIQUE |

Độ phủ: 14/14 thành phần ERD mảng B (theo T15 mục 2) đều có chỗ trong lược đồ.

## 5. Quy tắc sau ánh xạ

Lược đồ quan hệ (PK, FK, UNIQUE, NOT NULL) đã bảo đảm một phần quy tắc; phần còn lại chuyển sang cài đặt.

| Quy tắc | Lược đồ đã bảo đảm | Còn lại cho cài đặt (T33, T37) |
|---|---|---|
| BR-B01 | `LICH_HEN.ma_bac_si` | Lịch hẹn nằm trọn trong một ca còn hiệu lực |
| BR-B02 | – | Lịch còn hiệu lực của cùng bác sĩ, cùng bệnh nhân không giao nhau |
| BR-B03 | Mỗi giấy dùng cho tối đa một lịch hẹn (UNIQUE); giấy của chính bệnh nhân (khóa ngoại kép) | Còn hạn, đúng chuyên khoa; miễn khi tái khám |
| BR-B04 | – | Điều kiện theo `hinh_thuc` trên một hàng |
| BR-B05 | `trang_thai` NOT NULL | Miền giá trị, thứ tự chuyển trạng thái |
| BR-B06 | Một cột `hinh_thuc` NOT NULL (8C) | Miền giá trị |
| BR-B07 | Chỉ bác sĩ đa khoa lập giấy (FK → BAC_SI_DA_KHOA) | Hạn tối đa 30 ngày |
| BR-B08, BR-B10 | – | Phân quyền theo vai trò (T45) |
| BR-B09 | Mỗi bệnh nhân, nhân viên tối đa một tài khoản (UNIQUE) | Đúng một trong `ma_bn`, `ma_nv`; vai trò khớp loại nhân viên |

## 6. Cần thống nhất với mảng A (T19)

- FK `ma_bac_si_lap → BAC_SI_DA_KHOA` giả định T19 chọn phương án 8A cho phân lớp `BAC_SI` (có bảng `BAC_SI_DA_KHOA`). Nếu T19 chọn 8C, FK đổi thành `→ BAC_SI` và điều kiện "bác sĩ đa khoa" ở BR-B07 chuyển sang phần cài đặt.
- Tên khóa: `BAC_SI.ma_bac_si` kế thừa `NHAN_VIEN.ma_nv` (theo chú thích ERD mảng A).
