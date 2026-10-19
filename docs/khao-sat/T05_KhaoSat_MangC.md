# T05 – Ghi chú khảo sát mảng C: Hồ sơ bệnh án & Đơn thuốc điện tử

| | |
|---|---|
| Mã việc | T05 (GĐ0, tuần 1) |
| Người làm / review | Nguyễn Đăng Khoa / Đặng Hữu Khoa |
| Ngày soạn | 14/10/2026 |
| Dùng cho | T09 (BR-C), T13 (ERD mảng C), T21/T25/T28 (logic và chuẩn hóa), T34/T38 (SQL) |
| Trạng thái tài liệu | Bản đề xuất để nhóm review; cần chốt các giả định ở mục 7 |

## 1. Mục tiêu và giới hạn khảo sát

Xác định dữ liệu tối thiểu để lưu lịch sử lần khám, chẩn đoán, thuốc được kê và dị ứng bệnh nhân trong đồ án cơ sở dữ liệu. Mục tiêu là mô hình hóa và kiểm tra tính toàn vẹn dữ liệu, không mô tả đầy đủ quy trình chuyên môn y tế, không đưa ra khuyến nghị chẩn đoán/điều trị và không dùng dữ liệu bệnh nhân thật.

Mảng C tiếp nhận bệnh nhân và lịch hẹn từ mảng B, bác sĩ từ mảng A, rồi ghi nhận nội dung lần khám. Khám trực tiếp và tư vấn từ xa cùng tạo bản ghi lần khám; hệ thống chỉ lưu dữ liệu nghiệp vụ cần cho đồ án, không lưu nội dung cuộc gọi video.

## 2. Quy trình dữ liệu đề xuất

1. Bệnh nhân có hồ sơ bệnh án trong hệ thống; các thông tin nhận dạng và liên kết bệnh nhân do mảng B quản lý hoặc được tham chiếu theo khóa đã thống nhất.
2. Khi lịch hẹn đủ điều kiện hoàn thành, bác sĩ phụ trách tạo một lần khám gắn với lịch hẹn, bệnh nhân và bác sĩ. Lần khám giữ thời điểm, ghi chú/tóm tắt ở mức demo và người tạo.
3. Bác sĩ ghi một hoặc nhiều chẩn đoán cho lần khám; mỗi chẩn đoán tham chiếu mã và mô tả trong danh mục ICD-10 ở phạm vi dữ liệu mẫu.
4. Sau khi có chẩn đoán, bác sĩ có thể lập đơn thuốc cho lần khám. Đơn có một hoặc nhiều dòng thuốc; dòng thuốc ghi thuốc, số lượng và liều dùng/hướng dẫn sử dụng theo phạm vi đồ án.
5. Trước khi chấp nhận dòng thuốc, CSDL kiểm tra thuốc có hoạt chất nào trùng với hoạt chất mà bệnh nhân đã ghi nhận dị ứng. Nếu có, thao tác bị từ chối.
6. Hồ sơ bệnh án được giữ để tra cứu lịch sử. Khi cần ngừng sử dụng theo phạm vi demo, đánh dấu trạng thái thay vì xóa vật lý.

Đây là luồng thiết kế đề xuất theo yêu cầu sườn báo cáo; cần nhóm xác nhận thời điểm chuyển lịch sang HOAN_THANH và việc có cho phép nhiều đơn/lần khám hay không.

## 3. Phạm vi dữ liệu

| Trong phạm vi mảng C | Ngoài phạm vi / đơn giản hóa |
|---|---|
| Hồ sơ bệnh án gắn với bệnh nhân; trạng thái sử dụng và thông tin tạo/lưu vết tối thiểu | Nội dung bệnh án theo chuẩn triển khai lâm sàng thật, chữ ký số, lưu trữ hình ảnh/chẩn đoán hình ảnh |
| Lần khám gắn bệnh nhân, lịch hẹn và bác sĩ; khám trực tiếp hoặc từ xa được xác định qua lịch hẹn | Ghi âm/ghi hình, truyền video, hồ sơ liên thông giữa các bệnh viện |
| Chẩn đoán tham chiếu danh mục mã ICD-10 có trong dữ liệu mẫu | Tự động suy luận chẩn đoán hoặc thay thế đánh giá chuyên môn |
| Đơn thuốc và chi tiết đơn, thuốc và hoạt chất | Tương tác thuốc lâm sàng, liều theo tuổi/cân nặng, kiểm tra chống chỉ định, cấp phát thuốc |
| Dị ứng bệnh nhân ghi nhận theo hoạt chất và kiểm tra trùng hoạt chất khi kê | Xác minh dị ứng y khoa, mức độ dị ứng, phản ứng chéo, cảnh báo lâm sàng hoặc quy trình xử trí |
| Ngăn xóa hồ sơ theo rule của đề tài; role xem/ghi theo yêu cầu bảo mật | Quy trình chỉnh sửa hồ sơ theo pháp luật/y tế thực tế, nhật ký audit bất biến đầy đủ |
| Dữ liệu giả lập phục vụ truy vấn, demo và kiểm thử | Dữ liệu sức khỏe có thể nhận diện người thật |

