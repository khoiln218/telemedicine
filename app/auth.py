import hashlib
import hmac
import secrets
from functools import wraps

from flask import abort, flash, redirect, session, url_for

import db


def bam_mat_khau(mat_khau):
    """Cùng định dạng với seed: sha256$<hex>."""
    return "sha256$" + hashlib.sha256(mat_khau.encode("utf-8")).hexdigest()


def mat_khau_tam():
    """Mật khẩu tạm khi cấp hoặc đặt lại tài khoản; chỉ hiện một lần cho người cấp."""
    return secrets.token_urlsafe(6)


def xac_thuc(ten_dang_nhap, mat_khau):
    """Trả về dict người dùng, hoặc chuỗi lý do thất bại."""
    with db.ket_noi() as conn:
        tk = conn.execute(
            "SELECT ten_dang_nhap, mat_khau_hash, vai_tro, trang_thai, ma_bn, ma_nv"
            " FROM tai_khoan WHERE ten_dang_nhap = %s", (ten_dang_nhap,)).fetchone()
    if tk is None or not hmac.compare_digest(tk["mat_khau_hash"], bam_mat_khau(mat_khau)):
        return "Sai tên đăng nhập hoặc mật khẩu."
    if tk["trang_thai"] != "HOAT_DONG":
        return "Tài khoản đã bị khóa."
    return {k: tk[k] for k in ("ten_dang_nhap", "vai_tro", "ma_bn", "ma_nv")}


def dang_nhap_bat_buoc(f):
    @wraps(f)
    def wrapper(*a, **kw):
        if "user" not in session:
            return redirect(url_for("login"))
        with db.ket_noi() as conn:   # tài khoản bị khóa khi đang đăng nhập thì đăng xuất ngay (BR-B10)
            tt = conn.execute("SELECT trang_thai FROM tai_khoan WHERE ten_dang_nhap = %s",
                              (session["user"]["ten_dang_nhap"],)).fetchone()
        if tt is None or tt["trang_thai"] != "HOAT_DONG":
            session.clear()
            flash("Tài khoản đã bị khóa.")
            return redirect(url_for("login"))
        return f(*a, **kw)
    return wrapper


def can_vai_tro(*vai_tro):
    def deco(f):
        @wraps(f)
        @dang_nhap_bat_buoc
        def wrapper(*a, **kw):
            if session["user"]["vai_tro"] not in vai_tro:
                abort(403)
            return f(*a, **kw)
        return wrapper
    return deco
