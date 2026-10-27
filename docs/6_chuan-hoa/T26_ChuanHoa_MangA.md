# T26 – Chứng minh chuẩn hóa mảng A

| | |
|---|---|
| Mã việc | T26 (GĐ2) |
| Căn cứ | [T19 – ánh xạ](../5_anh-xa/T19_AnhXa_MangA.md), [T23 – FD và khóa](T23_FD_MangA.md) |

**Kết luận: các quan hệ mảng A đạt BCNF theo các FD đã xác định; không cần tách bảng.** BCNF mạnh hơn 3NF nên các quan hệ cũng đạt 3NF và 2NF.

## 1. 1NF

Mỗi cột chứa một giá trị đơn: ngày và thời điểm không gộp thành chuỗi; mỗi bác sĩ chỉ có một loại; ca và chuyên khoa không lưu danh sách lặp. Do đó các quan hệ đạt 1NF.

## 2. 2NF, 3NF và BCNF

| Quan hệ | Khóa ứng viên | FD không tầm thường | Kiểm tra định thức | Kết luận |
|---|---|---|---|---|
| NHAN_VIEN | `ma_nv`, `sdt` | Hai khóa trên xác định các thuộc tính còn lại | Mỗi định thức là khóa ứng viên | BCNF |
| BAC_SI | `ma_bac_si`, `so_chung_chi` | Hai khóa trên xác định các thuộc tính còn lại | Mỗi định thức là khóa ứng viên | BCNF |
| BAC_SI_DA_KHOA | `ma_bac_si` | Không có | Không có FD không tầm thường | BCNF |
| BAC_SI_CHUYEN_KHOA | `ma_bac_si` | `ma_bac_si → ma_chuyen_khoa` | Định thức là khóa | BCNF |
| CHUYEN_KHOA | `ma_chuyen_khoa`, `ten_chuyen_khoa` | Mỗi khóa xác định khóa kia | Mỗi định thức là khóa | BCNF |
| CA_LAM_VIEC | `ma_ca` | `ma_ca →` các thuộc tính còn lại | Định thức là khóa | BCNF |

Không có khóa ghép nên không thể có phụ thuộc bộ phận; 2NF được thỏa. Trong mọi FD không tầm thường được nêu ở T23, vế trái là khóa ứng viên, thỏa BCNF; do đó thỏa điều kiện 3NF.

## 3. Phụ thuộc suy ra và phạm vi kết luận

- `ngay_cap_cc < ngay_het_han_cc`, kiểm tra thời hạn giấy phép khi xếp ca, chồng giờ và điều kiện lớp con là ràng buộc miền/liên bảng, không phải FD giữa thuộc tính trong cùng một hàng.
- `loai_nv` chi phối việc có hàng ở BAC_SI là ràng buộc tham chiếu chuyên biệt hóa, không biểu diễn thành FD trong một quan hệ vì hai thuộc tính nằm ở hai bảng.
- Kết luận dựa trên các quy tắc nghiệp vụ đã chốt. Nếu nhóm không coi `sdt` hoặc `ten_chuyen_khoa` là duy nhất, bỏ FD tương ứng; khóa chính và kết luận BCNF của các quan hệ vẫn giữ nguyên.
