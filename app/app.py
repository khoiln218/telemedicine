from datetime import date

from flask import Flask, flash, redirect, render_template, request, session, url_for

import auth
import config
import benh_nhan
import db
import lich_hen
import tai_khoan
import trang_chu

app = Flask(__name__)
app.secret_key = config.SECRET_KEY
app.register_blueprint(lich_hen.bp)
app.register_blueprint(benh_nhan.bp)
app.register_blueprint(tai_khoan.bp)


def _menu(vai_tro):
    """Menu của vai trò (bỏ mục chưa có trang); đánh dấu mục đang mở: đúng endpoint, nếu không có thì
    mục đầu tiên cùng blueprint (vd. trang sửa lịch hẹn sáng mục Lịch hẹn)."""
    ds = [("Trang chủ", "home"), *config.MENU[vai_tro], ("Đổi mật khẩu", "tai_khoan.doi_mat_khau")]
    ds = [(nhan, ep) for nhan, ep in ds if ep in app.view_functions]
    hien_tai = request.endpoint or ""
    on = next((ep for _, ep in ds if ep == hien_tai), None) or next(
        (ep for _, ep in ds if "." in hien_tai and ep.split(".")[0] == request.blueprint), None)
    return [{"nhan": nhan, "url": url_for(ep), "on": ep == on} for nhan, ep in ds]


@app.context_processor
def them_ngu_canh():
    user = session.get("user")
    if not user:
        return {"user": None, "ten_vai_tro": None, "menu": []}
    return {"user": user, "ten_vai_tro": config.VAI_TRO[user["vai_tro"]][1], "menu": _menu(user["vai_tro"])}


@app.route("/login", methods=["GET", "POST"])
def login():
    if request.method == "POST":
        kq = auth.xac_thuc(request.form["ten_dang_nhap"].strip(), request.form["mat_khau"])
        if isinstance(kq, dict):
            session.clear()
            session["user"] = kq
            return redirect(url_for("home"))
        flash(kq)
    return render_template("login.html")


@app.post("/logout")
def logout():
    session.clear()
    return redirect(url_for("login"))


@app.route("/")
@auth.dang_nhap_bat_buoc
def home():
    """Trang chủ: dashboard theo vai trò (trang_chu.py). ?ngay=YYYY-MM-DD xem tình hình một ngày khác (lễ tân)."""
    try:
        ngay = date.fromisoformat(request.args.get("ngay", ""))
    except ValueError:
        ngay = date.today()
    with db.phien_lam_viec(session["user"]) as conn:   # truy vấn chạy dưới role PostgreSQL của người dùng
        role = conn.execute("SELECT current_user AS r").fetchone()["r"]
        d = trang_chu.du_lieu(conn, session["user"], ngay)
    return render_template("home.html", role_db=role, d=d, ngay=ngay, thu=lich_hen.THU[ngay.weekday()],
                           thu_cua=lambda t: lich_hen.THU[t.weekday()], TRANG_THAI=lich_hen.TRANG_THAI,
                           config_vai_tro=config.VAI_TRO)


@app.errorhandler(404)
def khong_thay(_):
    return render_template("loi.html", ma=404, noi_dung="Không tìm thấy dữ liệu."), 404


@app.errorhandler(403)
def cam(_):
    return render_template("loi.html", ma=403, noi_dung="Vai trò của bạn không có quyền vào trang này."), 403


if __name__ == "__main__":
    app.run(debug=True)
