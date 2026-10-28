-- T38 – Trigger + view mảng C (PostgreSQL 16).
-- Chạy sau A_schema.sql, B_schema.sql, C_schema.sql.
-- Giả định từ B hiện tại: lich_hen(ma_lh, ma_bn, ma_bac_si, trang_thai),
-- tai_khoan(ten_dang_nhap, vai_tro, ma_bn, ma_nv); tài khoản bác sĩ có ma_nv = lich_hen.ma_bac_si.
-- Cảnh báo C1/T30: vai_tro và nhan_vien.loai_nv còn chờ nhóm chốt; chức năng dưới đây không
-- tự sửa cấu trúc B, chỉ xác minh chủ tài khoản khớp bác sĩ được phân công.

-- BR-C02: lần khám và đơn thuốc chỉ thuộc lịch hoàn thành; người tạo phải là bác sĩ của lịch.
CREATE OR REPLACE FUNCTION fn_c_kiem_tra_lan_kham_don() RETURNS trigger AS $$
DECLARE
    v_trang_thai lich_hen.trang_thai%TYPE;
    v_ma_bac_si lich_hen.ma_bac_si%TYPE;
BEGIN
    IF TG_TABLE_NAME = 'lan_kham' THEN
        SELECT trang_thai, ma_bac_si INTO v_trang_thai, v_ma_bac_si
          FROM lich_hen WHERE ma_lh = NEW.ma_lh;
    ELSE
        SELECT l.trang_thai, l.ma_bac_si INTO v_trang_thai, v_ma_bac_si
          FROM lan_kham k JOIN lich_hen l ON l.ma_lh = k.ma_lh
         WHERE k.ma_lan_kham = NEW.ma_lan_kham;
    END IF;

    IF v_trang_thai IS DISTINCT FROM 'HOAN_THANH' THEN
        RAISE EXCEPTION 'BR-C02: chỉ ghi lần khám/đơn thuốc cho lịch hẹn đã hoàn thành'
            USING ERRCODE = 'check_violation';
    END IF;
    IF NOT EXISTS (
        SELECT 1 FROM tai_khoan tk
         WHERE tk.ten_dang_nhap = NEW.created_by
           AND tk.ma_nv = v_ma_bac_si
           AND tk.vai_tro = 'BAC_SI'
           AND tk.trang_thai = 'HOAT_DONG'
    ) THEN
        RAISE EXCEPTION 'BR-C02: người tạo phải là bác sĩ được phân công cho lịch hẹn'
            USING ERRCODE = 'check_violation';
    END IF;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trg_c_lan_kham_hoan_thanh_bac_si
    BEFORE INSERT OR UPDATE OF ma_lh, created_by ON lan_kham
    FOR EACH ROW EXECUTE FUNCTION fn_c_kiem_tra_lan_kham_don();
CREATE TRIGGER trg_c_don_thuoc_hoan_thanh_bac_si
    BEFORE INSERT OR UPDATE OF ma_lan_kham, created_by ON don_thuoc
    FOR EACH ROW EXECUTE FUNCTION fn_c_kiem_tra_lan_kham_don();

-- BR-C03: chỉ kê đơn khi lần khám đã có ít nhất một chẩn đoán đang hiệu lực.
CREATE OR REPLACE FUNCTION fn_c_don_co_chan_doan() RETURNS trigger AS $$
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM chan_doan
         WHERE ma_lan_kham = NEW.ma_lan_kham AND trang_thai = 'HIEU_LUC'
    ) THEN
        RAISE EXCEPTION 'BR-C03: cần ít nhất một chẩn đoán hiệu lực trước khi lập đơn'
            USING ERRCODE = 'check_violation';
    END IF;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;
CREATE TRIGGER trg_c_don_co_chan_doan
    BEFORE INSERT OR UPDATE OF ma_lan_kham ON don_thuoc
    FOR EACH ROW EXECUTE FUNCTION fn_c_don_co_chan_doan();

-- BR-C01: so hoạt chất của thuốc trong chi tiết với dị ứng của bệnh nhân từ lịch hẹn.
CREATE OR REPLACE FUNCTION fn_c_kiem_tra_di_ung() RETURNS trigger AS $$
DECLARE
    v_ma_bn INTEGER;
