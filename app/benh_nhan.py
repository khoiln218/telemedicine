from datetime import date, timedelta

import psycopg
from flask import Blueprint, abort, flash, redirect, render_template, request, session, url_for

import auth
import db

bp = Blueprint("benh_nhan", __name__, url_prefix="/benh-nhan")

COT = ("ho_ten", "ngay_sinh", "gioi_tinh", "sdt", "email")


def _gia_tri(f):
    return [f[c].strip() or None for c in COT]


@bp.route("/")
@auth.can_vai_tro("LE_TAN", "BAC_SI")
def danh_sach():
    q = request.args.get("q", "").strip()
    with db.phien_lam_viec(session["user"]) as conn:
        rows = conn.execute(
            "SELECT * FROM benh_nhan WHERE %(q)s = '' OR ho_ten ILIKE '%%' || %(q)s || '%%' OR sdt LIKE %(q)s || '%%'"
            " ORDER BY ma_bn DESC LIMIT 100", {"q": q}).fetchall()
    return render_template("benh_nhan_ds.html", rows=rows, q=q)


@bp.route("/them", methods=["GET", "POST"])
@auth.can_vai_tro("LE_TAN")
def them():
    f = request.form
    if request.method == "POST":
        try:
            with db.phien_lam_viec(session["user"]) as conn:
                ma_bn = conn.execute(
                    "INSERT INTO benh_nhan (ho_ten, ngay_sinh, gioi_tinh, sdt, email) VALUES (%s, %s, %s, %s, %s)"
                    " RETURNING ma_bn", _gia_tri(f)).fetchone()["ma_bn"]
            flash(f"Đã thêm bệnh nhân {f['ho_ten']}.")
            return redirect(url_for("benh_nhan.chi_tiet", ma_bn=ma_bn))
        except psycopg.Error as e:
            flash("Không thêm được bệnh nhân: " + db.loi_csdl(e))
    return render_template("benh_nhan_form.html", f=f, bn=None)


@bp.route("/<int:ma_bn>/sua", methods=["GET", "POST"])
@auth.can_vai_tro("LE_TAN")
def sua(ma_bn):
    with db.phien_lam_viec(session["user"]) as conn:
        bn = conn.execute("SELECT * FROM benh_nhan WHERE ma_bn = %s", (ma_bn,)).fetchone()
    if bn is None:
        abort(404)
    f = request.form
    if request.method == "POST":
        try:
            with db.phien_lam_viec(session["user"]) as conn:
                conn.execute("UPDATE benh_nhan SET ho_ten = %s, ngay_sinh = %s, gioi_tinh = %s, sdt = %s, email = %s"
                             " WHERE ma_bn = %s", [*_gia_tri(f), ma_bn])
            flash("Đã cập nhật thông tin bệnh nhân.")
            return redirect(url_for("benh_nhan.chi_tiet", ma_bn=ma_bn))
        except psycopg.Error as e:
            flash("Không cập nhật được: " + db.loi_csdl(e))
    else:
        f = {c: "" if bn[c] is None else str(bn[c]) for c in COT}
    return render_template("benh_nhan_form.html", f=f, bn=bn)


