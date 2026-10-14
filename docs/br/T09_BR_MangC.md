# T09 – Quy tắc nghiệp vụ mảng C: Hồ sơ bệnh án & Đơn thuốc điện tử

| | |
|---|---|
| Mã việc | T09 (GĐ0, tuần 2) |
| Người viết / review | Nguyễn Đăng Khoa / Lê Ngọc Khôi |
| Ngày soạn | 14/10/2026 |
| Dùng cho | Mục 1.2.3 (gộp ở T10), T15 (truy vết BR–ER), T28 (chuẩn hóa), T38 (trigger/view), T43 (kiểm thử) |
| Căn cứ | [T05 – khảo sát mảng C](../khao-sat/T05_KhaoSat_MangC.md), sườn báo cáo v0, kế hoạch nhóm |
| Trạng thái | Bản đề xuất để nhóm review; giữ nguyên mã BR-C01…C05 đang được sườn báo cáo tham chiếu |

## Thuật ngữ và giả định phạm vi

- **Lần khám hoàn thành:** lần khám gắn với lịch hẹn đã ở trạng thái `HOAN_THANH` theo mảng B. Tên cột/trạng thái cần khớp với lược đồ cuối.
- **Bác sĩ khám:** bác sĩ được gán cho lần khám. Đề xuất chỉ bác sĩ này được kê đơn cho lần khám đó.
- **Hoạt chất dị ứng:** mã hoạt chất được ghi nhận trong `DI_UNG` của bệnh nhân. Đồ án kiểm tra khớp mã hoạt chất chính xác; không mô hình hóa phản ứng chéo hay mức độ dị ứng lâm sàng.
- **Xóa bệnh án:** xóa vật lý bản ghi hồ sơ/lịch sử y tế bằng `DELETE`. Đề xuất giữ lịch sử và đánh dấu trạng thái thay vì xóa.
- Các quy tắc dưới đây là quy tắc dữ liệu của đồ án để học thiết kế CSDL, không phải tiêu chuẩn kê đơn hoặc hướng dẫn chăm sóc y tế.

## Bảng quy tắc (đầu vào mục 1.2.3)

| Mã | Phát biểu quy tắc | Loại ràng buộc | Cơ chế đảm bảo đề xuất |
|---|---|---|---|
| BR-C01 | Không được kê dòng thuốc có bất kỳ hoạt chất nào trùng với hoạt chất bệnh nhân đã ghi nhận dị ứng còn hiệu lực | Nghiệp vụ, liên bảng | Trigger kiểm tra khi thêm/cập nhật chi tiết đơn thuốc; khóa ngoại nối thuốc–hoạt chất và bệnh nhân–dị ứng. Nếu đổi hoạt chất/dị ứng, cần quyết định có kiểm tra lại đơn hiện hữu hay không. |
| BR-C02 | Đơn thuốc chỉ được lập cho lần khám đã hoàn thành và người kê đơn phải là bác sĩ phụ trách lần khám đó | Nghiệp vụ, liên bảng | FK tới lần khám/bác sĩ; trigger kiểm tra trạng thái lịch hẹn và so khớp bác sĩ kê với bác sĩ lần khám. Phải thống nhất cách ngăn trạng thái đổi sau khi đã kê. |
| BR-C03 | Một lần khám phải có ít nhất một chẩn đoán trước khi lập đơn thuốc | Nghiệp vụ, tính đầy đủ liên bảng | Trigger trước khi tạo đơn kiểm tra có ít nhất một `CHAN_DOAN` của lần khám. Có thể cần giao dịch/trạng thái quy trình để tránh xóa chẩn đoán sau khi lập đơn. |
| BR-C04 | Số lượng thuốc và thành phần số của liều dùng phải lớn hơn 0; hướng dẫn liều dùng không được để trống | Miền giá trị / bắt buộc | `CHECK (so_luong > 0)`; `NOT NULL` và kiểm tra giá trị số dương nếu liều được tách thành lượng/đơn vị. Nếu liều lưu văn bản, dùng `NOT NULL` + `CHECK (btrim(lieu_dung) <> '')`, không thể khẳng định ý nghĩa số học của văn bản. |
| BR-C05 | Hồ sơ bệnh án và lịch sử khám không được xóa vật lý; khi ngừng sử dụng phải đánh dấu trạng thái | Nghiệp vụ, lưu giữ dữ liệu | Trigger `BEFORE DELETE` từ chối xóa ở các bảng lịch sử y tế thuộc phạm vi đã chốt; cột trạng thái/`deleted_at` để đánh dấu. FK dùng `RESTRICT`/`NO ACTION`, tránh `ON DELETE CASCADE`. |

## Truy vết sơ bộ BR → ER/SQL (đầu vào T15)

