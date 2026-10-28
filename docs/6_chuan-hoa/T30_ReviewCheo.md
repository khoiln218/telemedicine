# T30 – Review chéo mục 2.2, 2.3, 3: danh sách lỗi đã sửa

| | |
|---|---|
| Mã việc | T30 (GĐ2, tuần 8) |
| Người làm / review | Nguyễn Đăng Khoa / cả nhóm |
| Ngày | 27/10/2026: rà phần B (Lê Ngọc Khôi); 28/10/2026: Đăng Khoa review chéo B, Khôi review chéo A, C và mục 3; sửa L07–L14, chốt C1, C5; đóng T30 |
| Dùng cho | T31 (báo cáo v2.2) |

## 1. Phạm vi và tình trạng đầu vào

| Mảng | 2.2 Ánh xạ | 2.3 FD, chuẩn hóa | 3 Từ điển dữ liệu | Đã rà |
|---|---|---|---|---|
| A | [T19](../5_anh-xa/T19_AnhXa_MangA.md) | [T23](T23_FD_MangA.md), [T26](T26_ChuanHoa_MangA.md) | [T29](T29_TuDienDuLieu_MangA.md), báo cáo mục 3 | **Có** (Khôi), đối chiếu thêm `sql/A_schema.sql`, `sql/A_trigger_view.sql` |
| B | [T20](../5_anh-xa/T20_AnhXa_MangB.md) | [T24](T24_FD_MangB.md), [T27](T27_ChuanHoa_MangB.md) | Báo cáo mục 3 (T29) | **Có**, đối chiếu thêm `sql/B_schema.sql`, `sql/B_trigger_view.sql` |
| C | [T21](../5_anh-xa/T21_AnhXa_MangC.md) | [T25](T25_FD_MangC.md), [T28](T28_ChuanHoa_MangC.md) | Báo cáo mục 3 (T29, theo `C_schema.sql`, `C_trigger_view.sql`) | **Có** (Khôi), đối chiếu thêm `sql/C_schema.sql`, `sql/C_trigger_view.sql`, `sql/rbac.sql` |

## 2. Nội dung kiểm tra

### Mảng B

| # | Kiểm tra | Kết quả |
|---|---|---|
| 1 | Mọi thành phần ERD B có trong lược đồ (T20 mục 4) | 14/14 |
| 2 | Lược đồ T20 khớp DDL T33: tên bảng, cột, PK, FK, UNIQUE, NOT NULL | Lệch 1 chỗ, đã sửa (L01) |
| 3 | FD, khóa ứng viên T24 dùng đúng thuộc tính của lược đồ; khóa ứng viên có UNIQUE/PK trong DDL | Khớp |
| 4 | Chuẩn hóa T27 có làm đổi thiết kế không | Không tách bảng, **ERD B không phải sửa** |
| 5 | Mọi quy tắc "còn lại cho cài đặt" (T20 mục 5) có cơ chế trong DDL hoặc trigger | Đủ, xem mục 4; BR-B08, BR-B10 phần quyền chờ T45 |
| 6 | Trigger T37 không đặt thêm quy tắc ngoài T08 | 4 điểm diễn giải, đã xác nhận và ghi vào T08 (L02–L05) |

### Mảng A, C (Lê Ngọc Khôi, 28/10/2026)

