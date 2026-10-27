# T30 – Review chéo mục 2.2, 2.3, 3: danh sách lỗi đã sửa

| | |
|---|---|
| Mã việc | T30 (GĐ2, tuần 8) |
| Người làm / review | Nguyễn Đăng Khoa / cả nhóm |
| Ngày | 27/10/2026: rà phần B (Lê Ngọc Khôi), chờ Đăng Khoa review chéo |
| Dùng cho | T31 (báo cáo v2.2) |

## 1. Phạm vi và tình trạng đầu vào

| Mảng | 2.2 Ánh xạ | 2.3 FD, chuẩn hóa | 3 Từ điển dữ liệu | Đã rà |
|---|---|---|---|---|
| A | T19 chưa có | T23, T26 chưa có | T29 chưa có | Chưa |
| B | [T20](../5_anh-xa/T20_AnhXa_MangB.md) | [T24](T24_FD_MangB.md), [T27](T27_ChuanHoa_MangB.md) | T29 chưa có | **Có**, đối chiếu thêm `sql/B_schema.sql`, `sql/B_trigger_view.sql` |
| C | T21 chưa có | T25, T28 chưa có | T29 chưa có | Chưa |

## 2. Nội dung kiểm tra (mảng B)

| # | Kiểm tra | Kết quả |
|---|---|---|
| 1 | Mọi thành phần ERD B có trong lược đồ (T20 mục 4) | 14/14 |
| 2 | Lược đồ T20 khớp DDL T33: tên bảng, cột, PK, FK, UNIQUE, NOT NULL | Lệch 1 chỗ, đã sửa (L01) |
| 3 | FD, khóa ứng viên T24 dùng đúng thuộc tính của lược đồ; khóa ứng viên có UNIQUE/PK trong DDL | Khớp |
| 4 | Chuẩn hóa T27 có làm đổi thiết kế không | Không tách bảng, **ERD B không phải sửa** |
| 5 | Mọi quy tắc "còn lại cho cài đặt" (T20 mục 5) có cơ chế trong DDL hoặc trigger | Đủ, xem mục 4; BR-B08, BR-B10 phần quyền chờ T45 |
| 6 | Trigger T37 không đặt thêm quy tắc ngoài T08 | 4 điểm diễn giải, đã xác nhận và ghi vào T08 (L02–L05) |

## 3. Danh sách lỗi

| Mã | Tài liệu | Lỗi | Xử lý | Trạng thái |
|---|---|---|---|---|
| L01 | T20 | Ghi FK đơn `LICH_HEN.ma_giay → GIAY_CHUYEN_KHOA` và xếp "giấy của chính bệnh nhân" (BR-B03) vào phần còn lại cho cài đặt; DDL T33 dùng khóa ngoại kép `(ma_giay, ma_bn) → GIAY_CHUYEN_KHOA(ma_giay, ma_bn)` đã bảo đảm điều này | Sửa T20 mục 1, 2.1, 3, 5. T24, T27 không đổi: `(ma_giay, ma_bn)` là siêu khóa, không thêm FD | Đã sửa |
| L02 | T37 / T08 | "Giấy còn hạn" chưa nói tính theo ngày nào. Trigger tính theo **ngày hẹn** nằm trong [`ngay_lap`, `ngay_het_han`] | Khôi xác nhận 27/10; ghi vào T08 mục 5 | Đã sửa |
| L03 | T37 / T08 | Trigger chặn lịch hẹn với **bác sĩ đa khoa** kèm giấy chuyển; T08 không nói rõ | Như L02 | Đã sửa |
| L04 | T37 / T08 | BR-B05 chỉ nói trạng thái cuối không chuyển tiếp; trigger chặn **mọi** sửa đổi trên lịch ở trạng thái cuối (theo lý do "không sửa lại lịch hẹn đã kết thúc") | Như L02 | Đã sửa |
| L05 | T37 / T08 | Lịch có giấy bị hủy hoặc vắng mặt thì giấy vẫn gắn với lịch đó, đặt lại bằng giấy cũ chỉ nhận lỗi UNIQUE thô `lich_hen_ma_giay_key`; T08 chưa nói giấy như vậy có tính là đã dùng | Chốt giữ thiết kế (không dùng UNIQUE riêng phần cho lịch còn hiệu lực, vì sẽ phát sinh `ma_lh → ma_giay → ma_bn`, vi phạm 3NF). Ghi vào T08 mục 5; trigger báo "BR-B03: giấy chuyển đã dùng"; đổi giờ, đổi bác sĩ thì UPDATE lịch, không hủy rồi đặt lại | Đã sửa |

