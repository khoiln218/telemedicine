-- T36 – Trigger và view mảng A. Chạy sau schema.sql (A + B).
-- Ca được kiểm tra với lịch hẹn ở trạng thái còn hiệu lực (khác HUY, VANG_MAT).
-- Hàm trigger có truy vấn bảng dùng SECURITY DEFINER: chạy với quyền chủ sở hữu, role ứng dụng
-- không cần SELECT trên bảng nó không được xem (T30 L11). Hàm trigger không gọi trực tiếp được.

-- Chuyên biệt hóa 8A: NHAN_VIEN -> BAC_SI (partial), BAC_SI -> đúng một lớp con (total, disjoint).
CREATE OR REPLACE FUNCTION fn_kiem_tra_phan_lop_a() RETURNS trigger AS $$
DECLARE
    v_ma_nv INTEGER;
    v_loai_nv VARCHAR(24);
    v_loai_bac_si VARCHAR(16);
    v_co_bac_si BOOLEAN;
    v_co_da_khoa BOOLEAN;
    v_co_chuyen_khoa BOOLEAN;
BEGIN
    IF TG_TABLE_NAME = 'nhan_vien' THEN
        v_ma_nv := COALESCE(NEW.ma_nv, OLD.ma_nv);
    ELSIF TG_TABLE_NAME = 'bac_si' THEN
        v_ma_nv := COALESCE(NEW.ma_bac_si, OLD.ma_bac_si);
    ELSE
        v_ma_nv := COALESCE(NEW.ma_bac_si, OLD.ma_bac_si);
    END IF;

    SELECT loai_nv INTO v_loai_nv FROM nhan_vien WHERE ma_nv = v_ma_nv;
    SELECT loai_bac_si INTO v_loai_bac_si FROM bac_si WHERE ma_bac_si = v_ma_nv;
    SELECT EXISTS (SELECT 1 FROM bac_si WHERE ma_bac_si = v_ma_nv) INTO v_co_bac_si;
    SELECT EXISTS (SELECT 1 FROM bac_si_da_khoa WHERE ma_bac_si = v_ma_nv) INTO v_co_da_khoa;
    SELECT EXISTS (SELECT 1 FROM bac_si_chuyen_khoa WHERE ma_bac_si = v_ma_nv) INTO v_co_chuyen_khoa;

    -- Khi nhân viên đã bị xóa, cascade có thể đang xóa các lớp con.
    IF v_loai_nv IS NULL AND NOT v_co_bac_si THEN RETURN NULL; END IF;
    IF (v_loai_nv = 'BAC_SI') <> v_co_bac_si THEN
        RAISE EXCEPTION 'BR-A10: nhân viên loại BAC_SI phải và chỉ phải có hàng BAC_SI (ma_nv=%)', v_ma_nv
            USING ERRCODE = 'check_violation';
    END IF;
    -- BR-A02 xét trước: bác sĩ chuyên khoa thiếu hàng lớp con là chưa có chuyên khoa.
    IF v_co_bac_si AND v_loai_bac_si = 'CHUYEN_KHOA' AND NOT v_co_chuyen_khoa THEN
        RAISE EXCEPTION 'BR-A02: bác sĩ chuyên khoa phải thuộc đúng một chuyên khoa (ma_bac_si=%)', v_ma_nv
            USING ERRCODE = 'check_violation';
    END IF;
    IF v_co_bac_si AND (
        (v_loai_bac_si = 'DA_KHOA' AND NOT v_co_da_khoa)
        OR (v_loai_bac_si = 'DA_KHOA' AND v_co_chuyen_khoa)
        OR (v_loai_bac_si = 'CHUYEN_KHOA' AND v_co_da_khoa)
    ) THEN
        RAISE EXCEPTION 'BR-A01: lớp con bác sĩ không khớp loai_bac_si (ma_bac_si=%)', v_ma_nv
            USING ERRCODE = 'check_violation';
    END IF;
    RETURN NULL;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER SET search_path = public, pg_temp;

CREATE CONSTRAINT TRIGGER trg_phan_lop_nhan_vien
    AFTER INSERT OR UPDATE OR DELETE ON nhan_vien DEFERRABLE INITIALLY DEFERRED
    FOR EACH ROW EXECUTE FUNCTION fn_kiem_tra_phan_lop_a();
CREATE CONSTRAINT TRIGGER trg_phan_lop_bac_si
    AFTER INSERT OR UPDATE OR DELETE ON bac_si DEFERRABLE INITIALLY DEFERRED
    FOR EACH ROW EXECUTE FUNCTION fn_kiem_tra_phan_lop_a();
CREATE CONSTRAINT TRIGGER trg_phan_lop_da_khoa
    AFTER INSERT OR UPDATE OR DELETE ON bac_si_da_khoa DEFERRABLE INITIALLY DEFERRED
    FOR EACH ROW EXECUTE FUNCTION fn_kiem_tra_phan_lop_a();
CREATE CONSTRAINT TRIGGER trg_phan_lop_chuyen_khoa
    AFTER INSERT OR UPDATE OR DELETE ON bac_si_chuyen_khoa DEFERRABLE INITIALLY DEFERRED
    FOR EACH ROW EXECUTE FUNCTION fn_kiem_tra_phan_lop_a();

