# T28 – Chứng minh chuẩn hóa mảng C

| | |
|---|---|
| Mã việc | T28 (GĐ2) |
| Người làm / review | Nguyễn Đăng Khoa / Đặng Hữu Khoa |
| Căn cứ | [T21 – ánh xạ C](../5_anh-xa/T21_AnhXa_MangC.md), [T25 – FD và khóa C](T25_FD_MangC.md), [T22 – khuôn](T22_Khuon_ChuanHoa.md) |

## 1. Kiểm tra 1NF và 2NF

Mỗi thuộc tính lưu một giá trị đơn theo miền đã xác định. Danh sách hoạt chất của thuốc, dị ứng, chẩn đoán và thuốc trong đơn đều được tách thành các quan hệ riêng; do đó không lưu nhóm giá trị lặp trong một ô. Các quan hệ đạt 1NF.

Các quan hệ có khóa đơn hiển nhiên không thể có phụ thuộc bộ phận vào khóa. Với ba quan hệ khóa ghép:

- `CHI_TIET_DON_THUOC(ma_don, ma_thuoc, so_luong, lieu_dung)`: theo quy tắc một thuốc xuất hiện tối đa một lần trong một đơn, không có FD từ riêng `ma_don` hoặc riêng `ma_thuoc` đến số lượng/liều dùng.
- `THUOC_HOAT_CHAT(ma_thuoc, ma_hoat_chat, ham_luong)`: lượng thành phần phụ thuộc vào đúng cặp thuốc–hoạt chất, không phụ thuộc riêng một thành phần.
- `DI_UNG(ma_bn, ma_hoat_chat, ngay_ghi_nhan, ghi_chu)`: thuộc tính ghi nhận phụ thuộc cặp bệnh nhân–hoạt chất; mô hình chỉ giữ một hàng dị ứng hiện hành cho mỗi cặp.

Vì vậy không có FD bộ phận của thuộc tính không khóa; tất cả quan hệ đạt 2NF.

## 2. Kiểm tra 3NF và BCNF

| Quan hệ | FD không tầm thường | Vế trái là siêu khóa? | Kết luận |
|---|---|---:|---|
| LAN_KHAM | `ma_lan_kham → ...`; `ma_lh → ...` | Có; cả hai là khóa ứng viên | BCNF |
| CHAN_DOAN | `ma_chan_doan → ...` | Có | BCNF |
| MA_ICD10 | `ma_icd10 → mo_ta` | Có | BCNF |
| DON_THUOC | `ma_don → ...` | Có | BCNF |
| THUOC | `ma_thuoc → ...` | Có | BCNF |
| HOAT_CHAT | `ma_hoat_chat → ten_hoat_chat`; `ten_hoat_chat → ma_hoat_chat` | Có; cả hai là khóa ứng viên | BCNF |
| CHI_TIET_DON_THUOC | `(ma_don, ma_thuoc) → so_luong, lieu_dung` | Có | BCNF |
| THUOC_HOAT_CHAT | `(ma_thuoc, ma_hoat_chat) → ham_luong` | Có | BCNF |
| DI_UNG | `(ma_bn, ma_hoat_chat) → ngay_ghi_nhan, ghi_chu` | Có | BCNF |

Mỗi FD không tầm thường có vế trái là khóa ứng viên (hoặc khóa ghép); do đó mọi quan hệ đạt BCNF, kéo theo 3NF. Không cần phân rã thêm theo tập FD hiện tại.

## 3. Dư thừa được tránh bằng thiết kế

- Không lưu bệnh nhân/bác sĩ trong `LAN_KHAM` và `DON_THUOC`; nếu lưu, các giá trị đó phụ thuộc vào lịch hẹn/lần khám và có thể mâu thuẫn khi lịch được liên kết sai.
- Danh mục ICD, thuốc, hoạt chất tách riêng; tên/mô tả không lặp trong mỗi chẩn đoán hay đơn thuốc.
- Thuốc–hoạt chất và bệnh nhân–dị ứng là quan hệ M:N có bảng kết hợp, giữ thuộc tính phụ thuộc toàn bộ khóa ghép.
- `ham_luong` ở `THUOC` (mô tả hàm lượng chung/nhãn) khác ngữ nghĩa `ham_luong` ở `THUOC_HOAT_CHAT` (lượng của một thành phần trong thuốc). Nếu nhóm xác nhận hai thuộc tính trùng cùng một sự kiện, cần sửa ERD thay vì lưu trùng.

## 4. Giới hạn kết luận

Kết luận dựa trên các khóa/UNIQUE và ngữ nghĩa đã nêu tại T21/T25, không dựa vào những quy tắc chưa được cưỡng chế. Ví dụ, nếu bổ sung quy tắc “mỗi lần khám có tối đa một chẩn đoán chính”, ràng buộc đó không tự tạo FD toàn cục `ma_lan_kham → ma_chan_doan` (vì có thể chưa có chẩn đoán chính); phải trình bày riêng như ràng buộc có điều kiện. Khi thay đổi ERD/BR hoặc T18, cần rà soát lại T25 và chứng minh này.
