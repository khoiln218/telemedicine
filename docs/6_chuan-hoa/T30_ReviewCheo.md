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
| A | [T19](../5_anh-xa/T19_AnhXa_MangA.md) | [T23](T23_FD_MangA.md), [T26](T26_ChuanHoa_MangA.md) | [T29](T29_TuDienDuLieu_MangA.md), báo cáo mục 3 | Đã lập, chờ review chéo |
| B | [T20](../5_anh-xa/T20_AnhXa_MangB.md) | [T24](T24_FD_MangB.md), [T27](T27_ChuanHoa_MangB.md) | Báo cáo mục 3 (T29) | **Có**, đối chiếu thêm `sql/B_schema.sql`, `sql/B_trigger_view.sql` |
| C | [T21](../5_anh-xa/T21_AnhXa_MangC.md) | [T25](T25_FD_MangC.md), [T28](T28_ChuanHoa_MangC.md) | Báo cáo mục 3 (T29, theo `C_schema.sql`, `C_trigger_view.sql`) | Có tài liệu, **chờ review chéo** |

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
| L06 | T33 / báo cáo 1.2.4 | Ràng buộc chung yêu cầu email đúng định dạng và ngày sinh không ở tương lai; `benh_nhan` chưa kiểm tra (phát hiện khi viết từ điển dữ liệu, T31) | Thêm CHECK `ngay_sinh <= CURRENT_DATE` và CHECK dạng email vào `B_schema.sql`; chạy lại bộ test T33, T37 không đổi | Đã sửa |
| L07 | Báo cáo mục 3 (A) | Sáu bảng mảng A ghi cột theo thứ tự Mô tả, Kiểu, Null, Khóa…, lệch tiêu đề Kiểu dữ liệu, Null, Khóa, Mặc định, Ràng buộc, Mô tả; tiêu đề bảng dùng kiểu Heading 3 (lọt vào mục lục); danh sách bảng còn dòng mẫu `bac_si` lặp | Khôi viết lại sáu bảng A theo `A_schema.sql`, `A_trigger_view.sql` cùng khuôn với B, kèm BR tương ứng; tiêu đề bảng về kiểu đoạn thường; danh sách bảng xếp A, B, C (19 bảng); bỏ dòng chờ trong bảng miền giá trị (28/10) | Đã sửa |
| L08 | T25 / `C_schema.sql` | T25 mục 4 ghi "tên thuốc/hoạt chất không được giả định duy nhất; chỉ mã là khóa", nhưng DDL khai báo `hoat_chat.ten_hoat_chat` UNIQUE NOT NULL, tức `{ten_hoat_chat}` là khóa ứng viên. Báo cáo mục 3 ghi theo DDL | Đăng Khoa chọn: bỏ UNIQUE trong DDL, hoặc thêm khóa ứng viên `{ten_hoat_chat}` vào T25, T28. Cả hai cách HOAT_CHAT vẫn đạt BCNF | Chờ sửa |

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
| C2 | Phương án ánh xạ `BAC_SI` ở T19; T20, T33 đang giả định 8A (có bảng `BAC_SI_DA_KHOA`) | Chọn 8A trong T19; FK `ma_bac_si_lap`, BR-B07 khớp giả định | **Đã chốt** |
| C3 | Quy ước T18: khóa `INTEGER` tự tăng, giờ `TIMESTAMP`, giá trị `loai_nv` trùng `vai_tro`, ca hủy là `'HUY'` | Đã ghi trong [T18](T18_QuyUocDuLieu.md), khớp B_schema và B_trigger_view | **Đã chốt** |
| C4 | Cách trình bày FD có điều kiện (cột UNIQUE cho phép NULL) chung cho 3 mảng | T24, T27 | Đăng Khoa (T22) |

## 6. Còn lại của T30

- Review chéo độc lập phần A (T19, T23, T26, T29) và rà phần C khi có T21, T25, T28.
- Rà phần A, C khi có T19, T21, T23, T25, T26, T28. Phần C đã có T21/T25/T28; Hữu Khoa review chéo sau khi đồng bộ.
- Rà mục 3 khi có T29.
- Đăng Khoa đã đọc chéo T20/T24/T27 và `B_schema.sql`, `B_trigger_view.sql`, `tests_B.sql` ngày 28/10/2026; kết quả kiểm thử ghi tại mục 7.

## 7. Ghi nhận review chéo B (Nguyễn Đăng Khoa, 28/10/2026)

| Phạm vi | Nhận xét |
|---|---|
| T20 ↔ `B_schema.sql` | Các bảng, khóa và FK chính khớp. Khóa ngoại kép `(ma_giay, ma_bn)` bảo đảm giấy chuyển thuộc đúng bệnh nhân; `LICH_HEN.ma_giay` UNIQUE cho quan hệ 1:1 tùy chọn. |
| T24/T27 ↔ DDL | FD và khóa ứng viên phù hợp các PK/UNIQUE/NOT NULL đang khai báo. T24/T27 đã tách FD có điều kiện do UNIQUE cho phép NULL khỏi khóa ứng viên toàn cục; T22 dùng cùng quy ước. |
| T08 ↔ `B_trigger_view.sql` | Các kiểm tra ca làm, giấy chuyển, trạng thái lịch, vai trò tài khoản và bảo toàn tài khoản có trigger/ràng buộc tương ứng. |
| Còn mở | C1 vẫn cần cả nhóm chốt chiều đồng bộ `TAI_KHOAN.vai_tro` ↔ `NHAN_VIEN.loai_nv`; trigger hiện tại chỉ kiểm tra khi ghi tài khoản, không tự xử lý khi đổi loại nhân viên. Không đóng C1 trong review này. C2/C3 vẫn phụ thuộc T18/T32 của mảng A. |
| Kiểm thử | Chạy `tests_B.sql` ngày 28/10/2026 trên PostgreSQL 16.15 với A stub tạm theo đúng giao diện B đang tham chiếu: 49/49 đạt. TB41 ban đầu không tới trigger vì FK chặn `TRUNCATE`; sửa thành `TRUNCATE ... CASCADE`, chạy lại trigger BR-B10 được gọi và test đạt. A stub chỉ kiểm tra tích hợp B, không thay cho A_schema chính thức. |

## 8. Tự rà soát phần C trước review

T21/T25/T28 và các script C được đối chiếu với T05/T09/ERD C. Các điểm cần reviewer/nhóm xác nhận: (1) `ham_luong` ở THUOC và liên kết CHỨA mang hai nghĩa riêng; (2) T21/DDL dùng `created_by → TAI_KHOAN`, nhưng ERD C hiện chỉ vẽ thuộc tính `created_by`, chưa vẽ TAI_KHOAN/liên kết tạo bản ghi; cần bổ sung quan hệ vào ERD C hoặc chốt không dùng FK; (3) patient-facing view dùng `app.ma_bn` do backend đã xác thực đặt, không an toàn nếu cấp SQL trực tiếp cho bệnh nhân; (4) A_schema/seed chính thức cần ghép trước khi kiểm thử tích hợp đầy đủ. Trên PostgreSQL 16.15 với A stub và dữ liệu giả lập: `tests_C.sql` đạt 13/13; bốn truy vấn C chạy được và trả kết quả với fixture gồm hai bác sĩ/lịch hẹn lịch sử. T44 đã chạy `EXPLAIN ANALYZE` trên fixture nhỏ; số đo không đại diện hiệu năng khi có dữ liệu thực nghiệm. T30 phần C vẫn chờ review chéo.
