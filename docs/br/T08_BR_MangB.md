# T08 – Quy tắc nghiệp vụ mảng B: Bệnh nhân & Lịch hẹn

| | |
|---|---|
| Mã việc | T08 (GĐ0, tuần 2) |
| Người viết / review | Lê Ngọc Khôi / Đặng Hữu Khoa |
| Ngày | 08/10/2026; cập nhật 19/10/2026 theo phạm vi đã chốt; 21/10/2026 thêm BR-B08 (phân quyền), BR-B09, BR-B10 (tài khoản) |
| Chuẩn tham chiếu | Business Rules Manifesto (Business Rules Group), SBVR (OMG); thuộc tính yêu cầu theo ISO/IEC/IEEE 29148:2018 |
| Căn cứ | [T03 – khảo sát mảng B](../khao-sat/T03_KhaoSat_MangB.md) |
| Dùng cho | Báo cáo mục 1.2.2, T12 (ERD mảng B), T15 (truy vết) |

Nguyên tắc viết: mỗi quy tắc là một phát biểu khẳng định, dùng thuật ngữ ở mục 1, không phụ thuộc cách cài đặt. Tài liệu chỉ nêu quy tắc là gì; quy tắc được bảo đảm bằng cơ chế nào trong CSDL thuộc bước cài đặt.

## 1. Thuật ngữ

| Thuật ngữ | Định nghĩa |
|---|---|
| Ca làm việc | Khoảng thời gian bác sĩ được xếp làm việc |
| Ca làm việc còn hiệu lực | Khoảng thời gian làm việc đã xếp và chưa bị hủy |
| Lịch hẹn còn hiệu lực | Cuộc hẹn chưa bị hủy và không phải trường hợp bệnh nhân vắng mặt |
| Giao nhau về thời gian | Hai khoảng thời gian có phần chung; hai cuộc hẹn nối tiếp nhau, cuộc trước kết thúc đúng lúc cuộc sau bắt đầu, không tính là giao nhau |
| Tư vấn từ xa | Khám qua cuộc gọi video thay vì đến phòng khám |
| Giấy chuyển chuyên khoa | Giấy do bác sĩ đa khoa lập để bệnh nhân được khám bác sĩ chuyên khoa trong cùng phòng khám |
| Tái khám | Bệnh nhân đã từng được khám xong ở cùng chuyên khoa |
| Lễ tân | Nhân viên (mảng A) tiếp nhận bệnh nhân và quản lý lịch hẹn |
| Tài khoản | Thông tin đăng nhập của một người dùng, mang đúng một vai trò: quản trị, bác sĩ, lễ tân hoặc bệnh nhân |

## 2. Danh sách quy tắc

Loại theo SBVR: **cấu trúc** là điều luôn đúng với dữ liệu; **hành vi** là điều kiện ràng buộc một thao tác.

