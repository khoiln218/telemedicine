# T08 – Quy tắc nghiệp vụ mảng B: Bệnh nhân & Lịch hẹn

| | |
|---|---|
| Mã việc | T08 (GĐ0, tuần 2) |
| Người viết / review | Lê Ngọc Khôi / Đặng Hữu Khoa |
| Dùng cho | Báo cáo mục 1.2.2 (gộp ở T10), ERD mảng B (T12), test 5.1 (T43) |
| Căn cứ | [T03 – khảo sát mảng B](../khao-sat/T03_KhaoSat_MangB.md), sườn báo cáo v0 |

BR-B01…B05 giữ đúng số hiệu như bản v0, vì mục 4.1.4 và 5.1 đã tham chiếu. Bảng này thay cho bảng quy tắc ở mục 5 của T03.

## Thuật ngữ dùng trong quy tắc

- **Lịch hẹn còn hiệu lực**: lịch hẹn có trạng thái khác HUY và VANG_MAT.
- **Giao nhau về thời gian**: hai khoảng [bắt đầu, kết thúc) có phần chung. Hẹn nối tiếp nhau, ví dụ 9:00–9:15 và 9:15–9:30, không bị tính là giao nhau.

## Bảng quy tắc (dán vào mục 1.2.2)

| Mã | Phát biểu quy tắc | Loại ràng buộc | Cơ chế đảm bảo |
|---|---|---|---|
| BR-B01 | Thời gian của một lịch hẹn phải nằm trọn trong một ca làm việc của bác sĩ được hẹn | Nghiệp vụ (liên bảng, mảng A) | Trigger `trg_lich_hen_hop_le` |
| BR-B02 | Hai lịch hẹn còn hiệu lực của cùng một bác sĩ không được giao nhau về thời gian | Nghiệp vụ | `EXCLUDE USING gist` (cần extension `btree_gist`) |
| BR-B03 | Lịch hẹn với bác sĩ chuyên khoa phải kèm giấy chuyển chuyên khoa còn hạn, đúng chuyên khoa, nếu bệnh nhân **chưa từng** có lịch hẹn HOAN_THANH ở chuyên khoa đó (tái khám không cần giấy) | Nghiệp vụ | Trigger `trg_lich_hen_hop_le` |
| BR-B04 | Lịch hẹn tư vấn từ xa bắt buộc có nền tảng, đường dẫn phiên và thời lượng > 0 phút | Miền giá trị | NOT NULL + CHECK |
| BR-B05 | Lịch hẹn mới luôn ở trạng thái DA_DAT. Trạng thái chỉ được chuyển: DA_DAT → DA_XAC_NHAN hoặc HUY; DA_XAC_NHAN → HOAN_THANH, HUY hoặc VANG_MAT. HOAN_THANH, HUY, VANG_MAT là trạng thái cuối | Nghiệp vụ (chuyển trạng thái) | CHECK miền giá trị + DEFAULT + trigger `trg_trang_thai_lich_hen` |
| BR-B06 | Mỗi lịch hẹn thuộc đúng một hình thức: khám trực tiếp hoặc tư vấn từ xa | Phân lớp (d, total) | Cột phân loại + CHECK; chi tiết theo phương án ánh xạ ở 2.2 |
| BR-B07 | Thời gian kết thúc của lịch hẹn phải sau thời gian bắt đầu | Miền giá trị | CHECK |
| BR-B08 | Mỗi giấy chuyển chuyên khoa chỉ được dùng cho tối đa một lịch hẹn | Bản số | UNIQUE trên cột mã giấy của lịch hẹn |
| BR-B09 | Giấy chuyển chuyên khoa chỉ do bác sĩ đa khoa lập, hiệu lực tối đa 30 ngày kể từ ngày lập | Phân lớp + miền giá trị | FK tới lớp bác sĩ đa khoa (mảng A) + CHECK |
| BR-B10 | Mỗi lịch hẹn có tối đa một hóa đơn, chỉ lập cho lịch hẹn HOAN_THANH, số tiền ≥ 0 | Bản số + nghiệp vụ | UNIQUE + CHECK + trigger |
| BR-B11 | Số điện thoại của bệnh nhân không trùng nhau | Khóa (khóa ứng viên) | UNIQUE |

## Cách kiểm chứng (đầu vào T43)

Mỗi quy tắc có ít nhất một thao tác sai phải bị CSDL từ chối:

| Mã | Thao tác thử (phải bị từ chối) |
|---|---|
| BR-B01 | INSERT lịch hẹn 18:00–18:15 khi ca của bác sĩ là 07:00–11:00 |
| BR-B02 | INSERT lịch 9:00–9:30 khi bác sĩ đã có lịch DA_XAC_NHAN 9:15–9:45. Ngược lại, nếu lịch cũ đã HUY thì INSERT phải **thành công** |
| BR-B03 | INSERT lịch với BS chuyên khoa Tim mạch cho bệnh nhân chưa từng khám Tim mạch, không kèm giấy chuyển |
| BR-B04 | INSERT tư vấn từ xa có link phiên NULL, hoặc thời lượng = 0 |
| BR-B05 | UPDATE lịch hẹn từ HOAN_THANH về DA_DAT; UPDATE từ DA_DAT thẳng sang HOAN_THANH |
| BR-B06 | Gán một lịch hẹn vào cả hai lớp trực tiếp và từ xa |
| BR-B07 | INSERT lịch hẹn có kết thúc = bắt đầu |
| BR-B08 | Dùng cùng một mã giấy chuyển cho lịch hẹn thứ hai |
| BR-B09 | INSERT giấy chuyển do bác sĩ chuyên khoa lập; hoặc giấy có ngày hết hạn = ngày lập + 45 |
| BR-B10 | INSERT hóa đơn cho lịch hẹn DA_XAC_NHAN; INSERT hóa đơn thứ hai cho cùng lịch hẹn |
| BR-B11 | INSERT bệnh nhân trùng số điện thoại |

## Liên kết mục tiêu (mục 1.1)

- MT-02 (lịch hẹn không xung đột): BR-B01, BR-B02, BR-B07
- MT-03 (khám trực tiếp và từ xa): BR-B04, BR-B06

## Phụ thuộc mảng A (nhờ Hữu Khoa xác nhận khi review)

- BR-B01 cần bảng ca làm việc có bác sĩ, ngày, giờ bắt đầu, giờ kết thúc.
- BR-B03 cần biết bác sĩ chuyên khoa thuộc chuyên khoa nào.
- BR-B09 cần tham chiếu được riêng lớp bác sĩ đa khoa. Điều này phụ thuộc phương án ánh xạ 8A/8B/8C. Nếu chọn phương án gộp một bảng (8C) thì BR-B09 chuyển sang dùng trigger.

## Đã chốt so với T03

- Giờ hẹn lưu dạng khoảng thời gian (bắt đầu, kết thúc) và dùng EXCLUDE để chống trùng. Không làm bảng khung giờ.
- Tái khám được miễn giấy chuyển. "Tái khám" nghĩa là bệnh nhân đã có lịch hẹn HOAN_THANH ở cùng chuyên khoa.
- Không có thực thể BAO_HIEM_Y_TE trong mảng B.
