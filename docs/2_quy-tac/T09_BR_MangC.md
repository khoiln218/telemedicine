# T09 – Quy tắc nghiệp vụ mảng C: Hồ sơ bệnh án & Đơn thuốc điện tử

| | |
|---|---|
| Mã việc | T09 (GĐ0, tuần 2) |
| Người viết / review | Nguyễn Đăng Khoa / Lê Ngọc Khôi |
| Ngày | 14/10/2026; cập nhật 19/10/2026 theo review và phạm vi đã chốt; 21/10/2026 thêm BR-C06 (phân quyền); tách quản trị theo 3 mảng |
| Chuẩn tham chiếu | Business Rules Manifesto (Business Rules Group), SBVR (OMG); thuộc tính yêu cầu theo ISO/IEC/IEEE 29148:2018 |
| Căn cứ | [T05 – khảo sát mảng C](../1_khao-sat/T05_KhaoSat_MangC.md) |
| Dùng cho | Báo cáo mục 1.2.3, T13 (ERD mảng C), T15 (truy vết) |

Nguyên tắc viết: mỗi quy tắc là một phát biểu khẳng định, dùng thuật ngữ ở mục 1, không phụ thuộc cách cài đặt. Tài liệu chỉ nêu quy tắc là gì; quy tắc được bảo đảm bằng cơ chế nào trong CSDL thuộc bước cài đặt.

## 1. Thuật ngữ

| Thuật ngữ | Định nghĩa |
|---|---|
| Lần khám | Một lần bác sĩ khám cho bệnh nhân theo cuộc hẹn đã đặt trước |
| Lịch hẹn hoàn thành | Cuộc hẹn mà bệnh nhân đã được khám xong; sau đó không đổi sang trạng thái khác được nữa |
| Bác sĩ khám | Bác sĩ được phân công cho cuộc hẹn và trực tiếp khám bệnh nhân |
| Đơn thuốc | Danh sách thuốc bác sĩ kê sau khi khám, mỗi thuốc ghi số lượng và cách dùng |
| Dị ứng đã ghi nhận | Hoạt chất mà bệnh nhân đã được ghi lại là bị dị ứng |
| Hồ sơ bệnh án | Toàn bộ thông tin khám, chẩn đoán, thuốc đã kê và dị ứng của một bệnh nhân |
| Hủy bản ghi | Đánh dấu một chẩn đoán hoặc đơn thuốc là không còn giá trị nhưng vẫn giữ lại, thay cho việc xóa |

Các quy tắc là quy tắc dữ liệu của đồ án để học thiết kế CSDL, không phải tiêu chuẩn kê đơn hay hướng dẫn chăm sóc y tế.

## 2. Danh sách quy tắc

Loại theo SBVR: **cấu trúc** là điều luôn đúng với dữ liệu; **hành vi** là điều kiện ràng buộc một thao tác.

| Mã | Phát biểu quy tắc | Loại | Lý do | Nguồn |
|---|---|---|---|---|
| BR-C01 | Không được kê cho bệnh nhân thuốc có hoạt chất mà bệnh nhân đã ghi nhận dị ứng | Hành vi | An toàn đơn thuốc | T05 bước 4; MT-05 |
| BR-C02 | Đơn thuốc chỉ được lập cho lần khám có lịch hẹn đã hoàn thành, và người kê là bác sĩ khám | Hành vi | Đơn phải gắn với một lần khám thật, đúng người chịu trách nhiệm | T05 bước 1, 3; MT-05 |
| BR-C03 | Mỗi lần khám phải có ít nhất một chẩn đoán trước khi lập đơn thuốc | Hành vi | Đơn thuốc phải có căn cứ chẩn đoán | T05 bước 2, 3; MT-04 |
| BR-C04 | Số lượng của mỗi thuốc trong đơn phải lớn hơn 0, và liều dùng phải được ghi | Cấu trúc | Đơn thuốc điện tử phải ghi thuốc, liều dùng và thời gian dùng | T05 bước 3; MT-05 |
| BR-C05 | Lần khám, chẩn đoán và đơn thuốc đã ghi không được xóa hay sửa nội dung; chẩn đoán và đơn ghi sai thì hủy | Hành vi | Giữ đầy đủ lịch sử bệnh án; hồ sơ bệnh án điện tử phải truy xuất, phục hồi được (Thông tư 13/2025/TT-BYT) | T05 bước 5; MT-04 |
| BR-C06 | Chỉ bác sĩ được ghi lần khám, chẩn đoán, đơn thuốc và dị ứng; lễ tân không được xem các dữ liệu này; bệnh nhân chỉ được xem bệnh án của chính mình; chỉ quản trị danh mục được thêm, sửa thuốc, hoạt chất và mã ICD-10 | Hành vi | Bệnh án là dữ liệu nhạy cảm, chỉ người khám được ghi và chỉ người liên quan được xem; danh mục do một bên chịu trách nhiệm | T05 mục 2; T03 mục 5; MT-06 |

