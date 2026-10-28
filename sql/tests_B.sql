-- T43 (phần mảng B) – Test ràng buộc mảng B: Bệnh nhân & Lịch hẹn
-- Người viết / review: Lê Ngọc Khôi / Nguyễn Đăng Khoa – 27/10/2026
-- Chạy sau schema.sql, B_trigger_view.sql (seed.sql có hay chưa đều được):
--   psql -d telemedicine -v ON_ERROR_STOP=1 -f sql/tests_B.sql
-- Mỗi ca chạy trong một khối con: ca mong đợi lỗi phải bị chặn đúng bởi ràng buộc/trigger ghi ở cột ky_vong
-- (tên ràng buộc hoặc một đoạn thông báo lỗi), ca mong đợi OK phải chạy được. Cuối script in bảng kết quả
-- rồi ROLLBACK, không để lại dữ liệu. Dữ liệu thử dùng mã 9101–9199 để không đụng dữ liệu mẫu.
--
-- Khối "Dữ liệu mảng A" chỉ ghi các cột mảng B cần (giả định ở B_schema.sql); khi có A_schema.sql (T32)
-- phải bổ sung cột bắt buộc của mảng A (ngày sinh, chứng chỉ hành nghề còn hạn đến 2030, …).

BEGIN;

CREATE TEMP TABLE kq (
    stt       serial,
    ma        text,
    quy_tac   text,
    mo_ta     text,
    ky_vong   text,
    dat       boolean,
    thong_bao text
);

-- Chạy một câu lệnh, so kết quả với ky_vong ('OK' hoặc tên ràng buộc / đoạn thông báo lỗi)
CREATE PROCEDURE pg_temp.kt(p_ma text, p_qt text, p_mo_ta text, p_sql text, p_ky_vong text) AS $$
DECLARE
    v_msg text := 'thực hiện được';
    v_con text;
    v_dat boolean;
BEGIN
    BEGIN
        EXECUTE p_sql;
        v_dat := p_ky_vong = 'OK';
    EXCEPTION WHEN OTHERS THEN
        GET STACKED DIAGNOSTICS v_msg = MESSAGE_TEXT, v_con = CONSTRAINT_NAME;
        v_dat := p_ky_vong <> 'OK' AND (v_con = p_ky_vong OR position(p_ky_vong IN v_msg) > 0);
    END;
    INSERT INTO kq (ma, quy_tac, mo_ta, ky_vong, dat, thong_bao) VALUES (p_ma, p_qt, p_mo_ta, p_ky_vong, v_dat, v_msg);
END;
$$ LANGUAGE plpgsql;

-- Kiểm tra một điều kiện SELECT trả về true
CREATE PROCEDURE pg_temp.kt_dung(p_ma text, p_qt text, p_mo_ta text, p_sql text) AS $$
DECLARE
    v boolean;
BEGIN
    EXECUTE p_sql INTO v;
    INSERT INTO kq (ma, quy_tac, mo_ta, ky_vong, dat, thong_bao)
    VALUES (p_ma, p_qt, p_mo_ta, 'true', coalesce(v, false), coalesce(v::text, 'NULL'));
END;
$$ LANGUAGE plpgsql;

-- ---------- Dữ liệu mảng A (sửa theo A_schema.sql) ----------
-- 9101, 9105: bác sĩ đa khoa; 9102: tim mạch; 9103: da liễu; 9104: lễ tân
INSERT INTO nhan_vien (ma_nv, ho_ten, loai_nv) VALUES
    (9101, 'TB Đa khoa 1', 'BAC_SI'), (9102, 'TB Tim mạch', 'BAC_SI'), (9103, 'TB Da liễu', 'BAC_SI'),
    (9104, 'TB Lễ tân', 'LE_TAN'), (9105, 'TB Đa khoa 2', 'BAC_SI');