BEGIN
    SELECT l.ma_bn INTO v_ma_bn
      FROM don_thuoc d JOIN lan_kham k ON k.ma_lan_kham = d.ma_lan_kham
      JOIN lich_hen l ON l.ma_lh = k.ma_lh
     WHERE d.ma_don = NEW.ma_don;
    IF EXISTS (
        SELECT 1 FROM thuoc_hoat_chat th
        JOIN di_ung du ON du.ma_hoat_chat = th.ma_hoat_chat
         WHERE th.ma_thuoc = NEW.ma_thuoc AND du.ma_bn = v_ma_bn
    ) THEN
        RAISE EXCEPTION 'BR-C01: thuốc có hoạt chất bệnh nhân đã ghi nhận dị ứng'
            USING ERRCODE = 'check_violation';
    END IF;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;
CREATE TRIGGER trg_c_chi_tiet_khong_ke_hoat_chat_di_ung
    BEFORE INSERT OR UPDATE OF ma_don, ma_thuoc ON chi_tiet_don_thuoc
    FOR EACH ROW EXECUTE FUNCTION fn_c_kiem_tra_di_ung();

-- BR-C05: lịch khám không sửa/xóa; chẩn đoán và đơn chỉ được chuyển HIEU_LUC → DA_HUY.
CREATE OR REPLACE FUNCTION fn_c_bao_ve_lich_kham() RETURNS trigger AS $$
BEGIN
    RAISE EXCEPTION 'BR-C05: lần khám đã ghi không được sửa hoặc xóa'
        USING ERRCODE = 'check_violation';
END;
$$ LANGUAGE plpgsql;
CREATE TRIGGER trg_c_lan_kham_bat_bien
    BEFORE UPDATE OR DELETE ON lan_kham
    FOR EACH ROW EXECUTE FUNCTION fn_c_bao_ve_lich_kham();
CREATE TRIGGER trg_c_lan_kham_khong_truncate
    BEFORE TRUNCATE ON lan_kham FOR EACH STATEMENT
    EXECUTE FUNCTION fn_c_bao_ve_lich_kham();

CREATE OR REPLACE FUNCTION fn_c_chi_huy_ban_ghi() RETURNS trigger AS $$
BEGIN
    IF TG_OP = 'DELETE' THEN
        RAISE EXCEPTION 'BR-C05: không xóa hồ sơ; hãy chuyển trạng thái sang DA_HUY'
            USING ERRCODE = 'check_violation';
    END IF;
    IF OLD.trang_thai <> 'HIEU_LUC' OR NEW.trang_thai <> 'DA_HUY'
       OR (to_jsonb(NEW) - 'trang_thai') <> (to_jsonb(OLD) - 'trang_thai') THEN
        RAISE EXCEPTION 'BR-C05: chỉ được hủy bản ghi hiệu lực; không sửa nội dung'
            USING ERRCODE = 'check_violation';
    END IF;
    IF TG_TABLE_NAME = 'chan_doan' THEN
        IF EXISTS (
            SELECT 1 FROM don_thuoc d
             WHERE d.ma_lan_kham = OLD.ma_lan_kham AND d.trang_thai = 'HIEU_LUC'
        ) AND NOT EXISTS (
            SELECT 1 FROM chan_doan cd
             WHERE cd.ma_lan_kham = OLD.ma_lan_kham
               AND cd.ma_chan_doan <> OLD.ma_chan_doan AND cd.trang_thai = 'HIEU_LUC'
        ) THEN
            RAISE EXCEPTION 'BR-C03: không thể hủy chẩn đoán hiệu lực cuối cùng khi còn đơn hiệu lực'
                USING ERRCODE = 'check_violation';
        END IF;
    END IF;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;
CREATE TRIGGER trg_c_chan_doan_chi_huy
    BEFORE UPDATE OR DELETE ON chan_doan
    FOR EACH ROW EXECUTE FUNCTION fn_c_chi_huy_ban_ghi();
CREATE TRIGGER trg_c_don_thuoc_chi_huy
    BEFORE UPDATE OR DELETE ON don_thuoc
    FOR EACH ROW EXECUTE FUNCTION fn_c_chi_huy_ban_ghi();

