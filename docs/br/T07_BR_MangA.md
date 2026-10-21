# T07 – Quy tắc nghiệp vụ mảng A: Nhân viên y tế & Lịch làm việc

| | |
|---|---|
| Mã việc | T07 (GĐ0, tuần 2) |
| Người viết / review | Đặng Hữu Khoa / Nguyễn Đăng Khoa |
| Ngày | 14/10/2026; cập nhật 19/10/2026 theo review và phạm vi đã chốt; 21/10/2026 thêm BR-A09 (phân quyền), BR-A10 (loại nhân viên) |
| Chuẩn tham chiếu | Business Rules Manifesto (Business Rules Group), SBVR (OMG); thuộc tính yêu cầu theo ISO/IEC/IEEE 29148:2018 |
| Căn cứ | [T04 – khảo sát mảng A](../khao-sat/T04_KhaoSat_MangA.md) |
| Dùng cho | Báo cáo mục 1.2.1, T11 (EER mảng A), T15 (truy vết) |

Nguyên tắc viết: mỗi quy tắc là một phát biểu khẳng định, dùng thuật ngữ ở mục 1, không phụ thuộc cách cài đặt. Tài liệu chỉ nêu quy tắc là gì; quy tắc được bảo đảm bằng cơ chế nào trong CSDL thuộc bước cài đặt.

## 1. Thuật ngữ

| Thuật ngữ | Định nghĩa |
|---|---|
| Bác sĩ đa khoa | Bác sĩ khám ban đầu cho mọi bệnh nhân, không giới hạn lĩnh vực |
| Bác sĩ chuyên khoa | Bác sĩ chỉ khám trong một lĩnh vực y khoa chuyên sâu |
| Chuyên khoa | Lĩnh vực chuyên sâu của y khoa, ví dụ tim mạch, da liễu |
| Chứng chỉ hành nghề | Giấy phép do cơ quan y tế cấp cho bác sĩ để được khám chữa bệnh, có ngày cấp và ngày hết hạn |
| Ca làm việc | Khoảng thời gian bác sĩ được xếp làm việc |
| Ca còn hiệu lực | Khoảng thời gian làm việc đã xếp và chưa bị hủy |
| Nhân viên | Người làm việc tại phòng khám và dùng hệ thống, thuộc đúng một loại: bác sĩ, lễ tân hoặc quản trị |
| Quản trị | Nhân viên quản lý nhân viên, bác sĩ, chuyên khoa, ca làm việc, danh mục và tài khoản |
| Chồng giờ | Hai khoảng thời gian có phần chung; hai khoảng nối tiếp nhau, khoảng trước kết thúc đúng lúc khoảng sau bắt đầu, không tính là chồng giờ |

## 2. Danh sách quy tắc

Loại theo SBVR: **cấu trúc** là điều luôn đúng với dữ liệu; **hành vi** là điều kiện ràng buộc một thao tác.

| Mã | Phát biểu quy tắc | Loại | Lý do | Nguồn |
|---|---|---|---|---|
| BR-A01 | Mỗi bác sĩ là bác sĩ đa khoa hoặc bác sĩ chuyên khoa, không đồng thời cả hai | Cấu trúc | Hai loại bác sĩ có phạm vi hành nghề khác nhau (Thông tư 32/2023/TT-BYT) | T04 bước 1; MT-01 |
| BR-A02 | Mỗi bác sĩ chuyên khoa thuộc đúng một chuyên khoa | Cấu trúc | Chuyên khoa của lịch hẹn được xác định qua bác sĩ | T04 bước 1; MT-01 |
| BR-A03 | Chỉ được xếp ca cho bác sĩ có chứng chỉ hành nghề còn hạn đến hết ngày của ca | Hành vi | Chỉ người có giấy phép còn hiệu lực mới được khám chữa bệnh (Luật 15/2023/QH15) | T04 bước 2, 5 |
| BR-A04 | Hai ca còn hiệu lực của cùng một bác sĩ không được chồng giờ | Cấu trúc | Bác sĩ không làm hai ca cùng lúc | T04 bước 2; MT-02 |
| BR-A05 | Mỗi bác sĩ có một số chứng chỉ hành nghề, không trùng với bác sĩ khác | Cấu trúc | Mỗi chứng chỉ chỉ cấp cho một người | T04 bước 1 |
| BR-A06 | Thời điểm kết thúc của ca làm việc phải sau thời điểm bắt đầu | Cấu trúc | Ca phải có độ dài hợp lệ | T04 bước 2 |
| BR-A07 | Ngày hết hạn của chứng chỉ hành nghề phải sau ngày cấp | Cấu trúc | Chứng chỉ có thời hạn, 5 năm theo Luật 15/2023/QH15 | T04 bước 1, 5 |
| BR-A08 | Không được sửa giờ hoặc hủy một ca nếu việc đó làm lịch hẹn còn hiệu lực nằm ngoài giờ làm việc của bác sĩ | Hành vi | Giữ hợp lệ các lịch hẹn đã nhận | T04 bước 4; MT-02 |
| BR-A09 | Chỉ quản trị được thêm, sửa nhân viên, bác sĩ, chuyên khoa và ca làm việc; bác sĩ và lễ tân chỉ được xem | Hành vi | Lịch làm việc là căn cứ đặt hẹn, chỉ một bên chịu trách nhiệm thay đổi | T04 mục 2; MT-06 |
| BR-A10 | Mỗi nhân viên thuộc đúng một loại: bác sĩ, lễ tân hoặc quản trị; chỉ nhân viên loại bác sĩ mới có thông tin bác sĩ | Cấu trúc | Thông tin cá nhân lưu một nơi; giấy phép hành nghề chỉ áp dụng cho bác sĩ | T04 bước 1 |

