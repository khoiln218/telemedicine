-- T42 – Bốn truy vấn phức tạp mảng C (PostgreSQL 16).
-- Tham số được khai báo trong CTE params để có thể chạy nguyên file; thay giá trị mẫu khi trình diễn.

-- Q09. Top 10 thuốc được kê nhiều nhất trong một quý (xếp theo số lượt kê, không theo số viên).
WITH params AS (
    SELECT date_trunc('quarter', CURRENT_DATE)::DATE AS tu_ngay,
           (date_trunc('quarter', CURRENT_DATE) + INTERVAL '3 months')::DATE AS den_ngay
)
SELECT t.ma_thuoc, t.ten_thuoc,
       COUNT(*) AS so_don_co_ke,
       SUM(ct.so_luong) AS tong_so_luong
  FROM params p
  JOIN don_thuoc d ON d.thoi_diem_ke >= p.tu_ngay AND d.thoi_diem_ke < p.den_ngay
  JOIN chi_tiet_don_thuoc ct ON ct.ma_don = d.ma_don
  JOIN thuoc t ON t.ma_thuoc = ct.ma_thuoc
 WHERE d.trang_thai = 'HIEU_LUC'
 GROUP BY t.ma_thuoc, t.ten_thuoc
 ORDER BY so_don_co_ke DESC, tong_so_luong DESC, t.ma_thuoc
 LIMIT 10;

-- Q10. Bệnh nhân có chẩn đoán ICD chỉ định, lần khám đã cách ngày chốt ít nhất 30 ngày,
-- nhưng không có lần khám hoàn thành tiếp theo trong 30 ngày tính từ lần khám đó.
WITH params AS (
    SELECT 'R51'::VARCHAR(10) AS ma_icd10, CURRENT_DATE AS ngay_chot
), cohort AS (
    SELECT DISTINCT l.ma_bn, k.ma_lan_kham, k.ma_lh, k.thoi_diem_kham
      FROM params p
      JOIN chan_doan cd ON cd.ma_icd10 = p.ma_icd10 AND cd.trang_thai = 'HIEU_LUC'
      JOIN lan_kham k ON k.ma_lan_kham = cd.ma_lan_kham
      JOIN lich_hen l ON l.ma_lh = k.ma_lh AND l.trang_thai = 'HOAN_THANH'
     WHERE k.thoi_diem_kham::date BETWEEN p.ngay_chot - 365 AND p.ngay_chot - 30
)
SELECT c.ma_bn, bn.ho_ten, c.ma_lan_kham, c.thoi_diem_kham
  FROM cohort c JOIN benh_nhan bn ON bn.ma_bn = c.ma_bn
 WHERE NOT EXISTS (
       SELECT 1 FROM lan_kham k2 JOIN lich_hen l2 ON l2.ma_lh = k2.ma_lh
        WHERE l2.ma_bn = c.ma_bn AND l2.trang_thai = 'HOAN_THANH'
          AND k2.thoi_diem_kham > c.thoi_diem_kham
          AND k2.thoi_diem_kham <= c.thoi_diem_kham + INTERVAL '30 days'
 )
 ORDER BY c.thoi_diem_kham, c.ma_bn;

-- Q11. Tra cứu lịch sử lâm sàng đầy đủ của bệnh nhân có lần khám mẫu (đổi ma_bn khi trình diễn).
WITH params AS (
    SELECT (SELECT l.ma_bn FROM lan_kham k JOIN lich_hen l ON l.ma_lh = k.ma_lh
             ORDER BY k.thoi_diem_kham DESC LIMIT 1) AS ma_bn
)
SELECT bn.ma_bn, bn.ho_ten, l.ma_lh, l.trang_thai AS trang_thai_lich,
       k.ma_lan_kham, k.thoi_diem_kham, k.tom_tat,
       cd.ma_icd10, i.mo_ta AS chan_doan, cd.trang_thai AS trang_thai_chan_doan,
       d.ma_don, d.thoi_diem_ke, d.trang_thai AS trang_thai_don,
       t.ten_thuoc, ct.so_luong, ct.lieu_dung,
       string_agg(DISTINCT ha.ten_hoat_chat, ', ' ORDER BY ha.ten_hoat_chat) AS hoat_chat,
       string_agg(DISTINCT di.ten_hoat_chat, ', ' ORDER BY di.ten_hoat_chat) AS di_ung_da_ghi_nhan
  FROM params p JOIN benh_nhan bn ON bn.ma_bn = p.ma_bn
  LEFT JOIN lich_hen l ON l.ma_bn = bn.ma_bn
  LEFT JOIN lan_kham k ON k.ma_lh = l.ma_lh
  LEFT JOIN chan_doan cd ON cd.ma_lan_kham = k.ma_lan_kham
  LEFT JOIN ma_icd10 i ON i.ma_icd10 = cd.ma_icd10
  LEFT JOIN don_thuoc d ON d.ma_lan_kham = k.ma_lan_kham
  LEFT JOIN chi_tiet_don_thuoc ct ON ct.ma_don = d.ma_don
  LEFT JOIN thuoc t ON t.ma_thuoc = ct.ma_thuoc
  LEFT JOIN thuoc_hoat_chat tha ON tha.ma_thuoc = t.ma_thuoc
  LEFT JOIN hoat_chat ha ON ha.ma_hoat_chat = tha.ma_hoat_chat
  LEFT JOIN di_ung du ON du.ma_bn = bn.ma_bn
  LEFT JOIN hoat_chat di ON di.ma_hoat_chat = du.ma_hoat_chat
 GROUP BY bn.ma_bn, bn.ho_ten, l.ma_lh, l.trang_thai, k.ma_lan_kham,
          k.thoi_diem_kham, k.tom_tat, cd.ma_icd10, i.mo_ta, cd.trang_thai,
          d.ma_don, d.thoi_diem_ke, d.trang_thai, t.ten_thuoc, ct.so_luong, ct.lieu_dung
 ORDER BY k.thoi_diem_kham DESC NULLS LAST, d.thoi_diem_ke DESC NULLS LAST;

-- Q12. Bác sĩ có số thuốc trung bình mỗi đơn cao hơn mức trung bình chung.
WITH so_thuoc_moi_don AS (
    SELECT d.ma_don, l.ma_bac_si, COUNT(*) AS so_loai_thuoc
      FROM don_thuoc d JOIN lan_kham k ON k.ma_lan_kham = d.ma_lan_kham
      JOIN lich_hen l ON l.ma_lh = k.ma_lh
      JOIN chi_tiet_don_thuoc ct ON ct.ma_don = d.ma_don
     WHERE d.trang_thai = 'HIEU_LUC'
     GROUP BY d.ma_don, l.ma_bac_si
), muc_chung AS (
    SELECT AVG(so_loai_thuoc::NUMERIC) AS tb_chung FROM so_thuoc_moi_don
)
SELECT s.ma_bac_si, nv.ho_ten AS ten_bac_si,
       COUNT(*) AS so_don,
       ROUND(AVG(s.so_loai_thuoc::NUMERIC), 2) AS tb_loai_thuoc_moi_don,
       ROUND(m.tb_chung, 2) AS tb_chung
  FROM so_thuoc_moi_don s CROSS JOIN muc_chung m
  JOIN nhan_vien nv ON nv.ma_nv = s.ma_bac_si
 GROUP BY s.ma_bac_si, nv.ho_ten, m.tb_chung
HAVING AVG(s.so_loai_thuoc::NUMERIC) > m.tb_chung
 ORDER BY tb_loai_thuoc_moi_don DESC, s.ma_bac_si;
