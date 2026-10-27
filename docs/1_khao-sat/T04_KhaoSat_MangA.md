# T04 – Báo cáo khảo sát mảng A: Nhân viên y tế & Lịch làm việc

| | |
|---|---|
| Mã việc | T04 (GĐ0, tuần 1) |
| Người thực hiện / review | Lê Ngọc Khôi / Đặng Hữu Khoa |
| Ngày | 19/10/2026; cập nhật 21/10/2026 tách quản trị theo 3 mảng |
| Chuẩn tham chiếu | ISO/IEC/IEEE 29148:2018 – thu thập và phân tích yêu cầu |
| Dùng cho | T07 (BR-A), T11 (EER mảng A) |

## 1. Thông tin khảo sát

| Mục | Nội dung |
|---|---|
| Mục tiêu | Xác định dữ liệu cần lưu về bác sĩ, chuyên khoa và ca làm việc để điều phối lịch hẹn, đủ cho một CSDL đồ án môn học |
| Phạm vi | Nhân viên (bác sĩ, lễ tân, ba loại quản trị), bác sĩ phân lớp đa khoa / chuyên khoa, chuyên khoa, giấy phép hành nghề của bác sĩ, ca làm việc |
| Ngoài phạm vi | Điều dưỡng và nhân sự khác; cơ sở khám; lương, hợp đồng; phạm vi kỹ thuật chuyên môn chi tiết; lịch sử các lần gia hạn giấy phép |
| Đối tượng khảo sát | Phần chọn bác sĩ và xem lịch làm việc trong các ứng dụng đặt khám Medpro, YouMed, BookingCare; quy định về giấy phép và phạm vi hành nghề |
| Phương pháp | Phân tích ứng dụng hiện có và nghiên cứu văn bản pháp lý. Không phỏng vấn trực tiếp nhân viên y tế |
| Giới hạn | Không mô tả đầy đủ quản lý nhân sự y tế thật; quy định pháp lý chỉ dùng làm căn cứ cho dữ liệu, không kiểm tra điều kiện cấp phép |

## 2. Bên liên quan

| Bên liên quan | Vai trò trong quy trình | Nhu cầu dữ liệu |
|---|---|---|
| Quản trị nhân sự | Thêm nhân viên, bác sĩ, chuyên khoa; xếp, sửa, hủy ca làm việc | Thêm, sửa nhân viên, bác sĩ, chuyên khoa, ca làm việc |
| Bác sĩ đa khoa | Khám ban đầu, lập giấy chuyển chuyên khoa | Xem lịch làm việc của mình |
| Bác sĩ chuyên khoa | Khám theo một chuyên khoa | Xem lịch làm việc của mình |
| Lễ tân | Đặt lịch hẹn cho bệnh nhân | Xem bác sĩ theo chuyên khoa và ca còn trống |

Mọi tác nhân là người của phòng khám đều là nhân viên; bác sĩ có thêm thông tin hành nghề. Quản trị tách theo mảng: quản trị nhân sự (mảng A), quản trị tài khoản (mảng B), quản trị danh mục (mảng C); mỗi loại chỉ quản lý dữ liệu nền của mảng mình. Mỗi vai trò chỉ thao tác trên phần dữ liệu ghi ở cột nhu cầu.

## 3. Hiện trạng quy trình

1. **Tiếp nhận nhân viên**: quản trị nhân sự lưu thông tin cá nhân và loại nhân viên (bác sĩ, lễ tân, quản trị nhân sự, quản trị tài khoản, quản trị danh mục); với bác sĩ, lưu thêm số giấy phép hành nghề, ngày cấp, ngày hết hạn và loại bác sĩ (đa khoa hoặc chuyên khoa). Bác sĩ chuyên khoa được gắn với chuyên khoa của mình.
2. **Xếp ca**: quản trị nhân sự xếp ca làm việc cho bác sĩ theo ngày và khung giờ. Bác sĩ có giấy phép hết hạn không được xếp ca. Một bác sĩ không có hai ca chồng giờ.
3. **Công bố lịch**: ứng dụng hiển thị bác sĩ theo chuyên khoa và các khung giờ còn trống trong ca để bệnh nhân hoặc lễ tân đặt lịch.
4. **Thay đổi ca**: quản trị nhân sự có thể sửa giờ hoặc hủy ca. Không được sửa hoặc hủy nếu việc đó làm lịch hẹn đã nhận rơi ra ngoài giờ làm việc.
5. **Gia hạn giấy phép**: giấy phép hành nghề có hiệu lực 5 năm; khi gia hạn, quản trị nhân sự cập nhật ngày hết hạn mới.

Lưu ý pháp lý: từ 01/01/2024, Luật Khám bệnh, chữa bệnh 15/2023/QH15 dùng tên **giấy phép hành nghề** (thay cho chứng chỉ hành nghề), thời hạn 5 năm. Phạm vi hành nghề của bác sĩ đa khoa và bác sĩ chuyên khoa được quy định khác nhau tại Thông tư 32/2023/TT-BYT.

