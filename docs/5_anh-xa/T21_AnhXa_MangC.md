# T21 – Ánh xạ mảng C sang lược đồ quan hệ

| | |
|---|---|
| Mã việc | T21 (GĐ2) |
| Người làm / review | Nguyễn Đăng Khoa / Lê Ngọc Khôi |
| Căn cứ | [ERD C](../3_erd/C.drawio), [T09 – quy tắc C](../2_quy-tac/T09_BR_MangC.md), [T05 – khảo sát C](../1_khao-sat/T05_KhaoSat_MangC.md), [T15 – truy vết](../4_truy-vet/T15_Traceability.md) |
| Phụ thuộc | `BENH_NHAN`, `LICH_HEN`, `TAI_KHOAN` từ B; `BAC_SI` từ A |

## 1. Quy ước ánh xạ

Ánh xạ thực thể mạnh thành quan hệ, lấy mã định danh làm khóa chính; liên kết 1:N được biểu diễn bằng khóa ngoại ở phía N, liên kết M:N thành quan hệ kết hợp có khóa chính ghép. ERD C không lưu lại bệnh nhân/bác sĩ trong lần khám hay đơn thuốc: hai thông tin này được suy ra qua `LICH_HEN`, tránh tạo phụ thuộc bắc cầu và dữ liệu lặp. Hồ sơ bệnh án là tập hợp lần khám, chẩn đoán, đơn thuốc và dị ứng, không tạo bảng hồ sơ riêng.

Các bảng hồ sơ dùng `ON DELETE RESTRICT` (mặc định PostgreSQL) để bảo toàn lịch sử. Tên cột và kiểu dưới đây là đề xuất ánh xạ; T18 quy ước kiểu chung của nhóm cần được áp dụng khi hợp nhất.

## 2. Lược đồ quan hệ

1. `LAN_KHAM(`**`ma_lan_kham`**`, ma_lh → LICH_HEN(ma_lh) UNIQUE NOT NULL, thoi_diem_kham, tom_tat, created_by → TAI_KHOAN(ten_dang_nhap))`
   - Liên kết `PHÁT_SINH` 1:1: `ma_lh` vừa là FK vừa `UNIQUE NOT NULL`. Mỗi lịch hẹn phát sinh tối đa một lần khám; mỗi lần khám thuộc đúng một lịch hẹn.
   - Không lưu `ma_bn`/`ma_bac_si`; lần khám lấy hai định danh này từ lịch hẹn.
2. `CHAN_DOAN(`**`ma_chan_doan`**`, ma_lan_kham → LAN_KHAM, ma_icd10 → MA_ICD10, la_chan_doan_chinh, ghi_chu, trang_thai)`
   - Liên kết 1:N từ lần khám; mỗi chẩn đoán tham chiếu đúng một mã ICD-10.
3. `MA_ICD10(`**`ma_icd10`**`, mo_ta)`
4. `DON_THUOC(`**`ma_don`**`, ma_lan_kham → LAN_KHAM, thoi_diem_ke, trang_thai, created_by → TAI_KHOAN)`
   - Mỗi đơn thuộc đúng một lần khám; một lần khám có thể có nhiều đơn.
5. `THUOC(`**`ma_thuoc`**`, ten_thuoc, dang_bao_che, ham_luong)`
6. `HOAT_CHAT(`**`ma_hoat_chat`**`, ten_hoat_chat)`
7. `CHI_TIET_DON_THUOC(`**`ma_don`**` → DON_THUOC, `**`ma_thuoc`**` → THUOC, so_luong, lieu_dung)`
   - Quan hệ kết hợp của `KÊ` M:N; PK ghép `(ma_don, ma_thuoc)` thể hiện một thuốc xuất hiện tối đa một lần trong một đơn. `so_luong > 0`, `lieu_dung` bắt buộc không rỗng.
8. `THUOC_HOAT_CHAT(`**`ma_thuoc`**` → THUOC, `**`ma_hoat_chat`**` → HOAT_CHAT, ham_luong)`
   - Quan hệ kết hợp của `CHỨA` M:N; `ham_luong` là lượng/nồng độ của hoạt chất đó trong thuốc, không phải tổng hàm lượng ghi ở nhãn thuốc.
