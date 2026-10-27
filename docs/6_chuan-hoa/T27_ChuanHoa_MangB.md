# T27 – Chứng minh chuẩn hóa mảng B: Bệnh nhân & Lịch hẹn

| | |
|---|---|
| Mã việc | T27 (GĐ2, tuần 7) |
| Người làm / review | Lê Ngọc Khôi / Nguyễn Đăng Khoa |
| Ngày | 27/10/2026 |
| Chuẩn tham chiếu | Elmasri & Navathe, *Fundamentals of Database Systems* (7th ed.), chương 14: định nghĩa 1NF, 2NF, 3NF, BCNF tổng quát (theo mọi khóa ứng viên) |
| Căn cứ | [T20 – lược đồ quan hệ mảng B](../5_anh-xa/T20_AnhXa_MangB.md), [T24 – FD và khóa ứng viên mảng B](T24_FD_MangB.md) |
| Dùng cho | Báo cáo mục 2.3 (phần B), T30 (review chéo) |

**Kết luận: cả 4 bảng mảng B đạt BCNF (nên đạt 3NF), không phải tách bảng.**

## 1. Định nghĩa dùng để kiểm tra

Với lược đồ R, tập FD F (phủ tối thiểu ở T24), thuộc tính khóa là thuộc tính nằm trong ít nhất một khóa ứng viên.

| Dạng chuẩn | Điều kiện |
|---|---|
| 1NF | Miền mọi thuộc tính là nguyên tố: không thuộc tính đa trị, phức hợp, quan hệ lồng |
| 2NF | 1NF và không thuộc tính không khóa nào phụ thuộc vào một phần thực sự của một khóa ứng viên |
| 3NF | Với mọi FD không tầm thường X → A: X là siêu khóa, hoặc A là thuộc tính khóa |
| BCNF | Với mọi FD không tầm thường X → A: X là siêu khóa |

Cách chứng minh: BCNF suy ra 3NF, 3NF suy ra 2NF. Vì vậy chỉ cần chứng minh 1NF và BCNF; 2NF, 3NF được nêu để đối chiếu với mẫu báo cáo.

## 2. 1NF

| Bảng | Kiểm tra | Kết quả |
|---|---|---|
| BENH_NHAN | `ho_ten` lưu nguyên một chuỗi (không có yêu cầu tìm theo họ, tên riêng); `sdt`, `email` mỗi bệnh nhân một giá trị | Đạt |
| GIAY_CHUYEN_KHOA | Mỗi giấy một chuyên khoa, một bác sĩ lập, một bệnh nhân | Đạt |
| LICH_HEN | Giờ hẹn tách thành hai thuộc tính nguyên tố `thoi_gian_bd`, `thoi_gian_kt`; mỗi lịch hẹn một hình thức, một phòng hoặc một đường dẫn phiên. Các cột NULL theo hình thức (8C) không làm mất tính nguyên tố | Đạt |
| TAI_KHOAN | Mỗi tài khoản đúng một vai trò (T08 mục 5) | Đạt |

ERD mảng B không có thuộc tính đa trị hay phức hợp, nên bước 6 của ánh xạ (T20) không sinh bảng nào.

## 3. 2NF, 3NF, BCNF

| Bảng | Khóa ứng viên | FD trong F (T24) | X là siêu khóa? | Kết luận |
|---|---|---|---|---|
| BENH_NHAN | {ma_bn}, {sdt} | ma_bn → ho_ten, ngay_sinh, gioi_tinh, sdt, email | Có (khóa ứng viên) | BCNF |
| | | sdt → ma_bn | Có (khóa ứng viên) | |
| GIAY_CHUYEN_KHOA | {ma_giay} | ma_giay → ngay_lap, ly_do, ngay_het_han, ma_bn, ma_bac_si_lap, ma_chuyen_khoa | Có | BCNF |
| LICH_HEN | {ma_lh} | ma_lh → (13 thuộc tính còn lại) | Có | BCNF, xem 3.1 |
| | | ma_giay → ma_lh (có điều kiện) | Có trên các hàng có giá trị, xem 3.1 | |
| TAI_KHOAN | {ten_dang_nhap} | ten_dang_nhap → mat_khau_hash, vai_tro, trang_thai, ma_bn, ma_nv | Có | BCNF, xem 3.1 |
| | | ma_bn → ten_dang_nhap, ma_nv → ten_dang_nhap (có điều kiện) | Có trên các hàng có giá trị, xem 3.1 | |

2NF: mọi khóa ứng viên của 4 bảng chỉ có một thuộc tính, nên không có "một phần thực sự của khóa" để phụ thuộc vào. Bốn bảng đạt 2NF ngay khi đạt 1NF.

