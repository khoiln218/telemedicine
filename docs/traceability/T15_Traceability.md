# T15 – Ma trận truy vết quy tắc nghiệp vụ → ERD

| | |
|---|---|
| Mã việc | T15 (GĐ1, tuần 4) |
| Người làm / review | Đặng Hữu Khoa (A), Lê Ngọc Khôi (B), Nguyễn Đăng Khoa (C) / Đặng Hữu Khoa |
| Ngày | 19/10/2026 |
| Chuẩn tham chiếu | ISO/IEC/IEEE 29148:2018 – truy vết yêu cầu hai chiều |
| Căn cứ | Khảo sát [T04](../khao-sat/T04_KhaoSat_MangA.md), [T03](../khao-sat/T03_KhaoSat_MangB.md), [T05](../khao-sat/T05_KhaoSat_MangC.md); quy tắc [T07](../br/T07_BR_MangA.md), [T08](../br/T08_BR_MangB.md), [T09](../br/T09_BR_MangC.md); ERD [A](../../erd/A.drawio), [B](../../erd/B.drawio), [C](../../erd/C.drawio) |
| Dùng cho | Báo cáo mục 2.1.5, T36–T38 (trigger/view), T43 (kiểm thử) |

Mục đích: chứng minh mỗi quy tắc nghiệp vụ có nguồn, được thể hiện trong ERD hoặc có cơ chế bổ sung, và có ca kiểm chứng; đồng thời mỗi thành phần ERD đều phục vụ ít nhất một yêu cầu.

Cách đọc: cột "Phần ERD không thể hiện được" là lý do cần cơ chế ngoài ERD; chi tiết cơ chế ở mục 3 và ca kiểm chứng ở mục 4 của tài liệu quy tắc từng mảng. Ca kiểm chứng ghi "Có" là đã có kịch bản, chưa đánh mã TC.

## 1. Truy vết xuôi: nguồn → quy tắc → ERD → cơ chế → kiểm chứng

### Mảng A (Đặng Hữu Khoa)

| Quy tắc | Nguồn (T04) | Thành phần ERD | Phần ERD không thể hiện được | Cơ chế | Kiểm chứng |
|---|---|---|---|---|---|
| BR-A01 | Bước 1 | Phân lớp `BAC_SI` → {`BAC_SI_DA_KHOA`, `BAC_SI_CHUYEN_KHOA`} | – | Cột phân loại + `CHECK` | TC-03 |
| BR-A02 | Bước 1 | Liên kết `THUỘC` 1:N, bác sĩ chuyên khoa bắt buộc tham gia | – | FK `NOT NULL` | Có |
| BR-A03 | Bước 2, 5 | Liên kết `XẾP_CA`; thuộc tính `ngay_het_han_cc` | So sánh ngày của ca với hạn chứng chỉ | Trigger `trg_kiem_tra_chung_chi` | Có |
| BR-A04 | Bước 2 | Liên kết `XẾP_CA` 1:N | Các ca của một bác sĩ không chồng giờ | `EXCLUDE` | Có |
| BR-A05 | Bước 1 | Thuộc tính `so_chung_chi` là khóa ứng viên | – | `UNIQUE` | Có |
| BR-A06 | Bước 2 | Thuộc tính `thoi_gian_bd`, `thoi_gian_kt` | Miền giá trị | `CHECK` | Có |
| BR-A07 | Bước 1, 5 | Thuộc tính `ngay_cap_cc`, `ngay_het_han_cc` | Miền giá trị | `CHECK` | Có |
| BR-A08 | Bước 4 | Liên kết `XẾP_CA`; `PHỤ_TRÁCH` (mảng B) | Lịch hẹn còn hiệu lực phải nằm trong ca sau khi sửa | Trigger `trg_bao_ve_ca_lam_viec` | Có |

### Mảng B (Lê Ngọc Khôi)

| Quy tắc | Nguồn (T03) | Thành phần ERD | Phần ERD không thể hiện được | Cơ chế | Kiểm chứng |
|---|---|---|---|---|---|
| BR-B01 | Bước 1 | Liên kết `PHỤ_TRÁCH`; `XẾP_CA` (mảng A) | Lịch hẹn nằm trọn trong một ca còn hiệu lực | Trigger `trg_lich_hen_hop_le` | TC-02 |
| BR-B02 | Bước 1 | Liên kết `PHỤ_TRÁCH` 1:N, `ĐẶT` 1:N | Các lịch còn hiệu lực của một bác sĩ, hoặc một bệnh nhân, không giao nhau | Hai `EXCLUDE` | TC-01 |
| BR-B03 | Bước 5 | Liên kết `SỬ_DỤNG` 1:1, `CHUYỂN_ĐẾN`; `THUỘC` (mảng A) | Giấy của chính bệnh nhân, còn hạn, đúng chuyên khoa; miễn khi tái khám | Trigger `trg_lich_hen_hop_le` + `UNIQUE` | Có |
| BR-B04 | Bước 4 | Thuộc tính `nen_tang`, `link_phien` của `TU_VAN_TU_XA` | Bắt buộc có giá trị | `NOT NULL` | Có |
| BR-B05 | Bước 2, sơ đồ trạng thái | Thuộc tính `trang_thai` của `LICH_HEN` | Thứ tự chuyển trạng thái | `CHECK` + `DEFAULT` + trigger `trg_trang_thai_lich_hen` | Có |
| BR-B06 | Bước 1 | Phân lớp `LICH_HEN` → {`KHAM_TRUC_TIEP`, `TU_VAN_TU_XA`} | – | Cột phân loại + `CHECK` | Có |
| BR-B07 | Bước 5 | Liên kết `LẬP_GIẤY` với `BAC_SI_DA_KHOA` (mảng A); thuộc tính `ngay_lap`, `ngay_het_han` | Hạn tối đa 30 ngày | FK + `CHECK` | Có |

