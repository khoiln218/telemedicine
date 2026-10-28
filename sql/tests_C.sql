-- T43 – Bộ kiểm thử ràng buộc mảng C.
-- Chạy sau schema.sql, A/B/C_trigger_view.sql, seed.sql và rbac.sql trên CSDL thử nghiệm.
-- Dữ liệu mẫu chung phải có một lịch hoàn thành, tài khoản bác sĩ và C_seed.sql đã chạy.
-- Mỗi ca lỗi được cô lập trong subtransaction; toàn bộ fixture được ROLLBACK cuối file.

BEGIN;
CREATE TEMP TABLE kq_c (
    ma text, quy_tac text, mo_ta text, ky_vong text, dat boolean, thong_bao text
);
CREATE PROCEDURE pg_temp.kt_c(p_ma text, p_qt text, p_mo_ta text, p_sql text, p_ky_vong text) AS $$
DECLARE
    v_msg text := 'thực hiện được';
    v_con text;
    v_dat boolean;
BEGIN
    BEGIN
        EXECUTE p_sql;
        v_dat := p_ky_vong = 'OK';
    EXCEPTION WHEN OTHERS THEN
        GET STACKED DIAGNOSTICS v_msg = MESSAGE_TEXT, v_con = CONSTRAINT_NAME;
        v_dat := p_ky_vong <> 'OK' AND (v_con = p_ky_vong OR position(p_ky_vong IN v_msg) > 0);
    END;
    INSERT INTO kq_c VALUES (p_ma, p_qt, p_mo_ta, p_ky_vong, v_dat, v_msg);
END;
$$ LANGUAGE plpgsql;

-- Tạo ma_thuoc thứ hai trong chi tiết để kiểm tra CHECK, không đụng khóa đã có.
CALL pg_temp.kt_c('TC04', 'BR-C04', 'Số lượng bằng 0 bị từ chối',
    $q$INSERT INTO chi_tiet_don_thuoc (ma_don, ma_thuoc, so_luong, lieu_dung)
       SELECT d.ma_don, t.ma_thuoc, 0, 'liều mẫu'
         FROM don_thuoc d CROSS JOIN thuoc t
        WHERE d.trang_thai = 'HIEU_LUC' AND t.ten_thuoc = 'Thuốc mẫu C-D'
        ORDER BY d.ma_don LIMIT 1$q$, 'ck_chi_tiet_don_thuoc_so_luong');
CALL pg_temp.kt_c('TC01', 'BR-C01', 'Kê thuốc chứa hoạt chất đang có trong dị ứng',
    $q$INSERT INTO chi_tiet_don_thuoc (ma_don, ma_thuoc, so_luong, lieu_dung)
       SELECT d.ma_don, t.ma_thuoc, 1, 'liều mẫu'
         FROM don_thuoc d CROSS JOIN thuoc t
        WHERE d.trang_thai = 'HIEU_LUC' AND t.ten_thuoc = 'Thuốc mẫu C-B'
        ORDER BY d.ma_don LIMIT 1$q$, 'BR-C01');

CALL pg_temp.kt_c('TC02', 'BR-C02', 'Đơn thuốc ghi bởi tài khoản bệnh nhân không phải bác sĩ của lịch',
    $q$INSERT INTO don_thuoc (ma_lan_kham, thoi_diem_ke, created_by)
       SELECT k.ma_lan_kham, CURRENT_TIMESTAMP, tk.ten_dang_nhap
         FROM lan_kham k CROSS JOIN tai_khoan tk
        WHERE tk.vai_tro = 'BENH_NHAN'
        ORDER BY k.ma_lan_kham, tk.ten_dang_nhap LIMIT 1$q$, 'BR-C02');

CALL pg_temp.kt_c('TC03', 'BR-C03', 'Không hủy chẩn đoán hiệu lực cuối khi đơn còn hiệu lực',
    $q$UPDATE chan_doan cd SET trang_thai = 'DA_HUY'
       WHERE cd.ma_chan_doan = (
           SELECT cd2.ma_chan_doan FROM chan_doan cd2 JOIN don_thuoc d USING (ma_lan_kham)
            WHERE cd2.trang_thai = 'HIEU_LUC' AND d.trang_thai = 'HIEU_LUC'
              AND NOT EXISTS (SELECT 1 FROM chan_doan c2
                               WHERE c2.ma_lan_kham = cd2.ma_lan_kham
                                 AND c2.ma_chan_doan <> cd2.ma_chan_doan AND c2.trang_thai = 'HIEU_LUC')
            ORDER BY cd2.ma_chan_doan LIMIT 1
       )$q$, 'BR-C03');
