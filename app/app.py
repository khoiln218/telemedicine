from flask import Flask, flash, redirect, render_template, request, session, url_for

import auth
import config
import db

app = Flask(__name__)
app.secret_key = config.SECRET_KEY


@app.context_processor
def them_ngu_canh():
    user = session.get("user")
    return {"user": user, "ten_vai_tro": config.VAI_TRO[user["vai_tro"]][1] if user else None}


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
    # Kiểm tra role PostgreSQL hoạt động: truy vấn chạy dưới quyền của người dùng
    with db.phien_lam_viec(session["user"]) as conn:
        role = conn.execute("SELECT current_user AS r").fetchone()["r"]
    return render_template("home.html", role_db=role)


@app.errorhandler(403)
def cam(_):
    return render_template("loi.html", ma=403, noi_dung="Vai trò của bạn không có quyền vào trang này."), 403


if __name__ == "__main__":
    app.run(debug=True)
