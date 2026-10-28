-- T39 – Phần dữ liệu mẫu mảng C, tích hợp vào sql/seed.sql.
-- Chạy sau A_schema.sql, B_schema.sql, C_schema.sql, A/B/C_trigger_view.sql và B seed.
-- B seed phải có ít nhất một lịch HOAN_THANH, tài khoản bác sĩ đang hoạt động gắn đúng ma_nv.
-- Để mọi truy vấn mẫu có kết quả: B seed nên có một lịch hoàn thành trong quý hiện tại,
-- một lịch hoàn thành cách hiện tại 30–365 ngày, và các lịch của ít nhất hai bác sĩ.
-- Tên bệnh nhân/tài khoản lấy từ fixture giả lập của B; không thêm dữ liệu bệnh nhân thật.

INSERT INTO ma_icd10 (ma_icd10, mo_ta) VALUES
    ('R51', 'Đau đầu (mã mẫu)'),
    ('J06.9', 'Nhiễm khuẩn đường hô hấp trên cấp, không đặc hiệu (mã mẫu)'),
    ('K21.9', 'Trào ngược dạ dày-thực quản, không viêm thực quản (mã mẫu)')
ON CONFLICT (ma_icd10) DO NOTHING;

INSERT INTO hoat_chat (ten_hoat_chat) VALUES
    ('Hoạt chất mẫu an toàn A'),
    ('Hoạt chất mẫu dị ứng B')
ON CONFLICT (ten_hoat_chat) DO NOTHING;

INSERT INTO thuoc (ten_thuoc, dang_bao_che, ham_luong)
SELECT v.ten_thuoc, v.dang_bao_che, v.ham_luong
  FROM (VALUES
        ('Thuốc mẫu C-A', 'viên nén', '250 mg'),
        ('Thuốc mẫu C-B', 'viên nang', '100 mg'),
        ('Thuốc mẫu C-C', 'viên nén', '500 mg'),
        ('Thuốc mẫu C-D', 'viên nén', '50 mg')
  ) AS v(ten_thuoc, dang_bao_che, ham_luong)
 WHERE NOT EXISTS (
       SELECT 1 FROM thuoc t
        WHERE t.ten_thuoc = v.ten_thuoc AND t.dang_bao_che = v.dang_bao_che
          AND t.ham_luong = v.ham_luong
 );

INSERT INTO thuoc_hoat_chat (ma_thuoc, ma_hoat_chat, ham_luong)
SELECT t.ma_thuoc, h.ma_hoat_chat,
       CASE h.ten_hoat_chat WHEN 'Hoạt chất mẫu an toàn A' THEN '250 mg' ELSE '100 mg' END
  FROM thuoc t CROSS JOIN hoat_chat h
 WHERE t.ten_thuoc IN ('Thuốc mẫu C-A', 'Thuốc mẫu C-B', 'Thuốc mẫu C-C', 'Thuốc mẫu C-D')
   AND h.ten_hoat_chat IN ('Hoạt chất mẫu an toàn A', 'Hoạt chất mẫu dị ứng B')
   AND ((t.ten_thuoc = 'Thuốc mẫu C-A' AND h.ten_hoat_chat = 'Hoạt chất mẫu an toàn A')
     OR (t.ten_thuoc = 'Thuốc mẫu C-B' AND h.ten_hoat_chat = 'Hoạt chất mẫu dị ứng B')
     OR (t.ten_thuoc IN ('Thuốc mẫu C-C', 'Thuốc mẫu C-D')
         AND h.ten_hoat_chat = 'Hoạt chất mẫu an toàn A'))
ON CONFLICT (ma_thuoc, ma_hoat_chat) DO NOTHING;

DO $$
DECLARE
    r RECORD;
    v_bac_si_thuoc_nhieu INTEGER;
    v_ma_lan_kham INTEGER;
    v_ma_don INTEGER;
    v_ma_thuoc_an_toan INTEGER;
    v_ma_thuoc_bo_sung INTEGER;
    v_ma_hoat_chat INTEGER;
