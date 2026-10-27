-- T35 – Schema tích hợp các script hiện có, theo thứ tự phụ thuộc.
-- Mảng A phải tạo trước vì B có khóa ngoại đến nhân viên/bác sĩ/chuyên khoa.
-- Mảng C chưa có script trong repository; bổ sung C_schema.sql sau B khi nhóm hoàn tất mảng C.
\set ON_ERROR_STOP on
\ir A_schema.sql
\ir B_schema.sql
