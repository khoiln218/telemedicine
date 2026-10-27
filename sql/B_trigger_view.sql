-- T37 – Trigger và view mảng B: Bệnh nhân & Lịch hẹn
-- Người viết / review: Lê Ngọc Khôi / Nguyễn Đăng Khoa – 27/10/2026
-- Căn cứ: docs/2_quy-tac/T08_BR_MangB.md; phần "còn lại cho cài đặt" ở docs/5_anh-xa/T20_AnhXa_MangB.md mục 5
--
-- Chạy sau schema.sql (A_schema.sql, B_schema.sql). Cột mảng A được dùng (giả định, chờ T32):
--   nhan_vien(ma_nv, ho_ten, loai_nv), bac_si_chuyen_khoa(ma_bac_si, ma_chuyen_khoa),
--   chuyen_khoa(ma_chuyen_khoa, ten_chuyen_khoa),
--   ca_lam_viec(ma_ca, ma_bac_si, thoi_gian_bd, thoi_gian_kt, trang_thai), ca đã hủy có trang_thai = 'HUY'.
--
-- Lỗi trả về mã 23514 (check_violation), thông báo bắt đầu bằng mã quy tắc để ứng dụng hiển thị (T49).
-- Dữ liệu mẫu (T39) phải theo các trigger này: lịch hẹn thêm ở DA_DAT rồi UPDATE sang trạng thái sau;
-- mỗi lịch hẹn nằm trong một ca; lịch chuyên khoa kèm giấy hoặc là tái khám.

-- BR-B01, BR-B03: lịch hẹn nằm trong ca; lịch chuyên khoa có giấy hợp lệ hoặc là tái khám
CREATE OR REPLACE FUNCTION fn_lich_hen_hop_le() RETURNS trigger AS $$
DECLARE
    v_chuyen_khoa INTEGER;   -- chuyên khoa của bác sĩ được hẹn, NULL nếu là bác sĩ đa khoa
    v_giay        giay_chuyen_khoa%ROWTYPE;