-- Không cho sửa ngày hết hạn làm mất điều kiện hợp lệ của ca đã xếp.
CREATE OR REPLACE FUNCTION fn_giay_phep_khong_vo_hieu_ca() RETURNS trigger AS $$
BEGIN
    IF EXISTS (
        SELECT 1 FROM ca_lam_viec c
        WHERE c.ma_bac_si = OLD.ma_bac_si
          AND c.trang_thai = 'DA_XEP'
          AND c.thoi_gian_kt::date > NEW.ngay_het_han_cc
    ) THEN
        RAISE EXCEPTION 'BR-A03: ngày hết hạn mới làm vô hiệu ca đã xếp (ma_bac_si=%)', OLD.ma_bac_si
            USING ERRCODE = 'check_violation';
    END IF;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER SET search_path = public, pg_temp;
CREATE OR REPLACE TRIGGER trg_giay_phep_khong_vo_hieu_ca
    BEFORE UPDATE OF ngay_het_han_cc ON bac_si
    FOR EACH ROW EXECUTE FUNCTION fn_giay_phep_khong_vo_hieu_ca();

-- BR-A03/A08: kiểm tra giấy phép khi xếp ca, và không làm lịch hiện hành rơi ngoài ca.
CREATE OR REPLACE FUNCTION fn_ca_lam_viec_hop_le() RETURNS trigger AS $$
DECLARE
    v_ngay_cap DATE;
    v_ngay_het_han DATE;
BEGIN
    IF NEW.trang_thai = 'DA_XEP' THEN
        SELECT ngay_cap_cc, ngay_het_han_cc INTO v_ngay_cap, v_ngay_het_han
        FROM bac_si WHERE ma_bac_si = NEW.ma_bac_si;
        IF v_ngay_cap IS NULL OR v_ngay_cap > NEW.thoi_gian_bd::date
           OR v_ngay_het_han < NEW.thoi_gian_kt::date THEN
            RAISE EXCEPTION 'BR-A03: giấy phép phải bao trùm toàn bộ ngày ca làm việc (ma_ca=%)', NEW.ma_ca
                USING ERRCODE = 'check_violation';
        END IF;
    END IF;

    IF TG_OP = 'UPDATE' AND EXISTS (
        SELECT 1 FROM lich_hen l
        WHERE l.ma_bac_si = OLD.ma_bac_si
          AND l.trang_thai NOT IN ('HUY', 'VANG_MAT')
          AND l.thoi_gian_bd >= OLD.thoi_gian_bd
          AND l.thoi_gian_kt <= OLD.thoi_gian_kt
          AND (
              NEW.trang_thai = 'HUY'
              OR NEW.ma_bac_si <> OLD.ma_bac_si
              OR l.thoi_gian_bd < NEW.thoi_gian_bd
              OR l.thoi_gian_kt > NEW.thoi_gian_kt
          )
    ) THEN
        RAISE EXCEPTION 'BR-A08: không thể sửa hoặc hủy ca vì có lịch hẹn còn hiệu lực nằm ngoài ca mới (ma_ca=%)', OLD.ma_ca
            USING ERRCODE = 'check_violation';
    END IF;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER SET search_path = public, pg_temp;

CREATE OR REPLACE TRIGGER trg_ca_lam_viec_hop_le
    BEFORE INSERT OR UPDATE OF thoi_gian_bd, thoi_gian_kt, trang_thai, ma_bac_si
    ON ca_lam_viec FOR EACH ROW EXECUTE FUNCTION fn_ca_lam_viec_hop_le();

-- Ca đã có lịch hẹn không thể bị xóa; phải chuyển sang HUY để giữ lịch sử và kiểm tra BR-A08.
CREATE OR REPLACE FUNCTION fn_ca_lam_viec_khong_xoa() RETURNS trigger AS $$
BEGIN
    IF EXISTS (
        SELECT 1 FROM lich_hen l
        WHERE l.ma_bac_si = OLD.ma_bac_si
          AND l.trang_thai NOT IN ('HUY', 'VANG_MAT')
          AND l.thoi_gian_bd >= OLD.thoi_gian_bd AND l.thoi_gian_kt <= OLD.thoi_gian_kt
    ) THEN
        RAISE EXCEPTION 'BR-A08: không thể xóa ca đang có lịch hẹn còn hiệu lực (ma_ca=%)', OLD.ma_ca
            USING ERRCODE = 'check_violation';
    END IF;
    RETURN OLD;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER SET search_path = public, pg_temp;
CREATE OR REPLACE TRIGGER trg_ca_lam_viec_khong_xoa
    BEFORE DELETE ON ca_lam_viec FOR EACH ROW EXECUTE FUNCTION fn_ca_lam_viec_khong_xoa();

-- Lịch trực sắp tới, cho bác sĩ và lễ tân tra cứu.
CREATE OR REPLACE VIEW v_lich_truc_bac_si AS
SELECT c.ma_ca, c.thoi_gian_bd, c.thoi_gian_kt, c.trang_thai,
       b.ma_bac_si, nv.ho_ten AS ten_bac_si,
       COALESCE(ck.ten_chuyen_khoa, 'Đa khoa') AS chuyen_khoa
FROM ca_lam_viec c
JOIN bac_si b ON b.ma_bac_si = c.ma_bac_si
JOIN nhan_vien nv ON nv.ma_nv = b.ma_bac_si
LEFT JOIN bac_si_chuyen_khoa bck ON bck.ma_bac_si = b.ma_bac_si
LEFT JOIN chuyen_khoa ck ON ck.ma_chuyen_khoa = bck.ma_chuyen_khoa
WHERE c.trang_thai = 'DA_XEP';
