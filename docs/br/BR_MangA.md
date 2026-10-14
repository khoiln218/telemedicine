# BR-MANG-A — Quy tắc nghiệp vụ mảng A

**Mảng:** Nhân viên y tế & Lịch làm việc  
**Phụ trách:** Đặng Hữu Khoa  
**Phạm vi:** Nhân viên y tế, phân lớp bác sĩ, chuyên khoa, chứng chỉ hành nghề, cơ sở khám chữa bệnh và ca làm việc.

## 1. Mục tiêu và phạm vi

Mảng A quản lý thông tin nhân viên y tế, phân loại chức danh, chuyên khoa, chứng chỉ hành nghề và lịch làm việc tại các cơ sở khám chữa bệnh.

Các quy tắc nghiệp vụ được sử dụng làm căn cứ để:

- Thiết kế mô hình EER và ERD mảng A.
- Xác định các ràng buộc dữ liệu và cơ chế kiểm soát tại PostgreSQL.
- Xây dựng trigger, view và truy vấn nghiệp vụ.
- Thiết kế test case để kiểm chứng tính đúng đắn của dữ liệu.
- Xác định hợp đồng dữ liệu với mảng B — Bệnh nhân & Lịch hẹn.

### 1.1. Các thực thể chính

- `NHAN_VIEN_Y_TE`: lớp cha nhân viên y tế.
- `BAC_SI`, `DIEU_DUONG`, `LE_TAN`: các lớp chức danh.
- `BAC_SI_DA_KHOA`, `BAC_SI_CHUYEN_KHOA`: các lớp con của `BAC_SI`.
- `CHUYEN_KHOA`: danh mục chuyên khoa.
- `CHUNG_CHI_HANH_NGHE`: thông tin chứng chỉ hành nghề.
- `CO_SO_KHAM`: cơ sở khám chữa bệnh.
- `CA_LAM_VIEC`: lịch làm việc của nhân viên y tế.

### 1.2. Quy ước thuật ngữ

- **Ca còn hiệu lực:** ca làm việc thuộc trạng thái được hệ thống tính là có hiệu lực.
- **Ca giao nhau:** hai khoảng thời gian có phần giao nhau. Ví dụ, ca 08:00–12:00 và 11:00–13:00 bị giao nhau; ca 08:00–12:00 và 12:00–14:00 không giao nhau.
- **Chứng chỉ hợp lệ:** chứng chỉ đáp ứng điều kiện về người sở hữu, thời hạn, phạm vi và trạng thái xác minh theo chính sách nghiệp vụ đã được phê duyệt.
- **Phân lớp disjoint:** một thực thể không được đồng thời thuộc hai lớp con loại trừ nhau.
- **Phân lớp total:** mọi thực thể thuộc lớp cha đều phải thuộc ít nhất một lớp con trong tập phân lớp được xét.

## 2. Danh mục quy tắc nghiệp vụ

