# T05 – Báo cáo khảo sát mảng C: Hồ sơ bệnh án & Đơn thuốc điện tử

| | |
|---|---|
| Mã việc | T05 (GĐ0, tuần 1) |
| Người thực hiện / review | Nguyễn Đăng Khoa / Đặng Hữu Khoa |
| Ngày | 14/10/2026; cập nhật 19/10/2026 theo phạm vi đã chốt |
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

| Bên liên quan | Vai trò trong quy trình | Nhu cầu dữ liệu | Trong ERD |
|---|---|---|---|
| Bác sĩ | Ghi lần khám, chẩn đoán, kê đơn | Xem lịch sử khám, dị ứng của bệnh nhân; thêm lần khám, chẩn đoán, đơn thuốc | Thực thể BAC_SI (mảng A) |
| Bệnh nhân | Người được khám, nhận đơn | Xem hồ sơ bệnh án, đơn thuốc của chính mình | Thực thể BENH_NHAN (mảng B) |
| Quản trị | Quản lý danh mục thuốc, hoạt chất, ICD-10 | Thêm, sửa danh mục | Không – role `r_quan_tri` |

Tác nhân ghi "Không" là người dùng hệ thống: chỉ có role CSDL để phân quyền, không lưu thành thực thể trong ERD.

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

Rút ra từ quy trình; phát biểu chính thức, đánh số và cách kiểm chứng ở [T09](../br/T09_BR_MangC.md).

| Nguồn trong quy trình | Yêu cầu | Quy tắc |
|---|---|---|
| Bước 4: kiểm tra dị ứng | Không kê thuốc có hoạt chất bệnh nhân dị ứng | BR-C01 |
| Bước 1, 3: lần khám từ lịch hoàn thành, bác sĩ của lịch kê đơn | Chỉ lập đơn cho lần khám của lịch hoàn thành; người kê là bác sĩ khám | BR-C02 |
| Bước 3: kê đơn sau khi có chẩn đoán | Lần khám phải có chẩn đoán trước khi lập đơn | BR-C03 |
| Bước 3: số lượng và liều dùng | Số lượng lớn hơn 0; liều dùng bắt buộc | BR-C04 |
| Bước 5: giữ lịch sử | Không xóa, không sửa nội dung lần khám, chẩn đoán, đơn thuốc | BR-C05 |

## 5. Ràng buộc và giả định

- Bệnh nhân và bác sĩ của lần khám lấy qua lịch hẹn, không lưu lặp.
- Một lần khám có thể có nhiều đơn; một thuốc chỉ xuất hiện một lần trong một đơn.
- Liều dùng lưu dạng văn bản, ghi cả cách dùng và thời gian dùng.
- Dị ứng chỉ xét trùng đúng mã hoạt chất; kiểm tra lúc kê đơn, không hồi tố đơn cũ.
- Danh mục ICD-10 là tập mã nhỏ giả lập, đủ cho dữ liệu mẫu.
- Hồ sơ bệnh án không có bảng riêng; trình bày bằng view `v_ho_so_tom_tat_benh_nhan`.
- Lưu vết tối thiểu bằng người tạo và thời điểm tạo; không làm audit đầy đủ.
- Quản trị là người dùng hệ thống, không phải thực thể: chỉ có role CSDL `r_quan_tri` (quản lý danh mục thuốc, hoạt chất, ICD-10).

## 6. Kết quả khảo sát (đầu vào T13)

| Thực thể | Thuộc tính chính | Liên kết |
|---|---|---|
| LAN_KHAM | ma_lan_kham, thoi_diem_kham, tom_tat, created_by | 1:1 LICH_HEN (B), mỗi lịch hoàn thành có tối đa một lần khám; 1:N CHAN_DOAN; 1:N DON_THUOC |
| CHAN_DOAN | ma_chan_doan, la_chan_doan_chinh, ghi_chu, trang_thai | N:1 LAN_KHAM; N:1 MA_ICD10 |
| MA_ICD10 | ma_icd10, mo_ta | 1:N CHAN_DOAN |
| DON_THUOC | ma_don, thoi_diem_ke, trang_thai, created_by | N:1 LAN_KHAM; M:N THUOC (KÊ) |
| THUOC | ma_thuoc, ten_thuoc, dang_bao_che, ham_luong | M:N DON_THUOC (KÊ); M:N HOAT_CHAT (CHỨA) |
| HOAT_CHAT | ma_hoat_chat, ten_hoat_chat | M:N THUOC (CHỨA); M:N BENH_NHAN (DỊ_ỨNG) |

Các liên kết:

| Liên kết | Thực thể tham gia | Tỉ số | Thuộc tính |
|---|---|---|---|
| PHÁT_SINH | LICH_HEN (B) – LAN_KHAM | 1:1 | – |
| CÓ_CHẨN_ĐOÁN | LAN_KHAM – CHAN_DOAN | 1:N | – |
| MÃ_HÓA | MA_ICD10 – CHAN_DOAN | 1:N | – |
| LẬP_ĐƠN | LAN_KHAM – DON_THUOC | 1:N | – |
| KÊ | DON_THUOC – THUOC | M:N | so_luong, lieu_dung |
| CHỨA | THUOC – HOAT_CHAT | M:N | ham_luong |
| DỊ_ỨNG | BENH_NHAN (B) – HOAT_CHAT | M:N | ngay_ghi_nhan, ghi_chu |

## Nguồn tham khảo

- Đề bài INT1313 – đề tài #5.
- Thông tư 27/2021/TT-BYT quy định kê đơn thuốc bằng hình thức điện tử: https://thongtinphapluat.bacgiang.gov.vn/documents/249229/0/27_2021_tt-byt_497939-pdf-19699966785803121.pdf/32f8c5a3-54f0-4eca-a506-e75f9b4237ff
- Thông tư 26/2025/TT-BYT quy định kê đơn thuốc hóa dược, sinh phẩm tại cơ sở khám chữa bệnh: https://luatvietnam.vn/y-te/thong-tu-26-2025-tt-byt-quy-dinh-ke-don-thuoc-hoa-duoc-sinh-pham-tai-co-so-kham-chua-benh-404246-d1.html
- Thông tư 13/2025/TT-BYT hướng dẫn triển khai hồ sơ bệnh án điện tử: https://caselaw.vn/van-ban-phap-luat/587211-thong-tu-so-13-2025-tt-byt-ngay-06-06-2025-cua-bo-truong-bo-y-te-huong-dan-trien-khai-ho-so-benh-an-dien-tu
- Hệ thống đơn thuốc quốc gia – hướng dẫn sử dụng: https://donthuocquocgia.vn/huong-dan-su-dung.pdf
- World Health Organization. ICD-10 Version 2019: https://icd.who.int/browse10/2019/en
- ISO/IEC/IEEE 29148:2018 – Systems and software engineering — Life cycle processes — Requirements engineering.
