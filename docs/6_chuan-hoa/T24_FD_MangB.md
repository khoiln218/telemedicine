# T24 – Phụ thuộc hàm và khóa ứng viên mảng B: Bệnh nhân & Lịch hẹn

| | |
|---|---|
| Mã việc | T24 (GĐ2, tuần 6) |
| Người làm / review | Lê Ngọc Khôi / Nguyễn Đăng Khoa |
| Ngày | 27/10/2026 |
| Chuẩn tham chiếu | Elmasri & Navathe, *Fundamentals of Database Systems* (7th ed.), chương 14 (phụ thuộc hàm, khóa), chương 15 (bao đóng, phủ tối thiểu) |
| Căn cứ | [T20 – lược đồ quan hệ mảng B](../5_anh-xa/T20_AnhXa_MangB.md), [T08 – quy tắc mảng B](../2_quy-tac/T08_BR_MangB.md) |
| Dùng cho | T27 (chứng minh 3NF/BCNF mảng B), báo cáo mục 2.3 |

Cách làm cho mỗi bảng:

1. Liệt kê FD có căn cứ (khóa trong ERD, quy tắc nghiệp vụ, quyết định đã chốt ở T08 mục 5); F đã là phủ tối thiểu (vế phải một thuộc tính, vế trái không thừa, không FD thừa).
2. Ghi các FD đã xét và loại, kèm lý do, để T27 không phải xét lại.
3. Tìm khóa ứng viên: thuộc tính không xuất hiện ở vế phải của FD nào phải có trong mọi khóa; kiểm tra bằng bao đóng X⁺.

Quy ước: khóa ứng viên không được NULL. Thuộc tính UNIQUE cho phép NULL (`ma_giay`, `ma_bn`, `ma_nv` trong tài khoản) cho FD chỉ đúng trên các hàng khác NULL; ghi là FD có điều kiện và không tính là khóa ứng viên.

Để gọn, "→ tất cả" là xác định mọi thuộc tính còn lại của bảng (tách thành từng FD một thuộc tính vế phải).

## 1. BENH_NHAN

BENH_NHAN(<u>ma_bn</u>, ho_ten, ngay_sinh, gioi_tinh, sdt, email)

| FD | Căn cứ |
|---|---|
| ma_bn → ho_ten, ngay_sinh, gioi_tinh, sdt, email | Khóa của thực thể `BENH_NHAN` |
| sdt → ma_bn | Số điện thoại không trùng, bắt buộc (ràng buộc chung, T20) |

FD đã xét và loại:

| FD | Lý do loại |
|---|---|
| email → ma_bn | Email không bắt buộc và không yêu cầu duy nhất (người nhà có thể dùng chung) |
| ho_ten, ngay_sinh → ma_bn | Có thể trùng họ tên và ngày sinh |

Khóa ứng viên:

- ho_ten, ngay_sinh, gioi_tinh, email không ở vế trái FD nào nên không góp vào khóa. Còn lại ma_bn, sdt.
- {ma_bn}⁺ = tất cả; {sdt}⁺ = {sdt, ma_bn} ∪ {ma_bn}⁺ = tất cả. Cả hai chỉ có một thuộc tính nên tối thiểu.
- **Khóa ứng viên: {ma_bn}, {sdt}.** Khóa chính: ma_bn. Thuộc tính khóa: ma_bn, sdt.

## 2. GIAY_CHUYEN_KHOA

GIAY_CHUYEN_KHOA(<u>ma_giay</u>, ngay_lap, ly_do, ngay_het_han, ma_bn, ma_bac_si_lap, ma_chuyen_khoa)

| FD | Căn cứ |
|---|---|
| ma_giay → ngay_lap, ly_do, ngay_het_han, ma_bn, ma_bac_si_lap, ma_chuyen_khoa | Khóa của thực thể; mỗi giấy cấp cho một bệnh nhân, do một bác sĩ lập, đến một chuyên khoa (liên kết 1:N) |

FD đã xét và loại:

| FD | Lý do loại |
|---|---|
| ngay_lap → ngay_het_han | BR-B07 chỉ giới hạn hạn **tối đa** 30 ngày, bác sĩ chọn hạn ngắn hơn được. Nếu nhóm đổi thành hạn cố định 30 ngày thì FD này đúng, `ngay_het_han` là thuộc tính suy ra và nên bỏ khỏi bảng |
| ma_bac_si_lap → ma_chuyen_khoa | Bác sĩ đa khoa chuyển đến nhiều chuyên khoa khác nhau |
| ma_bn, ma_chuyen_khoa → ma_giay | Một bệnh nhân có thể được cấp nhiều giấy cùng chuyên khoa ở các lần khác nhau |
| ma_bn, ngay_lap → ma_giay | Cùng ngày có thể được chuyển đến hai chuyên khoa |

Khóa ứng viên:

- ma_giay không ở vế phải FD nào nên có trong mọi khóa; {ma_giay}⁺ = tất cả.
- **Khóa ứng viên duy nhất: {ma_giay}.** Thuộc tính khóa: ma_giay.

## 3. LICH_HEN

LICH_HEN(<u>ma_lh</u>, thoi_gian_bd, thoi_gian_kt, ly_do_kham, trang_thai, hinh_thuc, phi_kham, ngay_tao, phong_kham, nen_tang, link_phien, ma_bn, ma_bac_si, ma_giay)

