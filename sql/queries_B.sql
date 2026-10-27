-- T41 – 4 truy vấn phức tạp mảng B: Bệnh nhân & Lịch hẹn
-- Người viết / review: Lê Ngọc Khôi / Nguyễn Đăng Khoa – 27/10/2026
-- Chạy sau schema.sql, trigger, seed.sql. Dùng thêm bảng mảng A: nhan_vien, bac_si_chuyen_khoa, chuyen_khoa.
--
-- Quy ước chung:
--   "khám" là lịch hẹn HOAN_THANH; doanh thu là tổng phi_kham của lịch HOAN_THANH;
--   chuyên khoa của lịch hẹn lấy qua bác sĩ (T08 mục 5), bác sĩ đa khoa ghi 'Đa khoa'.


-- Q1. Tỷ lệ hủy, vắng mặt theo bác sĩ
-- Chỉ tính lịch đã kết thúc (HOAN_THANH, HUY, VANG_MAT); bỏ bác sĩ có dưới 5 lịch để tỷ lệ có ý nghĩa.
-- Kỹ thuật: JOIN 4 bảng (2 LEFT JOIN), hàm tổng hợp có FILTER, GROUP BY, HAVING.
SELECT nv.ma_nv                                  AS ma_bac_si,
       nv.ho_ten                                 AS bac_si,
       COALESCE(ck.ten_chuyen_khoa, 'Đa khoa')   AS chuyen_khoa,
       count(*)                                  AS so_lich_ket_thuc,
       count(*) FILTER (WHERE l.trang_thai = 'HUY')      AS so_huy,
       count(*) FILTER (WHERE l.trang_thai = 'VANG_MAT') AS so_vang_mat,
       round(100.0 * count(*) FILTER (WHERE l.trang_thai IN ('HUY', 'VANG_MAT')) / count(*), 1)
                                                 AS ty_le_huy_vang_pct
FROM lich_hen l
JOIN nhan_vien nv                ON nv.ma_nv = l.ma_bac_si
LEFT JOIN bac_si_chuyen_khoa bck ON bck.ma_bac_si = l.ma_bac_si
LEFT JOIN chuyen_khoa ck         ON ck.ma_chuyen_khoa = bck.ma_chuyen_khoa
WHERE l.trang_thai IN ('HOAN_THANH', 'HUY', 'VANG_MAT')
GROUP BY nv.ma_nv, nv.ho_ten, ck.ten_chuyen_khoa
HAVING count(*) >= 5
ORDER BY ty_le_huy_vang_pct DESC, so_lich_ket_thuc DESC, ma_bac_si;


-- Q2. Doanh thu theo chuyên khoa theo tháng, kèm tỷ trọng trong tháng
-- Kỹ thuật: LEFT JOIN, GROUP BY theo biểu thức (tháng), hàm tổng hợp, hàm cửa sổ lồng hàm tổng hợp
-- (SUM(SUM(...)) OVER (PARTITION BY tháng)).
SELECT to_char(date_trunc('month', l.thoi_gian_bd), 'YYYY-MM') AS thang,
       COALESCE(ck.ten_chuyen_khoa, 'Đa khoa')                 AS chuyen_khoa,
       count(*)                                                AS so_luot_kham,
       sum(l.phi_kham)                                         AS doanh_thu,
       round(100.0 * sum(l.phi_kham)
             / NULLIF(sum(sum(l.phi_kham)) OVER (PARTITION BY date_trunc('month', l.thoi_gian_bd)), 0), 1)
                                                               AS ty_trong_thang_pct
FROM lich_hen l
LEFT JOIN bac_si_chuyen_khoa bck ON bck.ma_bac_si = l.ma_bac_si
LEFT JOIN chuyen_khoa ck         ON ck.ma_chuyen_khoa = bck.ma_chuyen_khoa
WHERE l.trang_thai = 'HOAN_THANH'
GROUP BY date_trunc('month', l.thoi_gian_bd), ck.ten_chuyen_khoa
ORDER BY thang, doanh_thu DESC, chuyen_khoa;


-- Q3. Bệnh nhân khám nhiều hơn 3 lần trong 6 tháng gần nhất, có tài khoản hay chưa
-- (lễ tân dùng để mời bệnh nhân thường xuyên tạo tài khoản xem lịch hẹn).
-- Kỹ thuật: subquery trong FROM có GROUP BY, HAVING; subquery tương quan EXISTS.
SELECT bn.ma_bn,
       bn.ho_ten,
       bn.sdt,
       k.so_lan_kham,
       k.lan_kham_gan_nhat,
       EXISTS (SELECT 1 FROM tai_khoan tk WHERE tk.ma_bn = bn.ma_bn) AS co_tai_khoan
FROM benh_nhan bn
JOIN (
    SELECT ma_bn,
           count(*)          AS so_lan_kham,
           max(thoi_gian_bd) AS lan_kham_gan_nhat
    FROM lich_hen
    WHERE trang_thai = 'HOAN_THANH'
      AND thoi_gian_bd >= CURRENT_DATE - INTERVAL '6 months'
    GROUP BY ma_bn
    HAVING count(*) > 3
) k ON k.ma_bn = bn.ma_bn
ORDER BY k.so_lan_kham DESC, bn.ho_ten;


-- Q4. Khung giờ đông nhất và tỷ lệ tư vấn từ xa so với khám trực tiếp
-- Tính mọi lịch trừ lịch đã hủy (lịch vắng mặt vẫn chiếm giờ đã xếp). Khung giờ theo giờ bắt đầu.
-- Dòng 'Tổng' (ROLLUP) cho tỷ lệ từ xa chung; hang_dong xếp hạng khung giờ theo số lịch.
-- Kỹ thuật: subquery trong FROM, GROUP BY ROLLUP, GROUPING(), FILTER, hàm cửa sổ RANK().
SELECT CASE WHEN GROUPING(gio) = 1 THEN 'Tổng'
            ELSE lpad(gio::text, 2, '0') || ':00–' || lpad((gio + 1)::text, 2, '0') || ':00'
       END                                                    AS khung_gio,
       count(*)                                               AS so_lich,
       count(*) FILTER (WHERE hinh_thuc = 'TRUC_TIEP')        AS truc_tiep,
       count(*) FILTER (WHERE hinh_thuc = 'TU_XA')            AS tu_xa,
       round(100.0 * count(*) FILTER (WHERE hinh_thuc = 'TU_XA') / count(*), 1) AS ty_le_tu_xa_pct,
       CASE WHEN GROUPING(gio) = 0
            THEN rank() OVER (PARTITION BY GROUPING(gio) ORDER BY count(*) DESC)
       END                                                    AS hang_dong
FROM (
    SELECT extract(hour FROM thoi_gian_bd)::int AS gio, hinh_thuc
    FROM lich_hen
    WHERE trang_thai <> 'HUY'
) l
GROUP BY ROLLUP (gio)
ORDER BY GROUPING(gio), gio;
