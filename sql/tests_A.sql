-- T43 (phần mảng A) – Test ràng buộc mảng A: Nhân viên y tế & Lịch làm việc
-- Chạy sau schema.sql, A/B/C_trigger_view.sql và rbac.sql (seed.sql có hay chưa đều được):
--   psql -d telemedicine -v ON_ERROR_STOP=1 -f sql/tests_A.sql
-- Cùng cách làm với tests_B.sql: mỗi ca chạy trong một khối con, ca mong đợi lỗi phải bị chặn đúng bởi ràng
-- buộc/trigger ghi ở cột ky_vong, ca mong đợi OK phải chạy được; cuối script in kết quả rồi ROLLBACK.
-- Dữ liệu thử dùng mã 9201–9299 (tests_B.sql dùng 9101–9199, dữ liệu mẫu dùng mã nhỏ hơn).
-- Ràng buộc phân lớp (BR-A01, A02, A10) là constraint trigger trì hoãn, nên ca thử chạy thêm
-- SET CONSTRAINTS ALL IMMEDIATE để kiểm tra ngay, rồi trả về DEFERRED nếu ca hợp lệ.
-- BR-A09 (quyền theo vai trò): ca chạy dưới role ứng dụng bằng SET LOCAL ROLE, thử thao tác thật.

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
        RESET ROLE;   -- ca chạy dưới role ứng dụng (SET LOCAL ROLE) mà không lỗi
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

-- ---------- Dữ liệu thử ----------
-- 9201: bác sĩ đa khoa; 9202: bác sĩ tim mạch, chứng chỉ hết hạn sau 20 ngày; 9203: lễ tân
INSERT INTO chuyen_khoa (ma_chuyen_khoa, ten_chuyen_khoa) VALUES (9201, 'TA Tim mạch');
INSERT INTO nhan_vien (ma_nv, ho_ten, ngay_sinh, sdt, loai_nv) VALUES
    (9201, 'TA Đa khoa', '1980-01-01', '0990029201', 'BAC_SI'),
    (9202, 'TA Tim mạch', '1980-01-01', '0990029202', 'BAC_SI'),
    (9203, 'TA Lễ tân', '1995-01-01', '0990029203', 'LE_TAN');
INSERT INTO bac_si (ma_bac_si, so_chung_chi, ngay_cap_cc, ngay_het_han_cc, loai_bac_si) VALUES
    (9201, 'TA-CC-9201', '2020-01-01', '2031-01-01', 'DA_KHOA'),
    (9202, 'TA-CC-9202', '2020-01-01', CURRENT_DATE + 20, 'CHUYEN_KHOA');
INSERT INTO bac_si_da_khoa (ma_bac_si) VALUES (9201);
INSERT INTO bac_si_chuyen_khoa (ma_bac_si, ma_chuyen_khoa) VALUES (9202, 9201);
-- Ca: 9201 ngày mai 08–12 (có lịch hẹn 09:00), ngày kia 08–12 (trống); 9202 sau 5 ngày 08–12
INSERT INTO ca_lam_viec (ma_ca, ma_bac_si, thoi_gian_bd, thoi_gian_kt) VALUES
    (9201, 9201, CURRENT_DATE + 1 + time '08:00', CURRENT_DATE + 1 + time '12:00'),
    (9202, 9201, CURRENT_DATE + 2 + time '08:00', CURRENT_DATE + 2 + time '12:00'),
    (9203, 9202, CURRENT_DATE + 5 + time '08:00', CURRENT_DATE + 5 + time '12:00');
INSERT INTO benh_nhan (ma_bn, ho_ten, ngay_sinh, gioi_tinh, sdt) VALUES (9201, 'TA Bệnh nhân', '1990-01-01', 'NAM', '0990029291');
INSERT INTO lich_hen (ma_lh, thoi_gian_bd, thoi_gian_kt, ly_do_kham, hinh_thuc, phi_kham, phong_kham, ma_bn, ma_bac_si)
VALUES (9201, CURRENT_DATE + 1 + time '09:00', CURRENT_DATE + 1 + time '09:30', 'Khám', 'TRUC_TIEP', 150000, 'P1', 9201, 9201);
SET CONSTRAINTS ALL IMMEDIATE;   -- dữ liệu thử phải tự hợp lệ
SET CONSTRAINTS ALL DEFERRED;

-- ---------- BR-A01, BR-A02: phân lớp bác sĩ ----------
CALL pg_temp.kt('TA01', 'BR-A01', 'Bác sĩ đa khoa có thêm hàng lớp con chuyên khoa',
    $q$INSERT INTO bac_si_chuyen_khoa VALUES (9201, 9201); SET CONSTRAINTS ALL IMMEDIATE$q$, 'BR-A01');
