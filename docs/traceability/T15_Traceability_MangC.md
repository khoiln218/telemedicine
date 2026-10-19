# T15 – Ma trận truy vết BR → ER/SQL mảng C

| | |
|---|---|
| Mã việc | T15 (GĐ1, tuần 4) |
| Người làm / review | Nguyễn Đăng Khoa / Đặng Hữu Khoa |
| Căn cứ | [T09 – BR mảng C](../br/T09_BR_MangC.md), [ER mảng C](../../erd/C.drawio), báo cáo v1 mục 1.2.3 |
| Trạng thái | Bản làm việc; cần đồng bộ với ERD tổng và báo cáo v2.1 |

## Ma trận truy vết

| BR | Thành phần ER/EER thể hiện | Ràng buộc không thể biểu diễn đầy đủ bằng ER | Cơ chế dự kiến trong DBMS | Kiểm chứng |
|---|---|---|---|---|
| BR-C01 | `BENH_NHAN` ghi nhận `DI_UNG` theo `HOAT_CHAT`; `THUOC` liên kết M:N với `HOAT_CHAT` qua `THUOC_HOAT_CHAT`; `DON_THUOC` có `CHI_TIET_DON_THUOC` và mỗi dòng trỏ tới `THUOC` | Không thể chỉ bằng cardinality thể hiện quy tắc tập hợp: không dòng thuốc nào của lần khám chứa hoạt chất đang hiệu lực trong dị ứng của bệnh nhân; cần xác định bệnh nhân qua lịch hẹn → lần khám | Trigger `trg_chan_thuoc_di_ung` trên INSERT/UPDATE `CHI_TIET_DON_THUOC`; so sánh mã hoạt chất, chỉ xét `DI_UNG.trang_thai = 'DANG_HIEU_LUC'` ở thời điểm kê | TC-04: dòng thuốc có hoạt chất dị ứng bị từ chối; dòng thuốc không trùng hoạt chất được chấp nhận |
| BR-C02 | `DON_THUOC` N:1 `LAN_KHAM`; `LAN_KHAM` 1:1 `LICH_HEN` qua FK UNIQUE; bác sĩ của lần khám được xác định bởi `LICH_HEN.ma_bac_si` (mảng A/B). Không lưu lặp `ma_bac_si` trong `LAN_KHAM` hoặc `ma_bac_si_ke` trong `DON_THUOC` | Trạng thái lịch hẹn phải là `HOAN_THANH`; người kê phải khớp bác sĩ lịch hẹn; lịch hẹn hoàn thành là trạng thái cuối theo BR-B05 | FK + trigger khi INSERT/UPDATE `DON_THUOC` xác nhận `LICH_HEN.trang_thai = 'HOAN_THANH'`. Bác sĩ thực hiện là bác sĩ được gán trên lịch; `created_by` là người dùng tạo bản ghi, không thay cho định danh bác sĩ nghiệp vụ | TC-06: FK `ma_lan_kham` không tồn tại bị từ chối; TC-08 đề xuất: lịch chưa hoàn thành/bác sĩ không khớp bị từ chối |
| BR-C03 | `LAN_KHAM` 1:N `CHAN_DOAN`; `LAN_KHAM` 1:N `DON_THUOC` | Khi lập đơn phải tồn tại tối thiểu một chẩn đoán thuộc chính lần khám đó; đây là điều kiện liên bảng theo thời điểm thao tác, không chỉ là cardinality | Trigger kiểm tra trước khi tạo đơn; BR-C05 chặn `DELETE` chẩn đoán sau khi đã ghi, nên điều kiện không bị phá vỡ bằng xóa vật lý | TC-09 đề xuất: tạo đơn khi chưa có chẩn đoán bị từ chối; thêm chẩn đoán rồi tạo đơn thành công |
| BR-C04 | `CHI_TIET_DON_THUOC.so_luong` và `lieu_dung` là thuộc tính bắt buộc của dòng đơn | Miền dương của số lượng và giá trị liều không rỗng là ràng buộc miền | `NOT NULL`; `CHECK (so_luong > 0)`; kiểm tra `btrim(lieu_dung) <> ''` nếu kiểu lưu là văn bản | TC-07: số lượng âm/0 hoặc liều trống bị từ chối; dòng hợp lệ được chấp nhận |
| BR-C05 | `HO_SO_BENH_AN`, `LAN_KHAM`, `CHAN_DOAN`, `DON_THUOC`, `CHI_TIET_DON_THUOC` lưu lịch sử; trạng thái thể hiện ngừng sử dụng | Cấm thao tác DELETE trên các bảng lịch sử; ER không thể mô tả sự kiện lệnh SQL bị cấm | Trigger `trg_khong_xoa_benh_an` `BEFORE DELETE` trên năm bảng; FK `RESTRICT`/`NO ACTION`, không dùng `ON DELETE CASCADE` cho dữ liệu y tế | TC-05: DELETE ở mỗi bảng bị từ chối; UPDATE trạng thái ngừng sử dụng thành công và bản ghi vẫn tồn tại |

