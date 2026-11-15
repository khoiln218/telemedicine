from contextlib import contextmanager

import psycopg
from psycopg.rows import dict_row

import config


@contextmanager
def ket_noi():
    """Kết nối bằng chủ sở hữu CSDL, chỉ dùng khi xác thực."""
    with psycopg.connect(config.DATABASE_URL, row_factory=dict_row) as conn:
        yield conn


@contextmanager
def phien_lam_viec(user):
    """Giao dịch chạy dưới role của người dùng đã đăng nhập.

    SET LOCAL ROLE để PostgreSQL áp quyền ở rbac.sql; app.ma_bn / app.ma_nv cho các view
    và hàm theo người dùng (v_lich_hen_cua_toi, doi_mat_khau). Hết giao dịch thì role tự trả về.
    """
    role = config.VAI_TRO[user["vai_tro"]][0]
    with psycopg.connect(config.DATABASE_URL, row_factory=dict_row) as conn:
        with conn.cursor() as cur:
            cur.execute(f"SET LOCAL ROLE {role}")  # role lấy từ bảng cố định, không từ người dùng
            cur.execute("SELECT set_config('app.ma_bn', %s, true), set_config('app.ma_nv', %s, true)",
                        (str(user["ma_bn"] or ""), str(user["ma_nv"] or "")))
        yield conn


# Lỗi ràng buộc -> thông điệp cho người dùng; trigger đã có thông điệp BR-xxx riêng
LOI_RANG_BUOC = {
    "ex_lich_hen_bac_si": "BR-B02: bác sĩ đã có lịch hẹn khác trùng giờ này.",
    "ex_lich_hen_benh_nhan": "BR-B02: bệnh nhân đã có lịch hẹn khác trùng giờ này.",
    "benh_nhan_sdt_key": "Số điện thoại đã thuộc về bệnh nhân khác.",
    "benh_nhan_sdt_check": "Số điện thoại phải gồm 10 chữ số, bắt đầu bằng 0.",
    "benh_nhan_email_check": "Email không hợp lệ.",
    "benh_nhan_ngay_sinh_check": "Ngày sinh không được sau hôm nay.",
    "ck_giay_han": "BR-B07: giấy chuyển có hiệu lực tối đa 30 ngày kể từ ngày lập.",
    "giay_chuyen_khoa_ma_bac_si_lap_fkey": "BR-B07: chỉ bác sĩ đa khoa được lập giấy chuyển.",
    "tai_khoan_pkey": "Tên đăng nhập đã tồn tại.",
    "tai_khoan_ma_bn_key": "BR-B09: bệnh nhân này đã có tài khoản.",
    "tai_khoan_ma_nv_key": "BR-B09: nhân viên này đã có tài khoản.",
}


def loi_csdl(e):
    if isinstance(e, psycopg.errors.InsufficientPrivilege):
        return "Vai trò của bạn không có quyền thực hiện thao tác này."
    return LOI_RANG_BUOC.get(e.diag.constraint_name) or e.diag.message_primary or str(e)
