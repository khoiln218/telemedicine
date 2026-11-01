from datetime import date

import psycopg
from flask import Blueprint, abort, flash, redirect, render_template, request, session, url_for

import auth
import db

bp = Blueprint("lich_hen", __name__, url_prefix="/lich-hen")

TRANG_THAI = {"DA_DAT": "Đã đặt", "DA_XAC_NHAN": "Đã xác nhận", "HOAN_THANH": "Hoàn thành",
              "HUY": "Hủy", "VANG_MAT": "Vắng mặt"}


thong_bao_loi = db.loi_csdl


def _gio(a, b):
    return f"{a.strftime('%d/%m %H:%M')}–{b.strftime('%H:%M')}"


def thong_tin_them(user, f, e, ma_bn=None, ma_lh=None):
    """Dòng thông tin giúp lễ tân xử lý lỗi: lịch đang trùng, ca của bác sĩ, giấy chuyển."""
    ct = e.diag.constraint_name or ""
    msg = e.diag.message_primary or ""
    ds = []
    try:
        with db.phien_lam_viec(user) as conn:
            if ct in ("ex_lich_hen_bac_si", "ex_lich_hen_benh_nhan"):
                cot, gt = ("ma_bac_si", f["ma_bac_si"]) if ct == "ex_lich_hen_bac_si" else ("ma_bn", ma_bn)
                for r in conn.execute(
                        f"SELECT l.ma_lh, l.thoi_gian_bd, l.thoi_gian_kt, l.trang_thai, bn.ho_ten, nv.ho_ten AS bs"
                        f" FROM lich_hen l JOIN benh_nhan bn USING (ma_bn) JOIN nhan_vien nv ON nv.ma_nv = l.ma_bac_si"
                        f" WHERE l.{cot} = %s AND l.trang_thai NOT IN ('HUY', 'VANG_MAT') AND l.ma_lh <> %s"
                        f" AND tsrange(l.thoi_gian_bd, l.thoi_gian_kt) && tsrange(%s::timestamp, %s::timestamp)",
                        (gt, ma_lh or -1, f["bd"], f["kt"])).fetchall():
                    ds.append(f"Đang trùng lịch {r['ma_lh']}: {_gio(r['thoi_gian_bd'], r['thoi_gian_kt'])}, "
                              f"{TRANG_THAI[r['trang_thai']]}, bệnh nhân {r['ho_ten']}, bác sĩ {r['bs']}")
            elif msg.startswith("BR-B01"):
                ca = conn.execute(
                    "SELECT thoi_gian_bd, thoi_gian_kt FROM ca_lam_viec WHERE ma_bac_si = %s AND trang_thai <> 'HUY'"
                    " AND thoi_gian_bd::date = %s::timestamp::date ORDER BY thoi_gian_bd", (f["ma_bac_si"], f["bd"])
                ).fetchall()
                ds.append("Ca làm việc của bác sĩ trong ngày " + f["bd"][:10].split("-")[2] + "/" + f["bd"][5:7] + ": "
                          + (", ".join(_gio(c["thoi_gian_bd"], c["thoi_gian_kt"]) for c in ca) or "không có ca nào"))
            elif msg.startswith("BR-B03") and f.get("ma_giay"):
                g = conn.execute(
                    "SELECT g.ma_giay, g.ngay_lap, g.ngay_het_han, g.ma_bn, ck.ten_chuyen_khoa, l.ma_lh AS da_dung"
                    " FROM giay_chuyen_khoa g JOIN chuyen_khoa ck USING (ma_chuyen_khoa)"
                    " LEFT JOIN lich_hen l ON l.ma_giay = g.ma_giay WHERE g.ma_giay = %s", (f["ma_giay"],)).fetchone()
                ds.append("Không có giấy chuyển mã " + f["ma_giay"] if g is None else
                          f"Giấy chuyển {g['ma_giay']}: chuyên khoa {g['ten_chuyen_khoa']}, lập "
                          f"{g['ngay_lap']:%d/%m/%Y}, hết hạn {g['ngay_het_han']:%d/%m/%Y}, "
                          + (f"đã dùng cho lịch {g['da_dung']}" if g["da_dung"] else "chưa dùng"))
    except psycopg.Error:
        pass
    return ds


