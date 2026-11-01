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