BEGIN
    SELECT MIN(x.ma_bac_si) INTO v_bac_si_thuoc_nhieu
      FROM (SELECT DISTINCT l.ma_bac_si
              FROM lich_hen l JOIN tai_khoan tk
                ON tk.ma_nv = l.ma_bac_si AND tk.vai_tro = 'BAC_SI' AND tk.trang_thai = 'HOAT_DONG'
             WHERE l.trang_thai = 'HOAN_THANH') x;
    IF v_bac_si_thuoc_nhieu IS NULL THEN
        RAISE EXCEPTION 'T39 C: B seed cần ít nhất một lịch HOAN_THANH và tài khoản bác sĩ tương ứng';
    END IF;

    SELECT ma_thuoc INTO v_ma_thuoc_an_toan FROM thuoc WHERE ten_thuoc = 'Thuốc mẫu C-A' LIMIT 1;
    SELECT ma_thuoc INTO v_ma_thuoc_bo_sung FROM thuoc WHERE ten_thuoc = 'Thuốc mẫu C-C' LIMIT 1;
    SELECT ma_hoat_chat INTO v_ma_hoat_chat FROM hoat_chat WHERE ten_hoat_chat = 'Hoạt chất mẫu dị ứng B';

    -- Mỗi lịch hoàn thành trong seed có một lần khám, chẩn đoán R51, một đơn và thuốc an toàn.
    -- Các đơn của một bác sĩ có mã nhỏ nhất được thêm thuốc thứ hai để Q12 có thể so sánh khi
    -- seed B có ít nhất hai bác sĩ; C-D được dành riêng cho ca test số lượng bằng 0.
    FOR r IN
        SELECT l.ma_lh, l.ma_bn, l.ma_bac_si, l.thoi_gian_bd, tk.ten_dang_nhap
          FROM lich_hen l JOIN tai_khoan tk
            ON tk.ma_nv = l.ma_bac_si AND tk.vai_tro = 'BAC_SI' AND tk.trang_thai = 'HOAT_DONG'
         WHERE l.trang_thai = 'HOAN_THANH'
         ORDER BY l.ma_lh
    LOOP
        v_ma_lan_kham := NULL;
        SELECT ma_lan_kham INTO v_ma_lan_kham FROM lan_kham WHERE ma_lh = r.ma_lh;
        IF v_ma_lan_kham IS NULL THEN
            INSERT INTO lan_kham (ma_lh, thoi_diem_kham, tom_tat, created_by)
            VALUES (r.ma_lh, r.thoi_gian_bd, 'Ca khám giả lập cho kiểm thử', r.ten_dang_nhap)
            RETURNING ma_lan_kham INTO v_ma_lan_kham;
        END IF;

        IF NOT EXISTS (SELECT 1 FROM chan_doan
                        WHERE ma_lan_kham = v_ma_lan_kham AND ma_icd10 = 'R51' AND trang_thai = 'HIEU_LUC') THEN
            INSERT INTO chan_doan (ma_lan_kham, ma_icd10, la_chan_doan_chinh, ghi_chu)
            VALUES (v_ma_lan_kham, 'R51', TRUE, 'Chẩn đoán minh họa; không phải hồ sơ thật');
        END IF;

        v_ma_don := NULL;
        SELECT ma_don INTO v_ma_don FROM don_thuoc
         WHERE ma_lan_kham = v_ma_lan_kham AND trang_thai = 'HIEU_LUC'
         ORDER BY ma_don LIMIT 1;
        IF v_ma_don IS NULL THEN
            INSERT INTO don_thuoc (ma_lan_kham, thoi_diem_ke, created_by)
            VALUES (v_ma_lan_kham, r.thoi_gian_bd, r.ten_dang_nhap)
            RETURNING ma_don INTO v_ma_don;
        END IF;

        IF NOT EXISTS (SELECT 1 FROM chi_tiet_don_thuoc
                        WHERE ma_don = v_ma_don AND ma_thuoc = v_ma_thuoc_an_toan) THEN
            INSERT INTO chi_tiet_don_thuoc (ma_don, ma_thuoc, so_luong, lieu_dung)
            VALUES (v_ma_don, v_ma_thuoc_an_toan, 6, '1 viên sau ăn, ngày 2 lần (hướng dẫn giả lập)');
        END IF;
        IF r.ma_bac_si = v_bac_si_thuoc_nhieu
           AND NOT EXISTS (SELECT 1 FROM chi_tiet_don_thuoc
                            WHERE ma_don = v_ma_don AND ma_thuoc = v_ma_thuoc_bo_sung) THEN
            INSERT INTO chi_tiet_don_thuoc (ma_don, ma_thuoc, so_luong, lieu_dung)
            VALUES (v_ma_don, v_ma_thuoc_bo_sung, 4, '1 viên mỗi ngày (hướng dẫn giả lập)');
        END IF;

        INSERT INTO di_ung (ma_bn, ma_hoat_chat, ngay_ghi_nhan, ghi_chu)
        VALUES (r.ma_bn, v_ma_hoat_chat, r.thoi_gian_bd::DATE, 'Dị ứng giả lập dùng kiểm thử BR-C01')
        ON CONFLICT (ma_bn, ma_hoat_chat) DO NOTHING;
    END LOOP;
END;
$$;