INSERT INTO chuyen_khoa (ma_chuyen_khoa, ten_chuyen_khoa) VALUES (9101, 'TB Tim mạch'), (9102, 'TB Da liễu');
INSERT INTO bac_si (ma_bac_si) VALUES (9101), (9102), (9103), (9105);
INSERT INTO bac_si_da_khoa (ma_bac_si) VALUES (9101), (9105);
INSERT INTO bac_si_chuyen_khoa (ma_bac_si, ma_chuyen_khoa) VALUES (9102, 9101), (9103, 9102);
-- Ca: hôm nay 07–11 (9101, 9105); 07/01/2030 07–11 (9101, 9102, 9103), 13–17 đã hủy (9101); 20/02/2030 07–11 (9102)
INSERT INTO ca_lam_viec (ma_ca, ma_bac_si, thoi_gian_bd, thoi_gian_kt, trang_thai) VALUES
    (9101, 9101, CURRENT_DATE + time '07:00', CURRENT_DATE + time '11:00', 'DA_XEP'),
    (9102, 9105, CURRENT_DATE + time '07:00', CURRENT_DATE + time '11:00', 'DA_XEP'),
    (9103, 9101, '2030-01-07 07:00', '2030-01-07 11:00', 'DA_XEP'),
    (9104, 9102, '2030-01-07 07:00', '2030-01-07 11:00', 'DA_XEP'),
    (9105, 9103, '2030-01-07 07:00', '2030-01-07 11:00', 'DA_XEP'),
    (9106, 9101, '2030-01-07 13:00', '2030-01-07 17:00', 'HUY'),
    (9107, 9102, '2030-02-20 07:00', '2030-02-20 11:00', 'DA_XEP');

-- ---------- Dữ liệu mảng B dùng chung ----------
INSERT INTO benh_nhan (ma_bn, ho_ten, ngay_sinh, gioi_tinh, sdt, email) VALUES
    (9101, 'TB Bệnh nhân 1', '1990-01-01', 'NAM', '0990009101', 'bn1@test.vn'),
    (9102, 'TB Bệnh nhân 2', '1985-05-05', 'NU', '0990009102', NULL);
-- Giấy (lập 01/01/2030, hết hạn 30/01/2030): 9101, 9103, 9104, 9105 tim mạch; 9102 da liễu; đều của bệnh nhân 9101
INSERT INTO giay_chuyen_khoa (ma_giay, ngay_lap, ly_do, ngay_het_han, ma_bn, ma_bac_si_lap, ma_chuyen_khoa) VALUES
    (9101, '2030-01-01', 'Đau ngực', '2030-01-30', 9101, 9101, 9101),
    (9102, '2030-01-01', 'Ngứa', '2030-01-30', 9101, 9101, 9102),
    (9103, '2030-01-01', 'Đau ngực', '2030-01-30', 9101, 9101, 9101),
    (9104, '2030-01-01', 'Đau ngực', '2030-01-30', 9101, 9101, 9101),
    (9105, '2030-01-01', 'Đau ngực', '2030-01-30', 9101, 9101, 9101);
INSERT INTO lich_hen (ma_lh, thoi_gian_bd, thoi_gian_kt, ly_do_kham, hinh_thuc, phi_kham, phong_kham, ma_bn, ma_bac_si)
VALUES (9101, CURRENT_DATE + time '08:00', CURRENT_DATE + time '08:15', 'Khám', 'TRUC_TIEP', 150000, 'P101', 9101, 9101);

-- ---------- BR-B01: lịch hẹn nằm trọn trong một ca còn hiệu lực ----------
CALL pg_temp.kt('TB01', 'BR-B01', 'Đặt lịch ngoài giờ ca (18:00)',
    $q$INSERT INTO lich_hen (thoi_gian_bd, thoi_gian_kt, ly_do_kham, hinh_thuc, phi_kham, phong_kham, ma_bn, ma_bac_si)
       VALUES (CURRENT_DATE + time '18:00', CURRENT_DATE + time '18:15', 'x', 'TRUC_TIEP', 0, 'P1', 9102, 9101)$q$, 'BR-B01');