| Mã | Nhóm | Phát biểu quy tắc | Loại ràng buộc | Cơ chế đảm bảo đề xuất |
|---|---|---|---|---|
| BR-A01 | Nhân sự | Mỗi nhân viên y tế phải có mã định danh duy nhất và không được để trống. | Khóa | `PRIMARY KEY` |
| BR-A02 | Phân lớp | Mỗi nhân viên y tế thuộc đúng một chức danh trong các loại bác sĩ, điều dưỡng hoặc lễ tân. | Phân lớp disjoint + total | EER và cơ chế ràng buộc theo phương án ánh xạ |
| BR-A03 | Phân lớp | Mỗi bác sĩ thuộc đúng một loại: bác sĩ đa khoa hoặc bác sĩ chuyên khoa. | Phân lớp disjoint + total | EER và cơ chế ràng buộc theo phương án ánh xạ |
| BR-A04 | Chuyên khoa | Mỗi bác sĩ chuyên khoa phải được liên kết với ít nhất một chuyên khoa hợp lệ. | Nghiệp vụ liên bảng | Trigger hoặc transaction kiểm tra |
| BR-A05 | Chuyên khoa | Mỗi chuyên khoa có mã định danh duy nhất và tên chuyên khoa hợp lệ. | Khóa + miền giá trị | `PRIMARY KEY`, `NOT NULL`, `UNIQUE` |
| BR-A06 | Chứng chỉ | Mỗi chứng chỉ hành nghề phải thuộc về một bác sĩ xác định, có số chứng chỉ và thông tin hiệu lực hợp lệ. | Khóa ngoại + miền giá trị | `FOREIGN KEY`, `NOT NULL`, `CHECK` |
| BR-A07 | Chứng chỉ | Bác sĩ chỉ được xếp ca khi chứng chỉ hành nghề đáp ứng điều kiện hiệu lực theo chính sách đã thống nhất. | Nghiệp vụ liên bảng | `trg_kiem_tra_chung_chi` |
| BR-A08 | Lịch làm việc | Thời điểm kết thúc ca làm việc phải sau thời điểm bắt đầu ca. | Miền giá trị | `CHECK` |
| BR-A09 | Lịch làm việc | Các ca làm việc còn hiệu lực của cùng một nhân viên không được giao nhau về thời gian. | Nghiệp vụ | `trg_ca_lam_viec_khong_trung` hoặc `EXCLUDE USING gist` |
| BR-A10 | Lịch làm việc | Mỗi ca làm việc phải được liên kết với một nhân viên y tế và một cơ sở khám chữa bệnh hợp lệ. | Khóa ngoại | `FOREIGN KEY` |
| BR-A11 | Cơ sở khám | Mỗi cơ sở khám chữa bệnh phải có mã định danh duy nhất và thông tin nhận diện bắt buộc. | Khóa + miền giá trị | `PRIMARY KEY`, `NOT NULL` |
| BR-A12 | Tích hợp A–B | Bác sĩ được phân công khám theo chuyên khoa phải có quan hệ chuyên khoa phù hợp với chuyên khoa của lịch hẹn. | Nghiệp vụ liên mảng | Kiểm tra liên bảng tại mảng B |
| BR-A13 | Lịch làm việc | Khi thay đổi thời gian hoặc trạng thái ca làm việc, hệ thống phải kiểm tra các ràng buộc liên quan để tránh tạo ca không hợp lệ. | Nghiệp vụ | Trigger hoặc transaction kiểm tra |

> **Lưu ý:** Cơ chế đảm bảo trong bảng là phương án thiết kế đề xuất. Cần xác nhận lại theo mô hình EER, cấu trúc bảng và chính sách nghiệp vụ thực tế trước khi triển khai.

## 3. Chi tiết quy tắc và cách kiểm chứng

### BR-A01 — Mã định danh nhân viên y tế

**Quy tắc:** Mỗi nhân viên y tế phải có mã định danh duy nhất và không được để trống.

**Cơ chế:** `PRIMARY KEY`.

**Test case:**

| Mã test | Thao tác | Kết quả mong đợi |
|---|---|---|
| TC-A01-01 | Thêm nhân viên với mã mới hợp lệ. | Thành công. |
| TC-A01-02 | Thêm nhân viên trùng mã đã tồn tại. | Bị từ chối. |
| TC-A01-03 | Thêm nhân viên không có mã định danh. | Bị từ chối. |

### BR-A02 — Phân lớp chức danh nhân viên

**Quy tắc:** Mỗi nhân viên y tế thuộc đúng một lớp chức danh trong tập `BAC_SI`, `DIEU_DUONG`, `LE_TAN`.

**Cơ chế:** Mô hình EER với phân lớp disjoint và total; cơ chế triển khai phụ thuộc phương án ánh xạ.

**Test case:**

| Mã test | Thao tác | Kết quả mong đợi |
|---|---|---|
| TC-A02-01 | Tạo nhân viên thuộc một lớp chức danh hợp lệ. | Thành công. |
| TC-A02-02 | Tạo nhân viên không thuộc lớp chức danh nào. | Bị từ chối. |
| TC-A02-03 | Gán cùng nhân viên vào hai lớp chức danh loại trừ nhau. | Bị từ chối. |

### BR-A03 — Phân loại bác sĩ

**Quy tắc:** Mỗi bác sĩ phải thuộc đúng một trong hai lớp `BAC_SI_DA_KHOA` hoặc `BAC_SI_CHUYEN_KHOA`.

**Cơ chế:** Phân lớp disjoint và total.

**Test case:**

