# T04 – Báo cáo khảo sát mảng A: Nhân viên y tế & Lịch làm việc

| | |
|---|---|
| Mã việc | T04 (GĐ0, tuần 1) |
| Người thực hiện / review | Lê Ngọc Khôi / Đặng Hữu Khoa |
| Ngày | 19/10/2026 |
| Chuẩn tham chiếu | ISO/IEC/IEEE 29148:2018 – thu thập và phân tích yêu cầu |
| Dùng cho | T07 (BR-A), T11 (EER mảng A) |

## 1. Thông tin khảo sát

| Mục | Nội dung |
|---|---|
| Mục tiêu | Xác định dữ liệu cần lưu về bác sĩ, chuyên khoa và ca làm việc để điều phối lịch hẹn, đủ cho một CSDL đồ án môn học |
| Phạm vi | Bác sĩ phân lớp đa khoa / chuyên khoa, chuyên khoa, giấy phép hành nghề của bác sĩ, ca làm việc |
| Ngoài phạm vi | Điều dưỡng, lễ tân và nhân sự khác; cơ sở khám; lương, hợp đồng; phạm vi kỹ thuật chuyên môn chi tiết; lịch sử các lần gia hạn giấy phép |
| Đối tượng khảo sát | Phần chọn bác sĩ và xem lịch làm việc trong các ứng dụng đặt khám Medpro, YouMed, BookingCare; quy định về giấy phép và phạm vi hành nghề |
| Phương pháp | Phân tích ứng dụng hiện có và nghiên cứu văn bản pháp lý. Không phỏng vấn trực tiếp nhân viên y tế |
| Giới hạn | Không mô tả đầy đủ quản lý nhân sự y tế thật; quy định pháp lý chỉ dùng làm căn cứ cho dữ liệu, không kiểm tra điều kiện cấp phép |

## 2. Bên liên quan

| Bên liên quan | Vai trò trong quy trình | Nhu cầu dữ liệu | Trong ERD |
|---|---|---|---|
| Quản trị | Thêm bác sĩ, chuyên khoa; xếp, sửa, hủy ca làm việc | Thêm, sửa bác sĩ, chuyên khoa, ca làm việc | Không – role `r_quan_tri` |
| Bác sĩ đa khoa | Khám ban đầu, lập giấy chuyển chuyên khoa | Xem lịch làm việc của mình | Thực thể BAC_SI_DA_KHOA |
| Bác sĩ chuyên khoa | Khám theo một chuyên khoa | Xem lịch làm việc của mình | Thực thể BAC_SI_CHUYEN_KHOA |
| Lễ tân | Đặt lịch hẹn cho bệnh nhân | Xem bác sĩ theo chuyên khoa và ca còn trống | Không – role `r_le_tan` |

Tác nhân ghi "Không" là người dùng hệ thống: chỉ có role CSDL để phân quyền, không lưu thành thực thể trong ERD.

## 3. Hiện trạng quy trình

1. **Tiếp nhận bác sĩ**: quản trị lưu thông tin bác sĩ, số giấy phép hành nghề, ngày cấp, ngày hết hạn và loại bác sĩ (đa khoa hoặc chuyên khoa). Bác sĩ chuyên khoa được gắn với chuyên khoa của mình.
2. **Xếp ca**: quản trị xếp ca làm việc cho bác sĩ theo ngày và khung giờ. Bác sĩ có giấy phép hết hạn không được xếp ca. Một bác sĩ không có hai ca chồng giờ.
3. **Công bố lịch**: ứng dụng hiển thị bác sĩ theo chuyên khoa và các khung giờ còn trống trong ca để bệnh nhân hoặc lễ tân đặt lịch.
4. **Thay đổi ca**: quản trị có thể sửa giờ hoặc hủy ca. Không được sửa hoặc hủy nếu việc đó làm lịch hẹn đã nhận rơi ra ngoài giờ làm việc.
5. **Gia hạn giấy phép**: giấy phép hành nghề có hiệu lực 5 năm; khi gia hạn, quản trị cập nhật ngày hết hạn mới.

Lưu ý pháp lý: từ 01/01/2024, Luật Khám bệnh, chữa bệnh 15/2023/QH15 dùng tên **giấy phép hành nghề** (thay cho chứng chỉ hành nghề), thời hạn 5 năm. Phạm vi hành nghề của bác sĩ đa khoa và bác sĩ chuyên khoa được quy định khác nhau tại Thông tư 32/2023/TT-BYT.

## 4. Yêu cầu đối với CSDL

Rút ra từ quy trình; phát biểu chính thức, đánh số và cách kiểm chứng ở [T07](../br/T07_BR_MangA.md).

