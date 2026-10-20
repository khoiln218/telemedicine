# T09 – Quy tắc nghiệp vụ mảng C: Hồ sơ bệnh án & Đơn thuốc điện tử

| | |
|---|---|
| Mã việc | T09 (GĐ0, tuần 2) |
| Người viết / review | Nguyễn Đăng Khoa / Lê Ngọc Khôi |
| Ngày | 14/10/2026; cập nhật 19/10/2026 theo review và phạm vi đã chốt |
| Chuẩn tham chiếu | Business Rules Manifesto (Business Rules Group), SBVR (OMG); thuộc tính yêu cầu theo ISO/IEC/IEEE 29148:2018 |
| Căn cứ | [T05 – khảo sát mảng C](../khao-sat/T05_KhaoSat_MangC.md) |
| Dùng cho | Báo cáo mục 1.2.3, T15 (truy vết BR → ER), T38 (trigger/view), T43 (kiểm thử) |

Nguyên tắc viết: mỗi quy tắc là một phát biểu khẳng định, dùng thuật ngữ ở mục 1, không phụ thuộc cách cài đặt; cơ chế cài đặt tách riêng ở mục 3. Số hiệu BR-C01…C05 giữ nguyên vì báo cáo đã tham chiếu.

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

## 3. Cơ chế đảm bảo

| Mã | Cơ chế trong CSDL | Ghi chú |
|---|---|---|
| BR-C01 | Trigger `trg_chan_thuoc_di_ung` trên INSERT `CHI_TIET_DON_THUOC`: so hoạt chất của thuốc với `DI_UNG` của bệnh nhân (bệnh nhân lấy qua đơn → lần khám → lịch hẹn) | Kiểm tra lúc kê; không hồi tố đơn cũ khi dị ứng hoặc danh mục thay đổi |
| BR-C02 | Trigger `trg_lan_kham_hoan_thanh` trên INSERT `LAN_KHAM`: lịch hẹn phải `HOAN_THANH`; FK `DON_THUOC.ma_lan_kham` | Vế "người kê là bác sĩ khám" được bảo đảm bằng thiết kế: không có cột bác sĩ kê, bác sĩ suy ra qua `LICH_HEN` |
| BR-C03 | Trigger trên INSERT `DON_THUOC`: tồn tại chẩn đoán `HIEU_LUC` của lần khám | BR-C05 ngăn xóa chẩn đoán sau khi lập đơn |
| BR-C04 | `NOT NULL` + `CHECK (so_luong > 0)` + `CHECK (btrim(lieu_dung) <> '')` | Liều dùng lưu dạng văn bản |
| BR-C05 | Trigger `trg_khong_xoa_benh_an` BEFORE DELETE, UPDATE trên `LAN_KHAM`, `CHAN_DOAN`, `DON_THUOC`, `CHI_TIET_DON_THUOC`: từ chối xóa; chỉ cho UPDATE `trang_thai` từ `HIEU_LUC` sang `DA_HUY` ở `CHAN_DOAN`, `DON_THUOC`; FK không `CASCADE` | Dòng thuốc ghi sai thì hủy cả đơn và kê lại; vì không sửa được nên BR-C01, BR-C02 chỉ cần kiểm tra khi INSERT |

## 4. Kiểm chứng (đầu vào T43)

Chạy trên dữ liệu giả lập, ghi rõ bản ghi tiền điều kiện và kết quả thực tế.

| Mã test | Quy tắc | Thao tác sai phải bị từ chối | Thao tác hợp lệ đi kèm |
|---|---|---|---|
| TC-04 | BR-C01 | Kê thuốc có hoạt chất bệnh nhân đã ghi nhận dị ứng | Kê thuốc không trùng hoạt chất dị ứng |
| TC-05 | BR-C05 | `DELETE` một lần khám, chẩn đoán, đơn hoặc dòng đơn; UPDATE số lượng của dòng đơn hoặc mã ICD-10 của chẩn đoán | UPDATE `DON_THUOC.trang_thai = 'DA_HUY'`, bản ghi vẫn còn |
| TC-06 | FK | Lập đơn với `ma_lan_kham` không tồn tại | Lập đơn với lần khám tồn tại |
| TC-07 | BR-C04 | Thêm thuốc vào đơn với số lượng 0/âm hoặc liều trống | Thêm thuốc với số lượng và liều hợp lệ |
| TC-08 | BR-C02 | Tạo lần khám cho lịch hẹn chưa `HOAN_THANH` | Tạo lần khám cho lịch `HOAN_THANH` rồi lập đơn |
| TC-09 | BR-C03 | Lập đơn cho lần khám chưa có chẩn đoán | Thêm chẩn đoán rồi lập đơn |

TC-04…TC-07 giữ số hiệu như báo cáo; TC-08, TC-09 là mã bổ sung, chốt khi gộp `tests.sql`.

## 5. Phụ thuộc mảng A, B

| Quy tắc | Dùng từ mảng khác | Nội dung |
|---|---|---|
| BR-C01 | B: `BENH_NHAN` | Dị ứng gắn với bệnh nhân |
| BR-C02 | B: `LICH_HEN`, BR-B05; A: `BAC_SI` | Trạng thái `HOAN_THANH` là trạng thái cuối; bác sĩ khám lấy từ lịch hẹn |
| BR-C03, BR-C05 | – | Chỉ dùng bảng mảng C |

## 6. Quyết định thiết kế đã chốt

- `LAN_KHAM` và `DON_THUOC` không lưu lặp bệnh nhân, bác sĩ; xác định qua lịch hẹn (`ma_lh`).
- Không có bảng hồ sơ bệnh án; hồ sơ trình bày bằng view `v_ho_so_tom_tat_benh_nhan`.
- Chi tiết đơn là liên kết M:N `KÊ` giữa đơn và thuốc, khóa `(ma_don, ma_thuoc)`.
- `DI_UNG` không có trạng thái: có bản ghi nghĩa là đang dị ứng; hết dị ứng thì xóa bản ghi (`DI_UNG` không thuộc BR-C05).
- Dị ứng chỉ xét trùng đúng mã hoạt chất; không mô hình hóa phản ứng chéo hay mức độ dị ứng lâm sàng.
- Một lần khám có thể có nhiều đơn.
- Liều dùng lưu dạng văn bản, ghi cả cách dùng và thời gian dùng.
- Danh mục ICD-10 là tập mã nhỏ giả lập, đủ cho dữ liệu mẫu.
- Không liên thông Hệ thống đơn thuốc quốc gia, không ký số đơn và hồ sơ; mã đơn là khóa nội bộ.
- Quản trị là người dùng hệ thống với role CSDL `r_quan_tri`, không phải thực thể.
