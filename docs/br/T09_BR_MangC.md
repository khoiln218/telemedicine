# T09 – Quy tắc nghiệp vụ mảng C: Hồ sơ bệnh án & Đơn thuốc điện tử

| | |
|---|---|
| Mã việc | T09 (GĐ0, tuần 2) |
| Người viết / review | Nguyễn Đăng Khoa / Lê Ngọc Khôi |
| Ngày cập nhật theo review | 19/10/2026 |
| Dùng cho | Mục 1.2.3 (gộp ở T10), T15 (truy vết BR–ER), T28 (chuẩn hóa), T38 (trigger/view), T43 (kiểm thử) |
| Căn cứ | [T05 – khảo sát mảng C](../khao-sat/T05_KhaoSat_MangC.md), sườn báo cáo v0, kế hoạch nhóm |
| Trạng thái | Bản đề xuất để nhóm review; giữ nguyên mã BR-C01…C05 đang được sườn báo cáo tham chiếu |

## Thuật ngữ và giả định phạm vi

- **Lần khám hoàn thành:** lần khám gắn với lịch hẹn đã ở trạng thái `HOAN_THANH` theo mảng B. Tên cột/trạng thái cần khớp với lược đồ cuối.
- **Bác sĩ khám:** bác sĩ được gán cho lần khám. Đề xuất chỉ bác sĩ này được kê đơn cho lần khám đó.
- **Dị ứng còn hiệu lực:** bản ghi `DI_UNG` có `trang_thai = 'DANG_HIEU_LUC'` tại thời điểm kê đơn. Đồ án kiểm tra khớp mã hoạt chất chính xác; không mô hình hóa phản ứng chéo hay mức độ dị ứng lâm sàng. Quy tắc được kiểm tra lúc kê/cập nhật dòng đơn; việc thay đổi dị ứng hoặc danh mục hoạt chất về sau không hồi tố đơn đã kê.
- **Xóa bệnh án:** xóa vật lý bản ghi hồ sơ/lịch sử y tế bằng `DELETE`. Đề xuất giữ lịch sử và đánh dấu trạng thái thay vì xóa.
- Các quy tắc dưới đây là quy tắc dữ liệu của đồ án để học thiết kế CSDL, không phải tiêu chuẩn kê đơn hoặc hướng dẫn chăm sóc y tế.

## Bảng quy tắc (đầu vào mục 1.2.3)

| Mã | Phát biểu quy tắc | Loại ràng buộc | Cơ chế đảm bảo đề xuất |
|---|---|---|---|
| BR-C01 | Không kê thuốc có hoạt chất trùng với hoạt chất mà bệnh nhân đã ghi nhận dị ứng còn hiệu lực tại thời điểm kê đơn | Nghiệp vụ, liên bảng | Trigger `trg_chan_thuoc_di_ung` trên chi tiết đơn; tra các bản ghi `DI_UNG` có trạng thái `DANG_HIEU_LUC` và hoạt chất tương ứng của thuốc. |
| BR-C02 | Đơn thuốc chỉ lập cho lần khám có lịch hẹn đã `HOAN_THANH`, và người kê là bác sĩ khám | Nghiệp vụ, liên bảng | FK + trigger kiểm tra trạng thái lịch hẹn và bác sĩ qua chuỗi `DON_THUOC` → `LAN_KHAM` → `LICH_HEN`; trạng thái `HOAN_THANH` là trạng thái cuối theo BR-B05. |
| BR-C03 | Một lần khám phải có ít nhất một chẩn đoán trước khi lập đơn thuốc | Nghiệp vụ, tính đầy đủ liên bảng | Trigger khi tạo đơn kiểm tra chẩn đoán tồn tại; việc chẩn đoán không bị xóa vật lý được bảo đảm bởi BR-C05. |
| BR-C04 | Số lượng thuốc phải lớn hơn 0; liều dùng bắt buộc và không được để trống | Miền giá trị | `NOT NULL` + `CHECK (so_luong > 0)`; với liều dùng lưu dạng văn bản, kiểm tra không rỗng sau `btrim`. |
| BR-C05 | Hồ sơ bệnh án và lịch sử khám không được xóa vật lý; khi ngừng sử dụng thì đánh dấu trạng thái | Nghiệp vụ, lưu giữ dữ liệu | Trigger `trg_khong_xoa_benh_an` chặn `DELETE` ở `HO_SO_BENH_AN`, `LAN_KHAM`, `CHAN_DOAN`, `DON_THUOC`, `CHI_TIET_DON_THUOC`; FK không `CASCADE`. |

## Truy vết sơ bộ BR → ER/SQL (đầu vào T15)