BEGIN
    -- Lịch hủy, vắng mặt không chiếm giờ nên không cần nằm trong ca
    IF NEW.trang_thai IN ('HUY', 'VANG_MAT') THEN
        RETURN NEW;
    END IF;

    IF NOT EXISTS (
        SELECT 1 FROM ca_lam_viec c
        WHERE c.ma_bac_si = NEW.ma_bac_si
          AND c.trang_thai <> 'HUY'
          AND c.thoi_gian_bd <= NEW.thoi_gian_bd
          AND c.thoi_gian_kt >= NEW.thoi_gian_kt
    ) THEN
        RAISE EXCEPTION 'BR-B01: lịch hẹn phải nằm trọn trong một ca còn hiệu lực của bác sĩ'
            USING ERRCODE = 'check_violation';
    END IF;

    SELECT ma_chuyen_khoa INTO v_chuyen_khoa
    FROM bac_si_chuyen_khoa WHERE ma_bac_si = NEW.ma_bac_si;

    IF v_chuyen_khoa IS NULL THEN
        IF NEW.ma_giay IS NOT NULL THEN
            RAISE EXCEPTION 'BR-B03: lịch hẹn với bác sĩ đa khoa không dùng giấy chuyển chuyên khoa'
                USING ERRCODE = 'check_violation';
        END IF;
        RETURN NEW;
    END IF;

    IF NEW.ma_giay IS NULL THEN
        -- Tái khám: đã có lịch hoàn thành trước đó ở cùng chuyên khoa
        IF NOT EXISTS (
            SELECT 1 FROM lich_hen l
            JOIN bac_si_chuyen_khoa b ON b.ma_bac_si = l.ma_bac_si
            WHERE l.ma_bn = NEW.ma_bn
              AND l.trang_thai = 'HOAN_THANH'
              AND l.thoi_gian_bd < NEW.thoi_gian_bd
              AND b.ma_chuyen_khoa = v_chuyen_khoa
        ) THEN
            RAISE EXCEPTION 'BR-B03: lịch hẹn chuyên khoa cần giấy chuyển chuyên khoa, trừ khi tái khám'
                USING ERRCODE = 'check_violation';
        END IF;
        RETURN NEW;
    END IF;

    -- Giấy đúng bệnh nhân và chưa dùng đã có ràng buộc ở B_schema.sql; ở đây báo lỗi dễ hiểu cho
    -- giấy đã dùng (kể cả lịch đã hủy, vắng mặt – T08 mục 5), rồi kiểm tra chuyên khoa và hạn
    IF EXISTS (SELECT 1 FROM lich_hen WHERE ma_giay = NEW.ma_giay AND ma_lh <> NEW.ma_lh) THEN
        RAISE EXCEPTION 'BR-B03: giấy chuyển % đã dùng cho lịch hẹn khác', NEW.ma_giay
            USING ERRCODE = 'check_violation';
    END IF;

    SELECT * INTO v_giay FROM giay_chuyen_khoa WHERE ma_giay = NEW.ma_giay;
    IF v_giay.ma_chuyen_khoa <> v_chuyen_khoa THEN
        RAISE EXCEPTION 'BR-B03: giấy chuyển không đúng chuyên khoa của bác sĩ được hẹn'
            USING ERRCODE = 'check_violation';
    END IF;
    IF NEW.thoi_gian_bd::date NOT BETWEEN v_giay.ngay_lap AND v_giay.ngay_het_han THEN
        RAISE EXCEPTION 'BR-B03: ngày hẹn nằm ngoài thời hạn của giấy chuyển (% – %)',
            v_giay.ngay_lap, v_giay.ngay_het_han
            USING ERRCODE = 'check_violation';
    END IF;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE OR REPLACE TRIGGER trg_lich_hen_hop_le
    BEFORE INSERT OR UPDATE OF thoi_gian_bd, thoi_gian_kt, ma_bac_si, ma_bn, ma_giay
    ON lich_hen
    FOR EACH ROW EXECUTE FUNCTION fn_lich_hen_hop_le();

-- BR-B05: lịch mới ở DA_DAT; chỉ chuyển theo sơ đồ; trạng thái cuối không sửa được nữa
CREATE OR REPLACE FUNCTION fn_trang_thai_lich_hen() RETURNS trigger AS $$
BEGIN
    IF TG_OP = 'INSERT' THEN
        IF NEW.trang_thai <> 'DA_DAT' THEN
            RAISE EXCEPTION 'BR-B05: lịch hẹn mới phải ở trạng thái DA_DAT'
                USING ERRCODE = 'check_violation';
        END IF;
        RETURN NEW;
    END IF;

    IF OLD.trang_thai IN ('HOAN_THANH', 'HUY', 'VANG_MAT') THEN
        RAISE EXCEPTION 'BR-B05: lịch hẹn % đã ở trạng thái cuối %, không được sửa',
            OLD.ma_lh, OLD.trang_thai
            USING ERRCODE = 'check_violation';
    END IF;

    IF NEW.trang_thai <> OLD.trang_thai AND (OLD.trang_thai, NEW.trang_thai) NOT IN (
        ('DA_DAT', 'DA_XAC_NHAN'), ('DA_DAT', 'HUY'),
        ('DA_XAC_NHAN', 'HOAN_THANH'), ('DA_XAC_NHAN', 'HUY'), ('DA_XAC_NHAN', 'VANG_MAT')
    ) THEN
        RAISE EXCEPTION 'BR-B05: không được chuyển lịch hẹn từ % sang %', OLD.trang_thai, NEW.trang_thai
            USING ERRCODE = 'check_violation';
    END IF;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE OR REPLACE TRIGGER trg_trang_thai_lich_hen
    BEFORE INSERT OR UPDATE ON lich_hen
    FOR EACH ROW EXECUTE FUNCTION fn_trang_thai_lich_hen();