| Mã | Phát biểu quy tắc | Loại | Lý do | Nguồn |
|---|---|---|---|---|
| BR-B01 | Thời gian của mỗi lịch hẹn phải nằm trọn trong một ca làm việc còn hiệu lực của bác sĩ được hẹn | Hành vi | Bác sĩ chỉ khám trong giờ làm việc | T03 bước 1; MT-02 |
| BR-B02 | Hai lịch hẹn còn hiệu lực của cùng một bác sĩ, hoặc của cùng một bệnh nhân, không được giao nhau về thời gian | Cấu trúc | Bác sĩ không khám hai bệnh nhân cùng lúc; bệnh nhân không khám hai nơi cùng lúc | T03 bước 1; MT-02 |
| BR-B03 | Lịch hẹn với bác sĩ chuyên khoa phải kèm một giấy chuyển chuyên khoa cấp cho chính bệnh nhân đó, còn hạn, đúng chuyên khoa và chưa dùng cho lịch hẹn khác, trừ khi là tái khám | Hành vi | Bệnh nhân khám chuyên khoa lần đầu phải qua bác sĩ đa khoa | T03 bước 5 |
| BR-B04 | Mỗi lịch hẹn tư vấn từ xa phải có nền tảng và đường dẫn phiên | Cấu trúc | Bệnh nhân cần thông tin để vào cuộc gọi | T03 bước 4; MT-03 |
| BR-B05 | Lịch hẹn mới luôn ở trạng thái đã đặt; chỉ được chuyển từ đã đặt sang đã xác nhận hoặc hủy, từ đã xác nhận sang hoàn thành, hủy hoặc vắng mặt; hoàn thành, hủy, vắng mặt là trạng thái cuối | Hành vi | Không sửa lại lịch hẹn đã kết thúc | T03 bước 2, sơ đồ trạng thái |
| BR-B06 | Mỗi lịch hẹn thuộc đúng một hình thức: khám trực tiếp hoặc tư vấn từ xa | Cấu trúc | Mỗi hình thức có thông tin riêng | T03 bước 1; MT-03 |
| BR-B07 | Giấy chuyển chuyên khoa chỉ do bác sĩ đa khoa lập và có hiệu lực tối đa 30 ngày kể từ ngày lập | Cấu trúc | Phân biệt vai trò bác sĩ đa khoa và chuyên khoa | T03 bước 5 |
| BR-B08 | Lễ tân được thêm, sửa bệnh nhân và lịch hẹn; bác sĩ chỉ được xem bệnh nhân, lịch hẹn và lập giấy chuyển chuyên khoa; bệnh nhân chỉ được xem lịch hẹn của chính mình | Hành vi | Mỗi vai trò chỉ có quyền đủ cho việc của mình; bệnh nhân không thấy dữ liệu của người khác | T03 mục 2, 5; MT-06 |
| BR-B09 | Tài khoản vai trò bệnh nhân gắn đúng một bệnh nhân; tài khoản vai trò khác gắn đúng một nhân viên có loại trùng vai trò; mỗi bệnh nhân, nhân viên có tối đa một tài khoản | Cấu trúc | Phân quyền theo hàng cần biết người đăng nhập là ai | T03 mục 2, 5; MT-06 |
| BR-B10 | Chỉ quản trị được tạo tài khoản nhân viên, đổi vai trò và khóa, mở khóa tài khoản; lễ tân chỉ được tạo tài khoản bệnh nhân và đặt lại mật khẩu cho tài khoản bệnh nhân; mỗi người chỉ đổi được mật khẩu của chính mình; tài khoản không bị xóa | Hành vi | Không ai tự nâng quyền; giữ dấu vết người tạo trên bản ghi y tế | T03 bước 1, mục 5; MT-06 |

## 3. Ví dụ minh họa