| Nguồn trong quy trình | Yêu cầu | Quy tắc |
|---|---|---|
| Bước 1: loại bác sĩ | Mỗi bác sĩ thuộc đúng một loại: đa khoa hoặc chuyên khoa | BR-A01 |
| Bước 1: gắn chuyên khoa | Mỗi bác sĩ chuyên khoa thuộc đúng một chuyên khoa | BR-A02 |
| Bước 2: giấy phép hết hạn | Chỉ xếp ca cho bác sĩ có giấy phép còn hạn đến hết ngày của ca | BR-A03 |
| Bước 2: không chồng ca | Các ca còn hiệu lực của một bác sĩ không chồng giờ | BR-A04 |
| Bước 1: số giấy phép | Số giấy phép bắt buộc và không trùng | BR-A05 |
| Bước 2: khung giờ ca | Ca kết thúc sau khi bắt đầu | BR-A06 |
| Bước 1, 5: thời hạn giấy phép | Ngày hết hạn sau ngày cấp | BR-A07 |
| Bước 4: thay đổi ca | Không sửa, hủy ca làm lịch hẹn đã nhận rơi ra ngoài ca | BR-A08 |

## 5. Ràng buộc và giả định

- Chỉ quản lý bác sĩ; điều dưỡng, lễ tân không lưu trong CSDL. Lễ tân, quản trị là người dùng hệ thống với role CSDL riêng, không phải thực thể.
- Giấy phép hành nghề là thuộc tính của bác sĩ; chỉ lưu giấy phép hiện hành, không lưu lịch sử gia hạn. Tên cột giữ `so_chung_chi`, `ngay_cap_cc`, `ngay_het_han_cc` để thống nhất với các mảng khác.
- Mỗi bác sĩ chuyên khoa thuộc đúng một chuyên khoa; bác sĩ đa khoa không gắn chuyên khoa.
- Ca làm việc lưu dạng khoảng thời gian (bắt đầu, kết thúc); ca bị hủy có trạng thái `HUY` và không tính khi kiểm tra chồng giờ.
- Phòng khám có một cơ sở; không mô hình hóa nơi làm việc của ca.

## 6. Kết quả khảo sát (đầu vào T11)

| Thực thể | Thuộc tính chính | Liên kết |
|---|---|---|
| BAC_SI (lớp cha) | ma_bac_si, ho_ten, ngay_sinh, sdt, email, so_chung_chi (UNIQUE), ngay_cap_cc, ngay_het_han_cc, loai_bac_si | 1:N CA_LAM_VIEC; 1:N LICH_HEN (B) |
| BAC_SI_DA_KHOA (lớp con) | – | ISA BAC_SI; 1:N GIAY_CHUYEN_KHOA (B) |
| BAC_SI_CHUYEN_KHOA (lớp con) | – | ISA BAC_SI; N:1 CHUYEN_KHOA |
| CHUYEN_KHOA | ma_chuyen_khoa, ten_chuyen_khoa | 1:N BAC_SI_CHUYEN_KHOA; 1:N GIAY_CHUYEN_KHOA (B) |
| CA_LAM_VIEC | ma_ca, thoi_gian_bd, thoi_gian_kt, trang_thai | N:1 BAC_SI |

Các liên kết:

| Liên kết | Thực thể tham gia | Tỉ số | Thuộc tính |
|---|---|---|---|
| THUỘC | CHUYEN_KHOA – BAC_SI_CHUYEN_KHOA | 1:N | – |
| XẾP_CA | BAC_SI – CA_LAM_VIEC | 1:N | – |

Phân lớp BAC_SI → {BAC_SI_DA_KHOA, BAC_SI_CHUYEN_KHOA}: mỗi bác sĩ thuộc **đúng một** lớp con, phân theo thuộc tính `loai_bac_si`. Đây là điểm EER trọng tâm của đề tài.

## Nguồn tham khảo

- Medpro – hình thức đặt khám: https://medpro.vn/cho-ray/hinh-thuc-dat-kham
- YouMed (App Store): https://apps.apple.com/app/id1466077723
- BookingCare (App Store): https://apps.apple.com/vn/app/id1347700144
- Luật Khám bệnh, chữa bệnh số 15/2023/QH15: https://thuvienphapluat.vn/van-ban/The-thao-Y-te/Luat-15-2023-QH15-kham-benh-chua-benh-372143.aspx
- Thông tư 32/2023/TT-BYT quy định chi tiết Luật Khám bệnh, chữa bệnh: https://trungtamytekhanhson.khanhhoa.gov.vn/wp-content/uploads/2024/01/Thông-tư-32-2023-TT-BYT.pdf
- ISO/IEC/IEEE 29148:2018 – Systems and software engineering — Life cycle processes — Requirements engineering.