@bp.route("/")
@auth.can_vai_tro("BAC_SI", "LE_TAN", "BENH_NHAN")
def danh_sach():
    user = session["user"]
    ngay = request.args.get("ngay") or date.today().isoformat()
    # Bác sĩ xem được mọi lịch hẹn (T08 mục 5); mặc định chỉ hiện lịch của mình
    cua_toi = user["vai_tro"] == "BAC_SI" and request.args.get("tat_ca") != "1"
    with db.phien_lam_viec(user) as conn:
        if user["vai_tro"] == "BENH_NHAN":   # chỉ có view v_lich_hen_cua_toi (BR-B08)
            rows = conn.execute(
                "SELECT ma_lh, thoi_gian_bd, thoi_gian_kt, trang_thai, hinh_thuc,"
                "       phong_hoac_nen_tang AS noi_kham, ten_bac_si, chuyen_khoa, ly_do_kham, phi_kham,"
                "       NULL::text AS ten_bn FROM v_lich_hen_cua_toi ORDER BY thoi_gian_bd DESC LIMIT 200"
            ).fetchall()
        else:
            rows = conn.execute(
                "SELECT l.ma_lh, l.thoi_gian_bd, l.thoi_gian_kt, l.trang_thai, l.hinh_thuc,"
                "       COALESCE(l.phong_kham, l.nen_tang) AS noi_kham, nv.ho_ten AS ten_bac_si,"
                "       COALESCE(ck.ten_chuyen_khoa, 'Đa khoa') AS chuyen_khoa, l.ly_do_kham, l.phi_kham,"
                "       bn.ho_ten AS ten_bn, l.ma_bn"
                " FROM lich_hen l JOIN benh_nhan bn USING (ma_bn)"
                " JOIN nhan_vien nv ON nv.ma_nv = l.ma_bac_si"
                " LEFT JOIN bac_si_chuyen_khoa bck ON bck.ma_bac_si = l.ma_bac_si"
                " LEFT JOIN chuyen_khoa ck ON ck.ma_chuyen_khoa = bck.ma_chuyen_khoa"
                " WHERE l.thoi_gian_bd >= %(d)s::date AND l.thoi_gian_bd < %(d)s::date + 1"
                + (" AND l.ma_bac_si = %(nv)s" if cua_toi else "")
                + " ORDER BY l.thoi_gian_bd LIMIT 500",
                {"d": ngay, "nv": user["ma_nv"]}).fetchall()
    return render_template("lich_hen_ds.html", rows=rows, ngay=ngay, cua_toi=cua_toi, TRANG_THAI=TRANG_THAI)


def _bac_si(conn):
    return conn.execute(
        "SELECT nv.ma_nv, nv.ho_ten, COALESCE(ck.ten_chuyen_khoa, 'Đa khoa') AS chuyen_khoa"
        " FROM bac_si b JOIN nhan_vien nv ON nv.ma_nv = b.ma_bac_si"
        " LEFT JOIN bac_si_chuyen_khoa bck ON bck.ma_bac_si = b.ma_bac_si"
        " LEFT JOIN chuyen_khoa ck ON ck.ma_chuyen_khoa = bck.ma_chuyen_khoa"
        " ORDER BY chuyen_khoa, nv.ho_ten").fetchall()


@bp.route("/dat", methods=["GET", "POST"])
@auth.can_vai_tro("LE_TAN")
def dat():
    user = session["user"]
    f = request.form if request.method == "POST" else request.args
    chi_tiet = ma_bn = None
    if request.method == "POST":
        tu_xa = f["hinh_thuc"] == "TU_XA"
        try:
            with db.phien_lam_viec(user) as conn:
                bn = conn.execute("SELECT ma_bn, ho_ten FROM benh_nhan WHERE sdt = %s",
                                  (f["sdt"].strip(),)).fetchone()
                ma_bn = bn and bn["ma_bn"]
                if bn is None:
                    flash("Không tìm thấy bệnh nhân có số điện thoại này.")
                else:
                    conn.execute(
                        "INSERT INTO lich_hen (thoi_gian_bd, thoi_gian_kt, ly_do_kham, hinh_thuc, phi_kham,"
                        " phong_kham, nen_tang, link_phien, ma_bn, ma_bac_si, ma_giay)"
                        " VALUES (%s::timestamp, %s::timestamp, %s, %s, %s, %s, %s, %s, %s, %s, %s)",
                        (f["bd"], f["kt"], f["ly_do"].strip(), f["hinh_thuc"], f["phi"],
                         None if tu_xa else f["phong"].strip() or None,
                         f["nen_tang"].strip() or None if tu_xa else None,
                         f["link"].strip() or None if tu_xa else None,
                         bn["ma_bn"], f["ma_bac_si"], f["ma_giay"] or None))
                    flash(f"Đã đặt lịch hẹn cho {bn['ho_ten']}.")
                    return redirect(url_for("lich_hen.danh_sach", ngay=f["bd"][:10]))
        except psycopg.Error as e:   # trigger BR-B01/B03/B05, EXCLUDE BR-B02, CHECK: giao dịch đã rollback
            flash("Không đặt được lịch: " + thong_bao_loi(e))
            chi_tiet = thong_tin_them(user, f, e, ma_bn)
    with db.phien_lam_viec(user) as conn:
        bac_si = _bac_si(conn)
    return render_template("lich_hen_dat.html", bac_si=bac_si, f=f, chi_tiet=chi_tiet)


