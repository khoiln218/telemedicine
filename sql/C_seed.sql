-- T39 – Dữ liệu mẫu mảng C: danh mục, dị ứng, lần khám, chẩn đoán, đơn thuốc (dữ liệu giả lập).
-- Chạy sau A_seed.sql, B_seed.sql; gọi từ seed.sql. Cần lịch HOAN_THANH và tài khoản bác sĩ đang hoạt động.
-- Không có hồ sơ người bệnh thật. Tên thuốc, hàm lượng lấy theo thuốc thông dụng để kết quả mẫu dễ đọc;
-- chỉ định và liều dùng là giả lập cho đồ án, không phải hướng dẫn điều trị.
-- Dữ liệu đi qua mọi trigger C: lần khám chỉ cho lịch hoàn thành, đúng bác sĩ (BR-C02); có chẩn đoán trước
-- khi kê (BR-C03); thuốc không chứa hoạt chất bệnh nhân dị ứng (BR-C01); sai thì hủy, không sửa (BR-C05).

INSERT INTO ma_icd10 (ma_icd10, mo_ta) VALUES
    ('J06.9', 'Nhiễm khuẩn đường hô hấp trên cấp, không đặc hiệu'),
    ('R50.9', 'Sốt, không đặc hiệu'),
    ('R51',   'Đau đầu'),
    ('K21.9', 'Bệnh trào ngược dạ dày – thực quản không viêm thực quản'),
    ('I10',   'Tăng huyết áp vô căn (nguyên phát)'),
    ('I20.9', 'Cơn đau thắt ngực, không đặc hiệu'),
    ('L20.9', 'Viêm da cơ địa, không đặc hiệu'),
    ('L50.9', 'Mày đay, không đặc hiệu'),
    ('J45.9', 'Hen phế quản, không đặc hiệu'),
    ('J01.9', 'Viêm xoang cấp, không đặc hiệu'),
    ('J02.9', 'Viêm họng cấp, không đặc hiệu'),
    ('H66.9', 'Viêm tai giữa, không đặc hiệu'),
    ('K29.7', 'Viêm dạ dày, không đặc hiệu'),
    ('K58.9', 'Hội chứng ruột kích thích không kèm tiêu chảy'),
    ('E11.9', 'Đái tháo đường type 2 không có biến chứng'),
    ('E78.5', 'Tăng lipid máu, không đặc hiệu'),
    ('E03.9', 'Suy giáp, không đặc hiệu');

INSERT INTO hoat_chat (ten_hoat_chat) VALUES
    ('Paracetamol'), ('Ibuprofen'), ('Amoxicillin'), ('Acid clavulanic'), ('Cetirizin'),
    ('Loratadin'), ('Omeprazol'), ('Salbutamol'), ('Amlodipin'), ('Metformin'), ('Atorvastatin'),
    ('Levothyroxin'), ('Trimebutin');

INSERT INTO thuoc (ten_thuoc, dang_bao_che, ham_luong) VALUES
    ('Panadol',          'viên nén',       '500 mg'),
    ('Efferalgan',       'viên sủi',       '500 mg'),
    ('Ibuprofen Stada',  'viên nén',       '400 mg'),
    ('Amoxicillin 500',  'viên nang',      '500 mg'),
    ('Augmentin',        'viên nén',       '625 mg'),
    ('Cetirizin',        'viên nén',       '10 mg'),
    ('Loratadin',        'viên nén',       '10 mg'),
    ('Omeprazol',        'viên nang',      '20 mg'),
    ('Ventolin',         'bình xịt',       '100 mcg/liều'),
    ('Amlodipin',        'viên nén',       '5 mg'),
    ('Glucophage',       'viên nén',       '500 mg'),
    ('Lipitor',          'viên nén',       '20 mg'),
    ('Berlthyrox',       'viên nén',       '100 mcg'),
    ('Debridat',         'viên nén',       '100 mg');

