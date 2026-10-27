# T05 – Báo cáo khảo sát mảng C: Hồ sơ bệnh án & Đơn thuốc điện tử

| | |
|---|---|
| Mã việc | T05 (GĐ0, tuần 1) |
| Người thực hiện / review | Nguyễn Đăng Khoa / Đặng Hữu Khoa |
| Ngày | 14/10/2026; cập nhật 19/10/2026 theo phạm vi đã chốt; 21/10/2026 tách quản trị theo 3 mảng |
| Chuẩn tham chiếu | ISO/IEC/IEEE 29148:2018 – thu thập và phân tích yêu cầu |
| Dùng cho | T09 (BR-C), T13 (ERD mảng C) |

## 1. Thông tin khảo sát

| Mục | Nội dung |
|---|---|
| Mục tiêu | Xác định dữ liệu, trạng thái và quy tắc cần lưu cho lần khám, chẩn đoán, đơn thuốc và dị ứng của bệnh nhân, đủ cho một CSDL đồ án môn học |
| Phạm vi | Lần khám gắn với lịch hẹn, chẩn đoán theo ICD-10, đơn thuốc, thuốc và hoạt chất, dị ứng theo hoạt chất |
| Ngoài phạm vi | Ghi âm/ghi hình, hồ sơ liên thông, liên thông đơn thuốc quốc gia, tương tác thuốc, liều theo tuổi/cân nặng, mức độ dị ứng, phản ứng chéo, chữ ký số; giá thuốc; chỉ định, kết quả và chi phí xét nghiệm, chẩn đoán hình ảnh |
| Đối tượng khảo sát | Luồng ghi nhận lần khám và kê đơn trong một phòng khám; quy định về kê đơn thuốc điện tử và hồ sơ bệnh án điện tử; Hệ thống đơn thuốc quốc gia; danh mục mã ICD-10 |
| Phương pháp | Nghiên cứu văn bản pháp lý của Bộ Y tế, tài liệu hướng dẫn của Hệ thống đơn thuốc quốc gia và danh mục ICD-10 của WHO. Không phỏng vấn trực tiếp nhân viên y tế |
| Giới hạn | Không mô tả quy trình chuyên môn y tế, không đưa ra khuyến nghị chẩn đoán hay điều trị, không dùng dữ liệu người thật |

## 2. Bên liên quan

| Bên liên quan | Vai trò trong quy trình | Nhu cầu dữ liệu |
|---|---|---|
| Bác sĩ | Ghi lần khám, chẩn đoán, kê đơn | Xem lịch sử khám, dị ứng của bệnh nhân; thêm lần khám, chẩn đoán, đơn thuốc |
| Bệnh nhân | Người được khám, nhận đơn | Xem hồ sơ bệnh án, đơn thuốc của chính mình |
| Quản trị danh mục | Quản lý danh mục thuốc, hoạt chất, ICD-10 | Thêm, sửa danh mục |

Mỗi vai trò chỉ thao tác trên phần dữ liệu ghi ở cột nhu cầu; lễ tân không xem bệnh án.

## 3. Hiện trạng quy trình

1. **Ghi nhận lần khám**: khi lịch hẹn đã hoàn thành, bác sĩ của lịch tạo một lần khám gắn với lịch hẹn đó, ghi thời điểm khám và tóm tắt.
2. **Chẩn đoán**: bác sĩ ghi một hoặc nhiều chẩn đoán cho lần khám, mỗi chẩn đoán theo một mã ICD-10.
3. **Kê đơn**: sau khi có chẩn đoán, bác sĩ lập đơn thuốc; mỗi thuốc trong đơn ghi số lượng và liều dùng.
4. **Kiểm tra dị ứng**: trước khi thêm một thuốc vào đơn, kiểm tra thuốc có hoạt chất nào bệnh nhân đã ghi nhận dị ứng.
5. **Lưu giữ**: lần khám, chẩn đoán, đơn thuốc được giữ để tra cứu lịch sử; chẩn đoán hoặc đơn ghi sai thì đánh dấu hủy, không xóa.

Hồ sơ bệnh án của một bệnh nhân là tập các lần khám, chẩn đoán, đơn thuốc và dị ứng của người đó.

Quy định và thực tế liên quan:

| Nội dung | Quy định / quan sát | Ảnh hưởng tới CSDL |
|---|---|---|
| Kê đơn điện tử | Thông tư 27/2021/TT-BYT quy định kê đơn thuốc bằng hình thức điện tử; Thông tư 26/2025/TT-BYT quy định kê đơn thuốc hóa dược, sinh phẩm ngoại trú | Đơn thuốc lưu thành dữ liệu có cấu trúc, gắn với một lần khám |
| Nội dung đơn | Đơn ghi thông tin người bệnh, thuốc, liều dùng và thời gian dùng | Mỗi thuốc trong đơn có số lượng và liều dùng; thông tin người bệnh lấy qua lịch hẹn |
| Liên thông đơn | Cơ sở khám chữa bệnh gửi đơn lên Hệ thống đơn thuốc quốc gia (donthuocquocgia.vn); người bệnh mua thuốc bằng mã đơn | Không liên thông; mã đơn là khóa nội bộ |
| Hồ sơ bệnh án điện tử | Thông tư 13/2025/TT-BYT: bệnh viện hoàn thành triển khai chậm nhất 30/9/2025; hồ sơ phải truy xuất, phục hồi được | Lịch sử khám không được xóa; ghi sai thì hủy và giữ lại bản ghi |