CALL pg_temp.kt('TB02', 'BR-B01', 'Đặt lịch vắt qua cuối ca (10:50–11:10)',
    $q$INSERT INTO lich_hen (thoi_gian_bd, thoi_gian_kt, ly_do_kham, hinh_thuc, phi_kham, phong_kham, ma_bn, ma_bac_si)
       VALUES (CURRENT_DATE + time '10:50', CURRENT_DATE + time '11:10', 'x', 'TRUC_TIEP', 0, 'P1', 9102, 9101)$q$, 'BR-B01');
CALL pg_temp.kt('TB03', 'BR-B01', 'Đặt lịch trong ca đã hủy',
    $q$INSERT INTO lich_hen (thoi_gian_bd, thoi_gian_kt, ly_do_kham, hinh_thuc, phi_kham, phong_kham, ma_bn, ma_bac_si)
       VALUES ('2030-01-07 14:00', '2030-01-07 14:15', 'x', 'TRUC_TIEP', 0, 'P1', 9102, 9101)$q$, 'BR-B01');
CALL pg_temp.kt('TB04', 'BR-B01', 'Đặt lịch sát cuối ca (10:45–11:00) – hợp lệ',
    $q$INSERT INTO lich_hen (ma_lh, thoi_gian_bd, thoi_gian_kt, ly_do_kham, hinh_thuc, phi_kham, phong_kham, ma_bn, ma_bac_si)
       VALUES (9102, CURRENT_DATE + time '10:45', CURRENT_DATE + time '11:00', 'x', 'TRUC_TIEP', 150000, 'P1', 9102, 9101)$q$, 'OK');

-- ---------- BR-B02: không trùng giờ ----------
CALL pg_temp.kt('TB05', 'BR-B02', 'Trùng giờ lịch còn hiệu lực của cùng bác sĩ',
    $q$INSERT INTO lich_hen (thoi_gian_bd, thoi_gian_kt, ly_do_kham, hinh_thuc, phi_kham, phong_kham, ma_bn, ma_bac_si)
       VALUES (CURRENT_DATE + time '08:10', CURRENT_DATE + time '08:20', 'x', 'TRUC_TIEP', 0, 'P1', 9102, 9101)$q$,
    'ex_lich_hen_bac_si');
CALL pg_temp.kt('TB06', 'BR-B02', 'Trùng giờ lịch còn hiệu lực của cùng bệnh nhân (bác sĩ khác)',
    $q$INSERT INTO lich_hen (thoi_gian_bd, thoi_gian_kt, ly_do_kham, hinh_thuc, phi_kham, phong_kham, ma_bn, ma_bac_si)
       VALUES (CURRENT_DATE + time '08:05', CURRENT_DATE + time '08:20', 'x', 'TRUC_TIEP', 0, 'P2', 9101, 9105)$q$,
    'ex_lich_hen_benh_nhan');
CALL pg_temp.kt('TB07', 'BR-B02', 'Lịch nối tiếp 08:15–08:30 sau lịch 08:00–08:15 – hợp lệ',
    $q$INSERT INTO lich_hen (ma_lh, thoi_gian_bd, thoi_gian_kt, ly_do_kham, hinh_thuc, phi_kham, phong_kham, ma_bn, ma_bac_si)
       VALUES (9103, CURRENT_DATE + time '08:15', CURRENT_DATE + time '08:30', 'x', 'TRUC_TIEP', 150000, 'P1', 9102, 9101)$q$, 'OK');
UPDATE lich_hen SET trang_thai = 'HUY' WHERE ma_lh = 9103;
CALL pg_temp.kt('TB08', 'BR-B02', 'Hủy lịch rồi đặt lịch khác đúng khung giờ đó – hợp lệ',
    $q$INSERT INTO lich_hen (ma_lh, thoi_gian_bd, thoi_gian_kt, ly_do_kham, hinh_thuc, phi_kham, phong_kham, ma_bn, ma_bac_si)
       VALUES (9104, CURRENT_DATE + time '08:15', CURRENT_DATE + time '08:30', 'x', 'TRUC_TIEP', 150000, 'P1', 9102, 9101)$q$, 'OK');