CALL pg_temp.kt('TA02', 'BR-A01', 'Bác sĩ đa khoa không có hàng lớp con',
    $q$INSERT INTO nhan_vien (ma_nv, ho_ten, ngay_sinh, sdt, loai_nv) VALUES (9204, 'x', '1980-01-01', '0990029204', 'BAC_SI');
       INSERT INTO bac_si VALUES (9204, 'TA-CC-9204', '2020-01-01', '2031-01-01', 'DA_KHOA');
       SET CONSTRAINTS ALL IMMEDIATE$q$, 'BR-A01');
CALL pg_temp.kt('TA03', 'BR-A01', 'Thêm bác sĩ đa khoa đủ lớp cha, lớp con – hợp lệ',
    $q$INSERT INTO nhan_vien (ma_nv, ho_ten, ngay_sinh, sdt, loai_nv) VALUES (9205, 'x', '1980-01-01', '0990029205', 'BAC_SI');
       INSERT INTO bac_si VALUES (9205, 'TA-CC-9205', '2020-01-01', '2031-01-01', 'DA_KHOA');
       INSERT INTO bac_si_da_khoa VALUES (9205);
       SET CONSTRAINTS ALL IMMEDIATE; SET CONSTRAINTS ALL DEFERRED$q$, 'OK');
CALL pg_temp.kt('TA04', 'BR-A02', 'Bác sĩ chuyên khoa chưa thuộc chuyên khoa nào',
    $q$INSERT INTO nhan_vien (ma_nv, ho_ten, ngay_sinh, sdt, loai_nv) VALUES (9206, 'x', '1980-01-01', '0990029206', 'BAC_SI');
       INSERT INTO bac_si VALUES (9206, 'TA-CC-9206', '2020-01-01', '2031-01-01', 'CHUYEN_KHOA');
       SET CONSTRAINTS ALL IMMEDIATE$q$, 'BR-A02');
CALL pg_temp.kt('TA05', 'BR-A02', 'Lớp con chuyên khoa để trống chuyên khoa',
    $q$UPDATE bac_si_chuyen_khoa SET ma_chuyen_khoa = NULL WHERE ma_bac_si = 9202$q$, 'ma_chuyen_khoa');

-- ---------- BR-A03: chứng chỉ còn hạn khi xếp ca ----------
CALL pg_temp.kt('TA06', 'BR-A03', 'Xếp ca sau ngày hết hạn chứng chỉ',
    $q$INSERT INTO ca_lam_viec (ma_bac_si, thoi_gian_bd, thoi_gian_kt)
       VALUES (9202, CURRENT_DATE + 30 + time '08:00', CURRENT_DATE + 30 + time '12:00')$q$, 'BR-A03');
CALL pg_temp.kt('TA07', 'BR-A03', 'Xếp ca trước ngày cấp chứng chỉ',
    $q$INSERT INTO ca_lam_viec (ma_bac_si, thoi_gian_bd, thoi_gian_kt)
       VALUES (9202, '2019-06-03 08:00', '2019-06-03 12:00')$q$, 'BR-A03');
CALL pg_temp.kt('TA08', 'BR-A03', 'Rút ngày hết hạn chứng chỉ về trước ca đã xếp',
    $q$UPDATE bac_si SET ngay_het_han_cc = CURRENT_DATE + 3 WHERE ma_bac_si = 9202$q$, 'BR-A03');
CALL pg_temp.kt('TA09', 'BR-A03', 'Xếp ca trong thời hạn chứng chỉ – hợp lệ',
    $q$INSERT INTO ca_lam_viec (ma_bac_si, thoi_gian_bd, thoi_gian_kt)
       VALUES (9202, CURRENT_DATE + 6 + time '08:00', CURRENT_DATE + 6 + time '12:00')$q$, 'OK');

-- ---------- BR-A04: ca còn hiệu lực không chồng giờ ----------
CALL pg_temp.kt('TA10', 'BR-A04', 'Ca 11:00–13:00 chồng ca 08:00–12:00',
    $q$INSERT INTO ca_lam_viec (ma_bac_si, thoi_gian_bd, thoi_gian_kt)
       VALUES (9201, CURRENT_DATE + 1 + time '11:00', CURRENT_DATE + 1 + time '13:00')$q$, 'ex_ca_lam_viec_bac_si');
CALL pg_temp.kt('TA11', 'BR-A04', 'Ca 12:00–14:00 nối tiếp ca 08:00–12:00 – hợp lệ',
    $q$INSERT INTO ca_lam_viec (ma_bac_si, thoi_gian_bd, thoi_gian_kt)
       VALUES (9201, CURRENT_DATE + 1 + time '12:00', CURRENT_DATE + 1 + time '14:00')$q$, 'OK');
