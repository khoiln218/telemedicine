-- T43 – Bộ test ràng buộc tích hợp ba mảng (báo cáo mục 5.1).
-- Chạy sau schema.sql, A/B/C_trigger_view.sql, seed.sql và rbac.sql:
--   psql -d telemedicine -f sql/tests.sql
-- Mỗi file tự tạo dữ liệu thử (A: mã 9201–9299, B: 9101–9199; C dùng dữ liệu mẫu), in bảng kết quả
-- từng ca và dòng tổng (so_ca, dat, khong_dat), rồi ROLLBACK nên không để lại dữ liệu.
\set ON_ERROR_STOP on
\echo '===== Mảng A: tests_A.sql ====='
\ir tests_A.sql
\echo '===== Mảng B: tests_B.sql ====='
\ir tests_B.sql
\echo '===== Mảng C: tests_C.sql ====='
\ir tests_C.sql