| Mã test | Thao tác | Kết quả mong đợi |
|---|---|---|
| TC-A03-01 | Tạo bác sĩ đa khoa hợp lệ. | Thành công. |
| TC-A03-02 | Tạo bác sĩ chuyên khoa hợp lệ. | Thành công. |
| TC-A03-03 | Tạo bác sĩ đồng thời thuộc hai lớp con. | Bị từ chối. |
| TC-A03-04 | Tạo bác sĩ không thuộc lớp con nào. | Bị từ chối. |

### BR-A04 — Chuyên khoa của bác sĩ chuyên khoa

**Quy tắc:** Mỗi bác sĩ chuyên khoa phải được liên kết với ít nhất một chuyên khoa hợp lệ.

**Cơ chế:** Kiểm tra quan hệ liên bảng bằng trigger hoặc transaction phù hợp.

**Test case:**

| Mã test | Thao tác | Kết quả mong đợi |
|---|---|---|
| TC-A04-01 | Liên kết bác sĩ chuyên khoa với chuyên khoa đang hoạt động. | Thành công. |
| TC-A04-02 | Hoàn tất tạo bác sĩ chuyên khoa nhưng không có chuyên khoa liên kết. | Không được xác nhận là hợp lệ. |
| TC-A04-03 | Liên kết với chuyên khoa không tồn tại. | Bị từ chối. |

### BR-A05 — Danh mục chuyên khoa

**Quy tắc:** Mỗi chuyên khoa phải có mã định danh duy nhất và tên chuyên khoa hợp lệ.

**Cơ chế:** `PRIMARY KEY`, `NOT NULL`, `UNIQUE` nếu yêu cầu tên không được trùng.

**Test case:**

| Mã test | Thao tác | Kết quả mong đợi |
|---|---|---|
| TC-A05-01 | Thêm chuyên khoa với mã và tên hợp lệ. | Thành công. |
| TC-A05-02 | Thêm chuyên khoa trùng mã. | Bị từ chối. |
| TC-A05-03 | Thêm chuyên khoa thiếu tên. | Bị từ chối. |

### BR-A06 — Thông tin chứng chỉ hành nghề

**Quy tắc:** Mỗi chứng chỉ hành nghề phải thuộc về một bác sĩ xác định, có số chứng chỉ và thông tin hiệu lực hợp lệ.

**Cơ chế:** `FOREIGN KEY`, `NOT NULL`, `CHECK`.

**Test case:**

| Mã test | Thao tác | Kết quả mong đợi |
|---|---|---|
| TC-A06-01 | Tạo chứng chỉ với dữ liệu hợp lệ. | Thành công. |
| TC-A06-02 | Tạo chứng chỉ không tham chiếu được bác sĩ. | Bị từ chối. |
| TC-A06-03 | Tạo chứng chỉ thiếu số chứng chỉ. | Bị từ chối. |
| TC-A06-04 | Tạo chứng chỉ có ngày hết hạn trước ngày cấp. | Bị từ chối. |

### BR-A07 — Kiểm tra hiệu lực chứng chỉ khi xếp ca

**Quy tắc:** Bác sĩ chỉ được xếp ca khi chứng chỉ đáp ứng điều kiện hiệu lực theo chính sách nghiệp vụ đã thống nhất.

**Cơ chế:** Trigger `trg_kiem_tra_chung_chi`.

**Test case:**

| Mã test | Thao tác | Kết quả mong đợi |
|---|---|---|
| TC-A07-01 | Xếp ca cho bác sĩ có chứng chỉ đáp ứng điều kiện. | Thành công. |
| TC-A07-02 | Xếp ca cho bác sĩ có chứng chỉ hết hạn. | Bị từ chối. |
| TC-A07-03 | Xếp ca cho bác sĩ không có chứng chỉ đáp ứng yêu cầu. | Bị từ chối. |

**Điểm cần xác nhận:** Chứng chỉ phải còn hiệu lực tại thời điểm xếp ca hay trong toàn bộ thời gian thực hiện ca. Nếu một bác sĩ có nhiều chứng chỉ, cần xác định chứng chỉ nào phù hợp với phạm vi hoạt động tương ứng.

### BR-A08 — Thời gian ca làm việc

**Quy tắc:** Thời điểm kết thúc ca phải sau thời điểm bắt đầu ca.

**Cơ chế:** `CHECK (end_datetime > start_datetime)` hoặc biểu thức tương đương với cấu trúc ngày và giờ được chọn.

**Test case:**

