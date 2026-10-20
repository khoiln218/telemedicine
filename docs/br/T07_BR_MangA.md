# T07 – Quy tắc nghiệp vụ mảng A: Nhân viên y tế & Lịch làm việc

| | |
|---|---|
| Mã việc | T07 (GĐ0, tuần 2) |
| Người viết / review | Đặng Hữu Khoa / Nguyễn Đăng Khoa |
| Ngày | 14/10/2026; cập nhật 19/10/2026 theo review và phạm vi đã chốt |
| Chuẩn tham chiếu | Business Rules Manifesto (Business Rules Group), SBVR (OMG); thuộc tính yêu cầu theo ISO/IEC/IEEE 29148:2018 |
| Căn cứ | [T04 – khảo sát mảng A](../khao-sat/T04_KhaoSat_MangA.md) |
| Dùng cho | Báo cáo mục 1.2.1, T11 (EER mảng A), T36 (trigger/view), T43 (kiểm thử) |

Nguyên tắc viết: mỗi quy tắc là một phát biểu khẳng định, dùng thuật ngữ ở mục 1, không phụ thuộc cách cài đặt; cơ chế cài đặt tách riêng ở mục 3. Số hiệu BR-A01…A08 giữ nguyên vì báo cáo đã tham chiếu.

## 1. Thuật ngữ

| Thuật ngữ | Định nghĩa |
|---|---|
| Bác sĩ đa khoa | Bác sĩ khám ban đầu cho mọi bệnh nhân, không giới hạn lĩnh vực |
| Bác sĩ chuyên khoa | Bác sĩ chỉ khám trong một lĩnh vực y khoa chuyên sâu |
| Chuyên khoa | Lĩnh vực chuyên sâu của y khoa, ví dụ tim mạch, da liễu |
| Chứng chỉ hành nghề | Giấy phép do cơ quan y tế cấp cho bác sĩ để được khám chữa bệnh, có ngày cấp và ngày hết hạn |
| Ca làm việc | Khoảng thời gian bác sĩ được xếp làm việc |
| Ca còn hiệu lực | Khoảng thời gian làm việc đã xếp và chưa bị hủy |
| Chồng giờ | Hai khoảng thời gian có phần chung; hai khoảng nối tiếp nhau, khoảng trước kết thúc đúng lúc khoảng sau bắt đầu, không tính là chồng giờ |

## 2. Danh sách quy tắc

Loại theo SBVR: **cấu trúc** là điều luôn đúng với dữ liệu; **hành vi** là điều kiện ràng buộc một thao tác.

| Mã | Phát biểu quy tắc | Loại | Lý do | Nguồn |
|---|---|---|---|---|
| BR-A01 | Mỗi bác sĩ là bác sĩ đa khoa hoặc bác sĩ chuyên khoa, không đồng thời cả hai | Cấu trúc | Hai loại bác sĩ có phạm vi hành nghề khác nhau (Thông tư 32/2023/TT-BYT) | T04 bước 1; MT-01 |
| BR-A02 | Mỗi bác sĩ chuyên khoa thuộc đúng một chuyên khoa | Cấu trúc | Chuyên khoa của lịch hẹn được xác định qua bác sĩ | T04 bước 1; MT-01 |
| BR-A03 | Chỉ được xếp ca cho bác sĩ có chứng chỉ hành nghề còn hạn đến hết ngày của ca | Hành vi | Chỉ người có giấy phép còn hiệu lực mới được khám chữa bệnh (Luật 15/2023/QH15) | T04 bước 2, 5 |
| BR-A04 | Hai ca còn hiệu lực của cùng một bác sĩ không được chồng giờ | Cấu trúc | Bác sĩ không làm hai ca cùng lúc | T04 bước 2; MT-02 |
| BR-A05 | Mỗi bác sĩ có một số chứng chỉ hành nghề, không trùng với bác sĩ khác | Cấu trúc | Mỗi chứng chỉ chỉ cấp cho một người | T04 bước 1 |
| BR-A06 | Thời điểm kết thúc của ca làm việc phải sau thời điểm bắt đầu | Cấu trúc | Ca phải có độ dài hợp lệ | T04 bước 2 |
| BR-A07 | Ngày hết hạn của chứng chỉ hành nghề phải sau ngày cấp | Cấu trúc | Chứng chỉ có thời hạn, 5 năm theo Luật 15/2023/QH15 | T04 bước 1, 5 |
| BR-A08 | Không được sửa giờ hoặc hủy một ca nếu việc đó làm lịch hẹn còn hiệu lực nằm ngoài giờ làm việc của bác sĩ | Hành vi | Giữ hợp lệ các lịch hẹn đã nhận | T04 bước 4; MT-02 |

## 3. Cơ chế đảm bảo