### Mảng C (Nguyễn Đăng Khoa)

| Quy tắc | Nguồn (T05) | Thành phần ERD | Phần ERD không thể hiện được | Cơ chế | Kiểm chứng |
|---|---|---|---|---|---|
| BR-C01 | Bước 4 | Liên kết M:N `DỊ_ỨNG`, `CHỨA`, `KÊ` | Không thuốc nào trong đơn chứa hoạt chất bệnh nhân dị ứng | Trigger `trg_chan_thuoc_di_ung` | TC-04 |
| BR-C02 | Bước 1, 3 | Liên kết `PHÁT_SINH` 1:1 (lần khám bắt buộc), `LẬP_ĐƠN`; `PHỤ_TRÁCH` (mảng B) | Lần khám chỉ được tạo khi lịch hẹn đã hoàn thành | Trigger `trg_lan_kham_hoan_thanh`; bác sĩ kê suy ra qua lịch hẹn | TC-06, TC-08 |
| BR-C03 | Bước 2, 3 | Liên kết `CÓ_CHẨN_ĐOÁN`, `LẬP_ĐƠN` | Chẩn đoán phải có trước khi lập đơn | Trigger khi tạo đơn | TC-09 |
| BR-C04 | Bước 3 | Thuộc tính `so_luong`, `lieu_dung` của `KÊ` | Số lượng dương, liều không rỗng | `NOT NULL`, `CHECK` | TC-07 |
| BR-C05 | Bước 5 | Thuộc tính `trang_thai` của `CHAN_DOAN`, `DON_THUOC` | Cấm lệnh xóa và sửa nội dung, chỉ cho hủy | Trigger `trg_khong_xoa_benh_an`; FK không `CASCADE` | TC-05 |

## 2. Truy vết ngược: thành phần ERD → yêu cầu

| Mảng | Thành phần ERD | Loại | Yêu cầu phục vụ |
|---|---|---|---|
| A | `BAC_SI` | Thực thể (lớp cha) | BR-A01, BR-A03, BR-A05, BR-A07 |
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

## 3. Phụ thuộc liên mảng

| Quy tắc | Dùng từ mảng khác | Nội dung |
|---|---|---|
| BR-A08 | B: `LICH_HEN` | Không sửa, hủy ca làm lịch hẹn còn hiệu lực nằm ngoài ca |
| BR-B01 | A: `CA_LAM_VIEC` | Lịch hẹn nằm trọn trong một ca |
| BR-B02 | A: `BAC_SI` | Khóa bác sĩ dùng chống trùng lịch |
| BR-B03 | A: `BAC_SI_CHUYEN_KHOA`, `CHUYEN_KHOA` | Chuyên khoa của lịch hẹn lấy qua bác sĩ |
| BR-B07 | A: `BAC_SI_DA_KHOA` | Chỉ bác sĩ đa khoa lập giấy chuyển |
| BR-C01 | B: `BENH_NHAN` | Dị ứng gắn với bệnh nhân; bệnh nhân của đơn lấy qua lịch hẹn |
| BR-C02 | B: `LICH_HEN`, BR-B05; A: `BAC_SI` | Hoàn thành là trạng thái cuối; bác sĩ kê đơn là bác sĩ của lịch hẹn |

## 4. Kiểm tra độ phủ

| Tiêu chí | Mảng A | Mảng B | Mảng C |
|---|---|---|---|
| Quy tắc có nguồn khảo sát | 8/8 | 7/7 | 5/5 |
| Quy tắc có thành phần ERD | 8/8 | 7/7 | 5/5 |
| Quy tắc có cơ chế trong CSDL | 8/8 | 7/7 | 5/5 |
| Quy tắc có kịch bản kiểm chứng | 8/8 | 7/7 | 5/5 |
| Quy tắc đã có mã TC | 1/8 | 2/7 | 5/5 |
| Thành phần ERD phục vụ ít nhất một yêu cầu | 7/7 | 11/11 | 13/13 |

Việc còn lại: đánh mã TC cho các quy tắc còn thiếu khi gộp `tests.sql` (T43).
