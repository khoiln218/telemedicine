-- T39 – Dữ liệu mẫu mảng B: bệnh nhân, tài khoản, giấy chuyển, lịch hẹn (dữ liệu giả lập).
-- Chạy sau A_seed.sql; gọi từ seed.sql.
-- Quy mô theo báo cáo mục 1: khoảng 150 lượt khám mỗi ngày, khoảng 20% tư vấn từ xa; 3 tháng hoạt động.
-- Lịch hẹn sinh theo thứ tự thời gian và đi qua trigger như thao tác thật: thêm ở DA_DAT rồi chuyển
-- trạng thái (BR-B05); lịch chuyên khoa lần đầu có giấy chuyển do bác sĩ đa khoa lập, tái khám thì không (BR-B03).
-- Mã lịch hẹn, giấy chuyển bắt đầu từ 10001 để không đụng mã 9101–9199 của tests_B.sql.
-- Mật khẩu mẫu chung của mọi tài khoản: Telemed@2026, lưu dạng sha256$<hex> (T47 dùng cùng định dạng).

-- 3.000 bệnh nhân chia ba nhóm theo tần suất đến khám (xem cách gán ma_bn trong vòng lặp lịch hẹn).
INSERT INTO benh_nhan (ma_bn, ho_ten, ngay_sinh, gioi_tinh, sdt, email)
SELECT i,
       (ARRAY['Nguyễn','Trần','Lê','Phạm','Hoàng','Huỳnh','Phan','Vũ','Võ','Đặng','Bùi','Đỗ','Hồ','Ngô','Dương','Lý'])[1 + i % 16]
       || ' ' || CASE WHEN i % 2 = 1
                      THEN (ARRAY['Văn','Minh','Đức','Quốc','Hữu','Gia','Thành'])[1 + i % 7] || ' '
                           || (ARRAY['Anh','Bảo','Dũng','Hải','Hiếu','Khang','Long','Phong','Tuấn','Việt','Nam','Sơn'])[1 + (i / 2) % 12]
                      ELSE (ARRAY['Thị','Ngọc','Thu','Thanh','Mỹ','Bảo','Khánh'])[1 + i % 7] || ' '
                           || (ARRAY['Chi','Dung','Giang','Hạnh','Linh','Ngân','Nhung','Trang','Uyên','Yến','Vy','Hà'])[1 + (i / 2) % 12]
                 END,
       DATE '1945-01-01' + (i * 397) % 28000,
       CASE WHEN i % 2 = 1 THEN 'NAM' ELSE 'NU' END,
       '0912' || lpad(i::text, 6, '0'),
       CASE WHEN i % 3 = 0 THEN 'benhnhan' || i || '@example.com' END
FROM generate_series(1, 3000) AS i;
SELECT setval(pg_get_serial_sequence('benh_nhan', 'ma_bn'), (SELECT max(ma_bn) FROM benh_nhan));

-- Tài khoản nhân viên (trừ bác sĩ 20 mới vào) và 40% bệnh nhân.
INSERT INTO tai_khoan (ten_dang_nhap, mat_khau_hash, vai_tro, ma_nv)
SELECT CASE nv.loai_nv WHEN 'BAC_SI' THEN 'bs' WHEN 'LE_TAN' THEN 'lt' ELSE 'qt' END || lpad(nv.ma_nv::text, 2, '0'),
       'sha256$' || encode(sha256(convert_to('Telemed@2026', 'UTF8')), 'hex'), nv.loai_nv, nv.ma_nv
FROM nhan_vien nv WHERE nv.ma_nv <> 20;
INSERT INTO tai_khoan (ten_dang_nhap, mat_khau_hash, vai_tro, ma_bn)
SELECT 'bn' || lpad(i::text, 4, '0'), 'sha256$' || encode(sha256(convert_to('Telemed@2026', 'UTF8')), 'hex'),
       'BENH_NHAN', i
FROM generate_series(1, 3000) AS i WHERE i % 5 < 2;

SELECT setval(pg_get_serial_sequence('lich_hen', 'ma_lh'), 10000);
SELECT setval(pg_get_serial_sequence('giay_chuyen_khoa', 'ma_giay'), 10000);

-- Lịch hẹn 30 phút trong ca. Tỷ lệ khung giờ được đặt: đa khoa 80%, chuyên khoa 65%; lịch sắp tới thưa dần.
-- Lịch đã qua: 10% hủy, 5% vắng mặt, còn lại hoàn thành; lịch từ hôm nay: đã đặt hoặc đã xác nhận.
DO $$
DECLARE
    s       RECORD;
    rn      INTEGER := 0;
    v_dem   INTEGER[] := ARRAY[0, 0, 0];   -- số lịch đã gán cho từng nhóm bệnh nhân
    v_nhom  INTEGER;
    v_bn    INTEGER;
    v_ck    INTEGER;
    v_giay  INTEGER;
    v_lh    INTEGER;
    v_tu_xa BOOLEAN;
    v_phi   NUMERIC(12,0);
    v_h     INTEGER;