| Quy tắc | Trường hợp vi phạm | Trường hợp hợp lệ |
|---|---|---|
| BR-B01 | Đặt lịch 18:00–18:15 khi ca của bác sĩ là 07:00–11:00; hoặc đặt vào ca đã hủy | Đặt lịch 08:00–08:15 trong ca còn hiệu lực |
| BR-B02 | Đặt lịch 9:00–9:30 khi bác sĩ, hoặc bệnh nhân, đã có lịch đã xác nhận 9:15–9:45 | Cùng lịch đó khi lịch cũ đã hủy |
| BR-B03 | Đặt lịch bác sĩ Tim mạch cho bệnh nhân chưa từng khám Tim mạch mà không kèm giấy; dùng giấy của bệnh nhân khác; dùng lại giấy đã gắn với lịch khác | Đặt lịch kèm giấy hợp lệ, hoặc tái khám không cần giấy |
| BR-B04 | Tư vấn từ xa không có nền tảng hoặc đường dẫn phiên | Tư vấn từ xa đủ nền tảng và đường dẫn phiên |
| BR-B05 | Chuyển lịch đã hoàn thành về đã đặt; chuyển đã đặt thẳng sang hoàn thành | Đã đặt → đã xác nhận → hoàn thành |
| BR-B06 | Một lịch hẹn vừa khám trực tiếp vừa tư vấn từ xa | Lịch hẹn thuộc đúng một hình thức |
| BR-B07 | Giấy chuyển do bác sĩ chuyên khoa lập; hoặc giấy có hạn 45 ngày | Giấy do bác sĩ đa khoa lập, hạn 30 ngày |
| BR-B08 | Lễ tân xóa một lịch hẹn; bác sĩ sửa lịch hẹn; bệnh nhân xem lịch hẹn của người khác | Lễ tân thêm lịch hẹn; bệnh nhân chỉ thấy lịch hẹn của mình |
| BR-B09 | Tài khoản bệnh nhân không gắn bệnh nhân nào; tài khoản lễ tân gắn với một bác sĩ; hai tài khoản cùng một bệnh nhân | Tài khoản bệnh nhân gắn một bệnh nhân chưa có tài khoản; tài khoản quản trị gắn nhân viên loại quản trị |
| BR-B10 | Lễ tân tạo tài khoản bác sĩ hoặc đổi vai trò một tài khoản thành quản trị; quản trị xóa tài khoản; bệnh nhân đổi mật khẩu của người khác | Lễ tân tạo tài khoản bệnh nhân; quản trị khóa tài khoản; bệnh nhân đổi mật khẩu của mình |

## 4. Phụ thuộc mảng A, C

| Quy tắc | Dùng từ mảng khác | Nội dung |
|---|---|---|
| BR-B01 | A: ca làm việc | Ca làm việc có bác sĩ, thời điểm bắt đầu, kết thúc |
| BR-B02 | A: bác sĩ | Lịch hẹn còn hiệu lực của cùng một bác sĩ không giao nhau |
| BR-B03 | A: bác sĩ chuyên khoa, chuyên khoa | Chuyên khoa của bác sĩ được hẹn |
| BR-B07 | A: bác sĩ đa khoa | Chỉ bác sĩ đa khoa lập giấy chuyển |
| BR-B09 | A: nhân viên | Tài khoản nhân viên gắn một nhân viên, vai trò trùng loại nhân viên |
| BR-B05 | C: BR-C02 dùng lại | Lần khám chỉ có cho lịch hẹn đã hoàn thành |
| BR-B08 | C: BR-C06 dùng lại | Bệnh nhân đăng nhập được nhận diện qua tài khoản, dùng chung khi xem bệnh án |

## 5. Quyết định đã chốt

- Giờ hẹn là một khoảng thời gian (bắt đầu, kết thúc); không chia khung giờ cố định.
- Chuyên khoa của lịch hẹn là chuyên khoa của bác sĩ được hẹn, không ghi riêng.
- Phí khám gắn với từng lịch hẹn.
- Không cấp số thứ tự khám; mỗi lịch hẹn có khoảng giờ riêng.
- Tư vấn từ xa dùng chung lần khám, chẩn đoán, đơn thuốc với khám trực tiếp; không kiểm tra bệnh có thuộc danh mục được khám từ xa (Thông tư 30/2023/TT-BYT).
- Giấy chuyển chuyên khoa là quy trình nội bộ trong một phòng khám, không liên quan chuyển người bệnh theo BHYT.
- Lễ tân là nhân viên (mảng A). Lễ tân chuyển mọi trạng thái lịch hẹn, kể cả hoàn thành.
- Có 4 vai trò cố định; mỗi tài khoản mang đúng một vai trò. Mật khẩu không lưu ở dạng đọc được.
- Bác sĩ xem được mọi lịch hẹn, không chỉ lịch của mình.
- Ngoài phạm vi: quên mật khẩu qua email, chính sách độ mạnh mật khẩu, nhật ký đăng nhập.
- Các ràng buộc đơn giản nằm ở ràng buộc chung (báo cáo mục 1.2.4): thời gian kết thúc sau bắt đầu, số điện thoại của bệnh nhân không trùng, phí khám không âm.
