# T25 – Phụ thuộc hàm và khóa mảng C

| | |
|---|---|
| Mã việc | T25 (GĐ2) |
| Người làm / review | Nguyễn Đăng Khoa / Đặng Hữu Khoa |
| Căn cứ | [T21 – ánh xạ C](../5_anh-xa/T21_AnhXa_MangC.md), [T22 – khuôn](T22_Khuon_ChuanHoa.md), [ERD C](../3_erd/C.drawio) |

## 1. Giả định dùng để suy ra FD

Theo T21: mã định danh là PK; `LAN_KHAM.ma_lh` và `HOAT_CHAT.ten_hoat_chat` là `UNIQUE NOT NULL`; các bảng kết hợp có PK ghép; mỗi thuốc xuất hiện tối đa một lần trong một đơn; một hoạt chất có tối đa một hàng dị ứng đang tồn tại cho mỗi bệnh nhân. FK không tự tạo FD. `created_by` chỉ lưu tài khoản tạo và không xác định các thuộc tính khác.

Ký hiệu ở các bảng dưới đây: `X → A` là một FD tối thiểu; các FD có cùng vế trái được gộp ở phần khóa nhưng khai triển ở phủ tối thiểu.

## 2. FD tối thiểu và khóa ứng viên

| Quan hệ | Phủ tối thiểu F (khai triển RHS) | Khóa ứng viên |
|---|---|---|
| LAN_KHAM(`ma_lan_kham`, `ma_lh`, thoi_diem_kham, tom_tat, created_by) | `ma_lan_kham → ma_lh, thoi_diem_kham, tom_tat, created_by`; `ma_lh → ma_lan_kham, thoi_diem_kham, tom_tat, created_by` | `{ma_lan_kham}`, `{ma_lh}` |
| CHAN_DOAN(`ma_chan_doan`, ma_lan_kham, ma_icd10, la_chan_doan_chinh, ghi_chu, trang_thai) | `ma_chan_doan → ma_lan_kham, ma_icd10, la_chan_doan_chinh, ghi_chu, trang_thai` | `{ma_chan_doan}` |
| MA_ICD10(`ma_icd10`, mo_ta) | `ma_icd10 → mo_ta` | `{ma_icd10}` |
| DON_THUOC(`ma_don`, ma_lan_kham, thoi_diem_ke, trang_thai, created_by) | `ma_don → ma_lan_kham, thoi_diem_ke, trang_thai, created_by` | `{ma_don}` |
| THUOC(`ma_thuoc`, ten_thuoc, dang_bao_che, ham_luong) | `ma_thuoc → ten_thuoc, dang_bao_che, ham_luong` | `{ma_thuoc}` |
| HOAT_CHAT(`ma_hoat_chat`, ten_hoat_chat) | `ma_hoat_chat → ten_hoat_chat`; `ten_hoat_chat → ma_hoat_chat` | `{ma_hoat_chat}`, `{ten_hoat_chat}` |
| CHI_TIET_DON_THUOC(`ma_don`, `ma_thuoc`, so_luong, lieu_dung) | `(ma_don, ma_thuoc) → so_luong`; `(ma_don, ma_thuoc) → lieu_dung` | `{ma_don, ma_thuoc}` |
| THUOC_HOAT_CHAT(`ma_thuoc`, `ma_hoat_chat`, ham_luong) | `(ma_thuoc, ma_hoat_chat) → ham_luong` | `{ma_thuoc, ma_hoat_chat}` |
| DI_UNG(`ma_bn`, `ma_hoat_chat`, ngay_ghi_nhan, ghi_chu) | `(ma_bn, ma_hoat_chat) → ngay_ghi_nhan`; `(ma_bn, ma_hoat_chat) → ghi_chu` | `{ma_bn, ma_hoat_chat}` |

## 3. Lập luận khóa

- Với các quan hệ có một mã PK (trừ `LAN_KHAM`, `HOAT_CHAT` ở hai ý dưới), mã không xuất hiện ở vế phải FD nào và xác định toàn bộ thuộc tính; vì vậy mọi khóa phải chứa mã và tập mã là tối thiểu.
- Trong `LAN_KHAM`, `ma_lh` vừa FK vừa `UNIQUE NOT NULL`. Bội số 1:1 cùng tham gia toàn phần phía lần khám cho hai chiều xác định; bao đóng của mỗi mã chứa toàn bộ thuộc tính nên cả hai đều là khóa ứng viên.
- Trong `HOAT_CHAT`, `ten_hoat_chat` là `UNIQUE NOT NULL` nên `{ten_hoat_chat}+ = {ten_hoat_chat, ma_hoat_chat}`; quan hệ chỉ có hai thuộc tính nên mỗi thuộc tính là một khóa ứng viên một phần tử.
- Ở `CHI_TIET_DON_THUOC`, `THUOC_HOAT_CHAT`, `DI_UNG`, không có FD từ riêng từng thành phần theo mô hình đã chốt. PK ghép xác định thuộc tính còn lại; bỏ một thành phần thì không thể xác định một dòng duy nhất.

## 4. FD không được giả định

- Không có `ma_lan_kham → ma_bn, ma_bac_si` trong bảng lần khám vì hai thuộc tính đó không được lưu; chúng được suy ra qua `ma_lh`.
- Không có `ma_don → ma_thuoc` hoặc `ma_thuoc → ma_don`; đây là quan hệ M:N.
- Không có `ma_hoat_chat → ham_luong` trong THUOC_HOAT_CHAT: lượng phụ thuộc vào cả thuốc và thành phần.
- Tên thuốc không được giả định duy nhất; chỉ `ma_thuoc` là khóa của THUOC. Tên hoạt chất thì duy nhất (T21), xem mục 3.
- Cờ chẩn đoán chính không được mặc định duy nhất mỗi lần khám trong tầng FD. Nếu nghiệp vụ muốn tối đa một chẩn đoán chính, đó là ràng buộc duy nhất có điều kiện và cần được ghi riêng/triển khai riêng.

## 5. Kết luận

Các khóa ghép không có FD bộ phận theo giả định mô hình; các FD không tầm thường còn lại có vế trái là khóa ứng viên. Phân tích chuẩn hóa chi tiết ở [T28](T28_ChuanHoa_MangC.md). Nếu nhóm đổi ràng buộc `ma_lh` hoặc PK của bảng kết hợp, cần cập nhật lại bảng FD và chứng minh khóa.
