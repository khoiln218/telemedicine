# T08 – Quy tắc nghiệp vụ mảng B: Bệnh nhân & Lịch hẹn

| | |
|---|---|
| Mã việc | T08 (GĐ0, tuần 2) |
| Người viết / review | Lê Ngọc Khôi / Đặng Hữu Khoa |
| Ngày | 08/10/2026; cập nhật 19/10/2026 theo phạm vi đã chốt |
| Chuẩn tham chiếu | Business Rules Manifesto (Business Rules Group), SBVR (OMG); thuộc tính yêu cầu theo ISO/IEC/IEEE 29148:2018 |
| Căn cứ | [T03 – khảo sát mảng B](../khao-sat/T03_KhaoSat_MangB.md) |
| Dùng cho | Báo cáo mục 1.2.2, T12 (ERD mảng B), T36 (trigger/view), T43 (kiểm thử) |

Nguyên tắc viết: mỗi quy tắc là một phát biểu khẳng định, dùng thuật ngữ ở mục 1, không phụ thuộc cách cài đặt; cơ chế cài đặt tách riêng ở mục 3. Số hiệu BR-B01…B05 giữ nguyên vì báo cáo đã tham chiếu.

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

## 3. Cơ chế đảm bảo

| Mã | Cơ chế trong CSDL | Ghi chú |
|---|---|---|
| BR-B01 | Trigger `trg_lich_hen_hop_le` trên INSERT/UPDATE `LICH_HEN`: tồn tại ca làm việc khác `HUY` của bác sĩ chứa khoảng thời gian hẹn | Liên bảng với mảng A |
| BR-B02 | Hai ràng buộc `EXCLUDE USING gist`: (`ma_bac_si` WITH =, khoảng thời gian WITH &&) và (`ma_bn` WITH =, khoảng thời gian WITH &&), chỉ áp dụng cho trạng thái khác `HUY`, `VANG_MAT` | Cần extension `btree_gist` |
| BR-B03 | Trigger `trg_lich_hen_hop_le` kiểm tra giấy cùng `ma_bn` với lịch hẹn, còn hạn, đúng chuyên khoa, và trường hợp tái khám; UNIQUE trên cột mã giấy của `LICH_HEN` | Tái khám: đã có lịch `HOAN_THANH` ở cùng chuyên khoa |
| BR-B04 | `NOT NULL` trên `nen_tang`, `link_phien` | Thời lượng tính từ thời điểm bắt đầu, kết thúc của lịch hẹn, không lưu riêng |
| BR-B05 | `CHECK` miền giá trị + `DEFAULT 'DA_DAT'` + trigger `trg_trang_thai_lich_hen` | Trạng thái: `DA_DAT`, `DA_XAC_NHAN`, `HOAN_THANH`, `HUY`, `VANG_MAT` |
| BR-B06 | Cột phân loại `hinh_thuc` + `CHECK` | Chi tiết theo phương án ánh xạ ở 2.2 |
| BR-B07 | FK tới lớp bác sĩ đa khoa + `CHECK (ngay_het_han <= ngay_lap + 30)` | Nếu chọn ánh xạ 8C (một bảng bác sĩ) thì phần bác sĩ đa khoa chuyển sang trigger |

## 4. Kiểm chứng (đầu vào T43)

Chạy trên dữ liệu giả lập, ghi rõ bản ghi tiền điều kiện và kết quả thực tế.

| Mã test | Quy tắc | Thao tác sai phải bị từ chối | Thao tác hợp lệ đi kèm |
|---|---|---|---|
| TC-02 | BR-B01 | Đặt lịch 18:00–18:15 khi ca của bác sĩ là 07:00–11:00; hoặc đặt vào ca đã hủy | Đặt lịch 08:00–08:15 trong ca còn hiệu lực |
| TC-01 | BR-B02 | Đặt lịch 9:00–9:30 khi bác sĩ, hoặc bệnh nhân, đã có lịch `DA_XAC_NHAN` 9:15–9:45 | Cùng thao tác khi lịch cũ đã `HUY` |
| – | BR-B03 | Đặt lịch bác sĩ chuyên khoa Tim mạch cho bệnh nhân chưa từng khám Tim mạch, không kèm giấy; dùng giấy của bệnh nhân khác; hoặc dùng lại giấy đã gắn với lịch khác | Đặt lịch kèm giấy hợp lệ, hoặc tái khám không cần giấy |
| – | BR-B04 | Tư vấn từ xa không có nền tảng hoặc link phiên | Tư vấn từ xa đủ nền tảng, link phiên |
| – | BR-B05 | Chuyển `HOAN_THANH` về `DA_DAT`; chuyển `DA_DAT` thẳng sang `HOAN_THANH` | Chuyển `DA_DAT` → `DA_XAC_NHAN` → `HOAN_THANH` |
| – | BR-B06 | Gán một lịch hẹn vào cả hai hình thức | Lịch hẹn thuộc đúng một hình thức |
| – | BR-B07 | Giấy chuyển do bác sĩ chuyên khoa lập; hoặc ngày hết hạn = ngày lập + 45 | Giấy do bác sĩ đa khoa lập, hạn 30 ngày |

TC-01, TC-02 giữ số hiệu như báo cáo; các quy tắc còn lại đánh mã test khi gộp `tests.sql`.

## 5. Phụ thuộc mảng A, C

| Quy tắc | Dùng từ mảng khác | Nội dung |
|---|---|---|
| BR-B01 | A: `CA_LAM_VIEC` | Ca làm việc có bác sĩ, thời điểm bắt đầu, kết thúc |
| BR-B02 | A: `BAC_SI` | Khóa bác sĩ dùng trong EXCLUDE |
| BR-B03 | A: `BAC_SI_CHUYEN_KHOA`, `CHUYEN_KHOA` | Chuyên khoa của bác sĩ được hẹn |
| BR-B07 | A: `BAC_SI_DA_KHOA` | Phụ thuộc phương án ánh xạ phân lớp bác sĩ |
| BR-B05 | C: BR-C02 dùng lại | Lần khám chỉ tạo cho lịch `HOAN_THANH` |

## 6. Quyết định thiết kế đã chốt

- Giờ hẹn lưu dạng khoảng thời gian (bắt đầu, kết thúc); không làm bảng khung giờ.
- Chuyên khoa của lịch hẹn lấy qua bác sĩ, không lưu riêng.
- Phí khám là thuộc tính `phi_kham` của lịch hẹn.
- Không cấp số thứ tự khám; mỗi lịch hẹn có khoảng giờ riêng.
- Tư vấn từ xa dùng chung lần khám, chẩn đoán, đơn thuốc với khám trực tiếp; không kiểm tra bệnh có thuộc danh mục được khám từ xa (Thông tư 30/2023/TT-BYT).
- Giấy chuyển chuyên khoa là quy trình nội bộ trong một phòng khám, không liên quan chuyển người bệnh theo BHYT.
- Lễ tân là người dùng hệ thống với role CSDL `r_le_tan`, không phải thực thể.
- Các ràng buộc đơn giản nằm ở ràng buộc chung (báo cáo mục 1.2.4), vẫn cài trong DDL: thời gian kết thúc sau bắt đầu, `sdt` của bệnh nhân không trùng, `phi_kham` không âm.