-- ---------- BR-B03: giấy chuyển chuyên khoa ----------
CALL pg_temp.kt('TB09', 'BR-B03', 'Lịch chuyên khoa không giấy, chưa từng khám chuyên khoa đó',
    $q$INSERT INTO lich_hen (thoi_gian_bd, thoi_gian_kt, ly_do_kham, hinh_thuc, phi_kham, phong_kham, ma_bn, ma_bac_si)
       VALUES ('2030-01-07 08:00', '2030-01-07 08:15', 'x', 'TRUC_TIEP', 0, 'P2', 9102, 9102)$q$, 'cần giấy chuyển');
CALL pg_temp.kt('TB10', 'BR-B03', 'Giấy chuyển da liễu cho lịch tim mạch',
    $q$INSERT INTO lich_hen (thoi_gian_bd, thoi_gian_kt, ly_do_kham, hinh_thuc, phi_kham, phong_kham, ma_bn, ma_bac_si, ma_giay)
       VALUES ('2030-01-07 08:00', '2030-01-07 08:15', 'x', 'TRUC_TIEP', 0, 'P2', 9101, 9102, 9102)$q$, 'không đúng chuyên khoa');
CALL pg_temp.kt('TB11', 'BR-B03', 'Ngày hẹn 20/02/2030 sau ngày hết hạn của giấy',
    $q$INSERT INTO lich_hen (thoi_gian_bd, thoi_gian_kt, ly_do_kham, hinh_thuc, phi_kham, phong_kham, ma_bn, ma_bac_si, ma_giay)
       VALUES ('2030-02-20 08:00', '2030-02-20 08:15', 'x', 'TRUC_TIEP', 0, 'P2', 9101, 9102, 9103)$q$, 'ngoài thời hạn');
CALL pg_temp.kt('TB12', 'BR-B03', 'Dùng giấy của bệnh nhân khác',
    $q$INSERT INTO lich_hen (thoi_gian_bd, thoi_gian_kt, ly_do_kham, hinh_thuc, phi_kham, phong_kham, ma_bn, ma_bac_si, ma_giay)
       VALUES ('2030-01-07 08:00', '2030-01-07 08:15', 'x', 'TRUC_TIEP', 0, 'P2', 9102, 9102, 9101)$q$, 'fk_lich_hen_giay');
CALL pg_temp.kt('TB13', 'BR-B03', 'Lịch tim mạch kèm giấy hợp lệ – hợp lệ',
    $q$INSERT INTO lich_hen (ma_lh, thoi_gian_bd, thoi_gian_kt, ly_do_kham, hinh_thuc, phi_kham, phong_kham, ma_bn, ma_bac_si, ma_giay)
       VALUES (9105, '2030-01-07 08:00', '2030-01-07 08:15', 'x', 'TRUC_TIEP', 300000, 'P2', 9101, 9102, 9101)$q$, 'OK');
CALL pg_temp.kt('TB14', 'BR-B03', 'Dùng lại giấy đã gắn với lịch khác',
    $q$INSERT INTO lich_hen (thoi_gian_bd, thoi_gian_kt, ly_do_kham, hinh_thuc, phi_kham, phong_kham, ma_bn, ma_bac_si, ma_giay)
       VALUES ('2030-01-07 09:00', '2030-01-07 09:15', 'x', 'TRUC_TIEP', 0, 'P2', 9101, 9102, 9101)$q$, 'đã dùng');
