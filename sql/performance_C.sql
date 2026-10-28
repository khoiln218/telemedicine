-- T44 – Đo hiệu năng truy vấn mảng C (PostgreSQL 16).
-- Chạy sau seed.sql; ghi lại actual time, rows, buffers trước/sau index nếu cần so sánh.
-- EXPLAIN ANALYZE thực thi SELECT nhưng không ghi dữ liệu.

ANALYZE lan_kham;
ANALYZE chan_doan;
ANALYZE don_thuoc;
ANALYZE chi_tiet_don_thuoc;
ANALYZE thuoc;
ANALYZE thuoc_hoat_chat;
ANALYZE di_ung;

EXPLAIN (ANALYZE, BUFFERS, VERBOSE)
SELECT l.ma_bn, k.ma_lan_kham, cd.ma_icd10
  FROM chan_doan cd
  JOIN lan_kham k ON k.ma_lan_kham = cd.ma_lan_kham
  JOIN lich_hen l ON l.ma_lh = k.ma_lh
 WHERE cd.trang_thai = 'HIEU_LUC'
   AND l.ma_bn = (SELECT ma_bn FROM lich_hen ORDER BY ma_lh LIMIT 1);

EXPLAIN (ANALYZE, BUFFERS, VERBOSE)
SELECT t.ma_thuoc, t.ten_thuoc, COUNT(*) AS so_luot
  FROM don_thuoc d
  JOIN chi_tiet_don_thuoc ct ON ct.ma_don = d.ma_don
  JOIN thuoc t ON t.ma_thuoc = ct.ma_thuoc
 WHERE d.trang_thai = 'HIEU_LUC'
   AND d.thoi_diem_ke >= TIMESTAMP '2026-01-01'
   AND d.thoi_diem_ke < TIMESTAMP '2027-01-01'
 GROUP BY t.ma_thuoc, t.ten_thuoc
 ORDER BY so_luot DESC;

EXPLAIN (ANALYZE, BUFFERS, VERBOSE)
SELECT l.ma_bn, th.ma_hoat_chat
  FROM chi_tiet_don_thuoc ct
  JOIN don_thuoc d ON d.ma_don = ct.ma_don
  JOIN lan_kham k ON k.ma_lan_kham = d.ma_lan_kham
  JOIN lich_hen l ON l.ma_lh = k.ma_lh
  JOIN thuoc_hoat_chat th ON th.ma_thuoc = ct.ma_thuoc
  JOIN di_ung du ON du.ma_bn = l.ma_bn AND du.ma_hoat_chat = th.ma_hoat_chat
 WHERE d.trang_thai = 'HIEU_LUC';