| # | Kiểm tra | A | C |
|---|---|---|---|
| 1 | Mọi thành phần ERD có trong lược đồ | 10/10 (6 thực thể, 2 phân lớp, THUỘC, XẾP_CA) | 15/15 (6 thực thể, 9 liên kết, gồm `GHI_KHÁM`, `GHI_ĐƠN` thêm theo C5) |
| 2 | Lược đồ (T19, T21) khớp DDL (T32, T34): tên bảng, cột, PK, FK, UNIQUE, NOT NULL | Khớp (sau khi sửa L09) | Khớp (sau khi sửa L08) |
| 3 | FD, khóa ứng viên (T23, T25) khớp PK/UNIQUE trong DDL | Khớp | Khớp (sau khi sửa L08) |
| 4 | Chuẩn hóa (T26, T28) có làm đổi thiết kế không | Không tách bảng, **ERD A không phải sửa** | Không tách bảng, **ERD C không phải sửa**; `ham_luong` ở THUOC và CHỨA mang hai nghĩa, giữ cả hai, báo cáo mục 3 đã ghi rõ nghĩa |
| 5 | Mọi quy tắc có cơ chế trong DDL hoặc trigger | Đủ, xem mục 4; BR-A09 chờ T45 | Đủ, xem mục 4; BR-C06 mới có phần C trong `rbac.sql` |
| 6 | Trigger (T36, T38) không đặt thêm quy tắc ngoài T07, T09 | 3 điểm diễn giải, 1 nhánh lỗi thừa (L10, đã sửa) | 4 điểm diễn giải (L12, đã ghi vào T09) |
| 7 | Chạy thử tích hợp trên PG16.10 với `A_schema.sql` chính thức (không dùng A stub) | 13 ca vi phạm BR-A01…A10 đều bị chặn, ca nối tiếp hợp lệ đi qua; `queries_A.sql` chạy có kết quả | Dữ liệu thử A + B (3 bác sĩ, 4 ca, 4 lịch, 1 giấy chuyển, 6 tài khoản) qua trigger; `C_seed.sql` chạy được; `tests_C.sql` **13/13**; `queries_C.sql` có kết quả; dưới role `r_bac_si` lỗi quyền (L11) |

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
| L08 | T25 / `C_schema.sql` | T25 mục 4 ghi "tên thuốc/hoạt chất không được giả định duy nhất; chỉ mã là khóa", nhưng DDL khai báo `hoat_chat.ten_hoat_chat` UNIQUE NOT NULL, tức `{ten_hoat_chat}` là khóa ứng viên. Báo cáo mục 3 ghi theo DDL | Giữ UNIQUE vì `C_seed.sql` dùng `ON CONFLICT (ten_hoat_chat)`. Khôi sửa 28/10: T21 ghi `ten_hoat_chat UNIQUE NOT NULL` kèm lý do; T25 thêm FD `ten_hoat_chat → ma_hoat_chat`, khóa ứng viên `{ten_hoat_chat}`, lập luận khóa, sửa mục 4; T28 cập nhật dòng HOAT_CHAT (vẫn BCNF). DDL, báo cáo mục 3 không đổi | Đã sửa |
| L09 | T19 / `A_schema.sql` / báo cáo 2.2.5 | Mọi FK mảng A dùng `ON UPDATE CASCADE`, lớp con dùng `ON DELETE CASCADE` về `bac_si`; B, C không dùng CASCADE. T19 chưa ghi hành động tham chiếu nên 2.2.5 phần A còn trống | Khôi sửa 28/10: bỏ `ON UPDATE CASCADE` ở 5 FK của `A_schema.sql` (khóa identity không đổi); giữ `ON DELETE CASCADE` ở lớp con (8A); T19 thêm bảng hành động tham chiếu; báo cáo 2.2.5 thêm đoạn và 5 dòng mảng A. Chạy lại: xóa bác sĩ còn ca, chuyên khoa còn bác sĩ bị chặn; xóa bác sĩ chưa có ca thì lớp con xóa theo; trigger A, `tests_C.sql` 15/15 không đổi | Đã sửa |
| L10 | T36 / T07 | Trigger diễn giải rộng hơn T07: (1) BR-A03 đòi ca nằm sau cả ngày cấp giấy phép; (2) chặn sửa `ngay_het_han_cc` làm ca đã xếp hết hợp lệ; (3) BR-A08 chặn xóa ca có lịch hẹn hiệu lực (ca chỉ được chuyển `HUY`). Nhánh báo lỗi BR-A02 không bao giờ chạy tới: bác sĩ chuyên khoa thiếu hàng lớp con đã bị báo BR-A01 | Khôi sửa 28/10: ghi (1)–(3) vào T07 mục 5, cập nhật dòng Ngày; `fn_kiem_tra_phan_lop_a` xét BR-A02 trước, bỏ nhánh trùng khỏi điều kiện BR-A01. Chạy lại: thiếu hàng chuyên khoa báo BR-A02; đa khoa có hàng chuyên khoa, chuyên khoa có hàng đa khoa, đa khoa thiếu lớp con báo BR-A01; các ca A khác và `tests_C.sql` 15/15 không đổi | Đã sửa |
| L11 | T36, T37, T38 / T45 | Hàm trigger chạy với quyền người gọi. Dưới `r_bac_si`, thêm lần khám báo `permission denied for table lich_hen`; trigger A (quản trị nhân sự) và B (lễ tân) cũng đọc bảng mảng khác. Nếu cấp SELECT bảng gốc thì lộ `tai_khoan.mat_khau_hash` | 12 hàm trigger có truy vấn bảng (A 4, B 2, C 6) khai báo `SECURITY DEFINER SET search_path = public, pg_temp` (hàm trigger không gọi trực tiếp được nên không mở thêm đường đọc dữ liệu). `tests_C.sql` thêm TC07A, TC07B chạy dưới `r_bac_si`, `r_quan_tri_danh_muc`: trước khi sửa báo lỗi quyền, sau khi sửa 15/15. Thử thêm dưới role: quản trị nhân sự hủy ca (BR-A08), lễ tân đặt lịch (BR-B01), bác sĩ ghi trọn lần khám – chẩn đoán – đơn – thuốc đều đúng (Khôi, 28/10) | Đã sửa |
| L12 | T38 / T09 | Trigger C có 4 điều T09 chưa ghi: (1) đơn có ít nhất một dòng thuốc (tham gia toàn phần của KÊ); (2) không hủy chẩn đoán hiệu lực cuối khi lần khám còn đơn hiệu lực; (3) thuốc, hoạt chất, ICD-10 đã được hồ sơ dùng thì không sửa (T05); (4) BR-C02 áp dụng cả cho lần khám, tài khoản phải đang hoạt động | Khôi sửa 28/10: ghi 4 điểm vào T09 mục 5, cập nhật dòng Ngày; trigger không đổi | Đã sửa |
| L13 | T18 mục 1 | Quy ước tên ràng buộc `pk_`, `fk_`, `uq_`, `ck_` chỉ mảng A theo đủ; B, C phần lớn dùng tên mặc định | Khôi sửa 28/10: T18 ghi đúng cách cả 3 mảng đang làm: ràng buộc mức bảng đặt tên theo mẫu; ràng buộc một cột để tên mặc định PostgreSQL (test đối chiếu tên này, ví dụ `benh_nhan_sdt_key`); chỉ mục `idx_<bang>_<cot hoặc mục đích>`; cho viết tắt tên bảng dài. Đã đối chiếu 23 ràng buộc, 12 chỉ mục có tên và mọi tên ràng buộc trong `tests_B.sql`, `tests_C.sql`; không phải đổi tên | Đã sửa |
| L14 | `queries_A.sql` Q4 | Chú thích ghi thay `:tu_luc`, `:den_luc` nhưng câu lệnh viết cứng 2026-01-01 … 2027-01-01 | Khôi sửa 28/10: Q4 khai báo khoảng `[tu_luc, den_luc)` trong CTE `params` như `queries_C.sql`, giữ giá trị mẫu cũ; chạy cả file được. Đối chiếu trên dữ liệu thử có 2 bác sĩ chuyên khoa: kết quả trùng bản cũ, ca ngoài khoảng bị loại | Đã sửa |

