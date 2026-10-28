-- T44 – Kiểm thử hiệu năng: EXPLAIN ANALYZE trước và sau chỉ mục (báo cáo mục 4.2.3).
-- Đo trên CSDL riêng có dữ liệu 1 năm hoạt động (khoảng 52.000 lịch hẹn, 43.000 lần khám):
--   createdb ... && psql -f sql/schema.sql, A/B/C_trigger_view.sql
--   psql -v so_ngay=365 -f sql/seed.sql
--   psql -f sql/performance.sql
-- "Trước chỉ mục": trong một giao dịch tạm bỏ chỉ mục (kể cả ràng buộc EXCLUDE có chỉ mục GiST trên cùng cột),
-- đo, rồi ROLLBACK nên CSDL không đổi. Cần quyền chủ sở hữu bảng. EXPLAIN ANALYZE chỉ đọc, không ghi dữ liệu.
-- Bệnh nhân 1, bác sĩ 1 là khách quen, bác sĩ đa khoa trong dữ liệu mẫu.
\set ON_ERROR_STOP on
ANALYZE;

\echo '===== PT-01 Lịch hẹn hôm nay (v_lich_hen_hom_nay, màn hình lễ tân) – idx_lich_hen_thoi_gian'
\echo '--- Trước chỉ mục (bỏ cả hai chỉ mục ghép có thoi_gian_bd, nếu không planner quét toàn bộ chỉ mục ghép để lọc)'
BEGIN;
DROP INDEX idx_lich_hen_thoi_gian, idx_lich_hen_bac_si, idx_lich_hen_benh_nhan;
EXPLAIN (ANALYZE, BUFFERS) SELECT * FROM v_lich_hen_hom_nay;
ROLLBACK;
\echo '--- Sau chỉ mục'
EXPLAIN (ANALYZE, BUFFERS) SELECT * FROM v_lich_hen_hom_nay;

\echo '===== PT-02 Lịch hẹn của một bệnh nhân (v_lich_hen_cua_toi) – idx_lich_hen_benh_nhan'
\echo '--- Trước chỉ mục'
BEGIN;
SET LOCAL app.ma_bn = '1';
DROP INDEX idx_lich_hen_benh_nhan;
ALTER TABLE lich_hen DROP CONSTRAINT ex_lich_hen_benh_nhan;
EXPLAIN (ANALYZE, BUFFERS) SELECT * FROM v_lich_hen_cua_toi;
ROLLBACK;
\echo '--- Sau chỉ mục'
BEGIN;
SET LOCAL app.ma_bn = '1';
EXPLAIN (ANALYZE, BUFFERS) SELECT * FROM v_lich_hen_cua_toi;
ROLLBACK;

\echo '===== PT-03 Lịch trực 7 ngày tới của một bác sĩ (v_lich_truc_bac_si; cùng điều kiện trigger BR-B01) – idx_ca_lam_viec_bac_si_thoi_gian'
\echo '--- Trước chỉ mục'
BEGIN;
DROP INDEX idx_ca_lam_viec_bac_si_thoi_gian;
ALTER TABLE ca_lam_viec DROP CONSTRAINT ex_ca_lam_viec_bac_si;
EXPLAIN (ANALYZE, BUFFERS)
SELECT * FROM v_lich_truc_bac_si
WHERE ma_bac_si = 1 AND thoi_gian_bd >= CURRENT_DATE AND thoi_gian_bd < CURRENT_DATE + 7;
ROLLBACK;
\echo '--- Sau chỉ mục'
EXPLAIN (ANALYZE, BUFFERS)
SELECT * FROM v_lich_truc_bac_si
WHERE ma_bac_si = 1 AND thoi_gian_bd >= CURRENT_DATE AND thoi_gian_bd < CURRENT_DATE + 7;

