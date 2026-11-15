import psycopg
from flask import Blueprint, flash, redirect, render_template, request, session, url_for

import auth
import config
import db

bp = Blueprint("tai_khoan", __name__, url_prefix="/tai-khoan")


@bp.route("/doi-mat-khau", methods=["GET", "POST"])
@auth.dang_nhap_bat_buoc
def doi_mat_khau():
    user = session["user"]
    f = request.form
    if request.method == "POST":
        if not isinstance(auth.xac_thuc(user["ten_dang_nhap"], f["cu"]), dict):
            flash("Mật khẩu hiện tại không đúng.")
        elif len(f["moi"]) < 8 or f["moi"] != f["nhap_lai"]:
            flash("Mật khẩu mới phải từ 8 ký tự và nhập lại trùng khớp.")
        else:
            try:
                with db.phien_lam_viec(user) as conn:   # hàm chỉ đổi tài khoản theo app.ma_bn / app.ma_nv
                    conn.execute("SELECT doi_mat_khau(%s)", (auth.bam_mat_khau(f["moi"]),))
                flash("Đã đổi mật khẩu.", "ok")
                return redirect(url_for("home"))
            except psycopg.Error as e:
                flash("Không đổi được mật khẩu: " + db.loi_csdl(e))
    return render_template("doi_mat_khau.html")


@bp.route("/")
@auth.can_vai_tro("QUAN_TRI_TAI_KHOAN")
def danh_sach():
    vai_tro = request.args.get("vai_tro", "")
    q = request.args.get("q", "").strip()
    with db.phien_lam_viec(session["user"]) as conn:
        # Không chọn mat_khau_hash: quản trị tài khoản không có quyền đọc cột này
        rows = conn.execute(
            "SELECT t.ten_dang_nhap, t.vai_tro, t.trang_thai, t.ma_bn, t.ma_nv, nv.ho_ten"
            " FROM tai_khoan t LEFT JOIN nhan_vien nv ON nv.ma_nv = t.ma_nv"
            " WHERE (%(vt)s = '' AND t.vai_tro <> 'BENH_NHAN' OR t.vai_tro = %(vt)s)"
            "   AND t.ten_dang_nhap LIKE %(q)s || '%%'"
            " ORDER BY t.vai_tro, t.ten_dang_nhap LIMIT 200", {"vt": vai_tro, "q": q}).fetchall()
        chua_co = conn.execute(
            "SELECT nv.ma_nv, nv.ho_ten, nv.loai_nv FROM nhan_vien nv"
            " WHERE NOT EXISTS (SELECT 1 FROM tai_khoan t WHERE t.ma_nv = nv.ma_nv) ORDER BY nv.ho_ten").fetchall()
    return render_template("tai_khoan_ds.html", rows=rows, chua_co=chua_co, vai_tro=vai_tro, q=q,
                           VAI_TRO=config.VAI_TRO)


@bp.post("/them")
@auth.can_vai_tro("QUAN_TRI_TAI_KHOAN")
def them():
    ten, mk = request.form["ten_dang_nhap"].strip(), auth.mat_khau_tam()
    try:
        with db.phien_lam_viec(session["user"]) as conn:   # vai trò lấy theo loại nhân viên (BR-B09)
            conn.execute(
                "INSERT INTO tai_khoan (ten_dang_nhap, mat_khau_hash, vai_tro, ma_nv)"
                " SELECT %s, %s, loai_nv, ma_nv FROM nhan_vien WHERE ma_nv = %s",
                (ten, auth.bam_mat_khau(mk), request.form["ma_nv"]))
        flash(f"Đã tạo tài khoản {ten}, mật khẩu tạm: {mk} (chỉ hiện một lần).", "ok")
    except psycopg.Error as e:
        flash("Không tạo được tài khoản: " + db.loi_csdl(e))
    return redirect(url_for("tai_khoan.danh_sach"))


@bp.post("/<ten>/trang-thai")
@auth.can_vai_tro("QUAN_TRI_TAI_KHOAN")
def doi_trang_thai(ten):
    if ten == session["user"]["ten_dang_nhap"]:
        flash("Không tự khóa tài khoản đang dùng.")
    else:
        try:
            with db.phien_lam_viec(session["user"]) as conn:
                conn.execute("UPDATE tai_khoan SET trang_thai = CASE trang_thai WHEN 'KHOA' THEN 'HOAT_DONG'"
                             " ELSE 'KHOA' END WHERE ten_dang_nhap = %s", (ten,))
            flash(f"Đã đổi trạng thái tài khoản {ten}.", "ok")
        except psycopg.Error as e:
            flash("Không đổi được trạng thái: " + db.loi_csdl(e))
    return redirect(request.referrer or url_for("tai_khoan.danh_sach"))