| Mã BR | Biểu diễn ở ER/EER | Cài đặt bổ sung cần có | Ca kiểm chứng tối thiểu |
|---|---|---|---|
| BR-C01 | Liên kết `BENH_NHAN`–`DI_UNG`–`HOAT_CHAT`; `THUOC` M:N `HOAT_CHAT`; chi tiết đơn thuộc đơn và thuốc | Trigger `trg_chan_thuoc_di_ung` kiểm tra dị ứng đang hiệu lực khi kê/cập nhật dòng đơn | Thuốc có hoạt chất dị ứng đang hiệu lực bị từ chối; thuốc không trùng hoạt chất được chấp nhận |
| BR-C02 | `DON_THUOC` thuộc `LAN_KHAM`; lần khám thuộc lịch hẹn, bác sĩ khám lấy từ lịch hẹn | FK + trigger; bác sĩ kê không lưu lặp ở `DON_THUOC`, được xác định qua `LICH_HEN`; yêu cầu lịch `HOAN_THANH` theo BR-B05 | Đơn cho lịch chưa hoàn thành hoặc bác sĩ khác bác sĩ lịch hẹn bị từ chối; đơn hợp lệ được chấp nhận |
| BR-C03 | `LAN_KHAM` 1:N `CHAN_DOAN`, `LAN_KHAM` 1:N `DON_THUOC` | Trigger khi tạo đơn kiểm tra chẩn đoán tồn tại; BR-C05 chặn xóa vật lý chẩn đoán | Tạo đơn khi chưa có chẩn đoán bị từ chối; thêm chẩn đoán trước rồi tạo đơn thành công |
| BR-C04 | `so_luong` dương; `lieu_dung` bắt buộc | `NOT NULL`, `CHECK (so_luong > 0)`, `CHECK (btrim(lieu_dung) <> '')` | Số lượng 0/âm hoặc liều trống bị từ chối |
| BR-C05 | Hồ sơ, lần khám, chẩn đoán, đơn và chi tiết đơn được giữ lại | Trigger `trg_khong_xoa_benh_an` chặn `DELETE` ở 5 bảng; FK không cascade | DELETE ở một trong 5 bảng bị từ chối; thao tác đánh dấu trạng thái được chấp nhận |

## Thao tác thử cho T43

Mỗi test cần chạy trên dữ liệu giả lập riêng, ghi rõ bản ghi tiền điều kiện và kết quả thật. Không dùng thông tin bệnh nhân thật.

| Mã test đề xuất | Quy tắc | Thao tác sai cần bị từ chối | Test hợp lệ đi kèm |
|---|---|---|---|
| TC-04 | BR-C01 | Tạo chi tiết đơn chứa thuốc có hoạt chất bệnh nhân đã ghi nhận dị ứng | Tạo chi tiết đơn với thuốc không trùng hoạt chất dị ứng |
| TC-08 | BR-C02 | Lập đơn cho lịch chưa `HOAN_THANH`, hoặc bác sĩ kê khác bác sĩ khám | Lập đơn cho lần khám hoàn thành do chính bác sĩ phụ trách thực hiện |
| TC-09 | BR-C03 | Lập đơn cho lần khám chưa có chẩn đoán | Thêm ít nhất một chẩn đoán hợp lệ rồi lập đơn |
| TC-06 | FK | INSERT đơn thuốc tham chiếu `ma_lan_kham` không tồn tại | Lập đơn với khóa lần khám tồn tại và hợp lệ |
| TC-07 | BR-C04 | Thêm dòng đơn với số lượng 0/âm hoặc liều trống/không dương theo kiểu đã chốt | Thêm dòng có số lượng và liều hợp lệ |
| TC-05 | BR-C05 | `DELETE` hồ sơ bệnh án hoặc bản ghi lịch sử thuộc phạm vi bảo vệ | Đánh dấu ngừng sử dụng bằng UPDATE và xác nhận bản ghi còn tồn tại |

TC-04, TC-05, TC-06 và TC-07 giữ nguyên số hiệu đã có trong sườn/báo cáo v1. TC-08/TC-09 là mã đề xuất bổ sung; cần người tổng hợp xác nhận không trùng mã test của nhóm trước khi đưa vào `tests.sql` và báo cáo.

## Mục tiêu hệ thống liên quan

- MT-04 (hồ sơ bệnh án đầy đủ): BR-C03, BR-C05 và khả năng truy vấn lịch sử.
- MT-05 (đơn thuốc an toàn): BR-C01, BR-C02, BR-C04.
- Các truy vấn Q09–Q12 phải chạy trên schema/seed thống nhất và không làm lộ dữ liệu ngoài vai trò.

## Điểm cần review/chốt với nhóm

1. Giữ nguyên BR-C01…C05 theo sườn v0 và bảng 1.2.3 của báo cáo v1.
2. Áp dụng đề xuất review: một hồ sơ/bệnh nhân; lần khám chỉ tạo khi lịch `HOAN_THANH`; liều dùng lưu văn bản; chặn `DELETE` năm bảng bệnh án.
3. Xác nhận trạng thái `DANG_HIEU_LUC` là cách biểu diễn dị ứng còn hiệu lực trong ERD/DDL.
4. Chốt mã test bổ sung TC-08/TC-09 với người gộp báo cáo/tests.

## Ghi chú về thuật ngữ và thiết kế

- Sườn/báo cáo v1 ghi “Mỗi lần khám có ít nhất một chẩn đoán trước khi kê đơn”; test TC-09 được đề xuất để có bằng chứng riêng.
- Theo review, `LAN_KHAM` không lưu lặp `ma_bn`/`ma_bac_si`; bệnh nhân và bác sĩ được xác định qua lịch hẹn. `DON_THUOC` không lưu `ma_bac_si_ke`, bác sĩ kê được xác định qua lần khám và lịch hẹn. Các khóa/cột này cần được giữ nhất quán ở T13/T21.
- Liều dùng được lưu dạng văn bản theo review nên kiểm tra được tính bắt buộc/không rỗng; chỉ `so_luong` bị kiểm tra số học dương.
- Trigger liên bảng cần xem xét cập nhật đồng thời và thứ tự thao tác; khi cài đặt cần tránh để INSERT/UPDATE cạnh tranh tạo trạng thái không hợp lệ.