9. `DI_UNG(`**`ma_bn`**` → BENH_NHAN, `**`ma_hoat_chat`**` → HOAT_CHAT, ngay_ghi_nhan, ghi_chu)`
   - Quan hệ kết hợp của `DỊ_ỨNG` M:N; cặp `(ma_bn, ma_hoat_chat)` duy nhất. Theo T09, dị ứng đang có hiệu lực được biểu diễn bằng sự tồn tại của hàng; xóa hàng là kết thúc ghi nhận.

`created_by` là khóa ngoại phục vụ truy vết tài khoản tạo hồ sơ. C02 yêu cầu người kê đơn là bác sĩ được phân công cho lịch; cơ sở dữ liệu cần kiểm tra điều đó bằng trigger (T38), không suy ra chỉ từ FK tài khoản.

## 3. Ràng buộc được đặt ở tầng cài đặt

| Quy tắc | Cơ chế dự kiến |
|---|---|
| BR-C01 | Trigger kiểm tra giao giữa hoạt chất của thuốc trong chi tiết đơn và bảng `DI_UNG` của bệnh nhân thuộc lịch hẹn. |
| BR-C02 | Trigger yêu cầu lịch hẹn `HOAN_THANH`; tài khoản tạo đơn phải gắn với bác sĩ của lịch. |
| BR-C03 | Trigger yêu cầu lần khám có ít nhất một chẩn đoán hiệu lực trước khi thêm đơn. |
| BR-C04 | `CHECK (so_luong > 0)` và `CHECK (btrim(lieu_dung) <> '')`. |
| BR-C05 | Trigger chặn sửa/xóa lịch khám, chẩn đoán, đơn và chi tiết; chỉ cho đổi trạng thái sang `DA_HUY` theo quy tắc. |
| BR-C06 | Role/GRANT ở T45; bệnh nhân chỉ đọc view hồ sơ của mình, lễ tân không có quyền đọc dữ liệu lâm sàng. |

Để đáp ứng yêu cầu T05 về lưu giữ lịch sử đơn thuốc/chẩn đoán trong khi vẫn cho quản trị viên sửa danh mục, T38 chỉ cho sửa mục danh mục chưa được hồ sơ tham chiếu. Mục đã được dùng được giữ nguyên; cần đổi nội dung thì tạo mục mới. Cách này tránh để sửa tên/hàm lượng thuốc hoặc mô tả ICD làm thay đổi cách diễn giải bản ghi lịch sử.

Quy tắc bắt buộc một đơn có ít nhất một dòng thuốc (tham gia toàn phần trong ERD) cần constraint trigger trì hoãn tới cuối giao dịch, vì `CHECK` không thể kiểm tra bảng khác.

## 4. Điểm cần nhóm đồng bộ

- T30/C1 còn chờ nhóm chốt quan hệ `TAI_KHOAN.vai_tro` và `NHAN_VIEN.loai_nv`. Mảng C chỉ phụ thuộc FK tới `TAI_KHOAN`, không tự kết luận vai trò nhân viên.
- T18/T32 (DDL A) chưa có trong nhánh khi lập ánh xạ; kiểu/FK nhân viên được lấy theo B hiện tại: `tai_khoan.ten_dang_nhap`, `lich_hen.ma_lh`, `lich_hen.ma_bac_si`.
- ERD đang dùng thuộc tính `ham_luong` cả ở THUOC và quan hệ CHỨA. Ánh xạ giữ cả hai nhưng phân biệt ngữ nghĩa: hàm lượng/nhãn tổng quát của thuốc và hàm lượng từng hoạt chất. Nhóm cần xác nhận cách ghi này trên ERD để tránh hiểu một dữ kiện bị lưu lặp.
- Thiết kế không dùng dữ liệu bệnh nhân thật. Dữ liệu minh họa trong seed phải là giả lập.
