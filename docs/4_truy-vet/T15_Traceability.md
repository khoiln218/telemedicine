# T15 – Ma trận truy vết quy tắc nghiệp vụ → ERD

| | |
|---|---|
| Mã việc | T15 (GĐ1, tuần 4) |
| Người làm / review | Đặng Hữu Khoa (A), Lê Ngọc Khôi (B), Nguyễn Đăng Khoa (C) / Đặng Hữu Khoa |
| Ngày | 19/10/2026; cập nhật 21/10/2026 thêm BR-A09, BR-B08, BR-C06 (phân quyền), BR-B09, BR-B10 và `TAI_KHOAN`; BR-A10 và `NHAN_VIEN`; tách quản trị theo 3 mảng; 28/10/2026 thêm `GHI_KHÁM`, `GHI_ĐƠN` theo T30 C5 |
| Chuẩn tham chiếu | ISO/IEC/IEEE 29148:2018 – truy vết yêu cầu hai chiều |
| Căn cứ | Khảo sát [T04](../1_khao-sat/T04_KhaoSat_MangA.md), [T03](../1_khao-sat/T03_KhaoSat_MangB.md), [T05](../1_khao-sat/T05_KhaoSat_MangC.md); quy tắc [T07](../2_quy-tac/T07_BR_MangA.md), [T08](../2_quy-tac/T08_BR_MangB.md), [T09](../2_quy-tac/T09_BR_MangC.md); ERD [A](../3_erd/A.drawio), [B](../3_erd/B.drawio), [C](../3_erd/C.drawio) |
| Dùng cho | Báo cáo mục 2.1.5 |

Mục đích: chứng minh mỗi quy tắc nghiệp vụ có nguồn khảo sát và được thể hiện trong ERD; đồng thời mỗi thành phần ERD đều phục vụ ít nhất một yêu cầu. Tài liệu dừng ở mô hình khái niệm, không ghi cơ chế cài đặt.

Cách đọc: cột "Phần ERD không thể hiện được" ghi phần của quy tắc mà ký hiệu ER/EER không diễn đạt được; phần này phải được bảo đảm thêm ở bước cài đặt.

## 1. Truy vết xuôi: nguồn → quy tắc → ERD

### Mảng A (Đặng Hữu Khoa)

| Quy tắc | Nguồn (T04) | Thành phần ERD | Phần ERD không thể hiện được |
|---|---|---|---|
| BR-A01 | Bước 1 | Phân lớp `BAC_SI` → {`BAC_SI_DA_KHOA`, `BAC_SI_CHUYEN_KHOA`} | – |
| BR-A02 | Bước 1 | Liên kết `THUỘC` 1:N, bác sĩ chuyên khoa bắt buộc tham gia | – |
| BR-A03 | Bước 2, 5 | Liên kết `XẾP_CA`; thuộc tính `ngay_het_han_cc` | So sánh ngày của ca với hạn chứng chỉ |
| BR-A04 | Bước 2 | Liên kết `XẾP_CA` 1:N | Các ca của một bác sĩ không chồng giờ |
| BR-A05 | Bước 1 | Thuộc tính `so_chung_chi` là khóa ứng viên | – |
| BR-A06 | Bước 2 | Thuộc tính `thoi_gian_bd`, `thoi_gian_kt` | Miền giá trị |
| BR-A07 | Bước 1, 5 | Thuộc tính `ngay_cap_cc`, `ngay_het_han_cc` | Miền giá trị |
| BR-A08 | Bước 4 | Liên kết `XẾP_CA`; `PHỤ_TRÁCH` (mảng B) | Lịch hẹn còn hiệu lực phải nằm trong ca sau khi sửa |
| BR-A09 | Mục 2 | `NHAN_VIEN`, `BAC_SI`, `CHUYEN_KHOA`, `CA_LAM_VIEC` | Quyền thao tác theo vai trò |
| BR-A10 | Bước 1 | Phân lớp `NHAN_VIEN` → `BAC_SI` theo `loai_nv` | Bản ghi `BAC_SI` chỉ cho nhân viên loại bác sĩ |

### Mảng B (Lê Ngọc Khôi)

