# T23 – Phụ thuộc hàm và khóa ứng viên mảng A

| | |
|---|---|
| Mã việc | T23 (GĐ2) |
| Căn cứ | [T19 – ánh xạ mảng A](../5_anh-xa/T19_AnhXa_MangA.md), [T07 – quy tắc mảng A](../2_quy-tac/T07_BR_MangA.md) |
| Dùng cho | Báo cáo mục 2.3, T26 |

Xét phụ thuộc hàm (FD) theo một quan hệ; các FK chỉ mô tả tham chiếu giữa quan hệ, không tạo FD nội bộ. Thuộc tính UNIQUE NOT NULL là khóa ứng viên.

## 1. FD và khóa ứng viên

| Quan hệ | FD không tầm thường | Khóa ứng viên |
|---|---|---|
| NHAN_VIEN(ma_nv, ho_ten, ngay_sinh, sdt, email, loai_nv) | `ma_nv → ho_ten, ngay_sinh, sdt, email, loai_nv`; `sdt → ma_nv, ho_ten, ngay_sinh, email, loai_nv` (BR chung: điện thoại không trùng) | `{ma_nv}`, `{sdt}` |
| BAC_SI(ma_bac_si, so_chung_chi, ngay_cap_cc, ngay_het_han_cc, loai_bac_si) | `ma_bac_si → so_chung_chi, ngay_cap_cc, ngay_het_han_cc, loai_bac_si`; `so_chung_chi → ma_bac_si, ngay_cap_cc, ngay_het_han_cc, loai_bac_si` (BR-A05) | `{ma_bac_si}`, `{so_chung_chi}` |
| BAC_SI_DA_KHOA(ma_bac_si) | Không có FD không tầm thường | `{ma_bac_si}` |
| BAC_SI_CHUYEN_KHOA(ma_bac_si, ma_chuyen_khoa) | `ma_bac_si → ma_chuyen_khoa` (mỗi bác sĩ thuộc đúng một chuyên khoa) | `{ma_bac_si}` |
| CHUYEN_KHOA(ma_chuyen_khoa, ten_chuyen_khoa) | `ma_chuyen_khoa → ten_chuyen_khoa`; `ten_chuyen_khoa → ma_chuyen_khoa` (tên danh mục duy nhất) | `{ma_chuyen_khoa}`, `{ten_chuyen_khoa}` |
| CA_LAM_VIEC(ma_ca, thoi_gian_bd, thoi_gian_kt, trang_thai, ma_bac_si) | `ma_ca → thoi_gian_bd, thoi_gian_kt, trang_thai, ma_bac_si` | `{ma_ca}` |

`ma_bac_si` trong bảng BAC_SI là PK đồng thời FK; không coi `ma_nv` là cột thứ hai trong quan hệ này. Bảng lớp con một cột có khóa là toàn bộ hàng và không có FD không tầm thường.

## 2. Bao đóng khóa

- NHAN_VIEN: `{ma_nv}+` và `{sdt}+` bằng toàn bộ thuộc tính theo các FD đã nêu.
- BAC_SI: `{ma_bac_si}+` và `{so_chung_chi}+` bằng toàn bộ thuộc tính.
- BAC_SI_CHUYEN_KHOA: `{ma_bac_si}+ = {ma_bac_si, ma_chuyen_khoa}`.
- CHUYEN_KHOA: `{ma_chuyen_khoa}+` và `{ten_chuyen_khoa}+` bằng toàn bộ thuộc tính.
- CA_LAM_VIEC: `{ma_ca}+` bằng toàn bộ thuộc tính.

Các tập trên tối thiểu vì bỏ thuộc tính duy nhất khỏi từng khóa đơn thì còn tập rỗng, không suy ra thuộc tính nào khác.

## 3. Giả định FD

Các FD từ số điện thoại và tên chuyên khoa dựa trên quy tắc duy nhất của dữ liệu phòng khám (T07/ràng buộc chung). Không giả định `ho_ten`, ngày sinh, loại nhân viên hoặc khung giờ là duy nhất. Không đưa quan hệ nghiệp vụ giữa `loai_nv` và sự tồn tại BAC_SI vào FD vì đây là ràng buộc xuyên bảng được bảo đảm bằng trigger.
