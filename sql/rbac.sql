-- T45 – Khung phân quyền theo vai trò, PostgreSQL 16.
-- Chạy sau schema.sql và các file trigger/view. Đây là phần C và khung 6 vai trò;
-- nhóm cần gộp GRANT cho bảng A/B vào đúng file này khi T32/T33 hoàn tất.
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

-- Ma trận nhóm (hoàn thiện khi gộp T45 A/B):
-- r_quan_tri_nhan_su: CRUD NHAN_VIEN/BAC_SI/CHUYEN_KHOA/CA_LAM_VIEC (mảng A).
-- r_quan_tri_tai_khoan: quản lý TAI_KHOAN theo BR-B10, không có quyền hồ sơ lâm sàng.
-- r_le_tan: thao tác lịch hẹn theo BR-B08, không đọc bảng/view lâm sàng.
-- r_benh_nhan: thao tác lịch hẹn của mình (B) và đọc v_ho_so_cua_toi (C).
-- Vai trò nhân viên và tai_khoan.vai_tro còn phụ thuộc quyết định C1 tại T30.
