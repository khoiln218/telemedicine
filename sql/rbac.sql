-- T45 – Khung phân quyền theo vai trò, PostgreSQL 16.
-- Chạy sau schema.sql và các file trigger/view. Sáu vai trò, quyền theo BR-A09, BR-B08, BR-B10, BR-C06
-- và báo cáo mục 5.2. Bảng không cấp cho ai thì chỉ chủ sở hữu dùng được (PostgreSQL không cấp quyền bảng cho PUBLIC).
-- Các role dưới đây là NOLOGIN. Ứng dụng/DBA cấp role phù hợp cho principal đã xác thực.

DO $$ BEGIN CREATE ROLE r_quan_tri_nhan_su NOLOGIN; EXCEPTION WHEN duplicate_object THEN NULL; END $$;
DO $$ BEGIN CREATE ROLE r_quan_tri_tai_khoan NOLOGIN; EXCEPTION WHEN duplicate_object THEN NULL; END $$;
DO $$ BEGIN CREATE ROLE r_quan_tri_danh_muc NOLOGIN; EXCEPTION WHEN duplicate_object THEN NULL; END $$;
DO $$ BEGIN CREATE ROLE r_bac_si NOLOGIN; EXCEPTION WHEN duplicate_object THEN NULL; END $$;
DO $$ BEGIN CREATE ROLE r_le_tan NOLOGIN; EXCEPTION WHEN duplicate_object THEN NULL; END $$;
DO $$ BEGIN CREATE ROLE r_benh_nhan NOLOGIN; EXCEPTION WHEN duplicate_object THEN NULL; END $$;

GRANT USAGE ON SCHEMA public TO
    r_quan_tri_nhan_su, r_quan_tri_tai_khoan, r_quan_tri_danh_muc,
    r_bac_si, r_le_tan, r_benh_nhan;

-- Mặc định không ai ngoài owner/superuser được truy cập trực tiếp dữ liệu lâm sàng.
REVOKE ALL ON TABLE lan_kham, chan_doan, ma_icd10, don_thuoc, thuoc, hoat_chat,
    chi_tiet_don_thuoc, thuoc_hoat_chat, di_ung, v_ho_so_tom_tat, v_ho_so_cua_toi,
    v_di_ung_tom_tat, v_di_ung_cua_toi FROM PUBLIC;
REVOKE ALL ON TABLE lan_kham, chan_doan, ma_icd10, don_thuoc, thuoc, hoat_chat,
    chi_tiet_don_thuoc, thuoc_hoat_chat, di_ung, v_ho_so_tom_tat, v_ho_so_cua_toi,
    v_di_ung_tom_tat, v_di_ung_cua_toi FROM
    r_quan_tri_nhan_su, r_quan_tri_tai_khoan, r_quan_tri_danh_muc,
    r_bac_si, r_le_tan, r_benh_nhan;

-- Bác sĩ đọc hồ sơ lâm sàng; ghi hồ sơ và đơn, chỉ được đổi trạng thái khi hủy.
GRANT SELECT ON lan_kham, chan_doan, ma_icd10, don_thuoc, thuoc, hoat_chat,
    chi_tiet_don_thuoc, thuoc_hoat_chat, di_ung, v_ho_so_tom_tat, v_di_ung_tom_tat TO r_bac_si;
GRANT INSERT ON lan_kham, chan_doan, don_thuoc, chi_tiet_don_thuoc, di_ung TO r_bac_si;
GRANT DELETE ON di_ung TO r_bac_si;
GRANT UPDATE (trang_thai) ON chan_doan, don_thuoc TO r_bac_si;

-- Quản trị danh mục chỉ quản lý danh mục thuốc/hoạt chất/ICD và cấu thành thuốc.
GRANT SELECT, INSERT, UPDATE ON ma_icd10, thuoc, hoat_chat, thuoc_hoat_chat TO r_quan_tri_danh_muc;

-- Bệnh nhân chỉ truy cập view lọc theo app.ma_bn; backend đáng tin cậy phải xác thực người dùng
-- rồi đặt context trong transaction. Không cấp quyền SELECT bảng gốc hoặc view toàn bộ cho bệnh nhân.
GRANT SELECT ON v_ho_so_cua_toi, v_di_ung_cua_toi TO r_benh_nhan;