| Mã test | Thời gian ca | Kết quả mong đợi |
|---|---|---|
| TC-A08-01 | 08:00–12:00 | Thành công. |
| TC-A08-02 | 08:00–08:00 | Bị từ chối. |
| TC-A08-03 | 12:00–08:00 trong cùng ngày | Bị từ chối. |

Nếu hệ thống hỗ trợ ca qua đêm, cần biểu diễn ngày giờ đầy đủ thay vì chỉ so sánh giờ trong ngày.

### BR-A09 — Ngăn ca làm việc giao nhau

**Quy tắc:** Các ca làm việc còn hiệu lực của cùng một nhân viên không được giao nhau về thời gian.

**Cơ chế:** Trigger `trg_ca_lam_viec_khong_trung` hoặc `EXCLUDE USING gist` nếu phù hợp với thiết kế dữ liệu.

**Test case:**

| Mã test | Ca hiện có | Ca mới | Kết quả mong đợi |
|---|---|---|---|
| TC-A09-01 | 08:00–12:00 | 11:00–13:00 | Bị từ chối. |
| TC-A09-02 | 08:00–12:00 | 12:00–14:00 | Thành công. |
| TC-A09-03 | 08:00–12:00 | 13:00–15:00 | Thành công. |
| TC-A09-04 | 08:00–12:00 | Cập nhật ca mới thành 10:00–13:00 | Bị từ chối. |

**Lưu ý:** Phải kiểm tra cả `INSERT` và `UPDATE`, chỉ xét các ca thuộc trạng thái được kiểm soát và xử lý tình huống nhiều transaction đồng thời.

### BR-A10 — Liên kết ca với nhân viên và cơ sở

**Quy tắc:** Mỗi ca làm việc phải tham chiếu một nhân viên y tế và một cơ sở khám chữa bệnh hợp lệ.

**Cơ chế:** `FOREIGN KEY`.

**Test case:**

| Mã test | Thao tác | Kết quả mong đợi |
|---|---|---|
| TC-A10-01 | Tạo ca với nhân viên và cơ sở tồn tại. | Thành công. |
| TC-A10-02 | Tạo ca tham chiếu nhân viên không tồn tại. | Bị từ chối. |
| TC-A10-03 | Tạo ca tham chiếu cơ sở không tồn tại. | Bị từ chối. |

Nếu cơ sở có trạng thái hoạt động, việc ngăn xếp ca tại cơ sở đã ngừng hoạt động cần được xác định thành quy tắc bổ sung hoặc điều kiện cụ thể của BR-A10.

### BR-A11 — Thông tin cơ sở khám chữa bệnh

**Quy tắc:** Mỗi cơ sở khám chữa bệnh phải có mã định danh duy nhất và các thông tin nhận diện bắt buộc.

**Cơ chế:** `PRIMARY KEY`, `NOT NULL`; bổ sung `UNIQUE` cho các trường cần duy nhất theo nghiệp vụ.

**Test case:**

| Mã test | Thao tác | Kết quả mong đợi |
|---|---|---|
| TC-A11-01 | Tạo cơ sở với thông tin hợp lệ. | Thành công. |
| TC-A11-02 | Tạo cơ sở trùng mã. | Bị từ chối. |
| TC-A11-03 | Tạo cơ sở thiếu tên. | Bị từ chối. |

### BR-A12 — Tương thích chuyên khoa giữa mảng A và B

**Quy tắc:** Bác sĩ được phân công khám theo chuyên khoa phải có quan hệ chuyên khoa phù hợp với chuyên khoa của lịch hẹn.

**Cơ chế:** Kiểm tra liên bảng tại mảng B, sử dụng khóa định danh bác sĩ và chuyên khoa từ mảng A.

**Test case:**

| Mã test | Thao tác | Kết quả mong đợi |
|---|---|---|
| TC-A12-01 | Đặt lịch chuyên khoa với bác sĩ có chuyên khoa phù hợp. | Thành công nếu các quy tắc khác cũng hợp lệ. |
| TC-A12-02 | Đặt lịch chuyên khoa với bác sĩ không có quan hệ chuyên khoa tương ứng. | Bị từ chối. |

### BR-A13 — Kiểm tra ràng buộc khi cập nhật ca

**Quy tắc:** Khi thay đổi thời gian hoặc trạng thái ca làm việc, hệ thống phải kiểm tra các ràng buộc liên quan để tránh tạo ca không hợp lệ.

