-- T40 – Bốn truy vấn phức tạp mảng A (PostgreSQL 16)

-- Q1. Lịch trực sắp tới và số lịch hẹn còn hiệu lực nằm trong từng ca.
SELECT v.ma_ca, v.ma_bac_si, v.ten_bac_si, v.chuyen_khoa,
       v.thoi_gian_bd, v.thoi_gian_kt,
       COUNT(l.ma_lh) AS so_lich_hen,
       COALESCE(SUM(EXTRACT(EPOCH FROM (l.thoi_gian_kt - l.thoi_gian_bd)) / 60), 0)::INTEGER AS tong_phut_kham
FROM v_lich_truc_bac_si v
LEFT JOIN lich_hen l ON l.ma_bac_si = v.ma_bac_si
    AND l.trang_thai NOT IN ('HUY', 'VANG_MAT')
    AND l.thoi_gian_bd >= v.thoi_gian_bd AND l.thoi_gian_kt <= v.thoi_gian_kt
WHERE v.thoi_gian_kt >= CURRENT_TIMESTAMP
GROUP BY v.ma_ca, v.ma_bac_si, v.ten_bac_si, v.chuyen_khoa, v.thoi_gian_bd, v.thoi_gian_kt
ORDER BY v.thoi_gian_bd, v.ten_bac_si;

-- Q2. Bác sĩ có tổng giờ ca đã xếp lớn hơn mức trung bình của các bác sĩ trong cùng loại.
WITH gio_theo_bac_si AS (
    SELECT b.ma_bac_si, nv.ho_ten, b.loai_bac_si,
           SUM(EXTRACT(EPOCH FROM (c.thoi_gian_kt - c.thoi_gian_bd)) / 3600) AS tong_gio
    FROM bac_si b
    JOIN nhan_vien nv ON nv.ma_nv = b.ma_bac_si
    JOIN ca_lam_viec c ON c.ma_bac_si = b.ma_bac_si AND c.trang_thai = 'DA_XEP'
    GROUP BY b.ma_bac_si, nv.ho_ten, b.loai_bac_si
)
SELECT g.ma_bac_si, g.ho_ten, g.loai_bac_si, ROUND(g.tong_gio::numeric, 2) AS tong_gio
FROM gio_theo_bac_si g
WHERE g.tong_gio > (
    SELECT AVG(g2.tong_gio) FROM gio_theo_bac_si g2 WHERE g2.loai_bac_si = g.loai_bac_si
)
ORDER BY g.tong_gio DESC;

-- Q3. Bác sĩ chưa từng được xếp ca còn hiệu lực (NOT EXISTS).
SELECT b.ma_bac_si, nv.ho_ten, b.loai_bac_si, b.ngay_het_han_cc
FROM bac_si b
JOIN nhan_vien nv ON nv.ma_nv = b.ma_bac_si
WHERE NOT EXISTS (
    SELECT 1 FROM ca_lam_viec c
    WHERE c.ma_bac_si = b.ma_bac_si AND c.trang_thai = 'DA_XEP'
);

-- Q4. Chuyên khoa có ít nhất hai bác sĩ có ca trực trong khoảng thời gian truyền vào.
-- Khoảng [tu_luc, den_luc) khai báo trong CTE params như queries_C.sql; đổi giá trị khi trình diễn.
WITH params AS (
    SELECT TIMESTAMP '2026-01-01 00:00:00' AS tu_luc,
           TIMESTAMP '2027-01-01 00:00:00' AS den_luc
)
SELECT ck.ma_chuyen_khoa, ck.ten_chuyen_khoa,
       COUNT(DISTINCT bck.ma_bac_si) AS so_bac_si,
       COUNT(DISTINCT c.ma_ca) AS so_ca,
       MIN(c.thoi_gian_bd) AS ca_dau_tien,
       MAX(c.thoi_gian_kt) AS ca_cuoi_cung
FROM params p
JOIN ca_lam_viec c ON c.thoi_gian_bd >= p.tu_luc AND c.thoi_gian_bd < p.den_luc
    AND c.trang_thai = 'DA_XEP'
JOIN bac_si_chuyen_khoa bck ON bck.ma_bac_si = c.ma_bac_si
JOIN chuyen_khoa ck ON ck.ma_chuyen_khoa = bck.ma_chuyen_khoa
GROUP BY ck.ma_chuyen_khoa, ck.ten_chuyen_khoa
HAVING COUNT(DISTINCT bck.ma_bac_si) >= 2
ORDER BY so_bac_si DESC, so_ca DESC;