@bp.route("/<int:ma_lh>/sua", methods=["GET", "POST"])
@auth.can_vai_tro("LE_TAN")
def sua(ma_lh):
    user = session["user"]
    f = request.form
    chi_tiet = None
    with db.phien_lam_viec(user) as conn:
        lh = conn.execute(
            "SELECT l.*, bn.ho_ten AS ten_bn, bn.sdt FROM lich_hen l JOIN benh_nhan bn USING (ma_bn)"
            " WHERE ma_lh = %s", (ma_lh,)).fetchone()
        bac_si = _bac_si(conn)
    if lh is None:
        abort(404)
    if request.method == "POST":
        tu_xa = f["hinh_thuc"] == "TU_XA"
        try:
            with db.phien_lam_viec(user) as conn:   # bệnh nhân không đổi; lịch hủy, vắng mặt không chiếm giờ
                conn.execute(
                    "UPDATE lich_hen SET thoi_gian_bd = %s::timestamp, thoi_gian_kt = %s::timestamp,"
                    " ly_do_kham = %s, hinh_thuc = %s, phi_kham = %s, phong_kham = %s, nen_tang = %s,"
                    " link_phien = %s, ma_bac_si = %s, ma_giay = %s WHERE ma_lh = %s",
                    (f["bd"], f["kt"], f["ly_do"].strip(), f["hinh_thuc"], f["phi"],
                     None if tu_xa else f["phong"].strip() or None,
                     f["nen_tang"].strip() or None if tu_xa else None,
                     f["link"].strip() or None if tu_xa else None,
                     f["ma_bac_si"], f["ma_giay"] or None, ma_lh))
            flash(f"Đã cập nhật lịch hẹn {ma_lh}.")
            return redirect(url_for("lich_hen.danh_sach", ngay=f["bd"][:10]))
        except psycopg.Error as e:
            flash("Không sửa được lịch: " + thong_bao_loi(e))
            chi_tiet = thong_tin_them(user, f, e, lh["ma_bn"], ma_lh)
    else:
        f = {"sdt": lh["sdt"], "ma_bac_si": str(lh["ma_bac_si"]), "ly_do": lh["ly_do_kham"],
             "bd": lh["thoi_gian_bd"].strftime("%Y-%m-%dT%H:%M"), "kt": lh["thoi_gian_kt"].strftime("%Y-%m-%dT%H:%M"),
             "hinh_thuc": lh["hinh_thuc"], "phong": lh["phong_kham"] or "", "nen_tang": lh["nen_tang"] or "",
             "link": lh["link_phien"] or "", "phi": str(lh["phi_kham"]), "ma_giay": lh["ma_giay"] or ""}
    return render_template("lich_hen_dat.html", bac_si=bac_si, f=f, sua=lh, chi_tiet=chi_tiet)


@bp.post("/<int:ma_lh>/trang-thai")
@auth.can_vai_tro("LE_TAN")
def doi_trang_thai(ma_lh):
    moi = request.form["trang_thai"]
    try:
        with db.phien_lam_viec(session["user"]) as conn:
            conn.execute("UPDATE lich_hen SET trang_thai = %s WHERE ma_lh = %s", (moi, ma_lh))
        flash(f"Lịch hẹn {ma_lh} chuyển sang {TRANG_THAI.get(moi, moi)}.")
    except psycopg.Error as e:
        flash("Không đổi được trạng thái: " + thong_bao_loi(e))
    return redirect(request.referrer or url_for("lich_hen.danh_sach"))
