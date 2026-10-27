# T29 – Từ điển dữ liệu mảng A

| | |
|---|---|
| Mã việc | T29 (GĐ2) |
| Căn cứ | [T19 – ánh xạ](../5_anh-xa/T19_AnhXa_MangA.md), [T18 – quy ước](T18_QuyUocDuLieu.md), T07 |
| Chuẩn trình bày | Theo hướng dẫn mô tả phần tử dữ liệu ISO/IEC 11179; tên, định nghĩa, kiểu/miền, quy tắc và nguồn |

## NHAN_VIEN

| Thuộc tính | Định nghĩa | Kiểu/miền | Bắt buộc | Khóa/ràng buộc |
|---|---|---|---|---|
| ma_nv | Mã định danh nội bộ của nhân viên | INTEGER identity | Có | PK |
| ho_ten | Họ tên đầy đủ | VARCHAR(100) | Có | Không rỗng |
| ngay_sinh | Ngày sinh theo hồ sơ | DATE | Có | Không sau ngày hiện tại |
| sdt | Số điện thoại liên hệ | VARCHAR(10) | Có | UNIQUE; định dạng `0` + 9 chữ số |
| email | Địa chỉ thư điện tử | VARCHAR(100) | Không | Nếu có phải đúng định dạng cơ bản |
| loai_nv | Loại nhân viên | VARCHAR(24) | Có | `BAC_SI`, `LE_TAN`, `QUAN_TRI_NHAN_SU`, `QUAN_TRI_TAI_KHOAN`, `QUAN_TRI_DANH_MUC` |

## BAC_SI

| Thuộc tính | Định nghĩa | Kiểu/miền | Bắt buộc | Khóa/ràng buộc |
|---|---|---|---|---|
| ma_bac_si | Mã bác sĩ kế thừa mã nhân viên | INTEGER | Có | PK, FK → NHAN_VIEN.ma_nv |
| so_chung_chi | Số giấy phép hành nghề hiện hành | VARCHAR(30) | Có | UNIQUE |
| ngay_cap_cc | Ngày cấp giấy phép | DATE | Có | Dùng cùng ngày hết hạn để kiểm tra A07 |
| ngay_het_han_cc | Ngày hết hạn giấy phép | DATE | Có | Phải sau ngày cấp |
| loai_bac_si | Phân loại hành nghề của bác sĩ | VARCHAR(16) | Có | `DA_KHOA` hoặc `CHUYEN_KHOA` |

## BAC_SI_DA_KHOA và BAC_SI_CHUYEN_KHOA

| Bảng/thuộc tính | Định nghĩa | Kiểu/miền | Bắt buộc | Khóa/ràng buộc |
|---|---|---|---|---|
| BAC_SI_DA_KHOA.ma_bac_si | Bác sĩ thuộc lớp đa khoa | INTEGER | Có | PK, FK → BAC_SI.ma_bac_si |
| BAC_SI_CHUYEN_KHOA.ma_bac_si | Bác sĩ thuộc lớp chuyên khoa | INTEGER | Có | PK, FK → BAC_SI.ma_bac_si |
| BAC_SI_CHUYEN_KHOA.ma_chuyen_khoa | Chuyên khoa duy nhất của bác sĩ | INTEGER | Có | FK → CHUYEN_KHOA.ma_chuyen_khoa |

## CHUYEN_KHOA

| Thuộc tính | Định nghĩa | Kiểu/miền | Bắt buộc | Khóa/ràng buộc |
|---|---|---|---|---|
| ma_chuyen_khoa | Mã định danh chuyên khoa | INTEGER identity | Có | PK |
| ten_chuyen_khoa | Tên lĩnh vực y khoa chuyên sâu | VARCHAR(100) | Có | UNIQUE |

## CA_LAM_VIEC

| Thuộc tính | Định nghĩa | Kiểu/miền | Bắt buộc | Khóa/ràng buộc |
|---|---|---|---|---|
| ma_ca | Mã định danh ca làm việc | INTEGER identity | Có | PK |
| thoi_gian_bd | Thời điểm bắt đầu ca | TIMESTAMP | Có | Nhỏ hơn thời điểm kết thúc |
| thoi_gian_kt | Thời điểm kết thúc ca | TIMESTAMP | Có | Lớn hơn thời điểm bắt đầu |
| trang_thai | Trạng thái hiệu lực của ca | VARCHAR(8) | Có | `DA_XEP` hoặc `HUY`; mặc định `DA_XEP` |
| ma_bac_si | Bác sĩ được xếp ca | INTEGER | Có | FK → BAC_SI.ma_bac_si |

## Quy tắc nghiệp vụ áp dụng

BR-A01/A02/A10: bảng lớp con khớp loại cha; BR-A03: giấy phép còn hiệu lực đến hết ngày của ca; BR-A04: ca hiệu lực không chồng; BR-A05: số giấy phép duy nhất; BR-A06/A07: thời gian ca hợp lệ và ngày hết hạn sau ngày cấp; BR-A08: không làm lịch hẹn hiệu lực rơi ngoài ca khi sửa/hủy. Ràng buộc định dạng email/điện thoại và ngày sinh tương ứng quy ước chung của dự án.