## 4. Yêu cầu đối với CSDL

Rút ra từ quy trình ở mục 3 và nhu cầu dữ liệu ở mục 2.

| Nguồn trong quy trình | Yêu cầu |
|---|---|
| Bước 4: kiểm tra dị ứng | Không kê thuốc có hoạt chất bệnh nhân dị ứng |
| Bước 1, 3: lần khám từ lịch hoàn thành, bác sĩ của lịch kê đơn | Chỉ lập đơn cho lần khám của lịch hoàn thành; người kê là bác sĩ khám |
| Bước 3: kê đơn sau khi có chẩn đoán | Lần khám phải có chẩn đoán trước khi lập đơn |
| Bước 3: số lượng và liều dùng | Số lượng lớn hơn 0; liều dùng bắt buộc |
| Bước 5: giữ lịch sử | Không xóa, không sửa nội dung lần khám, chẩn đoán, đơn thuốc |
| Mục 2: nhu cầu dữ liệu từng bên | Chỉ bác sĩ ghi bệnh án; lễ tân không xem; bệnh nhân chỉ xem hồ sơ của mình; chỉ quản trị danh mục thêm, sửa danh mục |

## 5. Ràng buộc và giả định

- Bệnh nhân và bác sĩ của lần khám là bệnh nhân, bác sĩ của lịch hẹn, không ghi lặp.
- Một lần khám có thể có nhiều đơn; một thuốc chỉ xuất hiện một lần trong một đơn.
- Liều dùng ghi dạng văn bản, gồm cả cách dùng và thời gian dùng.
- Dị ứng chỉ xét trùng đúng hoạt chất; kiểm tra lúc kê đơn, không hồi tố đơn cũ.
- Danh mục ICD-10 là tập mã nhỏ giả lập, đủ cho dữ liệu mẫu.
- Hồ sơ bệnh án là tổng hợp các lần khám, chẩn đoán, đơn thuốc, dị ứng của bệnh nhân, không lưu riêng.
- Lưu vết tối thiểu bằng người tạo và thời điểm tạo; không làm audit đầy đủ.
- Quản trị danh mục là nhân viên (mảng A), quản lý danh mục thuốc, hoạt chất, ICD-10; không xem bệnh án.

## 6. Kết quả khảo sát: dữ liệu cần lưu (đầu vào T09, T13)

| Đối tượng | Thông tin cần lưu | Quan hệ với đối tượng khác |
|---|---|---|
| Lần khám | Thời điểm khám, tóm tắt, người tạo | Phát sinh từ đúng một lịch hẹn đã hoàn thành (mảng B); có nhiều chẩn đoán, nhiều đơn thuốc |
| Chẩn đoán | Có phải chẩn đoán chính, ghi chú, trạng thái (hiệu lực, đã hủy) | Thuộc một lần khám; theo một mã ICD-10 |
| Mã ICD-10 | Mã, mô tả | Dùng cho nhiều chẩn đoán |
| Đơn thuốc | Thời điểm kê, trạng thái (hiệu lực, đã hủy), người tạo | Thuộc một lần khám; gồm nhiều thuốc, mỗi thuốc ghi số lượng và liều dùng |
| Thuốc | Tên thuốc, dạng bào chế, hàm lượng | Có trong nhiều đơn; chứa nhiều hoạt chất, mỗi hoạt chất ghi hàm lượng |
| Hoạt chất | Tên hoạt chất | Có trong nhiều thuốc; bệnh nhân (mảng B) có thể dị ứng nhiều hoạt chất, mỗi lần ghi nhận có ngày và ghi chú |

## Nguồn tham khảo

- Đề bài INT1313 – đề tài #5.
- Thông tư 27/2021/TT-BYT quy định kê đơn thuốc bằng hình thức điện tử: https://thongtinphapluat.bacgiang.gov.vn/documents/249229/0/27_2021_tt-byt_497939-pdf-19699966785803121.pdf/32f8c5a3-54f0-4eca-a506-e75f9b4237ff
- Thông tư 26/2025/TT-BYT quy định kê đơn thuốc hóa dược, sinh phẩm tại cơ sở khám chữa bệnh: https://luatvietnam.vn/y-te/thong-tu-26-2025-tt-byt-quy-dinh-ke-don-thuoc-hoa-duoc-sinh-pham-tai-co-so-kham-chua-benh-404246-d1.html
- Thông tư 13/2025/TT-BYT hướng dẫn triển khai hồ sơ bệnh án điện tử: https://caselaw.vn/van-ban-phap-luat/587211-thong-tu-so-13-2025-tt-byt-ngay-06-06-2025-cua-bo-truong-bo-y-te-huong-dan-trien-khai-ho-so-benh-an-dien-tu
- Hệ thống đơn thuốc quốc gia – hướng dẫn sử dụng: https://donthuocquocgia.vn/huong-dan-su-dung.pdf
- World Health Organization. ICD-10 Version 2019: https://icd.who.int/browse10/2019/en
- ISO/IEC/IEEE 29148:2018 – Systems and software engineering — Life cycle processes — Requirements engineering.