INSERT INTO lich_hen (ma_lh, thoi_gian_bd, thoi_gian_kt, ly_do_kham, hinh_thuc, phi_kham, phong_kham, ma_bn, ma_bac_si, ma_giay)
VALUES (9106, '2030-01-07 09:30', '2030-01-07 09:45', 'x', 'TRUC_TIEP', 300000, 'P2', 9101, 9102, 9104);
UPDATE lich_hen SET trang_thai = 'HUY' WHERE ma_lh = 9106;
CALL pg_temp.kt('TB15', 'BR-B03', 'Dùng lại giấy của lịch đã hủy (T08 mục 5)',
    $q$INSERT INTO lich_hen (thoi_gian_bd, thoi_gian_kt, ly_do_kham, hinh_thuc, phi_kham, phong_kham, ma_bn, ma_bac_si, ma_giay)
       VALUES ('2030-01-07 10:00', '2030-01-07 10:15', 'x', 'TRUC_TIEP', 0, 'P2', 9101, 9102, 9104)$q$, 'đã dùng');
CALL pg_temp.kt('TB16', 'BR-B03', 'Lịch với bác sĩ đa khoa kèm giấy chuyển',
    $q$INSERT INTO lich_hen (thoi_gian_bd, thoi_gian_kt, ly_do_kham, hinh_thuc, phi_kham, phong_kham, ma_bn, ma_bac_si, ma_giay)
       VALUES ('2030-01-07 07:00', '2030-01-07 07:15', 'x', 'TRUC_TIEP', 0, 'P1', 9101, 9101, 9105)$q$, 'bác sĩ đa khoa');

-- ---------- BR-B04, BR-B06: hình thức khám ----------
CALL pg_temp.kt('TB17', 'BR-B04', 'Tư vấn từ xa thiếu đường dẫn phiên',
    $q$INSERT INTO lich_hen (thoi_gian_bd, thoi_gian_kt, ly_do_kham, hinh_thuc, phi_kham, nen_tang, ma_bn, ma_bac_si)
       VALUES (CURRENT_DATE + time '09:00', CURRENT_DATE + time '09:15', 'x', 'TU_XA', 0, 'Zoom', 9102, 9101)$q$,
    'ck_lich_hen_hinh_thuc');
CALL pg_temp.kt('TB18', 'BR-B06', 'Khám trực tiếp kèm thông tin tư vấn từ xa',
    $q$INSERT INTO lich_hen (thoi_gian_bd, thoi_gian_kt, ly_do_kham, hinh_thuc, phi_kham, phong_kham, nen_tang, link_phien, ma_bn, ma_bac_si)
       VALUES (CURRENT_DATE + time '09:00', CURRENT_DATE + time '09:15', 'x', 'TRUC_TIEP', 0, 'P1', 'Zoom', 'https://z/1', 9102, 9101)$q$,
    'ck_lich_hen_hinh_thuc');
CALL pg_temp.kt('TB19', 'BR-B06', 'Khám trực tiếp không có phòng',
    $q$INSERT INTO lich_hen (thoi_gian_bd, thoi_gian_kt, ly_do_kham, hinh_thuc, phi_kham, ma_bn, ma_bac_si)
       VALUES (CURRENT_DATE + time '09:00', CURRENT_DATE + time '09:15', 'x', 'TRUC_TIEP', 0, 9102, 9101)$q$,
    'ck_lich_hen_hinh_thuc');
CALL pg_temp.kt('TB20', 'BR-B04', 'Tư vấn từ xa đủ nền tảng, đường dẫn phiên – hợp lệ',
    $q$INSERT INTO lich_hen (ma_lh, thoi_gian_bd, thoi_gian_kt, ly_do_kham, hinh_thuc, phi_kham, nen_tang, link_phien, ma_bn, ma_bac_si)
       VALUES (9108, CURRENT_DATE + time '09:00', CURRENT_DATE + time '09:15', 'x', 'TU_XA', 150000, 'Zoom', 'https://z/9108', 9102, 9101)$q$, 'OK');