CALL pg_temp.kt('TA12', 'BR-A04', 'Ca đã hủy trùng giờ ca đang xếp – hợp lệ (ca hủy không tính)',
    $q$INSERT INTO ca_lam_viec (ma_bac_si, thoi_gian_bd, thoi_gian_kt, trang_thai)
       VALUES (9201, CURRENT_DATE + 1 + time '10:00', CURRENT_DATE + 1 + time '11:00', 'HUY')$q$, 'OK');

-- ---------- BR-A05, A06, A07 ----------
CALL pg_temp.kt('TA13', 'BR-A05', 'Hai bác sĩ trùng số chứng chỉ',
    $q$UPDATE bac_si SET so_chung_chi = 'TA-CC-9201' WHERE ma_bac_si = 9202$q$, 'bac_si_so_chung_chi_key');
CALL pg_temp.kt('TA14', 'BR-A06', 'Ca kết thúc đúng lúc bắt đầu',
    $q$INSERT INTO ca_lam_viec (ma_bac_si, thoi_gian_bd, thoi_gian_kt)
       VALUES (9201, CURRENT_DATE + 3 + time '08:00', CURRENT_DATE + 3 + time '08:00')$q$, 'ck_ca_lam_viec_thoi_gian');
CALL pg_temp.kt('TA15', 'BR-A07', 'Ngày hết hạn chứng chỉ trước ngày cấp',
    $q$INSERT INTO nhan_vien (ma_nv, ho_ten, ngay_sinh, sdt, loai_nv) VALUES (9207, 'x', '1980-01-01', '0990029207', 'BAC_SI');
       INSERT INTO bac_si VALUES (9207, 'TA-CC-9207', '2025-01-01', '2024-01-01', 'DA_KHOA')$q$, 'ck_bac_si_han_giay_phep');

-- ---------- BR-A08: sửa, hủy, xóa ca không làm lịch hẹn rơi ngoài ca ----------
CALL pg_temp.kt('TA16', 'BR-A08', 'Hủy ca đang có lịch hẹn còn hiệu lực',
    $q$UPDATE ca_lam_viec SET trang_thai = 'HUY' WHERE ma_ca = 9201$q$, 'BR-A08');
CALL pg_temp.kt('TA17', 'BR-A08', 'Thu ngắn ca để lịch hẹn 09:00 rơi ra ngoài',
    $q$UPDATE ca_lam_viec SET thoi_gian_kt = CURRENT_DATE + 1 + time '09:00' WHERE ma_ca = 9201$q$, 'BR-A08');
CALL pg_temp.kt('TA18', 'BR-A08', 'Xóa ca đang có lịch hẹn còn hiệu lực',
    $q$DELETE FROM ca_lam_viec WHERE ma_ca = 9201$q$, 'BR-A08');
CALL pg_temp.kt('TA19', 'BR-A08', 'Thu ngắn ca nhưng lịch hẹn vẫn nằm trong ca – hợp lệ',
    $q$UPDATE ca_lam_viec SET thoi_gian_kt = CURRENT_DATE + 1 + time '10:00' WHERE ma_ca = 9201$q$, 'OK');
CALL pg_temp.kt('TA20', 'BR-A08', 'Hủy ca không có lịch hẹn – hợp lệ, ca vẫn được giữ',
    $q$UPDATE ca_lam_viec SET trang_thai = 'HUY' WHERE ma_ca = 9202$q$, 'OK');

-- ---------- BR-A10: loại nhân viên ----------
CALL pg_temp.kt('TA21', 'BR-A10', 'Lễ tân có thông tin bác sĩ',
    $q$INSERT INTO bac_si VALUES (9203, 'TA-CC-9203', '2020-01-01', '2031-01-01', 'DA_KHOA');
       INSERT INTO bac_si_da_khoa VALUES (9203);
       SET CONSTRAINTS ALL IMMEDIATE$q$, 'BR-A10');
CALL pg_temp.kt('TA22', 'BR-A10', 'Đổi bác sĩ đang có thông tin bác sĩ thành lễ tân',
    $q$UPDATE nhan_vien SET loai_nv = 'LE_TAN' WHERE ma_nv = 9201; SET CONSTRAINTS ALL IMMEDIATE$q$, 'BR-A10');
CALL pg_temp.kt('TA23', 'BR-A10', 'Loại nhân viên ngoài miền giá trị',
    $q$UPDATE nhan_vien SET loai_nv = 'DIEU_DUONG' WHERE ma_nv = 9203$q$, 'nhan_vien_loai_nv_check');