| FD | Căn cứ |
|---|---|
| ma_lh → thoi_gian_bd, thoi_gian_kt, ly_do_kham, trang_thai, hinh_thuc, phi_kham, ngay_tao, phong_kham, nen_tang, link_phien, ma_bn, ma_bac_si, ma_giay | Khóa của thực thể; mỗi lịch hẹn của một bệnh nhân, một bác sĩ, tối đa một giấy |
| ma_giay → ma_lh (có điều kiện) | `SỬ_DỤNG` 1:1, `ma_giay` UNIQUE; chỉ đúng khi `ma_giay` khác NULL |

FD đã xét và loại:

| FD | Lý do loại |
|---|---|
| ma_bac_si, thoi_gian_bd → ma_lh | BR-B02 chỉ cấm giao nhau giữa các lịch **còn hiệu lực**; lịch đã hủy, vắng mặt có thể cùng giờ với lịch mới của cùng bác sĩ. Tương tự với ma_bn, thoi_gian_bd |
| ma_bac_si → phi_kham | Phí khám gắn với từng lịch hẹn (T08 mục 5), không cố định theo bác sĩ |
| ma_bac_si → ma_chuyen_khoa | Không lưu chuyên khoa trong lịch hẹn (T08 mục 5), nên không có phụ thuộc bắc cầu qua bác sĩ |
| hinh_thuc → phong_kham / nen_tang / link_phien | `hinh_thuc` chỉ quyết định cột nào có giá trị (ràng buộc theo hàng của 8C, T20 mục 2.2), không quyết định giá trị cụ thể |
| link_phien → ma_lh | Không yêu cầu đường dẫn phiên duy nhất (bác sĩ có thể dùng một phòng họp cố định) |
| ma_giay → ma_bn | Giấy và lịch hẹn cùng bệnh nhân là ràng buộc giữa hai bảng (BR-B03); trong bảng này nó đã nằm trong ma_giay → ma_lh → ma_bn |

Khóa ứng viên:

- ma_lh chỉ ở vế phải FD có điều kiện; với các hàng `ma_giay` NULL không có thuộc tính nào khác xác định ma_lh, nên ma_lh có trong mọi khóa. {ma_lh}⁺ = tất cả.
- `ma_giay` cho {ma_giay}⁺ = tất cả trên các hàng có giấy, nhưng cho phép NULL nên không là khóa ứng viên.
- **Khóa ứng viên duy nhất: {ma_lh}.** Thuộc tính khóa: ma_lh.

## 4. TAI_KHOAN

TAI_KHOAN(<u>ten_dang_nhap</u>, mat_khau_hash, vai_tro, trang_thai, ma_bn, ma_nv)

| FD | Căn cứ |
|---|---|
| ten_dang_nhap → mat_khau_hash, vai_tro, trang_thai, ma_bn, ma_nv | Khóa của thực thể `TAI_KHOAN` |
| ma_bn → ten_dang_nhap (có điều kiện) | Mỗi bệnh nhân tối đa một tài khoản (BR-B09); khi `ma_bn` khác NULL |
| ma_nv → ten_dang_nhap (có điều kiện) | Mỗi nhân viên tối đa một tài khoản (BR-B09); khi `ma_nv` khác NULL |

FD đã xét và loại:

| FD | Lý do loại |
|---|---|
| mat_khau_hash → ten_dang_nhap | Hai tài khoản có thể cùng mật khẩu; hàm băm có muối cũng không bảo đảm duy nhất theo nghĩa nghiệp vụ |
| vai_tro → trang_thai | Không liên quan |

Khóa ứng viên:

- ten_dang_nhap chỉ ở vế phải các FD có điều kiện; mỗi hàng có đúng một trong `ma_bn`, `ma_nv` NULL nên không thuộc tính nào khác xác định ten_dang_nhap trên mọi hàng. {ten_dang_nhap}⁺ = tất cả.
- **Khóa ứng viên duy nhất: {ten_dang_nhap}.** Thuộc tính khóa: ten_dang_nhap.

## 5. Tổng hợp cho T27

| Bảng | Khóa ứng viên | Vế trái các FD | Nhận xét |
|---|---|---|---|
| BENH_NHAN | {ma_bn}, {sdt} | ma_bn, sdt | Mọi vế trái là khóa ứng viên |
| GIAY_CHUYEN_KHOA | {ma_giay} | ma_giay | Mọi vế trái là khóa ứng viên |
| LICH_HEN | {ma_lh} | ma_lh, ma_giay (có điều kiện) | `ma_giay` xác định cả hàng khi khác NULL; T27 cần lập luận riêng cho FD này |
| TAI_KHOAN | {ten_dang_nhap} | ten_dang_nhap, ma_bn, ma_nv (có điều kiện) | Như LICH_HEN |

Điểm cần thống nhất ở T27, T30:

- **FD có điều kiện** (vế trái UNIQUE cho phép NULL): đề xuất coi vế trái là khóa trên các hàng có giá trị, nên không gây dư thừa; cần Đăng Khoa chốt cách trình bày chung cho cả 3 mảng ở T22.
- **`TAI_KHOAN.vai_tro` với nhân viên** trùng thông tin với `NHAN_VIEN.loai_nv` (BR-B09 buộc khớp). Đây là dư thừa giữa hai bảng, chuẩn hóa từng bảng không phát hiện được. Đồng thời BR-B10 cho quản trị tài khoản "đổi vai trò", trong khi loại nhân viên do quản trị nhân sự sửa (BR-A09). Cần chốt ở T30: giữ `vai_tro` và kiểm tra khớp khi cài đặt, hay bỏ `vai_tro` và suy ra từ `loai_nv` (bệnh nhân suy từ `ma_bn`).