## 3. Ví dụ minh họa

| Quy tắc | Trường hợp vi phạm | Trường hợp hợp lệ |
|---|---|---|
| BR-C01 | Kê thuốc có hoạt chất bệnh nhân đã ghi nhận dị ứng | Kê thuốc không chứa hoạt chất đó |
| BR-C02 | Ghi lần khám hoặc lập đơn cho lịch hẹn chưa hoàn thành | Lịch hẹn hoàn thành, bác sĩ của lịch hẹn ghi lần khám rồi lập đơn |
| BR-C03 | Lập đơn cho lần khám chưa có chẩn đoán | Thêm chẩn đoán rồi lập đơn |
| BR-C04 | Thuốc trong đơn có số lượng 0 hoặc âm; liều dùng để trống | Số lượng dương, có ghi liều dùng |
| BR-C05 | Xóa một lần khám hoặc đơn thuốc; sửa số lượng thuốc hay mã ICD-10 đã ghi | Hủy đơn ghi sai, đơn vẫn được giữ lại |
| BR-C06 | Lễ tân xem chẩn đoán; bệnh nhân xem đơn thuốc của người khác; bác sĩ thêm thuốc vào danh mục | Bác sĩ thêm chẩn đoán; bệnh nhân xem hồ sơ của mình; quản trị danh mục thêm mã ICD-10 |

## 4. Phụ thuộc mảng A, B

| Quy tắc | Dùng từ mảng khác | Nội dung |
|---|---|---|
| BR-C01 | B: bệnh nhân | Dị ứng gắn với bệnh nhân |
| BR-C02 | B: lịch hẹn, BR-B05; A: bác sĩ | Hoàn thành là trạng thái cuối; bác sĩ khám là bác sĩ của lịch hẹn |
| BR-C03, BR-C05 | – | Chỉ dùng dữ liệu mảng C |
| BR-C06 | B: lịch hẹn, BR-B08 | Bệnh nhân của bệnh án lấy qua lịch hẹn; bệnh nhân đăng nhập được nhận diện qua tài khoản như BR-B08 |

## 5. Quyết định đã chốt

- Lần khám và đơn thuốc không ghi lặp bệnh nhân, bác sĩ; xác định qua lịch hẹn.
- Hồ sơ bệnh án là tổng hợp các lần khám, chẩn đoán, đơn thuốc, dị ứng của bệnh nhân, không lưu riêng.
- Một thuốc chỉ xuất hiện một lần trong một đơn; dòng thuốc ghi sai thì hủy cả đơn và kê lại.
- Dị ứng không có trạng thái: có ghi nhận nghĩa là đang dị ứng; hết dị ứng thì bỏ ghi nhận (dị ứng không thuộc BR-C05).
- Dị ứng chỉ xét trùng đúng hoạt chất; không xét phản ứng chéo hay mức độ dị ứng lâm sàng. Kiểm tra lúc kê, không hồi tố đơn cũ.
- Một lần khám có thể có nhiều đơn.
- Liều dùng ghi dạng văn bản, gồm cả cách dùng và thời gian dùng.
- Danh mục ICD-10 là tập mã nhỏ giả lập, đủ cho dữ liệu mẫu.
- Không liên thông Hệ thống đơn thuốc quốc gia, không ký số đơn và hồ sơ.
- Quản trị danh mục là nhân viên (mảng A), quản lý danh mục thuốc, hoạt chất, ICD-10; không xem bệnh án.