CALL pg_temp.kt_c('TC03B', 'BR-C bổ sung', 'Đơn thuốc không thể commit khi chưa có dòng thuốc',
    $q$DO $$
       DECLARE v_ma_lan_kham INTEGER; v_login VARCHAR(50); v_ma_don INTEGER;
       BEGIN
         SELECT k.ma_lan_kham, tk.ten_dang_nhap INTO v_ma_lan_kham, v_login
           FROM lan_kham k JOIN lich_hen l ON l.ma_lh = k.ma_lh
           JOIN tai_khoan tk ON tk.ma_nv = l.ma_bac_si AND tk.vai_tro = 'BAC_SI'
          ORDER BY k.ma_lan_kham LIMIT 1;
         INSERT INTO don_thuoc (ma_lan_kham, thoi_diem_ke, created_by)
         VALUES (v_ma_lan_kham, CURRENT_TIMESTAMP, v_login) RETURNING ma_don INTO v_ma_don;
         SET CONSTRAINTS ct_c_don_phai_co_chi_tiet IMMEDIATE;
       END
       $$ LANGUAGE plpgsql$q$, 'BR-C bổ sung');
CALL pg_temp.kt_c('TC05OK', 'BR-C05', 'Hủy chẩn đoán ghi sai nhưng giữ bản ghi',
    $q$DO $$
       DECLARE v_ma_lan_kham INTEGER; v_ma_chan_doan INTEGER;
       BEGIN
         SELECT ma_lan_kham INTO v_ma_lan_kham FROM lan_kham ORDER BY ma_lan_kham LIMIT 1;
         INSERT INTO chan_doan (ma_lan_kham, ma_icd10, ghi_chu)
         VALUES (v_ma_lan_kham, 'J06.9', 'test hủy hợp lệ') RETURNING ma_chan_doan INTO v_ma_chan_doan;
         UPDATE chan_doan SET trang_thai = 'DA_HUY' WHERE ma_chan_doan = v_ma_chan_doan;
       END
       $$ LANGUAGE plpgsql$q$, 'OK');
CALL pg_temp.kt_c('TC05A', 'BR-C05', 'Không sửa nội dung lần khám',
    $q$UPDATE lan_kham SET tom_tat = 'sửa sai' WHERE ma_lan_kham = (SELECT min(ma_lan_kham) FROM lan_kham)$q$, 'BR-C05');
CALL pg_temp.kt_c('TC05B', 'BR-C05', 'Không xóa dòng thuốc',
    $q$DELETE FROM chi_tiet_don_thuoc WHERE (ma_don, ma_thuoc) =
       (SELECT ma_don, ma_thuoc FROM chi_tiet_don_thuoc ORDER BY ma_don LIMIT 1)$q$, 'BR-C05');
CALL pg_temp.kt_c('TC05C', 'BR-C05', 'Không TRUNCATE chẩn đoán', 'TRUNCATE chan_doan', 'BR-C05');
CALL pg_temp.kt_c('TC05D', 'T05 lưu giữ lịch sử', 'Không sửa thuốc đã xuất hiện trong đơn',
    $q$UPDATE thuoc SET ten_thuoc = ten_thuoc || ' (sửa)'
        WHERE ma_thuoc = (SELECT ma_thuoc FROM chi_tiet_don_thuoc ORDER BY ma_don LIMIT 1)$q$, 'T05:');

-- BR-C06: lễ tân không được xem bảng/view lâm sàng; bệnh nhân chỉ được cấp view của mình.
INSERT INTO kq_c (ma, quy_tac, mo_ta, ky_vong, dat, thong_bao)
SELECT 'TC06A', 'BR-C06', 'Lễ tân không có quyền đọc chẩn đoán', 'false',
       NOT has_table_privilege('r_le_tan', 'chan_doan', 'SELECT'), 'has_table_privilege';
INSERT INTO kq_c (ma, quy_tac, mo_ta, ky_vong, dat, thong_bao)
SELECT 'TC06B', 'BR-C06', 'Bệnh nhân được đọc view hồ sơ của mình', 'true',
       has_table_privilege('r_benh_nhan', 'v_ho_so_cua_toi', 'SELECT'), 'has_table_privilege';
INSERT INTO kq_c (ma, quy_tac, mo_ta, ky_vong, dat, thong_bao)
SELECT 'TC06C', 'BR-C06', 'Bệnh nhân được đọc dị ứng của mình', 'true',
       has_table_privilege('r_benh_nhan', 'v_di_ung_cua_toi', 'SELECT'), 'has_table_privilege';

TABLE kq_c;
SELECT count(*) AS so_ca, count(*) FILTER (WHERE dat) AS dat,
       count(*) FILTER (WHERE NOT dat) AS khong_dat FROM kq_c;
ROLLBACK;