| Mã BR | Biểu diễn ở ER/EER | Cài đặt bổ sung cần có | Ca kiểm chứng tối thiểu |
|---|---|---|---|
| BR-C01 | Liên kết `BENH_NHAN`–`DI_UNG`–`HOAT_CHAT`; `THUOC` M:N `HOAT_CHAT`; chi tiết đơn thuộc đơn và thuốc | Trigger kiểm tra giao của tập hoạt chất thuốc với tập dị ứng bệnh nhân khi INSERT/UPDATE dòng đơn | Dòng đơn có thuốc chứa hoạt chất dị ứng bị từ chối; thuốc không chứa hoạt chất dị ứng được chấp nhận |
| BR-C02 | `DON_THUOC` thuộc `LAN_KHAM`; lần khám liên kết bác sĩ; lịch hẹn có trạng thái | FK + trigger kiểm tra lịch hoàn thành, bác sĩ kê trùng bác sĩ khám | Đơn cho lịch chưa hoàn thành hoặc bác sĩ khác bị từ chối; đơn hợp lệ được chấp nhận |
| BR-C03 | `LAN_KHAM` 1:N `CHAN_DOAN`, `LAN_KHAM` 1:N hoặc 0..N `DON_THUOC` | Trigger khi lập đơn kiểm tra chẩn đoán tồn tại; bảo vệ khỏi xóa chẩn đoán cuối nếu đơn đã tồn tại | Tạo đơn khi chưa có chẩn đoán bị từ chối; thêm chẩn đoán trước rồi tạo đơn thành công |
| BR-C04 | Thuộc tính chi tiết đơn có miền dương và bắt buộc | `NOT NULL`, `CHECK`, kiểm tra chuỗi rỗng nếu lưu liều dạng văn bản | Số lượng 0/âm, liều số 0/âm hoặc liều trống bị từ chối |
| BR-C05 | Mô hình trạng thái hồ sơ/lịch sử; liên kết giữ lịch sử | Trigger chặn DELETE và FK không cascade; thao tác ngừng sử dụng là UPDATE trạng thái | DELETE bị từ chối; UPDATE trạng thái được chấp nhận và bản ghi vẫn truy vấn được |

## Thao tác thử cho T43

Mỗi test cần chạy trên dữ liệu giả lập riêng, ghi rõ bản ghi tiền điều kiện và kết quả thật. Không dùng thông tin bệnh nhân thật.

| Mã test đề xuất | Quy tắc | Thao tác sai cần bị từ chối | Test hợp lệ đi kèm |
|---|---|---|---|
| TC-04 | BR-C01 | Tạo chi tiết đơn chứa thuốc có hoạt chất bệnh nhân đã ghi nhận dị ứng | Tạo chi tiết đơn với thuốc không trùng hoạt chất dị ứng |
| TC-08 | BR-C02 | Lập đơn cho lịch chưa `HOAN_THANH`, hoặc bác sĩ kê khác bác sĩ khám | Lập đơn cho lần khám hoàn thành do chính bác sĩ phụ trách thực hiện |
| TC-09 | BR-C03 | Lập đơn cho lần khám chưa có chẩn đoán | Thêm ít nhất một chẩn đoán hợp lệ rồi lập đơn |
| TC-07 | BR-C04 | Thêm dòng đơn với số lượng 0/âm hoặc liều trống/không dương theo kiểu đã chốt | Thêm dòng có số lượng và liều hợp lệ |
| TC-05 | BR-C05 | `DELETE` hồ sơ bệnh án hoặc bản ghi lịch sử thuộc phạm vi bảo vệ | Đánh dấu ngừng sử dụng bằng UPDATE và xác nhận bản ghi còn tồn tại |

TC-04, TC-05 và TC-07 giữ nguyên số hiệu đã có trong sườn báo cáo. TC-08/TC-09 là mã đề xuất bổ sung; cần người tổng hợp xác nhận không trùng mã test của nhóm trước khi đưa vào `tests.sql` và báo cáo.

## Mục tiêu hệ thống liên quan

- MT-04 (hồ sơ bệnh án đầy đủ): BR-C03, BR-C05 và khả năng truy vấn lịch sử.
- MT-05 (đơn thuốc an toàn): BR-C01, BR-C02, BR-C04.
- Các truy vấn Q09–Q12 phải chạy trên schema/seed thống nhất và không làm lộ dữ liệu ngoài vai trò.

## Điểm cần review/chốt với nhóm

1. Giữ nguyên BR-C01…C05 theo sườn v0; nếu cần chi tiết hơn thì diễn giải trong từng quy tắc, không đánh số lại.
2. Xác nhận `HO_SO_BENH_AN` là một hồ sơ/bệnh nhân hay có thể nhiều; chốt khóa và cardinality.
3. Chốt trạng thái chính xác của lịch hẹn/lần khám và thời điểm được lập đơn.
4. Chốt liều dùng lưu dạng văn bản hay cấu trúc số lượng + đơn vị + tần suất; nội dung hiện tại quy định kiểm tra phù hợp với lựa chọn đó.
5. Chốt phạm vi BR-C05: chỉ hồ sơ hay toàn bộ lịch sử y tế, và quy trình hiệu chỉnh sai sót.
6. Chốt mã test bổ sung TC-08/TC-09 với người gộp báo cáo/tests.
7. Chốt xử lý trường hợp sau khi đã kê thì dị ứng được cập nhật hoặc thuốc đổi hoạt chất; trigger ở bảng dị ứng/danh mục có cần kiểm tra đơn hiện hữu trong phạm vi đồ án không.

## Ghi chú về thuật ngữ và thiết kế

- Sườn hiện ghi “Mỗi lần khám có ít nhất một chẩn đoán trước khi kê đơn” nhưng bảng kiểm thử tổng hợp chưa có test riêng. Tài liệu này giữ quy tắc và đề xuất thêm test TC-09 để bảo đảm có bằng chứng.
- Số lượng và liều dùng không tương đương cùng một kiểu dữ liệu: số lượng có thể kiểm tra bằng CHECK; liều dạng văn bản chỉ kiểm tra được không rỗng, còn liều có cấu trúc mới cho phép kiểm tra phần số dương.
- Trigger liên bảng cần xem xét cập nhật đồng thời và thứ tự thao tác; khi cài đặt cần tránh để INSERT/UPDATE cạnh tranh tạo trạng thái không hợp lệ.