\echo '===== PT-04 Hồ sơ lâm sàng một bệnh nhân (lõi Q11: lịch hẹn → lần khám → chẩn đoán, đơn, thuốc) – idx_lich_hen_benh_nhan, idx_chan_doan_lan_kham, idx_don_thuoc_lan_kham'
\echo '--- Trước chỉ mục'
BEGIN;
DROP INDEX idx_lich_hen_benh_nhan, idx_chan_doan_lan_kham, idx_don_thuoc_lan_kham;
ALTER TABLE lich_hen DROP CONSTRAINT ex_lich_hen_benh_nhan;
EXPLAIN (ANALYZE, BUFFERS)
SELECT k.ma_lan_kham, k.thoi_diem_kham, cd.ma_icd10, d.ma_don, ct.ma_thuoc, ct.so_luong
FROM lich_hen l
JOIN lan_kham k ON k.ma_lh = l.ma_lh
LEFT JOIN chan_doan cd ON cd.ma_lan_kham = k.ma_lan_kham AND cd.trang_thai = 'HIEU_LUC'
LEFT JOIN don_thuoc d ON d.ma_lan_kham = k.ma_lan_kham AND d.trang_thai = 'HIEU_LUC'
LEFT JOIN chi_tiet_don_thuoc ct ON ct.ma_don = d.ma_don
WHERE l.ma_bn = 1;
ROLLBACK;
\echo '--- Sau chỉ mục'
EXPLAIN (ANALYZE, BUFFERS)
SELECT k.ma_lan_kham, k.thoi_diem_kham, cd.ma_icd10, d.ma_don, ct.ma_thuoc, ct.so_luong
FROM lich_hen l
JOIN lan_kham k ON k.ma_lh = l.ma_lh
LEFT JOIN chan_doan cd ON cd.ma_lan_kham = k.ma_lan_kham AND cd.trang_thai = 'HIEU_LUC'
LEFT JOIN don_thuoc d ON d.ma_lan_kham = k.ma_lan_kham AND d.trang_thai = 'HIEU_LUC'
LEFT JOIN chi_tiet_don_thuoc ct ON ct.ma_don = d.ma_don
WHERE l.ma_bn = 1;

\echo '===== PT-05 Thuốc kê nhiều nhất trong quý (Q09) – idx_don_thuoc_ngay_hieu_luc'
\echo '--- Trước chỉ mục (bỏ cả idx_don_thuoc_lan_kham vì cũng có cột thoi_diem_ke)'
BEGIN;
DROP INDEX idx_don_thuoc_ngay_hieu_luc, idx_don_thuoc_lan_kham;
EXPLAIN (ANALYZE, BUFFERS)
SELECT t.ma_thuoc, t.ten_thuoc, count(*) AS so_don_co_ke, sum(ct.so_luong) AS tong_so_luong
FROM don_thuoc d
JOIN chi_tiet_don_thuoc ct ON ct.ma_don = d.ma_don
JOIN thuoc t ON t.ma_thuoc = ct.ma_thuoc
WHERE d.trang_thai = 'HIEU_LUC'
  AND d.thoi_diem_ke >= date_trunc('quarter', CURRENT_DATE)
  AND d.thoi_diem_ke <  date_trunc('quarter', CURRENT_DATE) + INTERVAL '3 months'
GROUP BY t.ma_thuoc, t.ten_thuoc ORDER BY so_don_co_ke DESC LIMIT 10;
ROLLBACK;
\echo '--- Sau chỉ mục'
EXPLAIN (ANALYZE, BUFFERS)
SELECT t.ma_thuoc, t.ten_thuoc, count(*) AS so_don_co_ke, sum(ct.so_luong) AS tong_so_luong
FROM don_thuoc d
JOIN chi_tiet_don_thuoc ct ON ct.ma_don = d.ma_don
JOIN thuoc t ON t.ma_thuoc = ct.ma_thuoc
WHERE d.trang_thai = 'HIEU_LUC'
  AND d.thoi_diem_ke >= date_trunc('quarter', CURRENT_DATE)
  AND d.thoi_diem_ke <  date_trunc('quarter', CURRENT_DATE) + INTERVAL '3 months'
GROUP BY t.ma_thuoc, t.ten_thuoc ORDER BY so_don_co_ke DESC LIMIT 10;

\echo '===== PT-06 Tỷ lệ hủy, vắng theo bác sĩ (Q05, tổng hợp toàn bảng) – idx_lich_hen_bac_si'
\echo '--- Trước chỉ mục'
BEGIN;
DROP INDEX idx_lich_hen_bac_si;
EXPLAIN (ANALYZE, BUFFERS)
SELECT l.ma_bac_si, count(*) AS so_lich_ket_thuc,
       count(*) FILTER (WHERE l.trang_thai IN ('HUY', 'VANG_MAT')) AS so_huy_vang
FROM lich_hen l
WHERE l.trang_thai IN ('HOAN_THANH', 'HUY', 'VANG_MAT')
GROUP BY l.ma_bac_si;
ROLLBACK;
\echo '--- Sau chỉ mục'
EXPLAIN (ANALYZE, BUFFERS)
SELECT l.ma_bac_si, count(*) AS so_lich_ket_thuc,
       count(*) FILTER (WHERE l.trang_thai IN ('HUY', 'VANG_MAT')) AS so_huy_vang
FROM lich_hen l
WHERE l.trang_thai IN ('HOAN_THANH', 'HUY', 'VANG_MAT')
GROUP BY l.ma_bac_si;