## 4. Quy tắc → cơ chế cài đặt

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
| BR-A01 | CHECK miền `loai_bac_si`; `trg_phan_lop_bac_si`, `trg_phan_lop_da_khoa`, `trg_phan_lop_chuyen_khoa` (constraint trigger trì hoãn) |
| BR-A02 | PK `bac_si_chuyen_khoa.ma_bac_si`, FK NOT NULL `ma_chuyen_khoa` |
| BR-A03 | `trg_ca_lam_viec_hop_le`, `trg_giay_phep_khong_vo_hieu_ca` |
| BR-A04 | `ex_ca_lam_viec_bac_si` (EXCLUDE gist, ca `DA_XEP`) |
| BR-A05 | `bac_si.so_chung_chi` UNIQUE |
| BR-A06, BR-A07 | `ck_ca_lam_viec_thoi_gian`, `ck_bac_si_han_giay_phep` |
| BR-A08 | `trg_ca_lam_viec_hop_le`, `trg_ca_lam_viec_khong_xoa` |
| BR-A09 | T45 (`rbac.sql`, chưa có GRANT bảng A) |
| BR-A10 | CHECK miền `loai_nv`, `trg_phan_lop_nhan_vien` |
| BR-C01 | `trg_c_chi_tiet_khong_ke_hoat_chat_di_ung` |
| BR-C02 | `trg_c_lan_kham_hoan_thanh_bac_si`, `trg_c_don_thuoc_hoan_thanh_bac_si` |
| BR-C03 | `trg_c_don_co_chan_doan`, `trg_c_chan_doan_chi_huy` |
| BR-C04 | `ck_chi_tiet_don_thuoc_so_luong`, CHECK `lieu_dung` không rỗng |
| BR-C05 | `trg_c_lan_kham_bat_bien`, `trg_c_chan_doan_chi_huy`, `trg_c_don_thuoc_chi_huy`, `trg_c_chi_tiet_bat_bien`, các trigger `*_khong_truncate` |
| BR-C06 | `rbac.sql` (phần C); view `v_ho_so_cua_toi`, `v_di_ung_cua_toi` |
| Bổ sung C (L12) | `ct_c_don_phai_co_chi_tiet`; `trg_c_thuoc_bao_toan_lich_su`, `trg_c_hoat_chat_bao_toan_lich_su`, `trg_c_icd_bao_toan_lich_su`, `trg_c_thanh_phan_bao_toan_lich_su` |