## 4. Thực thể và thuộc tính ứng viên

Tên/khóa dưới đây là ứng viên; cần thống nhất tên khóa với mảng A/B trước khi chốt ERD và DDL.

| Thực thể | Thuộc tính ứng viên | Liên kết / ghi chú |
|---|---|---|
| HO_SO_BENH_AN | `ma_hs`, `ma_bn`, `ngay_tao`, `trang_thai`, `nguoi_tao` | Bệnh nhân 1 — 0..N hồ sơ hoặc 1 — 1 hồ sơ; cần chốt cardinality. Nếu mỗi bệnh nhân chỉ có một hồ sơ, `ma_bn` là UNIQUE. |
| LAN_KHAM | `ma_lan_kham`, `ma_lich_hen`, `thoi_diem_kham`, `tom_tat`, `nguoi_tao` | `ma_lich_hen` là FK UNIQUE; bệnh nhân và bác sĩ được suy ra qua `LICH_HEN`, không lặp `ma_bn`/`ma_bac_si`. Mỗi lịch hoàn thành có tối đa một lần khám. |
| CHAN_DOAN | `ma_chan_doan` hoặc khóa ghép, `ma_lan_kham`, `ma_icd10`, `ghi_chu`, `la_chan_doan_chinh` | Một lần khám có thể có nhiều chẩn đoán; danh mục mã ICD-10 cần chốt cách quản lý. |
| DON_THUOC | `ma_don`, `ma_lan_kham`, `thoi_diem_ke`, `nguoi_tao` | Đơn thuộc lần khám; bác sĩ kê được suy ra qua lần khám và lịch hẹn, không lưu lặp `ma_bac_si_ke`. Một lần khám có thể có nhiều đơn theo giả định hiện tại. |
| CHI_TIET_DON_THUOC | `ma_don`, `ma_thuoc`, `so_luong`, `lieu_dung`, có thể `thu_tu` | Thực thể kết hợp giữa đơn và thuốc; khóa ghép hoặc khóa thay thế. `so_luong` dương; quy tắc liều dùng cần định nghĩa miền không rỗng/dương phù hợp biểu diễn. |
| THUOC | `ma_thuoc`, `ten_thuoc`, `dang_bao_che`, `ham_luong`, `trang_thai` | Một thuốc có thể chứa một hoặc nhiều hoạt chất; không lưu danh sách hoạt chất dạng chuỗi. |
| HOAT_CHAT | `ma_hoat_chat`, `ten_hoat_chat` | Danh mục chuẩn hóa để liên kết thuốc với dị ứng. |
| THUOC_HOAT_CHAT | `ma_thuoc`, `ma_hoat_chat`, có thể `ham_luong` | Quan hệ M:N thuốc–hoạt chất; mỗi cặp phải duy nhất. |
| DI_UNG | `ma_bn`, `ma_hoat_chat`, `ngay_ghi_nhan`, `trang_thai`, `ghi_chu` | Dị ứng gắn bệnh nhân và hoạt chất; trạng thái `DANG_HIEU_LUC` xác định dị ứng đang hiệu lực. Kiểm tra tại thời điểm kê đơn; không tự hồi tố đơn cũ khi tình trạng dị ứng/danh mục thuốc thay đổi. |

Mảng B đã đề xuất `LAN_KHAM` liên kết 1:1 với `LICH_HEN`, với `ma_lh`/`ma_lich_hen` UNIQUE NOT NULL. Mảng C cần thống nhất chính xác tên cột và quy tắc chỉ tạo lần khám khi lịch đạt trạng thái phù hợp.

## 5. Quy tắc và toàn vẹn dữ liệu cần có