**Cơ chế:** Trigger hoặc transaction kiểm tra cập nhật.

**Test case:**

| Mã test | Thao tác | Kết quả mong đợi |
|---|---|---|
| TC-A13-01 | Cập nhật ca nhưng vẫn đáp ứng tất cả ràng buộc. | Thành công. |
| TC-A13-02 | Cập nhật ca làm phát sinh giao nhau với ca khác. | Bị từ chối. |
| TC-A13-03 | Hủy ca đã có lịch hẹn liên quan. | Xử lý theo chính sách hủy, đổi ca hoặc thông báo đã thống nhất. |

## 4. Phụ thuộc giữa mảng A và mảng B

| Quy tắc mảng B | Phụ thuộc từ mảng A | Nội dung cần thống nhất |
|---|---|---|
| BR-B01 | `BAC_SI`, `CA_LAM_VIEC` | Khóa bác sĩ, thời gian và trạng thái ca. |
| BR-B02 | `BAC_SI` | Khóa định danh bác sĩ được hẹn. |
| BR-B03 | `BAC_SI_CHUYEN_KHOA`, `CHUYEN_KHOA` | Quan hệ bác sĩ – chuyên khoa và mã chuyên khoa dùng chung. |
| BR-B09 | `BAC_SI_DA_KHOA` | Phương án ánh xạ EER và cơ chế xác minh người lập giấy chuyển. |

Các quy tắc kiểm soát lịch hẹn, bệnh nhân, hóa đơn và thông tin tư vấn từ xa thuộc phạm vi chính của mảng B.

## 5. Cơ chế kỹ thuật cần triển khai

| Thành phần | Tên đề xuất | Mục đích |
|---|---|---|
| Trigger | `trg_ca_lam_viec_khong_trung` | Chặn ca làm việc giao nhau của cùng nhân viên. |
| Trigger | `trg_kiem_tra_chung_chi` | Kiểm tra điều kiện chứng chỉ khi xếp ca. |
| View | `v_lich_truc_bac_si` | Tổng hợp lịch làm việc của bác sĩ. |
| Truy vấn 1 | Bác sĩ chuyên khoa còn ca trống tuần tới | Lọc theo chuyên khoa và lịch làm việc. |
| Truy vấn 2 | Tổng giờ làm việc mỗi bác sĩ theo tháng | Sử dụng `GROUP BY`, `HAVING`. |
| Truy vấn 3 | Bác sĩ chưa được xếp ca | Sử dụng `NOT EXISTS`. |
| Truy vấn 4 | Chứng chỉ hết hạn trong 30 ngày tới | Lọc theo ngày hết hạn và trạng thái chứng chỉ. |

## 6. Những nội dung cần chốt trước khi triển khai

- [ ] Chọn phương án ánh xạ EER 8A/8B/8C.
- [ ] Chốt khóa chính và khóa ngoại giữa các thực thể.
- [ ] Xác định trạng thái nào của ca được xem là còn hiệu lực.
- [ ] Xác định chính sách kiểm tra hiệu lực chứng chỉ.
- [ ] Xác định quan hệ nhiều-nhiều giữa bác sĩ và chuyên khoa.
- [ ] Kiểm tra xung đột ca khi `INSERT`, `UPDATE` và khi nhiều transaction đồng thời.
- [ ] Kiểm thử các phụ thuộc A–B theo BR-B01, BR-B03 và BR-B09.

## 7. Tiêu chí hoàn thành

Mảng A được xem là hoàn thành phần quy tắc nghiệp vụ khi:

1. Mỗi quy tắc có mã định danh ổn định và phát biểu rõ ràng.
2. Mỗi quy tắc có cơ chế đảm bảo phù hợp với mô hình dữ liệu.
3. Mỗi quy tắc có ít nhất một test case với kết quả mong đợi.
4. Các ràng buộc phân lớp và liên bảng được kiểm tra bằng cơ chế phù hợp.
5. Các phụ thuộc với mảng B được thống nhất trước khi tích hợp.
6. Các test case được chạy trên PostgreSQL và ghi nhận kết quả thực tế.

**Trạng thái tài liệu:** Bản dự thảo phục vụ review nghiệp vụ và thiết kế cơ sở dữ liệu. Các cơ chế kỹ thuật và chính sách chưa được xác nhận cần được chốt trước khi triển khai chính thức.