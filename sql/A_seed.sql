-- T39 – Dữ liệu mẫu mảng A: nhân viên, bác sĩ, chuyên khoa, ca làm việc (dữ liệu giả lập).
-- Chạy sau schema.sql và A/B/C_trigger_view.sql; gọi từ seed.sql.
-- Quy mô theo báo cáo mục 1: một cơ sở, 20 bác sĩ (8 đa khoa, 12 chuyên khoa thuộc 6 chuyên khoa);
-- điều dưỡng không lưu trong CSDL (T07 mục 5) nên chỉ có lễ tân và quản trị. Phòng khám đã hoạt động
-- 3 tháng: ca làm việc từ 91 ngày trước đến 14 ngày tới, tính theo CURRENT_DATE.
-- Mã nhân viên, chuyên khoa 1–99; tests_B.sql dùng 9101–9199 nên không đụng nhau.

BEGIN;  -- phân lớp bác sĩ kiểm tra bằng constraint trigger trì hoãn tới cuối giao dịch

INSERT INTO chuyen_khoa (ma_chuyen_khoa, ten_chuyen_khoa) VALUES
    (1, 'Tim mạch'), (2, 'Da liễu'), (3, 'Nhi khoa'), (4, 'Tai mũi họng'), (5, 'Tiêu hóa'), (6, 'Nội tiết');

INSERT INTO nhan_vien (ma_nv, ho_ten, ngay_sinh, sdt, email, loai_nv)
SELECT v.ma_nv, v.ho_ten, v.ngay_sinh::date, '0901000' || lpad(v.ma_nv::text, 3, '0'),
       CASE WHEN v.ma_nv % 3 <> 0 THEN 'nv' || lpad(v.ma_nv::text, 3, '0') || '@phongkham.example' END,
       CASE WHEN v.ma_nv <= 20 THEN 'BAC_SI' WHEN v.ma_nv <= 24 THEN 'LE_TAN'
            WHEN v.ma_nv = 25 THEN 'QUAN_TRI_NHAN_SU' WHEN v.ma_nv = 26 THEN 'QUAN_TRI_TAI_KHOAN'
            ELSE 'QUAN_TRI_DANH_MUC' END
FROM (VALUES
    (1, 'Nguyễn Văn An', '1978-03-12'),     (2, 'Trần Thị Bình', '1982-07-25'),
    (3, 'Lê Hoàng Cường', '1986-11-02'),    (4, 'Phạm Thị Dung', '1990-02-17'),
    (5, 'Võ Minh Đạt', '1984-09-30'),       (6, 'Đặng Thu Giang', '1988-12-08'),
    (7, 'Bùi Quốc Hùng', '1979-05-22'),     (8, 'Phan Ngọc Hân', '1992-01-14'),
    (9, 'Phạm Minh Đức', '1975-01-30'),     (10, 'Huỳnh Thị Hồng', '1983-06-03'),
    (11, 'Vũ Thanh Hương', '1988-09-09'),   (12, 'Lý Văn Kiên', '1987-04-19'),
    (13, 'Đỗ Quang Khải', '1980-12-21'),    (14, 'Ngô Thị Lan', '1985-08-11'),
    (15, 'Trịnh Văn Long', '1981-10-27'),   (16, 'Mai Thị Minh', '1989-03-05'),
    (17, 'Hồ Đức Nghĩa', '1977-07-16'),     (18, 'Dương Thị Oanh', '1986-05-29'),
    (19, 'Lâm Quốc Phong', '1983-11-13'),   (20, 'Tạ Ngọc Quyên', '1994-04-14'),
    (21, 'Ngô Thị Mai', '1996-02-03'),      (22, 'Đặng Văn Nam', '1998-08-27'),
    (23, 'Chu Thị Nga', '1997-06-21'),      (24, 'Kiều Văn Sơn', '1999-01-09'),
    (25, 'Lý Thị Oanh', '1985-06-11'),      (26, 'Trịnh Văn Phúc', '1990-10-05'),
    (27, 'Mai Thị Quỳnh', '1991-03-19')) AS v(ma_nv, ho_ten, ngay_sinh);

-- 1–8 đa khoa; 9–20 chuyên khoa, mỗi chuyên khoa hai bác sĩ. Bác sĩ 20 mới vào, chưa xếp ca (Q3).
INSERT INTO bac_si (ma_bac_si, so_chung_chi, ngay_cap_cc, ngay_het_han_cc, loai_bac_si)
SELECT i, lpad((100 + i)::text, 6, '0') || '/BYT-CCHN',
       CASE WHEN i = 20 THEN DATE '2026-09-01' ELSE DATE '2020-01-15' + i * 97 END,
       CASE WHEN i = 20 THEN DATE '2031-09-01' ELSE DATE '2030-01-15' + i * 97 END,
       CASE WHEN i <= 8 THEN 'DA_KHOA' ELSE 'CHUYEN_KHOA' END
FROM generate_series(1, 20) AS i;
INSERT INTO bac_si_da_khoa (ma_bac_si) SELECT i FROM generate_series(1, 8) AS i;
INSERT INTO bac_si_chuyen_khoa (ma_bac_si, ma_chuyen_khoa) SELECT i, (i - 9) / 2 + 1 FROM generate_series(9, 20) AS i;

-- Ca sáng 07:30–11:30 thứ 2–7, ca chiều 13:30–17:00 thứ 2–6. Bác sĩ chuyên khoa nghỉ một ngày trong tuần,
-- bác sĩ đa khoa nghỉ một buổi chiều, lệch nhau giữa các bác sĩ (tổng giờ khác nhau cho Q2).
INSERT INTO ca_lam_viec (thoi_gian_bd, thoi_gian_kt, ma_bac_si)
SELECT d::date + v.bd, d::date + v.kt, b
FROM generate_series(CURRENT_DATE - 91, CURRENT_DATE + 14, INTERVAL '1 day') AS g(d)
CROSS JOIN generate_series(1, 19) AS b
CROSS JOIN (VALUES (time '07:30', time '11:30', false), (time '13:30', time '17:00', true)) AS v(bd, kt, chieu)
WHERE extract(isodow FROM d) <= 6
  AND (b <= 8 OR extract(isodow FROM d) <> 1 + b % 6)
  AND (NOT v.chieu OR (extract(isodow FROM d) <= 5 AND (b > 8 OR extract(isodow FROM d) <> 1 + b % 5)));

-- Ca hủy được giữ lại với trạng thái HUY (T07 mục 5): ca chiều gần nhất sắp tới của bác sĩ 11.
UPDATE ca_lam_viec SET trang_thai = 'HUY'
WHERE ma_ca = (SELECT ma_ca FROM ca_lam_viec
               WHERE ma_bac_si = 11 AND thoi_gian_bd > CURRENT_DATE + 1
                 AND thoi_gian_bd::time = time '13:30'
               ORDER BY thoi_gian_bd LIMIT 1);

COMMIT;

SELECT setval(pg_get_serial_sequence('nhan_vien', 'ma_nv'), (SELECT max(ma_nv) FROM nhan_vien));
SELECT setval(pg_get_serial_sequence('chuyen_khoa', 'ma_chuyen_khoa'), (SELECT max(ma_chuyen_khoa) FROM chuyen_khoa));
