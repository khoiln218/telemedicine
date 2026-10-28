# T46 – Nội dung nháp mảng C cho báo cáo v3

Tài liệu này là bản nháp Markdown để review/gộp vào báo cáo Word khi nhóm thống nhất; chưa sửa file Word dùng chung.

## 4.1.6. Cài đặt và kiểm soát dữ liệu bệnh án (đóng góp mảng C)

Mảng C được cài đặt trên PostgreSQL 16 bằng các bảng `LAN_KHAM`, `CHAN_DOAN`, `MA_ICD10`, `DON_THUOC`, `THUOC`, `HOAT_CHAT` và các bảng kết hợp `CHI_TIET_DON_THUOC`, `THUOC_HOAT_CHAT`, `DI_UNG`. Khóa ngoại nối lần khám với lịch hẹn, đơn thuốc với lần khám, chẩn đoán với ICD-10 và chi tiết đơn với thuốc. Bệnh nhân/bác sĩ được lấy qua lịch hẹn, tránh lưu lặp. Các khóa ngoại mặc định chặn xóa dữ liệu đang được tham chiếu.

Các điều kiện đơn hàng được kiểm tra ở nơi phù hợp: `CHECK` giới hạn số lượng dương và liều dùng không rỗng; trigger kiểm tra lịch hẹn hoàn thành, tài khoản tạo đơn thuộc bác sĩ của lịch, có chẩn đoán hiệu lực trước khi lập đơn và thuốc không chứa hoạt chất bệnh nhân đã ghi nhận dị ứng. Constraint trigger trì hoãn kiểm tra đơn có ít nhất một dòng thuốc tới cuối giao dịch để cho phép thêm đơn và chi tiết trong cùng giao dịch.

Để giữ lịch sử, lần khám không được sửa/xóa; chẩn đoán và đơn thuốc chỉ có thể chuyển từ `HIEU_LUC` sang `DA_HUY`, không sửa nội dung. Chi tiết thuốc đã ghi không được sửa/xóa; nếu có sai sót thì hủy cả đơn và lập đơn mới theo quy trình. Quyền truy cập được tách bằng role: bác sĩ thao tác hồ sơ; bệnh nhân chỉ đọc view của mình; lễ tân và các vai trò quản trị ngoài danh mục không được cấp quyền đọc dữ liệu lâm sàng; quản trị danh mục chỉ cập nhật thuốc, hoạt chất và ICD-10.

View `v_ho_so_tom_tat` và `v_di_ung_tom_tat` phục vụ tra cứu lâm sàng; `v_ho_so_cua_toi` và `v_di_ung_cua_toi` lọc hồ sơ bệnh nhân theo ngữ cảnh `app.ma_bn` do backend đã xác thực đặt trong transaction. Mô hình này giả định bệnh nhân không kết nối SQL trực tiếp bằng tài khoản ứng dụng dùng chung và không tự đặt biến ngữ cảnh. Mục thuốc/hoạt chất/ICD đã được hồ sơ tham chiếu không được sửa để nội dung lịch sử không đổi; quản trị viên tạo mục mới khi cần thay thế.

## 4.2. Truy vấn và kiểm tra hiệu năng (đóng góp mảng C)

Các truy vấn mẫu gồm: top thuốc theo quý; lập danh sách bệnh nhân có mã chẩn đoán cần theo dõi nhưng chưa tái khám trong 30 ngày; tra cứu lịch sử một bệnh nhân qua lần khám, chẩn đoán, đơn thuốc, thuốc và dị ứng; so sánh số loại thuốc trung bình mỗi đơn theo bác sĩ với mức chung. Truy vấn theo khoảng thời gian dùng cận dưới bao gồm và cận trên loại trừ để tận dụng chỉ mục B-tree.

Tệp `sql/performance_C.sql` dùng `EXPLAIN (ANALYZE, BUFFERS, VERBOSE)` cho các đường truy cập lịch sử theo bệnh nhân, tổng hợp thuốc kê và phát hiện giao giữa hoạt chất kê với dị ứng. Cần chạy trên PostgreSQL 16 sau khi nạp dữ liệu giả lập; báo cáo v3 sẽ ghi plan, actual time, số hàng và buffer thực tế thay vì điền số đo suy đoán.

## 5. Kiểm thử ràng buộc mảng C

`sql/tests_C.sql` kiểm thử các trường hợp đại diện cho BR-C01–C06: kê thuốc có hoạt chất dị ứng, người tạo không phải bác sĩ phụ trách, hủy chẩn đoán cuối khi còn đơn hiệu lực, số lượng bằng 0, đơn không có dòng thuốc, sửa/xóa dữ liệu lâm sàng, `TRUNCATE` chẩn đoán và kiểm tra quyền đọc của lễ tân/bệnh nhân. Dữ liệu dùng trong seed là dữ liệu giả lập, không chứa hồ sơ người bệnh thật. Các kiểm thử kỳ vọng vi phạm được cô lập trong subtransaction và toàn bộ dữ liệu test được rollback.

Đã chạy 13/13 ca C trên PostgreSQL 16.15 với A stub trong cụm tạm và fixture giả lập; chạy 49/49 ca B cùng môi trường. Đây là kiểm tra hợp đồng C–B dựa trên giao diện hiện tại, chưa thay cho lần chạy cuối cùng với A_schema và seed tổng do nhóm tích hợp. `EXPLAIN ANALYZE` chạy thành công trên fixture nhỏ; cần đo lại sau khi nạp seed tổng trước khi ghi số liệu hiệu năng vào báo cáo.