- Mỗi lần khám phải tham chiếu được bệnh nhân, bác sĩ và lịch hẹn hợp lệ; khóa ngoại không được để lại bản ghi mồ côi.
- Mỗi chẩn đoán phải thuộc một lần khám và tham chiếu mã ICD-10 hợp lệ.
- Không kê thuốc chứa hoạt chất đã được ghi nhận dị ứng cho bệnh nhân của lần khám.
- Chỉ lập đơn cho lần khám hoàn thành và người kê đơn phải là bác sĩ phụ trách lần khám.
- Theo yêu cầu sườn, lần khám cần ít nhất một chẩn đoán trước khi kê đơn. Đây là ràng buộc liên bảng/điều kiện theo trình tự, không chỉ là `NOT NULL`; cần thống nhất cách cài đặt và thời điểm kiểm tra.
- Số lượng thuốc phải lớn hơn 0. Liều dùng phải có nội dung; nếu biểu diễn số lượng/đơn vị có cấu trúc thì các thành phần số phải dương.
- Hồ sơ bệnh án không xóa vật lý; dùng trạng thái ngừng sử dụng theo quy tắc đề tài. Cần chốt xem quy tắc áp dụng cho hồ sơ hay cả lần khám, chẩn đoán, đơn thuốc.
- Các bản ghi y tế có thời điểm tạo và người tạo để phục vụ lưu vết tối thiểu.
- Quyền truy cập phải theo vai trò; bệnh nhân chỉ được xem hồ sơ của mình nếu phạm vi demo có tài khoản bệnh nhân.

## 6. Đầu ra phục vụ các giai đoạn sau

| Đầu ra sau khảo sát | Dùng trong |
|---|---|
| Thực thể, thuộc tính, liên kết, khóa ứng viên | T13 – ER mảng C |
| Quy tắc, loại ràng buộc, nơi thực thi | T09 – BR-C; T15 – truy vết BR → ER/SQL |
| Khóa/FK liên kết lịch hẹn, bệnh nhân, bác sĩ | T21 – ánh xạ logic |
| FD/khóa ứng viên và giả định về cardinality | T25/T28 – chuẩn hóa |
| Quy tắc dị ứng, trạng thái lần khám, không xóa | T34/T38 – DDL, trigger, view |
| Các trường hợp hợp lệ/không hợp lệ và dữ liệu giả lập | T39/T43 – seed và kiểm thử |

## 7. Giả định cần nhóm xác nhận

1. Áp dụng đề xuất của trưởng nhóm: mỗi bệnh nhân có đúng một hồ sơ bệnh án nội bộ; `ma_bn` UNIQUE ở `HO_SO_BENH_AN`.
2. Một lịch hẹn chỉ tạo lần khám khi lịch đã `HOAN_THANH`; `ma_lich_hen` UNIQUE ở `LAN_KHAM`. Hủy/no-show không tạo lần khám.
3. Một lần khám có thể có nhiều đơn thuốc; bác sĩ khám là người kê. Cần chốt quyền sửa sau khi kê trong thiết kế SQL.
4. Chẩn đoán tối thiểu một là điều kiện trước khi tạo đơn, trước khi hoàn tất lần khám, hay chỉ áp dụng cho lần khám có kê đơn?
5. Danh mục ICD-10 là tập mã nhỏ giả lập hay cần nhập toàn bộ danh mục? Trường nào là nguồn mô tả chính?
6. Thuốc chứa nhiều hoạt chất không? Dị ứng chỉ xét hoạt chất khớp chính xác trong đồ án hay cần mô hình phản ứng chéo? Đề xuất giới hạn ở khớp mã hoạt chất chính xác.
7. Theo review, chặn `DELETE` vật lý trên năm bảng `HO_SO_BENH_AN`, `LAN_KHAM`, `CHAN_DOAN`, `DON_THUOC`, `CHI_TIET_DON_THUOC`; dùng trạng thái/thu hồi phù hợp khi ngừng sử dụng.
8. Ai tạo/cập nhật bệnh án và có cần lưu đầy đủ lịch sử sửa đổi cho demo không? Đề xuất lưu `created_at`, `created_by`; audit chi tiết để ngoài phạm vi nếu không được yêu cầu.
9. Cách liên kết user/role của bệnh nhân với `ma_bn` là gì? Nếu không có đăng nhập thực, demo chỉ kiểm thử role DB và ghi rõ hạn chế.

## 8. Nguồn và căn cứ

- Sườn báo cáo đồ án trong `docs/INT1313_TX_G5_DeTai05_Telemedicine_v0.docx`, phần 1.2.3, 2.1, 2.3, 4.1, 5.1 và 5.2.
- Kế hoạch nhóm trong `docs/KeHoach_G5_Telemedicine.xlsx`, đặc biệt mảng C và các việc T05, T09, T13, T21, T25, T28, T34, T38, T42–T46, T50.
- `docs/khao-sat/T03_KhaoSat_MangB.md` cho luồng lịch hẹn và liên kết đề xuất `LICH_HEN`–`LAN_KHAM`.
- Quy tắc sản phẩm ở tài liệu này là phạm vi thiết kế học phần; không xem như hướng dẫn hoặc tiêu chuẩn chăm sóc y tế.
