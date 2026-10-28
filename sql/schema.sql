-- T35 – Schema tích hợp ba mảng, theo thứ tự phụ thuộc khóa ngoại: A → B → C.
-- B có khóa ngoại đến nhân viên/bác sĩ/chuyên khoa (A); C đến lịch hẹn, bệnh nhân, tài khoản (B).
-- Trigger/view chạy sau toàn bộ schema vì trigger A đọc lich_hen (B): xem README, mục "Chạy script SQL".
\set ON_ERROR_STOP on
\ir A_schema.sql
\ir B_schema.sql
\ir C_schema.sql