-- ---------- BR-B05: trạng thái lịch hẹn ----------
CALL pg_temp.kt('TB21', 'BR-B05', 'Thêm lịch mới ở trạng thái HOAN_THANH',
    $q$INSERT INTO lich_hen (thoi_gian_bd, thoi_gian_kt, ly_do_kham, trang_thai, hinh_thuc, phi_kham, phong_kham, ma_bn, ma_bac_si)
       VALUES (CURRENT_DATE + time '09:30', CURRENT_DATE + time '09:45', 'x', 'HOAN_THANH', 'TRUC_TIEP', 0, 'P1', 9102, 9101)$q$,
    'phải ở trạng thái DA_DAT');
CALL pg_temp.kt('TB22', 'BR-B05', 'Chuyển thẳng DA_DAT → HOAN_THANH',
    $q$UPDATE lich_hen SET trang_thai = 'HOAN_THANH' WHERE ma_lh = 9108$q$, 'không được chuyển');
CALL pg_temp.kt('TB23', 'BR-B05', 'Chuyển DA_DAT → DA_XAC_NHAN – hợp lệ',
    $q$UPDATE lich_hen SET trang_thai = 'DA_XAC_NHAN' WHERE ma_lh = 9105$q$, 'OK');
CALL pg_temp.kt('TB24', 'BR-B03', 'Dời giờ lịch đã xác nhận có giấy, trong ca – hợp lệ, giữ giấy',
    $q$UPDATE lich_hen SET thoi_gian_bd = '2030-01-07 08:30', thoi_gian_kt = '2030-01-07 08:45' WHERE ma_lh = 9105$q$, 'OK');
CALL pg_temp.kt('TB25', 'BR-B01', 'Dời giờ lịch đã xác nhận ra ngoài ca',
    $q$UPDATE lich_hen SET thoi_gian_bd = '2030-01-07 12:00', thoi_gian_kt = '2030-01-07 12:15' WHERE ma_lh = 9105$q$, 'BR-B01');
CALL pg_temp.kt('TB26', 'BR-B05', 'Chuyển DA_XAC_NHAN → HOAN_THANH – hợp lệ',
    $q$UPDATE lich_hen SET trang_thai = 'HOAN_THANH' WHERE ma_lh = 9105$q$, 'OK');
CALL pg_temp.kt('TB27', 'BR-B05', 'Sửa lý do khám của lịch đã hoàn thành',
    $q$UPDATE lich_hen SET ly_do_kham = 'sửa' WHERE ma_lh = 9105$q$, 'trạng thái cuối');
CALL pg_temp.kt('TB28', 'BR-B05', 'Chuyển lịch đã hủy về DA_XAC_NHAN',
    $q$UPDATE lich_hen SET trang_thai = 'DA_XAC_NHAN' WHERE ma_lh = 9103$q$, 'trạng thái cuối');

-- ---------- BR-B03 (tiếp): tái khám, dựa trên lịch 9105 đã hoàn thành ----------
CALL pg_temp.kt('TB29', 'BR-B03', 'Tái khám tim mạch không giấy – hợp lệ',
    $q$INSERT INTO lich_hen (ma_lh, thoi_gian_bd, thoi_gian_kt, ly_do_kham, hinh_thuc, phi_kham, phong_kham, ma_bn, ma_bac_si)
       VALUES (9107, '2030-02-20 08:00', '2030-02-20 08:15', 'Tái khám', 'TRUC_TIEP', 300000, 'P2', 9101, 9102)$q$, 'OK');
CALL pg_temp.kt('TB30', 'BR-B03', 'Khám da liễu không giấy (đã khám tim mạch, chưa khám da liễu)',
    $q$INSERT INTO lich_hen (thoi_gian_bd, thoi_gian_kt, ly_do_kham, hinh_thuc, phi_kham, phong_kham, ma_bn, ma_bac_si)
       VALUES ('2030-01-07 10:30', '2030-01-07 10:45', 'x', 'TRUC_TIEP', 0, 'P3', 9101, 9103)$q$, 'cần giấy chuyển');