-- BR-B09: vai trò của tài khoản nhân viên trùng loại nhân viên
-- (chiều ngược lại – sửa nhan_vien.loai_nv khi đã có tài khoản – chờ chốt ở T30)
CREATE OR REPLACE FUNCTION fn_tai_khoan_vai_tro() RETURNS trigger AS $$
DECLARE
    v_loai_nv nhan_vien.loai_nv%TYPE;
BEGIN
    IF NEW.ma_nv IS NOT NULL THEN
        SELECT loai_nv INTO v_loai_nv FROM nhan_vien WHERE ma_nv = NEW.ma_nv;
        IF v_loai_nv <> NEW.vai_tro THEN
            RAISE EXCEPTION 'BR-B09: vai trò % không trùng loại nhân viên %', NEW.vai_tro, v_loai_nv
                USING ERRCODE = 'check_violation';
        END IF;
    END IF;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE OR REPLACE TRIGGER trg_tai_khoan_vai_tro
    BEFORE INSERT OR UPDATE OF vai_tro, ma_nv ON tai_khoan
    FOR EACH ROW EXECUTE FUNCTION fn_tai_khoan_vai_tro();

-- BR-B10: tài khoản không bị xóa, chỉ khóa (áp dụng cả với chủ sở hữu bảng, không chỉ qua GRANT).
-- TRUNCATE không kích hoạt trigger DELETE nên chặn thêm bằng trigger mức câu lệnh.
CREATE OR REPLACE FUNCTION fn_tai_khoan_khong_xoa() RETURNS trigger AS $$
BEGIN
    IF TG_OP = 'TRUNCATE' THEN
        RAISE EXCEPTION 'BR-B10: tài khoản không được xóa, chỉ được khóa'
            USING ERRCODE = 'check_violation';
    END IF;
    RAISE EXCEPTION 'BR-B10: tài khoản % không được xóa, chỉ được khóa', OLD.ten_dang_nhap
        USING ERRCODE = 'check_violation';
END;
$$ LANGUAGE plpgsql;

CREATE OR REPLACE TRIGGER trg_tai_khoan_khong_xoa
    BEFORE DELETE ON tai_khoan
    FOR EACH ROW EXECUTE FUNCTION fn_tai_khoan_khong_xoa();

CREATE OR REPLACE TRIGGER trg_tai_khoan_khong_truncate
    BEFORE TRUNCATE ON tai_khoan
    FOR EACH STATEMENT EXECUTE FUNCTION fn_tai_khoan_khong_xoa();

-- Lịch hẹn trong ngày cho lễ tân, bác sĩ (màn hình T49). Lọc theo khoảng để dùng idx_lich_hen_thoi_gian.
CREATE OR REPLACE VIEW v_lich_hen_hom_nay AS
SELECT l.ma_lh,
       l.thoi_gian_bd,
       l.thoi_gian_kt,
       l.trang_thai,
       l.hinh_thuc,
       COALESCE(l.phong_kham, l.nen_tang) AS phong_hoac_nen_tang,
       l.link_phien,
       l.ma_bn,
       bn.ho_ten  AS ten_benh_nhan,
       bn.sdt     AS sdt_benh_nhan,
       l.ma_bac_si,
       nv.ho_ten  AS ten_bac_si,
       COALESCE(ck.ten_chuyen_khoa, 'Đa khoa') AS chuyen_khoa,
       l.ly_do_kham,
       l.phi_kham
FROM lich_hen l
JOIN benh_nhan bn ON bn.ma_bn = l.ma_bn
JOIN nhan_vien nv ON nv.ma_nv = l.ma_bac_si
LEFT JOIN bac_si_chuyen_khoa bck ON bck.ma_bac_si = l.ma_bac_si
LEFT JOIN chuyen_khoa ck ON ck.ma_chuyen_khoa = bck.ma_chuyen_khoa
WHERE l.thoi_gian_bd >= CURRENT_DATE
  AND l.thoi_gian_bd <  CURRENT_DATE + 1;
