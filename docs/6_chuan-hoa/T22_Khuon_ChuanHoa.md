# T22 – Khuôn phân tích phụ thuộc hàm và chuẩn hóa

| | |
|---|---|
| Mã việc | T22 (GĐ2) |
| Người làm / review | Nguyễn Đăng Khoa / Lê Ngọc Khôi |
| Mục đích | Dùng thống nhất cho T24, T25 và T27, T28 của ba mảng |

## 1. Mẫu trình bày cho mỗi quan hệ

### R(A₁, …, Aₙ)

1. **Ngữ nghĩa và ràng buộc:** mô tả một hàng biểu diễn điều gì; PK, FK, `UNIQUE`, `NOT NULL`, miền giá trị và giả định nghiệp vụ.
2. **Tập phụ thuộc hàm F:** liệt kê FD không tầm thường suy ra từ ngữ nghĩa và ràng buộc đã nêu. Tách vế phải thành từng thuộc tính khi lập phủ tối thiểu. Ghi riêng các FD có điều kiện và FD bị bác bỏ.
3. **Phủ tối thiểu:** kiểm tra vế phải đơn thuộc tính, thuộc tính thừa ở vế trái và FD dư thừa; nêu kết quả, không chỉ nêu kết luận.
4. **Khóa:** tính bao đóng của tập thuộc tính, chứng minh mọi khóa ứng viên tối thiểu; không mặc định mọi UNIQUE là khóa nếu cột cho phép NULL.
5. **Phân lớp thuộc tính:** thuộc tính khóa là thuộc tính nằm trong ít nhất một khóa ứng viên; thuộc tính không khóa là phần còn lại.
6. **Chuẩn hóa:** xét lần lượt 1NF, 2NF, 3NF, BCNF trên các FD đã xác lập. Nếu vi phạm, chỉ rõ FD gây vi phạm và đưa ra phép phân rã nếu đề yêu cầu.
7. **Bảo toàn:** kiểm tra nối không mất mát và bảo toàn FD cho phân rã; kiểm tra thiết kế cuối so với BR và ERD.

## 2. FD có điều kiện do UNIQUE và NULL

Trong PostgreSQL, `UNIQUE` mặc định cho phép nhiều hàng có `NULL`; do đó `x → các thuộc tính còn lại` chỉ đúng trên tập con hàng có `x IS NOT NULL`, không phải FD trên toàn quan hệ. Trình bày riêng là **FD có điều kiện**, không đưa vào phủ tối thiểu FD toàn cục hoặc dùng nó để loại thuộc tính khỏi khóa ứng viên toàn cục. Nếu cột `UNIQUE` đồng thời `NOT NULL`, nó là khóa ứng viên và FD toàn cục.

`UNIQUE` trên khóa ghép chỉ bảo đảm tính duy nhất của cả bộ; không suy ra FD từ từng thành phần riêng lẻ. FK tự nó không tạo FD. Một quan hệ 1:1 chỉ cho FD ngược khi phía FK được khai báo `UNIQUE NOT NULL` theo đúng bội số.

## 3. Kiểm tra nhanh

- 1NF: mỗi ô chứa một giá trị nguyên tố theo miền đã chọn; thuộc tính đa trị được tách thành quan hệ riêng.
- 2NF: quan hệ ở 1NF và không có thuộc tính không khóa phụ thuộc bộ phận vào một tập con thực sự của bất kỳ khóa ghép nào.
- 3NF: với mỗi FD không tầm thường `X → A`, `X` là siêu khóa hoặc `A` là thuộc tính khóa.
- BCNF: với mỗi FD không tầm thường `X → Y`, `X` là siêu khóa.

Không kết luận chuẩn hóa chỉ từ tên khóa chính; phải xét toàn bộ FD hợp lệ theo ngữ nghĩa/ràng buộc. Các phụ thuộc nghiệp vụ không được khai báo hoặc không được đảm bảo trong dữ liệu không được dùng để chứng minh.