BEGIN
    FOR s IN
        SELECT c.ma_bac_si, c.thoi_gian_bd + n * INTERVAL '30 minutes' AS bd, b.ma_chuyen_khoa
        FROM ca_lam_viec c
        LEFT JOIN bac_si_chuyen_khoa b ON b.ma_bac_si = c.ma_bac_si
        CROSS JOIN LATERAL generate_series(
            0, (extract(epoch FROM c.thoi_gian_kt - c.thoi_gian_bd) / 1800)::int - 1) AS n
        WHERE c.trang_thai = 'DA_XEP'
          AND (c.ma_ca * 31 + n * 17) % 100
              < CASE WHEN b.ma_chuyen_khoa IS NULL THEN 80 ELSE 65 END
                * CASE WHEN c.thoi_gian_bd::date >= CURRENT_DATE
                       THEN 1 - (c.thoi_gian_bd::date - CURRENT_DATE) / 16.0 ELSE 1 END
        ORDER BY bd, c.ma_bac_si
    LOOP
        rn := rn + 1;
        -- Khách quen 1–500 (30% lượt, khoảng 9 ngày một lần), bệnh nhân thường 501–1800 (50%, khoảng 15 ngày),
        -- bệnh nhân thỉnh thoảng 1801–3000 (20%, khoảng 34 ngày; có người chưa tái khám sau 30 ngày cho Q10).
        -- Mỗi nhóm có bộ đếm riêng; hệ số nhân nguyên tố cùng nhau với cỡ nhóm nên lần lượt đi qua mọi bệnh nhân
        -- của nhóm, và các lịch cùng khung giờ (bộ đếm liên tiếp) thuộc về bệnh nhân khác nhau (BR-B02).
        v_nhom := CASE WHEN rn % 10 < 3 THEN 1 WHEN rn % 10 < 8 THEN 2 ELSE 3 END;
        v_dem[v_nhom] := v_dem[v_nhom] + 1;
        v_bn := CASE v_nhom WHEN 1 THEN 1 + (v_dem[1] * 761) % 500
                            WHEN 2 THEN 501 + (v_dem[2] * 1201) % 1300
                            ELSE 1801 + (v_dem[3] * 787) % 1200 END;
        v_tu_xa := rn % 5 = 0;
        v_ck := s.ma_chuyen_khoa;
        v_phi := CASE WHEN v_ck IS NULL THEN 150000 ELSE 250000 END - CASE WHEN v_tu_xa THEN 30000 ELSE 0 END;

        v_giay := NULL;
        IF v_ck IS NOT NULL AND NOT EXISTS (
            SELECT 1 FROM lich_hen l JOIN bac_si_chuyen_khoa b ON b.ma_bac_si = l.ma_bac_si
            WHERE l.ma_bn = v_bn AND l.trang_thai = 'HOAN_THANH'
              AND l.thoi_gian_bd < s.bd AND b.ma_chuyen_khoa = v_ck)
        THEN
            INSERT INTO giay_chuyen_khoa (ngay_lap, ly_do, ngay_het_han, ma_bn, ma_bac_si_lap, ma_chuyen_khoa)
            VALUES (s.bd::date - 3, 'Đề nghị khám chuyên khoa (giả lập)', s.bd::date + 27,
                    v_bn, 1 + v_bn % 8, v_ck)
            RETURNING ma_giay INTO v_giay;
        END IF;

        INSERT INTO lich_hen (thoi_gian_bd, thoi_gian_kt, ly_do_kham, hinh_thuc, phi_kham, ngay_tao,
                              phong_kham, nen_tang, link_phien, ma_bn, ma_bac_si, ma_giay)
        VALUES (s.bd, s.bd + INTERVAL '30 minutes',
                (ARRAY['Khám tổng quát','Sốt, ho','Đau đầu','Tái khám theo hẹn','Đau ngực','Mẩn ngứa',
                       'Tư vấn kết quả xét nghiệm','Khám sức khỏe định kỳ','Đau bụng','Đau họng'])[1 + rn % 10],
                CASE WHEN v_tu_xa THEN 'TU_XA' ELSE 'TRUC_TIEP' END, v_phi, s.bd - INTERVAL '3 days',
                CASE WHEN v_tu_xa THEN NULL ELSE 'P' || (100 + s.ma_bac_si) END,
                CASE WHEN v_tu_xa THEN (ARRAY['Zoom','Google Meet'])[1 + rn % 2] END,
                CASE WHEN v_tu_xa THEN 'https://meet.phongkham.example/lh-' || rn END,
                v_bn, s.ma_bac_si, v_giay)
        RETURNING ma_lh INTO v_lh;

        IF s.bd::date < CURRENT_DATE THEN
            v_h := (rn * 7) % 20;
            IF v_h < 2 THEN
                UPDATE lich_hen SET trang_thai = 'HUY' WHERE ma_lh = v_lh;
            ELSE
                UPDATE lich_hen SET trang_thai = 'DA_XAC_NHAN' WHERE ma_lh = v_lh;
                UPDATE lich_hen SET trang_thai = CASE WHEN v_h = 2 THEN 'VANG_MAT' ELSE 'HOAN_THANH' END
                WHERE ma_lh = v_lh;
            END IF;
        ELSIF rn % 2 = 0 THEN
            UPDATE lich_hen SET trang_thai = 'DA_XAC_NHAN' WHERE ma_lh = v_lh;
        END IF;
    END LOOP;
END;
$$;