## 3. Ví dụ minh họa

| Quy tắc | Trường hợp vi phạm | Trường hợp hợp lệ |
|---|---|---|
| BR-A01 | Một bác sĩ vừa là bác sĩ đa khoa vừa là bác sĩ chuyên khoa | Bác sĩ thuộc đúng một loại |
| BR-A02 | Bác sĩ chuyên khoa không thuộc chuyên khoa nào | Bác sĩ chuyên khoa thuộc chuyên khoa Tim mạch |
| BR-A03 | Xếp ca ngày 20/12 cho bác sĩ có chứng chỉ hết hạn 15/12 | Xếp ca trong thời hạn chứng chỉ |
| BR-A04 | Thêm ca 11:00–13:00 khi bác sĩ đã có ca 08:00–12:00 | Thêm ca 12:00–14:00 (nối tiếp) |
| BR-A05 | Hai bác sĩ có cùng số chứng chỉ | Mỗi bác sĩ một số chứng chỉ riêng |
| BR-A06 | Ca 08:00–08:00 | Ca 08:00–12:00 |
| BR-A07 | Chứng chỉ có ngày hết hạn trước ngày cấp | Ngày hết hạn sau ngày cấp |
| BR-A08 | Hủy ca đang có lịch hẹn đã xác nhận | Hủy ca không còn lịch hẹn hiệu lực |
| BR-A09 | Lễ tân hoặc bác sĩ sửa giờ một ca làm việc | Lễ tân, bác sĩ xem ca; quản trị sửa ca |
| BR-A10 | Nhân viên loại "tạp vụ"; một lễ tân có thông tin chứng chỉ hành nghề | Lễ tân không có thông tin bác sĩ; nhân viên loại bác sĩ có thông tin bác sĩ |

## 4. Phụ thuộc mảng B, C

| Quy tắc | Dùng từ mảng A | Nội dung |
|---|---|---|
| BR-B01 | Ca làm việc | Lịch hẹn nằm trọn trong một ca của bác sĩ |
| BR-B02 | Bác sĩ | Lịch hẹn còn hiệu lực của cùng một bác sĩ không giao nhau |
| BR-B03 | Bác sĩ chuyên khoa, chuyên khoa | Chuyên khoa của lịch hẹn là chuyên khoa của bác sĩ |
| BR-B07 | Bác sĩ đa khoa | Chỉ bác sĩ đa khoa lập giấy chuyển |
| BR-B09 | Nhân viên | Tài khoản nhân viên gắn một nhân viên, vai trò trùng loại nhân viên |
| BR-C02 | Bác sĩ (qua lịch hẹn) | Bác sĩ kê đơn là bác sĩ của lịch hẹn |
| BR-A08 | B: lịch hẹn | Kiểm tra lịch hẹn còn hiệu lực khi sửa, hủy ca |

## 5. Quyết định đã chốt

- Nhân viên gồm bác sĩ, lễ tân, quản trị; chỉ bác sĩ có thông tin riêng (giấy phép, loại bác sĩ). Không quản lý điều dưỡng, nhân sự khác.
- Mỗi bác sĩ là đa khoa hoặc chuyên khoa; bác sĩ chuyên khoa thuộc đúng một chuyên khoa, bác sĩ đa khoa không gắn chuyên khoa.
- Chỉ lưu giấy phép hành nghề hiện hành, không lưu lịch sử gia hạn.
- Ca làm việc có thời điểm bắt đầu, kết thúc; ca bị hủy vẫn được giữ lại với trạng thái hủy.
- Phòng khám có một cơ sở; không quản lý nơi làm việc của ca.