@bp.route("/<int:ma_bn>")
@auth.can_vai_tro("LE_TAN", "BAC_SI")
def chi_tiet(ma_bn):
    user = session["user"]
    with db.phien_lam_viec(user) as conn:
        bn = conn.execute("SELECT * FROM benh_nhan WHERE ma_bn = %s", (ma_bn,)).fetchone()
        if bn is None:
            abort(404)
        giay = conn.execute(
            "SELECT g.*, ck.ten_chuyen_khoa, nv.ho_ten AS bac_si_lap, l.ma_lh AS da_dung"
            " FROM giay_chuyen_khoa g JOIN chuyen_khoa ck USING (ma_chuyen_khoa)"
            " JOIN nhan_vien nv ON nv.ma_nv = g.ma_bac_si_lap LEFT JOIN lich_hen l ON l.ma_giay = g.ma_giay"
            " WHERE g.ma_bn = %s ORDER BY g.ngay_lap DESC", (ma_bn,)).fetchall()
        lich = conn.execute(
            "SELECT l.ma_lh, l.thoi_gian_bd, l.thoi_gian_kt, l.trang_thai, l.hinh_thuc, nv.ho_ten AS ten_bac_si"
            " FROM lich_hen l JOIN nhan_vien nv ON nv.ma_nv = l.ma_bac_si"
            " WHERE l.ma_bn = %s ORDER BY l.thoi_gian_bd DESC LIMIT 20", (ma_bn,)).fetchall()
        # Chỉ bác sĩ đa khoa thấy form lập giấy chuyển (BR-B07)
        da_khoa = user["vai_tro"] == "BAC_SI" and conn.execute(
            "SELECT 1 FROM bac_si_da_khoa WHERE ma_bac_si = %s", (user["ma_nv"],)).fetchone() is not None
        chuyen_khoa = conn.execute("SELECT * FROM chuyen_khoa ORDER BY ten_chuyen_khoa").fetchall() if da_khoa else []
    return render_template("benh_nhan_ct.html", bn=bn, giay=giay, lich=lich, da_khoa=da_khoa,
                           chuyen_khoa=chuyen_khoa, hom_nay=date.today())


@bp.post("/<int:ma_bn>/giay-chuyen")
@auth.can_vai_tro("BAC_SI")
def lap_giay(ma_bn):
    f = request.form
    try:
        with db.phien_lam_viec(session["user"]) as conn:
            ma = conn.execute(
                "INSERT INTO giay_chuyen_khoa (ly_do, ngay_het_han, ma_bn, ma_bac_si_lap, ma_chuyen_khoa)"
                " VALUES (%s, %s, %s, %s, %s) RETURNING ma_giay",
                (f["ly_do"].strip(), date.today() + timedelta(days=int(f["so_ngay"])), ma_bn,
                 session["user"]["ma_nv"], f["ma_chuyen_khoa"])).fetchone()["ma_giay"]
        flash(f"Đã lập giấy chuyển khoa mã {ma}.")
    except psycopg.Error as e:
        flash("Không lập được giấy chuyển: " + db.loi_csdl(e))
    return redirect(url_for("benh_nhan.chi_tiet", ma_bn=ma_bn))


@bp.post("/<int:ma_bn>/tai-khoan")
@auth.can_vai_tro("LE_TAN")
def tao_tai_khoan(ma_bn):
    ten, mk = request.form["ten_dang_nhap"].strip(), auth.mat_khau_tam()
    try:
        with db.phien_lam_viec(session["user"]) as conn:   # lễ tân chỉ gọi hàm, không ghi thẳng tai_khoan (BR-B10)
            conn.execute("SELECT tao_tai_khoan_benh_nhan(%s, %s, %s)", (ten, auth.bam_mat_khau(mk), ma_bn))
        flash(f"Đã tạo tài khoản {ten}, mật khẩu tạm: {mk} (chỉ hiện một lần, đưa cho bệnh nhân).")
    except psycopg.Error as e:
        flash("Không tạo được tài khoản: " + db.loi_csdl(e))
    return redirect(url_for("benh_nhan.chi_tiet", ma_bn=ma_bn))


@bp.post("/<int:ma_bn>/dat-lai-mat-khau")
@auth.can_vai_tro("LE_TAN")
def dat_lai_mat_khau(ma_bn):
    ten, mk = request.form["ten_dang_nhap"].strip(), auth.mat_khau_tam()
    try:
        with db.phien_lam_viec(session["user"]) as conn:
            conn.execute("SELECT dat_lai_mat_khau_benh_nhan(%s, %s)", (ten, auth.bam_mat_khau(mk)))
        flash(f"Đã đặt lại mật khẩu {ten}, mật khẩu tạm: {mk} (chỉ hiện một lần).")
    except psycopg.Error as e:
        flash("Không đặt lại được mật khẩu: " + db.loi_csdl(e))
    return redirect(url_for("benh_nhan.chi_tiet", ma_bn=ma_bn))