3NF, BCNF: với các FD thường, vế trái luôn là khóa ứng viên. Với FD không tầm thường X → A bất kỳ trong F⁺: nếu X không chứa vế trái nào của F thì không FD nào áp dụng được, X⁺ = X và X → A tầm thường; vậy X chứa một khóa ứng viên, tức X là siêu khóa. Do đó không có phụ thuộc bắc cầu qua thuộc tính không khóa.

### 3.1. FD có điều kiện

Ba cột `LICH_HEN.ma_giay`, `TAI_KHOAN.ma_bn`, `TAI_KHOAN.ma_nv` là UNIQUE nhưng cho phép NULL, nên không là khóa ứng viên (T24), và định nghĩa BCNF theo đúng chữ không áp dụng trực tiếp.

Lập luận không có dư thừa: BCNF nhằm loại bỏ trường hợp cùng một giá trị vế trái X lặp lại ở nhiều hàng, kéo theo vế phải lặp lại. Với ba cột trên, UNIQUE bảo đảm mỗi giá trị khác NULL xuất hiện ở tối đa một hàng; hàng NULL không tham gia FD. Vì vậy trên mọi hàng mà FD có hiệu lực, vế trái là siêu khóa, không thể có dữ liệu lặp và không có dị thường cập nhật.

Phương án tách để đạt BCNF theo đúng định nghĩa, và lý do không chọn:

| Tách thành | Lý do không chọn |
|---|---|
| LICH_HEN bỏ `ma_giay` + SU_DUNG(<u>ma_lh</u>, ma_giay) với `ma_giay` UNIQUE NOT NULL | Lịch hẹn chuyên khoa phải ghi hai bảng; kiểm tra BR-B03 (giấy của chính bệnh nhân, đúng chuyên khoa) phải nối thêm một bảng. Không giảm dư thừa vì bảng gốc vốn không có |
| TAI_KHOAN bỏ `ma_bn`, `ma_nv` + TK_BENH_NHAN(<u>ten_dang_nhap</u>, ma_bn), TK_NHAN_VIEN(<u>ten_dang_nhap</u>, ma_nv) | Điều kiện "mỗi tài khoản gắn đúng một người" (BR-B09) chuyển từ kiểm tra trên một hàng thành kiểm tra giữa ba bảng |

## 4. Thiết kế đã tránh vi phạm chuẩn

Một số quyết định ở T08 mục 5 và T20 đã loại trước các vi phạm 3NF. Ghi lại để T30 không đưa nhầm trở lại.

| Nếu thiết kế khác đi | FD phát sinh | Vi phạm |
|---|---|---|
| Lưu `ma_chuyen_khoa` trong LICH_HEN | ma_bac_si → ma_chuyen_khoa | 3NF: bắc cầu ma_lh → ma_bac_si → ma_chuyen_khoa |
| Phí khám cố định theo bác sĩ | ma_bac_si → phi_kham | 3NF: bắc cầu qua ma_bac_si; phải tách bảng phí |
| Giấy chuyển hạn đúng 30 ngày | ngay_lap → ngay_het_han | 3NF: `ngay_het_han` là thuộc tính suy ra, phải bỏ |
| Chép họ tên, số điện thoại bệnh nhân vào LICH_HEN | ma_bn → ho_ten, sdt | 3NF: bắc cầu qua ma_bn |
| Phân lớp lịch hẹn theo 8B (T20 mục 2.2) | – | Không vi phạm dạng chuẩn, nhưng thuộc tính chung chép ở hai bảng |

## 5. Ngoài phạm vi chuẩn hóa từng bảng

`TAI_KHOAN.vai_tro` của tài khoản nhân viên trùng thông tin với `NHAN_VIEN.loai_nv` (BR-B09 buộc khớp). Đây là dư thừa **giữa hai bảng** (cùng một sự kiện lưu ở hai nơi). Chuẩn hóa xét từng bảng với FD của chính nó, nên không phát hiện và không xử lý được trường hợp này; TAI_KHOAN vẫn đạt BCNF.

Đề xuất cho T30: giữ `vai_tro` vì đây là cột duy nhất cho biết vai trò của mọi tài khoản, kể cả bệnh nhân (không có `loai_nv`), và phân quyền đọc vai trò từ một chỗ. Việc khớp với `loai_nv` kiểm tra khi cài đặt (T37). Mâu thuẫn giữa BR-B10 (quản trị tài khoản đổi vai trò) và BR-A09 (quản trị nhân sự sửa loại nhân viên) cần nhóm chốt ở T30.