## Liên kết với quy tắc chung A/B

- **Mảng B – BR-B05:** `LICH_HEN` chỉ chuyển sang `HOAN_THANH` qua luồng trạng thái cho phép; BR-C02 dựa vào trạng thái cuối này. Mảng C không tự sửa trạng thái lịch hẹn.
- **Mảng B – `LICH_HEN`/`BENH_NHAN`:** bệnh nhân của lần khám được suy ra từ lịch hẹn. Không thêm `ma_bn` vào `LAN_KHAM`, tránh lưu trùng thông tin đã có qua FK.
- **Mảng A/B – bác sĩ của lịch:** bác sĩ khám được xác định qua `LICH_HEN` và khóa bác sĩ do các mảng sở hữu; không thêm `ma_bac_si` vào `LAN_KHAM` hoặc `DON_THUOC`.
- **Ràng buộc chung:** PK/FK, `NOT NULL`, miền giá trị, thời điểm/người tạo theo sườn báo cáo. `created_by` lưu tác nhân audit, không thay cho FK nghiệp vụ tới bác sĩ.

## Giả định để ERD và ma trận nhất quán

1. Một bệnh nhân có đúng một `HO_SO_BENH_AN`; `HO_SO_BENH_AN.ma_bn` là FK UNIQUE.
2. Chỉ lịch hẹn `HOAN_THANH` mới phát sinh một `LAN_KHAM`; `LAN_KHAM.ma_lich_hen` là FK UNIQUE. Bệnh nhân và bác sĩ được truy ra từ lịch hẹn, vì vậy `LAN_KHAM` không có `ma_bn`/`ma_bac_si`.
3. Một lần khám có thể có nhiều đơn; đơn không lưu `ma_bac_si_ke`. Bác sĩ kê là bác sĩ gắn với lịch hẹn của lần khám.
4. Liều dùng lưu kiểu văn bản cho phạm vi demo; CSDL đảm bảo bắt buộc/không rỗng, không xác thực tính phù hợp chuyên môn.
5. Dị ứng đang hiệu lực được nhận diện bằng `DI_UNG.trang_thai = 'DANG_HIEU_LUC'`; kiểm tra khi kê/cập nhật dòng đơn, không hồi tố dữ liệu cũ khi trạng thái thay đổi.
6. BR-C05 chặn DELETE trên đúng năm bảng lịch sử nêu trong ma trận; ngừng sử dụng bằng cập nhật trạng thái.

## Ghi chú tích hợp báo cáo

- Bảng 1.2.3 trong báo cáo v1 đã được đối chiếu: BR-C01…C05 và cơ chế/trigger khớp với nội dung T09 sau review. Có thể giữ nguyên bảng; phần giải thích chi tiết giả định, bảng bị chặn xóa và liên kết BR-B05 đặt ở mục thiết kế/ma trận.
- Báo cáo v1 có TC-06 cho FK `DON_THUOC.ma_lan_kham` không tồn tại. Tài liệu này giữ mã TC-06; TC-08/TC-09 chỉ là mã bổ sung đề xuất, cần thống nhất trước khi gộp vào bảng kiểm thử tổng.
- ERD tổng do Hữu Khoa gộp; kiểm tra lại tên khóa `ma_lich_hen`, `ma_bac_si`, `ma_bn` với lược đồ cuối của mảng A/B trước khi chốt v2.1.