## 4. Quy tắc mảng B → cơ chế cài đặt

Dùng lại cho báo cáo mục 4.1 và test T43.

| Quy tắc | Cơ chế |
|---|---|
| BR-B01 | `trg_lich_hen_hop_le` |
| BR-B02 | `ex_lich_hen_bac_si`, `ex_lich_hen_benh_nhan` (EXCLUDE gist) |
| BR-B03 | `lich_hen.ma_giay` UNIQUE, `fk_lich_hen_giay` (khóa ngoại kép), `trg_lich_hen_hop_le` (chuyên khoa, hạn, tái khám) |
| BR-B04, BR-B06 | `ck_lich_hen_hinh_thuc` |
| BR-B05 | CHECK miền `trang_thai`, `trg_trang_thai_lich_hen` |
| BR-B07 | `ck_giay_han`, FK `ma_bac_si_lap → bac_si_da_khoa` |
| BR-B08 | T45 (`rbac.sql`) |
| BR-B09 | `ck_tai_khoan_chu_so_huu`, UNIQUE `ma_bn`, `ma_nv`, `trg_tai_khoan_vai_tro` |
| BR-B10 | `trg_tai_khoan_khong_xoa`, `trg_tai_khoan_khong_truncate`; phần quyền ở T45 |
| Ràng buộc chung | `ck_lich_hen_thoi_gian`, CHECK `phi_kham >= 0`, `benh_nhan.sdt` UNIQUE |

## 5. Chờ nhóm chốt

| Mã | Nội dung | Ảnh hưởng | Người chốt |
|---|---|---|---|
| C1 | `TAI_KHOAN.vai_tro` trùng `NHAN_VIEN.loai_nv` (dư thừa giữa hai bảng, T27 mục 5); BR-B10 cho quản trị tài khoản "đổi vai trò" mâu thuẫn BR-A09 (quản trị nhân sự sửa loại nhân viên). Hai hướng: (a) giữ `vai_tro`, vai trò nhân viên luôn theo `loai_nv`, bỏ "đổi vai trò" khỏi BR-B10, thêm trigger chặn sửa `loai_nv` khi lệch tài khoản; (b) bỏ `vai_tro`, suy từ `loai_nv` hoặc `ma_bn` | T08, T20, T24, T27, ERD B, `B_schema.sql`, `B_trigger_view.sql` | Cả nhóm (họp) |
| C2 | Phương án ánh xạ `BAC_SI` ở T19; T20, T33 đang giả định 8A (có bảng `BAC_SI_DA_KHOA`) | FK `ma_bac_si_lap`, BR-B07 | Hữu Khoa |
| C3 | Quy ước T18: khóa `INTEGER` tự tăng, giờ `TIMESTAMP`, giá trị `loai_nv` trùng `vai_tro`, ca hủy là `'HUY'` | `B_schema.sql`, `B_trigger_view.sql` | Hữu Khoa |
| C4 | Cách trình bày FD có điều kiện (cột UNIQUE cho phép NULL) chung cho 3 mảng | T24, T27 | Đăng Khoa (T22) |

## 6. Còn lại của T30

- Rà phần A, C khi có T19, T21, T23, T25, T26, T28.
- Rà mục 3 khi có T29.
- Đăng Khoa review chéo phần B ở trên.