-- ---------- BR-B07: giấy chuyển ----------
CALL pg_temp.kt('TB31', 'BR-B07', 'Giấy có hạn 31 ngày',
    $q$INSERT INTO giay_chuyen_khoa (ngay_lap, ly_do, ngay_het_han, ma_bn, ma_bac_si_lap, ma_chuyen_khoa)
       VALUES ('2030-01-01', 'x', '2030-02-01', 9101, 9101, 9101)$q$, 'ck_giay_han');
CALL pg_temp.kt('TB32', 'BR-B07', 'Giấy do bác sĩ chuyên khoa lập',
    $q$INSERT INTO giay_chuyen_khoa (ngay_lap, ly_do, ngay_het_han, ma_bn, ma_bac_si_lap, ma_chuyen_khoa)
       VALUES ('2030-01-01', 'x', '2030-01-20', 9101, 9102, 9101)$q$, 'giay_chuyen_khoa_ma_bac_si_lap_fkey');
CALL pg_temp.kt('TB33', 'BR-B07', 'Ngày hết hạn trước ngày lập',
    $q$INSERT INTO giay_chuyen_khoa (ngay_lap, ly_do, ngay_het_han, ma_bn, ma_bac_si_lap, ma_chuyen_khoa)
       VALUES ('2030-01-10', 'x', '2030-01-05', 9101, 9101, 9101)$q$, 'ck_giay_han');

-- ---------- BR-B09: tài khoản ----------
INSERT INTO tai_khoan (ten_dang_nhap, mat_khau_hash, vai_tro, ma_bn, ma_nv) VALUES
    ('tb_bn1', 'x', 'BENH_NHAN', 9101, NULL), ('tb_letan', 'x', 'LE_TAN', NULL, 9104);
CALL pg_temp.kt('TB34', 'BR-B09', 'Tài khoản bệnh nhân không gắn bệnh nhân nào',
    $q$INSERT INTO tai_khoan (ten_dang_nhap, mat_khau_hash, vai_tro) VALUES ('tb_x1', 'x', 'BENH_NHAN')$q$,
    'ck_tai_khoan_chu_so_huu');
CALL pg_temp.kt('TB35', 'BR-B09', 'Tài khoản vai trò lễ tân gắn với một bác sĩ',
    $q$INSERT INTO tai_khoan (ten_dang_nhap, mat_khau_hash, vai_tro, ma_nv) VALUES ('tb_x2', 'x', 'LE_TAN', 9101)$q$, 'BR-B09');
CALL pg_temp.kt('TB36', 'BR-B09', 'Hai tài khoản cùng một bệnh nhân',
    $q$INSERT INTO tai_khoan (ten_dang_nhap, mat_khau_hash, vai_tro, ma_bn) VALUES ('tb_x3', 'x', 'BENH_NHAN', 9101)$q$,
    'tai_khoan_ma_bn_key');
CALL pg_temp.kt('TB37', 'BR-B09', 'Tài khoản gắn cả bệnh nhân và nhân viên',
    $q$INSERT INTO tai_khoan (ten_dang_nhap, mat_khau_hash, vai_tro, ma_bn, ma_nv) VALUES ('tb_x4', 'x', 'BAC_SI', 9102, 9105)$q$,
    'ck_tai_khoan_chu_so_huu');
CALL pg_temp.kt('TB38', 'BR-B09', 'Đổi vai trò tài khoản lễ tân thành quản trị tài khoản',
    $q$UPDATE tai_khoan SET vai_tro = 'QUAN_TRI_TAI_KHOAN' WHERE ten_dang_nhap = 'tb_letan'$q$, 'BR-B09');

-- ---------- BR-B10: tài khoản không bị xóa ----------
CALL pg_temp.kt('TB39', 'BR-B10', 'Khóa tài khoản – hợp lệ',
    $q$UPDATE tai_khoan SET trang_thai = 'KHOA' WHERE ten_dang_nhap = 'tb_bn1'$q$, 'OK');
CALL pg_temp.kt('TB40', 'BR-B10', 'Xóa tài khoản',
    $q$DELETE FROM tai_khoan WHERE ten_dang_nhap = 'tb_bn1'$q$, 'BR-B10');