-- Augmentin chứa hai hoạt chất: ví dụ liên kết M:N CHỨA.
INSERT INTO thuoc_hoat_chat (ma_thuoc, ma_hoat_chat, ham_luong)
SELECT t.ma_thuoc, h.ma_hoat_chat, v.ham_luong
FROM (VALUES ('Panadol', 'Paracetamol', '500 mg'), ('Efferalgan', 'Paracetamol', '500 mg'),
             ('Ibuprofen Stada', 'Ibuprofen', '400 mg'), ('Amoxicillin 500', 'Amoxicillin', '500 mg'),
             ('Augmentin', 'Amoxicillin', '500 mg'), ('Augmentin', 'Acid clavulanic', '125 mg'),
             ('Cetirizin', 'Cetirizin', '10 mg'), ('Loratadin', 'Loratadin', '10 mg'),
             ('Omeprazol', 'Omeprazol', '20 mg'), ('Ventolin', 'Salbutamol', '100 mcg'),
             ('Amlodipin', 'Amlodipin', '5 mg'), ('Glucophage', 'Metformin', '500 mg'),
             ('Lipitor', 'Atorvastatin', '20 mg'), ('Berlthyrox', 'Levothyroxin', '100 mcg'),
             ('Debridat', 'Trimebutin', '100 mg')) AS v(thuoc, hoat_chat, ham_luong)
JOIN thuoc t ON t.ten_thuoc = v.thuoc
JOIN hoat_chat h ON h.ten_hoat_chat = v.hoat_chat;

-- Dị ứng ghi nhận cho khoảng 9% bệnh nhân, trước các lần khám.
INSERT INTO di_ung (ma_bn, ma_hoat_chat, ngay_ghi_nhan, ghi_chu)
SELECT bn.ma_bn, h.ma_hoat_chat, CURRENT_DATE - 400 + bn.ma_bn % 300, v.ghi_chu
FROM benh_nhan bn
JOIN (VALUES (23, 'Amoxicillin', 'Nổi mẩn sau dùng kháng sinh'),
             (37, 'Ibuprofen', 'Khó thở nhẹ sau dùng thuốc giảm đau'),
             (41, 'Paracetamol', 'Mày đay sau dùng thuốc hạ sốt')) AS v(chia_het, hoat_chat, ghi_chu)
  ON bn.ma_bn % v.chia_het = 0
JOIN hoat_chat h ON h.ten_hoat_chat = v.hoat_chat;

DO $$
DECLARE
    r        RECORD;
    v_ck     TEXT;
    v_ma     TEXT[];
    v_chinh  TEXT;
    v_phu    TEXT;
    v_thuoc  TEXT[];
    v_ke     TEXT[];
    v_t      TEXT;
    v_lk     INTEGER;
    v_don    INTEGER;
    v_cd_phu INTEGER;
    v_lan    INTEGER;
