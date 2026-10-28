-- T39 – Dữ liệu mẫu tích hợp ba mảng (dữ liệu giả lập, không có hồ sơ người bệnh thật).
-- Chạy sau schema.sql và A/B/C_trigger_view.sql; dữ liệu đi qua mọi trigger như thao tác thật.
-- Ngày tính theo CURRENT_DATE nên chạy lại vào ngày khác vẫn đủ để truy vấn mẫu có kết quả.
\set ON_ERROR_STOP on
\ir A_seed.sql
\ir B_seed.sql
\ir C_seed.sql