## 4. Yêu cầu đối với CSDL

Rút ra từ quy trình ở mục 3 và nhu cầu dữ liệu ở mục 2.

| Nguồn trong quy trình | Yêu cầu |
|---|---|
| Bước 1: loại bác sĩ | Mỗi bác sĩ thuộc đúng một loại: đa khoa hoặc chuyên khoa |
| Bước 1: gắn chuyên khoa | Mỗi bác sĩ chuyên khoa thuộc đúng một chuyên khoa |
| Bước 2: giấy phép hết hạn | Chỉ xếp ca cho bác sĩ có giấy phép còn hạn đến hết ngày của ca |
| Bước 2: không chồng ca | Các ca còn hiệu lực của một bác sĩ không chồng giờ |
| Bước 1: số giấy phép | Số giấy phép bắt buộc và không trùng |
| Bước 2: khung giờ ca | Ca kết thúc sau khi bắt đầu |
| Bước 1, 5: thời hạn giấy phép | Ngày hết hạn sau ngày cấp |
| Bước 4: thay đổi ca | Không sửa, hủy ca làm lịch hẹn đã nhận rơi ra ngoài ca |
| Mục 2: nhu cầu dữ liệu từng bên | Chỉ quản trị nhân sự thay đổi nhân viên, bác sĩ, chuyên khoa, ca; bác sĩ, lễ tân chỉ xem |
| Bước 1: loại nhân viên | Mỗi nhân viên thuộc đúng một loại; chỉ bác sĩ có thông tin bác sĩ |

## 5. Ràng buộc và giả định

- Quản lý nhân viên gồm bác sĩ, lễ tân và ba loại quản trị (nhân sự, tài khoản, danh mục); điều dưỡng và nhân sự khác không thuộc phạm vi. Lễ tân, quản trị không có thông tin riêng ngoài thông tin chung của nhân viên.
- Chỉ lưu giấy phép hành nghề hiện hành của bác sĩ, không lưu lịch sử gia hạn.
- Mỗi bác sĩ chuyên khoa thuộc đúng một chuyên khoa; bác sĩ đa khoa không gắn chuyên khoa.
- Ca làm việc có thời điểm bắt đầu, kết thúc; ca bị hủy vẫn được giữ lại và không tính khi xét chồng giờ.
- Phòng khám có một cơ sở; không quản lý nơi làm việc của ca.

## 6. Kết quả khảo sát: dữ liệu cần lưu (đầu vào T07, T11)

| Đối tượng | Thông tin cần lưu | Quan hệ với đối tượng khác |
|---|---|---|
| Nhân viên | Họ tên, ngày sinh, số điện thoại, email, loại nhân viên (bác sĩ, lễ tân, quản trị nhân sự, quản trị tài khoản, quản trị danh mục) | Có tối đa một tài khoản đăng nhập (mảng B) |
| Bác sĩ | Số giấy phép hành nghề, ngày cấp, ngày hết hạn, loại bác sĩ (đa khoa, chuyên khoa) | Là một nhân viên; có nhiều ca làm việc; phụ trách nhiều lịch hẹn (mảng B). Bác sĩ chuyên khoa thuộc một chuyên khoa; bác sĩ đa khoa lập giấy chuyển chuyên khoa (mảng B) |
| Chuyên khoa | Tên chuyên khoa | Có nhiều bác sĩ chuyên khoa; là nơi chuyển đến của giấy chuyển (mảng B) |
| Ca làm việc | Thời điểm bắt đầu, kết thúc, trạng thái (còn hiệu lực, đã hủy) | Thuộc đúng một bác sĩ |

Hai điểm phân loại cần chú ý ở bước thiết kế: nhân viên chia theo loại và chỉ bác sĩ có thông tin riêng; mỗi bác sĩ thuộc đúng một trong hai loại đa khoa, chuyên khoa.

## Nguồn tham khảo

- Medpro – hình thức đặt khám: https://medpro.vn/cho-ray/hinh-thuc-dat-kham
- YouMed (App Store): https://apps.apple.com/app/id1466077723
- BookingCare (App Store): https://apps.apple.com/vn/app/id1347700144
- Luật Khám bệnh, chữa bệnh số 15/2023/QH15: https://thuvienphapluat.vn/van-ban/The-thao-Y-te/Luat-15-2023-QH15-kham-benh-chua-benh-372143.aspx
- Thông tư 32/2023/TT-BYT quy định chi tiết Luật Khám bệnh, chữa bệnh: https://trungtamytekhanhson.khanhhoa.gov.vn/wp-content/uploads/2024/01/Thông-tư-32-2023-TT-BYT.pdf
- ISO/IEC/IEEE 29148:2018 – Systems and software engineering — Life cycle processes — Requirements engineering.