-- Sinh mã cho bản ghi mới; danh sách chỉ gồm sequence C, không mở sequence A/B.
GRANT USAGE, SELECT ON SEQUENCE
    lan_kham_ma_lan_kham_seq, chan_doan_ma_chan_doan_seq, don_thuoc_ma_don_seq,
    thuoc_ma_thuoc_seq, hoat_chat_ma_hoat_chat_seq
TO r_bac_si, r_quan_tri_danh_muc;

-- ---------- Mảng A (BR-A09) ----------
-- Chỉ quản trị nhân sự thêm, sửa nhân viên, bác sĩ, chuyên khoa, ca; không cấp DELETE (ca hủy giữ lại, T07).
GRANT SELECT, INSERT, UPDATE ON nhan_vien, bac_si, bac_si_da_khoa, bac_si_chuyen_khoa, chuyen_khoa, ca_lam_viec
TO r_quan_tri_nhan_su;
GRANT USAGE, SELECT ON SEQUENCE nhan_vien_ma_nv_seq, chuyen_khoa_ma_chuyen_khoa_seq, ca_lam_viec_ma_ca_seq
TO r_quan_tri_nhan_su;
-- Bác sĩ, lễ tân chỉ xem bác sĩ, chuyên khoa, ca để đặt hẹn, khám.
GRANT SELECT ON nhan_vien, bac_si, bac_si_da_khoa, bac_si_chuyen_khoa, chuyen_khoa, ca_lam_viec, v_lich_truc_bac_si
TO r_bac_si, r_le_tan;
-- Quản trị tài khoản xem nhân viên để tạo tài khoản đúng người (BR-B09).
GRANT SELECT ON nhan_vien TO r_quan_tri_tai_khoan;

-- ---------- Mảng B (BR-B08, BR-B10) ----------
-- Lễ tân thêm, sửa bệnh nhân và lịch hẹn; không xóa. Bác sĩ chỉ xem, và lập giấy chuyển.
GRANT SELECT, INSERT, UPDATE ON benh_nhan, lich_hen TO r_le_tan;
GRANT SELECT ON giay_chuyen_khoa, v_lich_hen_hom_nay TO r_le_tan;
GRANT USAGE, SELECT ON SEQUENCE benh_nhan_ma_bn_seq, lich_hen_ma_lh_seq TO r_le_tan;
GRANT SELECT ON benh_nhan, lich_hen, v_lich_hen_hom_nay TO r_bac_si;
GRANT SELECT, INSERT ON giay_chuyen_khoa TO r_bac_si;
GRANT USAGE, SELECT ON SEQUENCE giay_chuyen_khoa_ma_giay_seq TO r_bac_si;
-- Quản trị tài khoản tạo tài khoản nhân viên, khóa/mở khóa (chỉ sửa trang_thai); không đọc mật khẩu băm,
-- không đổi vai trò (vai trò theo loại nhân viên, T30 C1), không xóa (trigger BR-B10 chặn cả chủ sở hữu).
GRANT SELECT (ten_dang_nhap, vai_tro, trang_thai, ma_bn, ma_nv), INSERT ON tai_khoan TO r_quan_tri_tai_khoan;
GRANT UPDATE (trang_thai) ON tai_khoan TO r_quan_tri_tai_khoan;
-- Lễ tân không có quyền trên tai_khoan, chỉ gọi hàm tạo tài khoản, đặt lại mật khẩu cho bệnh nhân.
GRANT EXECUTE ON FUNCTION tao_tai_khoan_benh_nhan(VARCHAR, VARCHAR, INTEGER),
    dat_lai_mat_khau_benh_nhan(VARCHAR, VARCHAR) TO r_le_tan;
-- Mọi người dùng đổi mật khẩu của chính mình qua hàm (theo app.ma_bn / app.ma_nv).
GRANT EXECUTE ON FUNCTION doi_mat_khau(VARCHAR) TO
    r_quan_tri_nhan_su, r_quan_tri_tai_khoan, r_quan_tri_danh_muc, r_bac_si, r_le_tan, r_benh_nhan;
-- Bệnh nhân chỉ xem lịch hẹn của mình qua view lọc theo app.ma_bn.
GRANT SELECT ON v_lich_hen_cua_toi TO r_benh_nhan;