## 5. Chờ nhóm chốt

| Mã | Nội dung | Ảnh hưởng | Người chốt |
|---|---|---|---|
| C1 | `TAI_KHOAN.vai_tro` trùng `NHAN_VIEN.loai_nv` (dư thừa giữa hai bảng, T27 mục 5); BR-B10 cho quản trị tài khoản "đổi vai trò" mâu thuẫn BR-A09 (quản trị nhân sự sửa loại nhân viên). Hai hướng: (a) giữ `vai_tro`, vai trò nhân viên luôn theo `loai_nv`, bỏ "đổi vai trò" khỏi BR-B10, thêm trigger chặn sửa `loai_nv` khi lệch tài khoản; (b) bỏ `vai_tro`, suy từ `loai_nv` hoặc `ma_bn` | T08, T20, T24, T27, ERD B, `B_schema.sql`, `B_trigger_view.sql` | **Đã chốt (a)** 28/10: giữ `vai_tro`; BR-B10 bỏ "đổi vai trò" (T08, T03, báo cáo 1.2.2, 5.2); thêm `trg_nhan_vien_giu_vai_tro` chặn đổi loại của nhân viên đã có tài khoản (`B_trigger_view.sql`, `tests_B.sql` TB38B); cập nhật T24, T27, T21, báo cáo 2.3.4, 4.1.4, 4.1.6 |
| C2 | Phương án ánh xạ `BAC_SI` ở T19; T20, T33 đang giả định 8A (có bảng `BAC_SI_DA_KHOA`) | Chọn 8A trong T19; FK `ma_bac_si_lap`, BR-B07 khớp giả định | **Đã chốt** |
| C3 | Quy ước T18: khóa `INTEGER` tự tăng, giờ `TIMESTAMP`, giá trị `loai_nv` trùng `vai_tro`, ca hủy là `'HUY'` | Đã ghi trong [T18](T18_QuyUocDuLieu.md), khớp B_schema và B_trigger_view | **Đã chốt** |
| C4 | Cách trình bày FD có điều kiện (cột UNIQUE cho phép NULL) chung cho 3 mảng | Đã ghi trong [T22](T22_Khuon_ChuanHoa.md) mục 2; T24, T27 dùng đúng | **Đã chốt** |
| C5 | `LAN_KHAM.created_by`, `DON_THUOC.created_by` là FK tới `TAI_KHOAN` nhưng ERD C vẽ là thuộc tính. Hai hướng: (a) vẽ liên kết GHI giữa TAI_KHOAN và LAN_KHAM, DON_THUOC (sửa ERD C, ERD tổng, 2.1, T15); (b) giữ thuộc tính, ghi chú trên ERD C như ERD A ghi các liên kết vẽ ở ERD B | ERD C, ERD tổng, báo cáo 2.1, 2.2, T15 | **Đã chốt (a)** 28/10: ERD C, ERD tổng vẽ TAI_KHOAN và hai liên kết 1:N `GHI_KHÁM`, `GHI_ĐƠN` (TAI_KHOAN partial, LAN_KHAM/DON_THUOC total), bỏ thuộc tính `created_by`; báo cáo 2.1 (bảng thực thể, liên kết, truy vết, Hình 2.1, 2.1c, 19 liên kết), T15, T21. Lược đồ, DDL không đổi |