BEGIN
    FOR r IN
        SELECT l.ma_lh, l.ma_bn, l.ma_bac_si, l.thoi_gian_bd, tk.ten_dang_nhap, ck.ten_chuyen_khoa
        FROM lich_hen l
        JOIN tai_khoan tk ON tk.ma_nv = l.ma_bac_si AND tk.vai_tro = 'BAC_SI' AND tk.trang_thai = 'HOAT_DONG'
        LEFT JOIN bac_si_chuyen_khoa b ON b.ma_bac_si = l.ma_bac_si
        LEFT JOIN chuyen_khoa ck ON ck.ma_chuyen_khoa = b.ma_chuyen_khoa
        WHERE l.trang_thai = 'HOAN_THANH'
        ORDER BY l.thoi_gian_bd, l.ma_lh
    LOOP
        -- Chẩn đoán theo chuyên khoa của bác sĩ; 1/4 lần khám có thêm chẩn đoán phụ
        v_ma := CASE r.ten_chuyen_khoa
                    WHEN 'Tim mạch'     THEN ARRAY['I10', 'I20.9', 'E78.5']
                    WHEN 'Da liễu'      THEN ARRAY['L20.9', 'L50.9']
                    WHEN 'Nhi khoa'     THEN ARRAY['J06.9', 'R50.9', 'J45.9', 'H66.9']
                    WHEN 'Tai mũi họng' THEN ARRAY['J01.9', 'J02.9', 'H66.9']
                    WHEN 'Tiêu hóa'     THEN ARRAY['K21.9', 'K29.7', 'K58.9']
                    WHEN 'Nội tiết'     THEN ARRAY['E11.9', 'E78.5', 'E03.9']
                    ELSE ARRAY['J06.9', 'R51', 'K21.9', 'R50.9', 'I10', 'J02.9']
                END;
        v_chinh := v_ma[1 + (r.ma_lh * 7) % array_length(v_ma, 1)];
        v_phu := CASE WHEN r.ma_lh % 4 = 0 THEN v_ma[1 + (r.ma_lh * 7 + 1) % array_length(v_ma, 1)] END;

        INSERT INTO lan_kham (ma_lh, thoi_diem_kham, tom_tat, created_by)
        VALUES (r.ma_lh, r.thoi_gian_bd + INTERVAL '5 minutes',
                'Khám ' || lower((SELECT mo_ta FROM ma_icd10 WHERE ma_icd10 = v_chinh))
                || CASE WHEN r.ma_lh % 7 = 3 THEN '; theo dõi, chưa cần dùng thuốc' ELSE '; kê đơn điều trị' END,
                r.ten_dang_nhap)
        RETURNING ma_lan_kham INTO v_lk;
        INSERT INTO chan_doan (ma_lan_kham, ma_icd10, la_chan_doan_chinh)
        VALUES (v_lk, v_chinh, TRUE);
        IF v_phu IS NOT NULL THEN
            INSERT INTO chan_doan (ma_lan_kham, ma_icd10, ghi_chu)
            VALUES (v_lk, v_phu, 'Chẩn đoán kèm theo')
            RETURNING ma_chan_doan INTO v_cd_phu;
            -- Ghi nhầm thì hủy, giữ bản ghi (BR-C05)
            IF r.ma_lh % 12 = 0 THEN
                UPDATE chan_doan SET trang_thai = 'DA_HUY' WHERE ma_chan_doan = v_cd_phu;
                v_phu := NULL;
            END IF;
        END IF;

        CONTINUE WHEN r.ma_lh % 7 = 3;   -- lần khám chỉ theo dõi, không kê đơn

        -- Thuốc theo chẩn đoán còn hiệu lực
        v_thuoc := ARRAY[]::TEXT[];
        FOREACH v_t IN ARRAY array_remove(ARRAY[v_chinh, v_phu], NULL) LOOP
            v_thuoc := v_thuoc || CASE v_t
                WHEN 'J06.9' THEN ARRAY[CASE WHEN r.ma_lh % 2 = 0 THEN 'Augmentin' ELSE 'Amoxicillin 500' END, 'Panadol']
                WHEN 'R50.9' THEN ARRAY['Efferalgan']
                WHEN 'R51'   THEN ARRAY[CASE WHEN r.ma_lh % 3 = 0 THEN 'Ibuprofen Stada' ELSE 'Panadol' END]
                WHEN 'K21.9' THEN ARRAY['Omeprazol']
                WHEN 'I10'   THEN ARRAY['Amlodipin']
                WHEN 'I20.9' THEN ARRAY['Amlodipin']
                WHEN 'L20.9' THEN ARRAY['Cetirizin']
                WHEN 'L50.9' THEN ARRAY['Loratadin']
                WHEN 'J45.9' THEN ARRAY['Ventolin']
                WHEN 'J01.9' THEN ARRAY['Augmentin', 'Cetirizin']
                WHEN 'J02.9' THEN ARRAY['Panadol']
                WHEN 'H66.9' THEN ARRAY['Amoxicillin 500', 'Panadol']
                WHEN 'K29.7' THEN ARRAY['Omeprazol']
                WHEN 'K58.9' THEN ARRAY['Debridat']
                WHEN 'E11.9' THEN ARRAY['Glucophage']
                WHEN 'E78.5' THEN ARRAY['Lipitor']
                WHEN 'E03.9' THEN ARRAY['Berlthyrox']
                ELSE ARRAY[]::TEXT[]
            END;
        END LOOP;

        -- Bỏ thuốc chứa hoạt chất bệnh nhân dị ứng (BR-C01); thuốc hạ sốt, giảm đau đổi sang loại khác
        v_ke := ARRAY[]::TEXT[];
        FOREACH v_t IN ARRAY v_thuoc LOOP
            FOR v_lan IN 1..2 LOOP
                EXIT WHEN v_t IS NULL OR v_t = ANY (v_ke);
                IF NOT EXISTS (SELECT 1 FROM thuoc t
                               JOIN thuoc_hoat_chat th ON th.ma_thuoc = t.ma_thuoc
                               JOIN di_ung du ON du.ma_hoat_chat = th.ma_hoat_chat AND du.ma_bn = r.ma_bn
                               WHERE t.ten_thuoc = v_t) THEN
                    v_ke := v_ke || v_t;
                    EXIT;
                END IF;
                v_t := CASE WHEN v_t IN ('Panadol', 'Efferalgan') THEN 'Ibuprofen Stada'
                            WHEN v_t = 'Ibuprofen Stada' THEN 'Panadol' END;
            END LOOP;
        END LOOP;
        CONTINUE WHEN cardinality(v_ke) = 0;

        FOR v_lan IN 1..CASE WHEN r.ma_lh % 31 = 0 THEN 2 ELSE 1 END LOOP
            -- Đơn ghi sai được hủy rồi kê lại đơn mới (BR-C05); đơn và dòng thuốc ghi cùng giao dịch
            INSERT INTO don_thuoc (ma_lan_kham, thoi_diem_ke, created_by)
            VALUES (v_lk, r.thoi_gian_bd + v_lan * INTERVAL '10 minutes', r.ten_dang_nhap)
            RETURNING ma_don INTO v_don;
            INSERT INTO chi_tiet_don_thuoc (ma_don, ma_thuoc, so_luong, lieu_dung)
            SELECT v_don, t.ma_thuoc,
                   CASE t.ten_thuoc WHEN 'Amoxicillin 500' THEN 21 WHEN 'Amlodipin' THEN 30
                                    WHEN 'Glucophage' THEN 60 WHEN 'Lipitor' THEN 30 WHEN 'Berlthyrox' THEN 30
                                    WHEN 'Debridat' THEN 30
                                    WHEN 'Augmentin' THEN 14 WHEN 'Omeprazol' THEN 14
                                    WHEN 'Ventolin' THEN 1 ELSE 10 END
                   + CASE WHEN v_lan = 1 AND r.ma_lh % 31 = 0 THEN 5 ELSE 0 END,  -- đơn bị hủy ghi nhầm số lượng
                   CASE t.ten_thuoc
                       WHEN 'Panadol'         THEN '1 viên khi sốt, đau; cách nhau ít nhất 4–6 giờ'
                       WHEN 'Efferalgan'      THEN '1 viên hòa tan vào nước khi sốt; cách nhau 4–6 giờ'
                       WHEN 'Ibuprofen Stada' THEN '1 viên sau ăn, ngày 2 lần'
                       WHEN 'Amoxicillin 500' THEN '1 viên, ngày 3 lần, dùng 7 ngày'
                       WHEN 'Augmentin'       THEN '1 viên sau ăn, ngày 2 lần, dùng 7 ngày'
                       WHEN 'Cetirizin'       THEN '1 viên buổi tối'
                       WHEN 'Loratadin'       THEN '1 viên mỗi ngày'
                       WHEN 'Omeprazol'       THEN '1 viên trước ăn sáng 30 phút'
                       WHEN 'Ventolin'        THEN '2 nhát xịt khi khó thở'
                       WHEN 'Amlodipin'       THEN '1 viên mỗi sáng'
                       WHEN 'Glucophage'      THEN '1 viên sau ăn sáng và tối'
                       WHEN 'Lipitor'         THEN '1 viên buổi tối'
                       WHEN 'Berlthyrox'      THEN '1 viên buổi sáng lúc đói'
                       WHEN 'Debridat'        THEN '1 viên trước ăn, ngày 3 lần'
                   END
            FROM thuoc t WHERE t.ten_thuoc = ANY (v_ke);
            IF v_lan = 1 AND r.ma_lh % 31 = 0 THEN
                UPDATE don_thuoc SET trang_thai = 'DA_HUY' WHERE ma_don = v_don;
            END IF;
        END LOOP;
    END LOOP;
END;
$$;