| Mã | Cơ chế trong CSDL | Ghi chú |
|---|---|---|
| BR-A01 | Cột phân loại `loai_bac_si` NOT NULL + `CHECK (loai_bac_si IN ('DA_KHOA','CHUYEN_KHOA'))` | Chi tiết theo phương án ánh xạ ở 2.2; nếu chọn 8A (bảng riêng cho từng lớp con) thì cần thêm trigger |
| BR-A02 | FK `ma_chuyen_khoa` NOT NULL ở lớp bác sĩ chuyên khoa | |
| BR-A03 | Trigger `trg_kiem_tra_chung_chi` trên INSERT/UPDATE `CA_LAM_VIEC`: `ngay_het_han_cc` ≥ ngày của ca | |
| BR-A04 | `EXCLUDE USING gist (ma_bac_si WITH =, khoảng thời gian WITH &&)` chỉ áp dụng cho ca khác `HUY` | Cần extension `btree_gist` |
| BR-A05 | `so_chung_chi` NOT NULL + UNIQUE | |
| BR-A06 | `CHECK (thoi_gian_kt > thoi_gian_bd)` | |
| BR-A07 | `CHECK (ngay_het_han_cc > ngay_cap_cc)` | |
| BR-A08 | Trigger `trg_bao_ve_ca_lam_viec` BEFORE UPDATE trên `CA_LAM_VIEC`: không còn lịch hẹn `DA_DAT`, `DA_XAC_NHAN` của bác sĩ nằm ngoài ca sau khi sửa | Liên mảng với B |

## 4. Kiểm chứng (đầu vào T43)

Chạy trên dữ liệu giả lập, ghi rõ bản ghi tiền điều kiện và kết quả thực tế.

| Mã test | Quy tắc | Thao tác sai phải bị từ chối | Thao tác hợp lệ đi kèm |
|---|---|---|---|
| TC-03 | BR-A01 | Gán một bác sĩ vào cả hai lớp đa khoa và chuyên khoa | Tạo bác sĩ thuộc đúng một lớp |
| – | BR-A02 | Tạo bác sĩ chuyên khoa không có chuyên khoa | Tạo bác sĩ chuyên khoa với chuyên khoa tồn tại |
| – | BR-A03 | Xếp ca ngày 20/12 cho bác sĩ có chứng chỉ hết hạn 15/12 | Xếp ca trong thời hạn chứng chỉ |
| – | BR-A04 | Thêm ca 11:00–13:00 khi bác sĩ đã có ca 08:00–12:00 | Thêm ca 12:00–14:00 (nối tiếp) |
| – | BR-A05 | Thêm bác sĩ trùng số chứng chỉ | Thêm bác sĩ với số chứng chỉ mới |
| – | BR-A06 | Thêm ca 08:00–08:00 | Thêm ca 08:00–12:00 |
| – | BR-A07 | Chứng chỉ có ngày hết hạn trước ngày cấp | Ngày hết hạn sau ngày cấp |
| – | BR-A08 | Hủy ca đang có lịch hẹn `DA_XAC_NHAN` | Hủy ca không còn lịch hẹn hiệu lực |

TC-03 giữ số hiệu như báo cáo; các quy tắc còn lại đánh mã test khi gộp `tests.sql`.

## 5. Phụ thuộc mảng B, C

| Quy tắc | Dùng từ mảng A | Nội dung |
|---|---|---|
| BR-B01 | `CA_LAM_VIEC` | Lịch hẹn nằm trọn trong một ca của bác sĩ |
| BR-B02 | `BAC_SI` | Khóa bác sĩ dùng trong EXCLUDE chống trùng lịch hẹn |
| BR-B03 | `BAC_SI_CHUYEN_KHOA`, `CHUYEN_KHOA` | Chuyên khoa của lịch hẹn lấy qua bác sĩ |
| BR-B07 | `BAC_SI_DA_KHOA` | Chỉ bác sĩ đa khoa lập giấy chuyển; phụ thuộc phương án ánh xạ |
| BR-C02 | `BAC_SI` (qua lịch hẹn) | Bác sĩ kê đơn là bác sĩ của lịch hẹn |
| BR-A08 | B: `LICH_HEN` | Kiểm tra lịch hẹn còn hiệu lực khi sửa, hủy ca |

## 6. Quyết định thiết kế đã chốt

- Chỉ giữ một phân lớp: bác sĩ → {đa khoa, chuyên khoa}. Không quản lý điều dưỡng, lễ tân, nhân sự khác.
- Chứng chỉ hành nghề là thuộc tính của bác sĩ; chỉ lưu chứng chỉ hiện hành, không lưu lịch sử gia hạn.
- Mỗi bác sĩ chuyên khoa thuộc đúng một chuyên khoa; bác sĩ đa khoa không gắn chuyên khoa.
- Ca làm việc lưu dạng khoảng thời gian; ca bị hủy có trạng thái `HUY`.
- Phòng khám có một cơ sở; không lưu nơi làm việc của ca.
- Lễ tân, quản trị là người dùng hệ thống với role CSDL, không phải thực thể.

Còn mở:
- [ ] Phương án ánh xạ phân lớp bác sĩ (8A/8B/8C) – ảnh hưởng BR-A01, BR-A02, BR-B07.
- [ ] Tên khóa `ma_bac_si`, `ma_chuyen_khoa` dùng chung với ERD B, C.