-- ---------- Ràng buộc chung, khóa ngoại ----------
CALL pg_temp.kt('TA24', 'Chung', 'Trùng số điện thoại nhân viên',
    $q$UPDATE nhan_vien SET sdt = '0990029201' WHERE ma_nv = 9203$q$, 'nhan_vien_sdt_key');
CALL pg_temp.kt('TA25', 'Chung', 'Trùng tên chuyên khoa',
    $q$INSERT INTO chuyen_khoa (ten_chuyen_khoa) VALUES ('TA Tim mạch')$q$, 'chuyen_khoa_ten_chuyen_khoa_key');
CALL pg_temp.kt('TA26', 'Chung', 'Xóa chuyên khoa còn bác sĩ',
    $q$DELETE FROM chuyen_khoa WHERE ma_chuyen_khoa = 9201$q$, 'fk_bac_si_chuyen_khoa_chuyen_khoa');
CALL pg_temp.kt('TA27', 'Chung', 'Xóa bác sĩ còn ca làm việc',
    $q$DELETE FROM bac_si WHERE ma_bac_si = 9202$q$, 'fk_ca_lam_viec_bac_si');

-- ---------- View ----------
CALL pg_temp.kt_dung('TA28', 'View', 'v_lich_truc_bac_si chỉ có ca đang xếp của dữ liệu thử, bác sĩ đa khoa ghi "Đa khoa"',
    $q$SELECT count(*) FILTER (WHERE ma_bac_si = 9201) = 2
          AND bool_and(chuyen_khoa = 'Đa khoa') FILTER (WHERE ma_bac_si = 9201)
          AND bool_and(chuyen_khoa = 'TA Tim mạch') FILTER (WHERE ma_bac_si = 9202)
       FROM v_lich_truc_bac_si WHERE ma_bac_si BETWEEN 9201 AND 9299$q$);

-- ---------- BR-A09: chỉ quản trị nhân sự thêm, sửa; bác sĩ, lễ tân chỉ xem ----------
CALL pg_temp.kt('TA29', 'BR-A09', 'Lễ tân sửa giờ một ca làm việc',
    $q$SET LOCAL ROLE r_le_tan;
       UPDATE ca_lam_viec SET thoi_gian_kt = thoi_gian_kt + INTERVAL '1 hour' WHERE ma_ca = 9203$q$, 'permission denied');
CALL pg_temp.kt('TA30', 'BR-A09', 'Bác sĩ tự thêm ca làm việc',
    $q$SET LOCAL ROLE r_bac_si;
       INSERT INTO ca_lam_viec (ma_ca, ma_bac_si, thoi_gian_bd, thoi_gian_kt)
       VALUES (9209, 9201, CURRENT_DATE + 4 + time '08:00', CURRENT_DATE + 4 + time '12:00')$q$, 'permission denied');
CALL pg_temp.kt('TA31', 'BR-A09', 'Quản trị danh mục sửa ca làm việc',
    $q$SET LOCAL ROLE r_quan_tri_danh_muc;
       UPDATE ca_lam_viec SET trang_thai = 'HUY' WHERE ma_ca = 9203$q$, 'permission denied');
CALL pg_temp.kt('TA32', 'BR-A09', 'Lễ tân sửa thông tin bác sĩ',
    $q$SET LOCAL ROLE r_le_tan;
       UPDATE nhan_vien SET email = 'x@y.vn' WHERE ma_nv = 9201$q$, 'permission denied');
CALL pg_temp.kt('TA33', 'BR-A09', 'Bác sĩ, lễ tân xem lịch trực – hợp lệ',
    $q$SET LOCAL ROLE r_bac_si; SELECT count(*) FROM ca_lam_viec; SELECT count(*) FROM v_lich_truc_bac_si;
       SET LOCAL ROLE r_le_tan; SELECT count(*) FROM ca_lam_viec; SELECT count(*) FROM v_lich_truc_bac_si$q$, 'OK');
CALL pg_temp.kt('TA34', 'BR-A09', 'Quản trị nhân sự sửa giờ ca, thêm lễ tân – hợp lệ',
    $q$SET LOCAL ROLE r_quan_tri_nhan_su;
       UPDATE ca_lam_viec SET thoi_gian_kt = thoi_gian_kt + INTERVAL '1 hour' WHERE ma_ca = 9203;
       INSERT INTO nhan_vien (ho_ten, ngay_sinh, sdt, loai_nv) VALUES ('TA Lễ tân 2', '1997-01-01', '0990029208', 'LE_TAN')$q$, 'OK');
CALL pg_temp.kt('TA35', 'BR-A09', 'Quản trị nhân sự xóa ca (ca hủy phải giữ lại)',
    $q$SET LOCAL ROLE r_quan_tri_nhan_su; DELETE FROM ca_lam_viec WHERE ma_ca = 9202$q$, 'permission denied');

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