CREATE OR REPLACE FUNCTION fn_c_chi_tiet_bat_bien() RETURNS trigger AS $$
BEGIN
    RAISE EXCEPTION 'BR-C05: chi tiết đơn thuốc đã ghi không được sửa hoặc xóa; hủy cả đơn'
        USING ERRCODE = 'check_violation';
END;
$$ LANGUAGE plpgsql;
CREATE TRIGGER trg_c_chi_tiet_bat_bien
    BEFORE UPDATE OR DELETE ON chi_tiet_don_thuoc
    FOR EACH ROW EXECUTE FUNCTION fn_c_chi_tiet_bat_bien();
CREATE TRIGGER trg_c_chi_tiet_khong_truncate
    BEFORE TRUNCATE ON chi_tiet_don_thuoc FOR EACH STATEMENT
    EXECUTE FUNCTION fn_c_chi_tiet_bat_bien();

-- T05 yêu cầu giữ nguyên ý nghĩa dữ liệu đã ghi trong đơn/chẩn đoán.
-- Cho phép quản trị danh mục sửa mục chưa được dùng; đóng băng mục đã được hồ sơ tham chiếu.
CREATE OR REPLACE FUNCTION fn_c_bao_toan_danh_muc() RETURNS trigger AS $$
BEGIN
    IF TG_TABLE_NAME = 'thuoc' AND EXISTS (
        SELECT 1 FROM chi_tiet_don_thuoc WHERE ma_thuoc = OLD.ma_thuoc
    ) THEN
        RAISE EXCEPTION 'T05: không sửa thuốc đã xuất hiện trong đơn; hãy tạo mục danh mục mới'
            USING ERRCODE = 'check_violation';
    ELSIF TG_TABLE_NAME = 'hoat_chat' AND (
        EXISTS (
            SELECT 1 FROM thuoc_hoat_chat th
            JOIN chi_tiet_don_thuoc ct ON ct.ma_thuoc = th.ma_thuoc
             WHERE th.ma_hoat_chat = OLD.ma_hoat_chat
        )
        OR EXISTS (SELECT 1 FROM di_ung WHERE ma_hoat_chat = OLD.ma_hoat_chat)
    ) THEN
        RAISE EXCEPTION 'T05: không sửa hoạt chất đã được hồ sơ tham chiếu; hãy tạo mục danh mục mới'
            USING ERRCODE = 'check_violation';
    ELSIF TG_TABLE_NAME = 'ma_icd10' AND EXISTS (
        SELECT 1 FROM chan_doan WHERE ma_icd10 = OLD.ma_icd10
    ) THEN
        RAISE EXCEPTION 'T05: không sửa mã ICD-10 đã được chẩn đoán tham chiếu'
            USING ERRCODE = 'check_violation';
    ELSIF TG_TABLE_NAME = 'thuoc_hoat_chat' AND EXISTS (
        SELECT 1 FROM chi_tiet_don_thuoc WHERE ma_thuoc = OLD.ma_thuoc
    ) THEN
        RAISE EXCEPTION 'T05: không sửa thành phần thuốc đã xuất hiện trong đơn'
            USING ERRCODE = 'check_violation';
    END IF;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;
CREATE TRIGGER trg_c_thuoc_bao_toan_lich_su BEFORE UPDATE ON thuoc
    FOR EACH ROW EXECUTE FUNCTION fn_c_bao_toan_danh_muc();
CREATE TRIGGER trg_c_hoat_chat_bao_toan_lich_su BEFORE UPDATE ON hoat_chat
    FOR EACH ROW EXECUTE FUNCTION fn_c_bao_toan_danh_muc();
CREATE TRIGGER trg_c_icd_bao_toan_lich_su BEFORE UPDATE ON ma_icd10
    FOR EACH ROW EXECUTE FUNCTION fn_c_bao_toan_danh_muc();
CREATE TRIGGER trg_c_thanh_phan_bao_toan_lich_su BEFORE UPDATE ON thuoc_hoat_chat
    FOR EACH ROW EXECUTE FUNCTION fn_c_bao_toan_danh_muc();