## 6. Kết luận T30

Hoàn thành ngày 28/10/2026. Review chéo đủ ba mảng: B do Đăng Khoa (mục 7), A, C và mục 3 do Khôi (mục 2). Lỗi L01–L14 đã sửa hết; C1–C5 đã chốt. Thay đổi thiết kế duy nhất là ERD C, ERD tổng vẽ thêm `GHI_KHÁM`, `GHI_ĐƠN` (C5); lược đồ, DDL không đổi theo chuẩn hóa.

## 7. Ghi nhận review chéo B (Nguyễn Đăng Khoa, 28/10/2026)

| Phạm vi | Nhận xét |
|---|---|
| T20 ↔ `B_schema.sql` | Các bảng, khóa và FK chính khớp. Khóa ngoại kép `(ma_giay, ma_bn)` bảo đảm giấy chuyển thuộc đúng bệnh nhân; `LICH_HEN.ma_giay` UNIQUE cho quan hệ 1:1 tùy chọn. |
| T24/T27 ↔ DDL | FD và khóa ứng viên phù hợp các PK/UNIQUE/NOT NULL đang khai báo. T24/T27 đã tách FD có điều kiện do UNIQUE cho phép NULL khỏi khóa ứng viên toàn cục; T22 dùng cùng quy ước. |
| T08 ↔ `B_trigger_view.sql` | Các kiểm tra ca làm, giấy chuyển, trạng thái lịch, vai trò tài khoản và bảo toàn tài khoản có trigger/ràng buộc tương ứng. |
| Còn mở | C1 vẫn cần cả nhóm chốt chiều đồng bộ `TAI_KHOAN.vai_tro` ↔ `NHAN_VIEN.loai_nv`; trigger hiện tại chỉ kiểm tra khi ghi tài khoản, không tự xử lý khi đổi loại nhân viên. Không đóng C1 trong review này. C2/C3 vẫn phụ thuộc T18/T32 của mảng A. |
| Kiểm thử | Chạy `tests_B.sql` ngày 28/10/2026 trên PostgreSQL 16.15 với A stub tạm theo đúng giao diện B đang tham chiếu: 49/49 đạt. TB41 ban đầu không tới trigger vì FK chặn `TRUNCATE`; sửa thành `TRUNCATE ... CASCADE`, chạy lại trigger BR-B10 được gọi và test đạt. A stub chỉ kiểm tra tích hợp B, không thay cho A_schema chính thức. |

## 8. Tự rà soát phần C trước review

T21/T25/T28 và các script C được đối chiếu với T05/T09/ERD C. Các điểm cần reviewer/nhóm xác nhận: (1) `ham_luong` ở THUOC và liên kết CHỨA mang hai nghĩa riêng; (2) T21/DDL dùng `created_by → TAI_KHOAN`, nhưng ERD C hiện chỉ vẽ thuộc tính `created_by`, chưa vẽ TAI_KHOAN/liên kết tạo bản ghi; cần bổ sung quan hệ vào ERD C hoặc chốt không dùng FK; (3) patient-facing view dùng `app.ma_bn` do backend đã xác thực đặt, không an toàn nếu cấp SQL trực tiếp cho bệnh nhân; (4) A_schema/seed chính thức cần ghép trước khi kiểm thử tích hợp đầy đủ. Trên PostgreSQL 16.15 với A stub và dữ liệu giả lập: `tests_C.sql` đạt 13/13; bốn truy vấn C chạy được và trả kết quả với fixture gồm hai bác sĩ/lịch hẹn lịch sử. T44 đã chạy `EXPLAIN ANALYZE` trên fixture nhỏ; số đo không đại diện hiệu năng khi có dữ liệu thực nghiệm. Kết quả review (28/10): (1) giữ cả hai, đã phân biệt nghĩa ở báo cáo mục 3; (2) chốt ở C5, đã vẽ liên kết; (3) giữ thiết kế, đã ghi trong nháp 4.1.6 (T46); (4) đã chạy với `A_schema.sql` chính thức, xem mục 2.