| Quy tắc | Nguồn (T03) | Thành phần ERD | Phần ERD không thể hiện được |
|---|---|---|---|
| BR-B01 | Bước 1 | Liên kết `PHỤ_TRÁCH`; `XẾP_CA` (mảng A) | Lịch hẹn nằm trọn trong một ca còn hiệu lực |
| BR-B02 | Bước 1 | Liên kết `PHỤ_TRÁCH` 1:N, `ĐẶT` 1:N | Các lịch còn hiệu lực của một bác sĩ, hoặc một bệnh nhân, không giao nhau |
| BR-B03 | Bước 5 | Liên kết `SỬ_DỤNG` 1:1, `CHUYỂN_ĐẾN`; `THUỘC` (mảng A) | Giấy của chính bệnh nhân, còn hạn, đúng chuyên khoa; miễn khi tái khám |
| BR-B04 | Bước 4 | Thuộc tính `nen_tang`, `link_phien` của `TU_VAN_TU_XA` | Bắt buộc có giá trị |
| BR-B05 | Bước 2, sơ đồ trạng thái | Thuộc tính `trang_thai` của `LICH_HEN` | Thứ tự chuyển trạng thái |
| BR-B06 | Bước 1 | Phân lớp `LICH_HEN` → {`KHAM_TRUC_TIEP`, `TU_VAN_TU_XA`} | – |
| BR-B07 | Bước 5 | Liên kết `LẬP_GIẤY` với `BAC_SI_DA_KHOA` (mảng A); thuộc tính `ngay_lap`, `ngay_het_han` | Hạn tối đa 30 ngày |
| BR-B08 | Mục 2, 5 | `BENH_NHAN`, `LICH_HEN`, `GIAY_CHUYEN_KHOA`; liên kết `ĐẶT` | Quyền thao tác theo vai trò; bệnh nhân chỉ thấy hàng của mình |
| BR-B09 | Mục 2, 5 | Thực thể `TAI_KHOAN`; liên kết `TK_BỆNH_NHÂN`, `TK_NHÂN_VIÊN` 1:1 | Tài khoản gắn đúng loại người; vai trò khớp loại nhân viên |
| BR-B10 | Bước 1, mục 5 | Thực thể `TAI_KHOAN` (`vai_tro`, `trang_thai`) | Ai được tạo, sửa tài khoản loại nào |

### Mảng C (Nguyễn Đăng Khoa)

| Quy tắc | Nguồn (T05) | Thành phần ERD | Phần ERD không thể hiện được |
|---|---|---|---|
| BR-C01 | Bước 4 | Liên kết M:N `DỊ_ỨNG`, `CHỨA`, `KÊ` | Không thuốc nào trong đơn chứa hoạt chất bệnh nhân dị ứng |
| BR-C02 | Bước 1, 3 | Liên kết `PHÁT_SINH` 1:1 (lần khám bắt buộc), `LẬP_ĐƠN`; `PHỤ_TRÁCH` (mảng B); `GHI_KHÁM`, `GHI_ĐƠN` (tài khoản ghi) | Lần khám chỉ được tạo khi lịch hẹn đã hoàn thành |
| BR-C03 | Bước 2, 3 | Liên kết `CÓ_CHẨN_ĐOÁN`, `LẬP_ĐƠN` | Chẩn đoán phải có trước khi lập đơn |
| BR-C04 | Bước 3 | Thuộc tính `so_luong`, `lieu_dung` của `KÊ` | Số lượng dương, liều không rỗng |
| BR-C05 | Bước 5 | Thuộc tính `trang_thai` của `CHAN_DOAN`, `DON_THUOC` | Không được xóa, sửa nội dung; chỉ được hủy |
| BR-C06 | Mục 2 | `LAN_KHAM`, `CHAN_DOAN`, `DON_THUOC`, `KÊ`, `DỊ_ỨNG`; `PHÁT_SINH` (qua lịch hẹn); `THUOC`, `HOAT_CHAT`, `MA_ICD10` | Quyền thao tác theo vai trò; bệnh nhân chỉ thấy hàng của mình |

## 2. Truy vết ngược: thành phần ERD → yêu cầu