CALL pg_temp.kt('TB41', 'BR-B10', 'TRUNCATE bảng tài khoản',
    $q$TRUNCATE tai_khoan CASCADE$q$, 'BR-B10');

-- ---------- Ràng buộc chung (1.2.4) ----------
CALL pg_temp.kt('TB42', 'Chung', 'Lịch hẹn kết thúc trước khi bắt đầu',
    $q$INSERT INTO lich_hen (thoi_gian_bd, thoi_gian_kt, ly_do_kham, hinh_thuc, phi_kham, phong_kham, ma_bn, ma_bac_si)
       VALUES (CURRENT_DATE + time '10:00', CURRENT_DATE + time '09:50', 'x', 'TRUC_TIEP', 0, 'P1', 9102, 9101)$q$,
    'ck_lich_hen_thoi_gian');
CALL pg_temp.kt('TB43', 'Chung', 'Phí khám âm',
    $q$INSERT INTO lich_hen (thoi_gian_bd, thoi_gian_kt, ly_do_kham, hinh_thuc, phi_kham, phong_kham, ma_bn, ma_bac_si)
       VALUES (CURRENT_DATE + time '09:30', CURRENT_DATE + time '09:45', 'x', 'TRUC_TIEP', -1, 'P1', 9102, 9101)$q$,
    'lich_hen_phi_kham_check');
CALL pg_temp.kt('TB44', 'Chung', 'Số điện thoại bệnh nhân trùng',
    $q$INSERT INTO benh_nhan (ho_ten, ngay_sinh, gioi_tinh, sdt) VALUES ('x', '2000-01-01', 'NAM', '0990009101')$q$,
    'benh_nhan_sdt_key');
CALL pg_temp.kt('TB45', 'Chung', 'Số điện thoại sai định dạng',
    $q$INSERT INTO benh_nhan (ho_ten, ngay_sinh, gioi_tinh, sdt) VALUES ('x', '2000-01-01', 'NAM', '12345')$q$,
    'benh_nhan_sdt_check');
CALL pg_temp.kt('TB46', 'Chung', 'Ngày sinh ở tương lai',
    $q$INSERT INTO benh_nhan (ho_ten, ngay_sinh, gioi_tinh, sdt) VALUES ('x', CURRENT_DATE + 1, 'NAM', '0990009199')$q$,
    'benh_nhan_ngay_sinh_check');
CALL pg_temp.kt('TB47', 'Chung', 'Email sai định dạng',
    $q$INSERT INTO benh_nhan (ho_ten, ngay_sinh, gioi_tinh, sdt, email) VALUES ('x', '2000-01-01', 'NAM', '0990009198', 'a@b')$q$,
    'benh_nhan_email_check');
CALL pg_temp.kt('TB48', 'Chung', 'Xóa bệnh nhân còn lịch hẹn',
    $q$DELETE FROM benh_nhan WHERE ma_bn = 9102$q$, 'lich_hen_ma_bn_fkey');

-- ---------- View ----------
CALL pg_temp.kt_dung('TB49', 'View', 'v_lich_hen_hom_nay chỉ có 5 lịch hôm nay của dữ liệu thử, bác sĩ đa khoa ghi "Đa khoa"',
    $q$SELECT count(*) = 5 AND bool_and(chuyen_khoa = 'Đa khoa') FROM v_lich_hen_hom_nay WHERE ma_lh BETWEEN 9101 AND 9199$q$);

-- ---------- Kết quả ----------
SELECT ma, quy_tac, mo_ta, ky_vong,
       CASE WHEN dat THEN 'ĐẠT' ELSE 'KHÔNG ĐẠT' END AS ket_qua,
       thong_bao
FROM kq ORDER BY stt;

SELECT count(*) AS so_ca,
       count(*) FILTER (WHERE dat) AS dat,
       count(*) FILTER (WHERE NOT dat) AS khong_dat
FROM kq;

ROLLBACK;