CREATE OR REPLACE FUNCTION fn_c_cam_truncate() RETURNS trigger AS $$
BEGIN
    RAISE EXCEPTION 'BR-C05: không được TRUNCATE dữ liệu hồ sơ lâm sàng'
        USING ERRCODE = 'check_violation';
END;
$$ LANGUAGE plpgsql;
CREATE TRIGGER trg_c_chan_doan_khong_truncate
    BEFORE TRUNCATE ON chan_doan FOR EACH STATEMENT EXECUTE FUNCTION fn_c_cam_truncate();
CREATE TRIGGER trg_c_don_thuoc_khong_truncate
    BEFORE TRUNCATE ON don_thuoc FOR EACH STATEMENT EXECUTE FUNCTION fn_c_cam_truncate();

-- ERD quy định đơn có ít nhất một thuốc. Constraint trigger trì hoãn để cho phép
-- INSERT đơn + các dòng thuốc trong cùng giao dịch.
CREATE OR REPLACE FUNCTION fn_c_don_co_chi_tiet() RETURNS trigger AS $$
BEGIN
    IF NOT EXISTS (SELECT 1 FROM chi_tiet_don_thuoc WHERE ma_don = NEW.ma_don) THEN
        RAISE EXCEPTION 'BR-C bổ sung: mỗi đơn thuốc phải có ít nhất một dòng thuốc'
            USING ERRCODE = 'check_violation';
    END IF;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;
CREATE CONSTRAINT TRIGGER ct_c_don_phai_co_chi_tiet
    AFTER INSERT ON don_thuoc DEFERRABLE INITIALLY DEFERRED
    FOR EACH ROW EXECUTE FUNCTION fn_c_don_co_chi_tiet();

-- View lâm sàng cho bác sĩ: người bệnh và bác sĩ lấy từ lịch hẹn, không lưu lặp.
CREATE OR REPLACE VIEW v_ho_so_tom_tat AS
SELECT l.ma_bn, l.ma_bac_si, k.ma_lh, k.ma_lan_kham, k.thoi_diem_kham, k.tom_tat,
       cd.ma_chan_doan, cd.ma_icd10, i.mo_ta AS mo_ta_chan_doan,
       d.ma_don, d.thoi_diem_ke, d.trang_thai AS trang_thai_don,
       cdt.ma_thuoc, t.ten_thuoc, cdt.so_luong, cdt.lieu_dung
  FROM lan_kham k JOIN lich_hen l ON l.ma_lh = k.ma_lh
  LEFT JOIN chan_doan cd ON cd.ma_lan_kham = k.ma_lan_kham AND cd.trang_thai = 'HIEU_LUC'
  LEFT JOIN ma_icd10 i ON i.ma_icd10 = cd.ma_icd10
  LEFT JOIN don_thuoc d ON d.ma_lan_kham = k.ma_lan_kham AND d.trang_thai = 'HIEU_LUC'
  LEFT JOIN chi_tiet_don_thuoc cdt ON cdt.ma_don = d.ma_don
  LEFT JOIN thuoc t ON t.ma_thuoc = cdt.ma_thuoc;

-- Patient-facing view. Trust boundary: only a trusted application backend may set app.ma_bn
-- after authenticating the caller; a shared SQL login must never expose arbitrary SET to clients.
CREATE OR REPLACE VIEW v_ho_so_cua_toi AS
SELECT * FROM v_ho_so_tom_tat
 WHERE ma_bn = NULLIF(current_setting('app.ma_bn', TRUE), '')::INTEGER;

-- Dị ứng là một phần của hồ sơ; tách view để bệnh nhân không mất thông tin khi chưa có lần khám.
CREATE OR REPLACE VIEW v_di_ung_tom_tat AS
SELECT du.ma_bn, du.ma_hoat_chat, h.ten_hoat_chat, du.ngay_ghi_nhan, du.ghi_chu
  FROM di_ung du JOIN hoat_chat h ON h.ma_hoat_chat = du.ma_hoat_chat;
CREATE OR REPLACE VIEW v_di_ung_cua_toi AS
SELECT * FROM v_di_ung_tom_tat
 WHERE ma_bn = NULLIF(current_setting('app.ma_bn', TRUE), '')::INTEGER;