| Mảng | Thành phần ERD | Loại | Yêu cầu phục vụ |
|---|---|---|---|
| A | `NHAN_VIEN` | Thực thể (lớp cha) | BR-A10, BR-B09 |
| A | `BAC_SI` | Lớp con của `NHAN_VIEN`, lớp cha của 2 lớp | BR-A01, BR-A03, BR-A05, BR-A07, BR-A10 |
| A | `BAC_SI_DA_KHOA` | Lớp con | BR-A01, BR-B07 |
| A | `BAC_SI_CHUYEN_KHOA` | Lớp con | BR-A01, BR-A02 |
| A | `CHUYEN_KHOA` | Thực thể | BR-A02, BR-B03 |
| A | `CA_LAM_VIEC` | Thực thể | BR-A03, BR-A04, BR-A06, BR-A08, BR-B01 |
| A | `THUỘC` | Liên kết 1:N | BR-A02, BR-B03 |
| A | `XẾP_CA` | Liên kết 1:N | BR-A03, BR-A04, BR-A08 |
| B | `BENH_NHAN` | Thực thể | BR-B02, BR-B03; ràng buộc chung (`sdt` không trùng) |
| B | `LICH_HEN` | Thực thể (lớp cha) | BR-B01, BR-B02, BR-B03, BR-B05, BR-B06 |
| B | `KHAM_TRUC_TIEP` | Lớp con | BR-B06 |
| B | `TU_VAN_TU_XA` | Lớp con | BR-B04, BR-B06 |
| B | `GIAY_CHUYEN_KHOA` | Thực thể | BR-B03, BR-B07 |
| B | `ĐẶT` | Liên kết 1:N | BR-B02 |
| B | `PHỤ_TRÁCH` | Liên kết 1:N | BR-B01, BR-B02, BR-C02 |
| B | `ĐƯỢC_CẤP` | Liên kết 1:N | BR-B03 |
| B | `LẬP_GIẤY` | Liên kết 1:N | BR-B07 |
| B | `CHUYỂN_ĐẾN` | Liên kết 1:N | BR-B03 |
| B | `SỬ_DỤNG` | Liên kết 1:1 | BR-B03 |
| B | `TAI_KHOAN` | Thực thể | BR-B09, BR-B10; MT-06 |
| B | `TK_BỆNH_NHÂN` | Liên kết 1:1 | BR-B09 |
| B | `TK_NHÂN_VIÊN` | Liên kết 1:1 | BR-B09 |
| C | `LAN_KHAM` | Thực thể | BR-C02, BR-C03, BR-C05 |
| C | `CHAN_DOAN` | Thực thể | BR-C03, BR-C05 |
| C | `MA_ICD10` | Thực thể | T05 bước 2 (chẩn đoán theo mã ICD-10) |
| C | `DON_THUOC` | Thực thể | BR-C02, BR-C05 |
| C | `THUOC` | Thực thể | BR-C01, BR-C04 |
| C | `HOAT_CHAT` | Thực thể | BR-C01 |
| C | `PHÁT_SINH` | Liên kết 1:1 | BR-C02 |
| C | `CÓ_CHẨN_ĐOÁN` | Liên kết 1:N | BR-C03 |
| C | `MÃ_HÓA` | Liên kết 1:N | T05 bước 2 |
| C | `LẬP_ĐƠN` | Liên kết 1:N | BR-C02, BR-C03 |
| C | `KÊ` | Liên kết M:N | BR-C01, BR-C04, BR-C05 |
| C | `CHỨA` | Liên kết M:N | BR-C01 |
| C | `DỊ_ỨNG` | Liên kết M:N | BR-C01 |
| C | `GHI_KHÁM` | Liên kết 1:N (TAI_KHOAN – LAN_KHAM) | BR-C02, BR-C06 |
| C | `GHI_ĐƠN` | Liên kết 1:N (TAI_KHOAN – DON_THUOC) | BR-C02, BR-C06 |

## 3. Phụ thuộc liên mảng

| Quy tắc | Dùng từ mảng khác | Nội dung |
|---|---|---|
| BR-A08 | B: `LICH_HEN` | Không sửa, hủy ca làm lịch hẹn còn hiệu lực nằm ngoài ca |
| BR-B01 | A: `CA_LAM_VIEC` | Lịch hẹn nằm trọn trong một ca |
| BR-B02 | A: `BAC_SI` | Lịch hẹn còn hiệu lực của cùng một bác sĩ không giao nhau |
| BR-B03 | A: `BAC_SI_CHUYEN_KHOA`, `CHUYEN_KHOA` | Chuyên khoa của lịch hẹn lấy qua bác sĩ |
| BR-B07 | A: `BAC_SI_DA_KHOA` | Chỉ bác sĩ đa khoa lập giấy chuyển |
| BR-B09 | A: `NHAN_VIEN` | Tài khoản nhân viên gắn một nhân viên, vai trò trùng loại nhân viên |
| BR-C01 | B: `BENH_NHAN` | Dị ứng gắn với bệnh nhân; bệnh nhân của đơn lấy qua lịch hẹn |
| BR-C02 | B: `LICH_HEN`, `TAI_KHOAN`, BR-B05; A: `BAC_SI` | Hoàn thành là trạng thái cuối; tài khoản ghi lần khám, kê đơn là của bác sĩ phụ trách lịch hẹn |
| BR-C06 | B: `LICH_HEN`, BR-B08 | Bệnh nhân của bản ghi bệnh án lấy qua lịch hẹn; nhận diện bệnh nhân đăng nhập dùng chung |

## 4. Kiểm tra độ phủ

| Tiêu chí | Mảng A | Mảng B | Mảng C |
|---|---|---|---|
| Quy tắc có nguồn khảo sát | 10/10 | 10/10 | 6/6 |
| Quy tắc có thành phần ERD | 10/10 | 10/10 | 6/6 |
| Thành phần ERD phục vụ ít nhất một yêu cầu | 8/8 | 14/14 | 15/15 |

Mục tiêu MT-06 (phân quyền) truy vết qua BR-A09, BR-B08, BR-B09, BR-B10, BR-C06 và `TAI_KHOAN`. Truy vết ngược ở mục 2 không ghi BR-A09, BR-B08, BR-C06 vì chúng áp lên gần như mọi thực thể. Ba vai trò quản trị tách theo mảng: quản trị nhân sự (BR-A09), quản trị tài khoản (BR-B10), quản trị danh mục (BR-C06); loại nhân viên tương ứng ở BR-A10.

