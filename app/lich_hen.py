import secrets
from datetime import date, datetime, timedelta

import psycopg
from flask import Blueprint, abort, flash, redirect, render_template, request, session, url_for

import auth
import db

bp = Blueprint("lich_hen", __name__, url_prefix="/lich-hen")

TRANG_THAI = {"DA_DAT": "Đã đặt", "DA_XAC_NHAN": "Đã xác nhận", "HOAN_THANH": "Hoàn thành",
              "HUY": "Hủy", "VANG_MAT": "Vắng mặt"}


THU = ("Thứ Hai", "Thứ Ba", "Thứ Tư", "Thứ Năm", "Thứ Sáu", "Thứ Bảy", "Chủ nhật")
CON_HIEU_LUC = ("DA_DAT", "DA_XAC_NHAN", "HOAN_THANH")   # lịch hủy, vắng mặt không chiếm giờ
# Bảng giá khám theo loại bác sĩ và hình thức (khớp seed: từ xa giảm 30.000 đ); lễ tân chọn, không gõ tay
NEN_TANG = ("Google Meet", "Zoom")   # nền tảng khám từ xa phòng khám dùng (khớp seed)
BANG_GIA = [
    {"loai": "DA_KHOA", "ht": "TRUC_TIEP", "gia": 150000, "nhan": "150.000 đ · Đa khoa, trực tiếp"},
    {"loai": "DA_KHOA", "ht": "TU_XA", "gia": 120000, "nhan": "120.000 đ · Đa khoa, từ xa"},
    {"loai": "CHUYEN_KHOA", "ht": "TRUC_TIEP", "gia": 250000, "nhan": "250.000 đ · Chuyên khoa, trực tiếp"},
    {"loai": "CHUYEN_KHOA", "ht": "TU_XA", "gia": 220000, "nhan": "220.000 đ · Chuyên khoa, từ xa"},
]

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


def _ngay(s):
    try:
        return date.fromisoformat(s)
    except (TypeError, ValueError):
        return date.today()


@bp.route("/")
@auth.can_vai_tro("BAC_SI", "LE_TAN", "BENH_NHAN")
def danh_sach():
    user = session["user"]
    ngay = _ngay(request.args.get("ngay"))
    # Bác sĩ xem được mọi lịch hẹn (T08 mục 5); mặc định chỉ hiện lịch của mình
    cua_toi = user["vai_tro"] == "BAC_SI" and request.args.get("tat_ca") != "1"
    loc_bs = request.args.get("ma_bac_si", "") if user["vai_tro"] == "LE_TAN" else ""
    bac_si = sap_toi = None
    with db.phien_lam_viec(user) as conn:
        if user["vai_tro"] == "BENH_NHAN":   # chỉ có view v_lich_hen_cua_toi (BR-B08)
            rows = conn.execute(
                "SELECT ma_lh, thoi_gian_bd, thoi_gian_kt, trang_thai, hinh_thuc, link_phien,"
                "       phong_hoac_nen_tang AS noi_kham, ten_bac_si, chuyen_khoa, ly_do_kham, phi_kham"
                " FROM v_lich_hen_cua_toi ORDER BY thoi_gian_bd DESC LIMIT 200"
            ).fetchall()
            bay_gio = datetime.now()
            sap_toi = min((r for r in rows if r["thoi_gian_kt"] >= bay_gio and r["trang_thai"] in ("DA_DAT", "DA_XAC_NHAN")),
                          key=lambda r: r["thoi_gian_bd"], default=None)
        else:
            rows = conn.execute(
                "SELECT l.ma_lh, l.thoi_gian_bd, l.thoi_gian_kt, l.trang_thai, l.hinh_thuc, l.ma_giay,"
                "       COALESCE(l.phong_kham, l.nen_tang) AS noi_kham, nv.ho_ten AS ten_bac_si,"
                "       COALESCE(ck.ten_chuyen_khoa, 'Đa khoa') AS chuyen_khoa, l.ly_do_kham, l.phi_kham,"
                "       bn.ho_ten AS ten_bn, bn.sdt, l.ma_bn"
                " FROM lich_hen l JOIN benh_nhan bn USING (ma_bn)"
                " JOIN nhan_vien nv ON nv.ma_nv = l.ma_bac_si"
                " LEFT JOIN bac_si_chuyen_khoa bck ON bck.ma_bac_si = l.ma_bac_si"
                " LEFT JOIN chuyen_khoa ck ON ck.ma_chuyen_khoa = bck.ma_chuyen_khoa"
                " WHERE l.thoi_gian_bd >= %(d)s::date AND l.thoi_gian_bd < %(d)s::date + 1"
                + (" AND l.ma_bac_si = %(nv)s" if cua_toi else "")
                + (" AND l.ma_bac_si = %(bs)s::int" if loc_bs else "")
                + " ORDER BY l.thoi_gian_bd LIMIT 500",
                {"d": ngay, "nv": user["ma_nv"], "bs": loc_bs}).fetchall()
            if user["vai_tro"] == "LE_TAN":
                bac_si = _bac_si(conn)
    return render_template("lich_hen_ds.html", rows=rows, ngay=ngay, thu=THU[ngay.weekday()], cua_toi=cua_toi,
                           loc_bs=loc_bs, bac_si=bac_si, sap_toi=sap_toi, TRANG_THAI=TRANG_THAI)


def _bac_si(conn, phong=False):
    return conn.execute(
        "SELECT nv.ma_nv, nv.ho_ten, bck.ma_chuyen_khoa, COALESCE(ck.ten_chuyen_khoa, 'Đa khoa') AS chuyen_khoa"
        # phòng bác sĩ hay dùng nhất, để chọn sẵn khi đặt lịch trực tiếp
        + (", (SELECT l.phong_kham FROM lich_hen l WHERE l.ma_bac_si = b.ma_bac_si AND l.phong_kham IS NOT NULL"
           "   GROUP BY l.phong_kham ORDER BY count(*) DESC LIMIT 1) AS phong_quen" if phong else "")
        + " FROM bac_si b JOIN nhan_vien nv ON nv.ma_nv = b.ma_bac_si"
        " LEFT JOIN bac_si_chuyen_khoa bck ON bck.ma_bac_si = b.ma_bac_si"
        " LEFT JOIN chuyen_khoa ck ON ck.ma_chuyen_khoa = bck.ma_chuyen_khoa"
        " ORDER BY chuyen_khoa, nv.ho_ten").fetchall()


def _tim_bn(conn, sdt):
    return conn.execute("SELECT ma_bn, ho_ten, gioi_tinh, ngay_sinh, sdt FROM benh_nhan WHERE sdt = %s",
                        ((sdt or "").strip(),)).fetchone()


def _phong(conn):
    """Chưa có bảng phòng khám: lấy các phòng đã dùng trong lịch hẹn."""
    return [r["phong_kham"] for r in conn.execute(
        "SELECT DISTINCT phong_kham FROM lich_hen WHERE phong_kham IS NOT NULL ORDER BY 1").fetchall()]


def _giay(conn, ma_bn, ma_lh=None, ma_giay=None):
    """Giấy chuyển của bệnh nhân chưa gắn lịch nào (trừ lịch đang sửa), còn hạn tính đến hôm nay.

    Giấy đang gắn với lịch đang sửa luôn có trong danh sách dù đã hết hạn."""
    return conn.execute(
        "SELECT g.ma_giay, g.ma_chuyen_khoa, ck.ten_chuyen_khoa, g.ngay_het_han"
        " FROM giay_chuyen_khoa g JOIN chuyen_khoa ck USING (ma_chuyen_khoa)"
        " WHERE g.ma_bn = %(bn)s AND (g.ngay_het_han >= CURRENT_DATE OR g.ma_giay = %(giay)s)"
        "   AND NOT EXISTS (SELECT 1 FROM lich_hen l WHERE l.ma_giay = g.ma_giay AND l.ma_lh <> %(lh)s)"
        " ORDER BY g.ngay_lap DESC",
        {"bn": ma_bn, "lh": ma_lh or -1, "giay": int(ma_giay) if str(ma_giay or "").isdigit() else -1}).fetchall()


def _tai_kham(conn, ma_bn):
    """Chuyên khoa bệnh nhân đã khám xong ít nhất một lần: đặt lại không cần giấy (BR-B03)."""
    return [r["ma_chuyen_khoa"] for r in conn.execute(
        "SELECT DISTINCT bck.ma_chuyen_khoa FROM lich_hen l JOIN bac_si_chuyen_khoa bck USING (ma_bac_si)"
        " WHERE l.ma_bn = %s AND l.trang_thai = 'HOAN_THANH'", (ma_bn,)).fetchall()]


def _ngay_kham(f):
    """Ngày khám đang chọn ở form: ô ngày, hoặc ngày của giờ bắt đầu đã chọn."""
    return f.get("ngay") or (f.get("bd") or "")[:10]


def _khung_gio(conn, ma_bac_si, ngay, bd=None, kt=None, bo_qua=None, buoc=timedelta(minutes=30)):
    """Các ca của bác sĩ trong `ngay`; khoảng trống chia thành ô `buoc` phút để bấm chọn giờ khám.

    Ô đang chọn [bd, kt) được đánh dấu; lịch đã có giao với giờ đang chọn là lịch trùng; ô đã qua không chọn được."""
    try:
        ngay = date.fromisoformat(ngay)
        ma_bac_si = int(ma_bac_si)
    except (TypeError, ValueError):
        return None
    try:
        bd, kt = datetime.fromisoformat(bd), datetime.fromisoformat(kt)
    except (TypeError, ValueError):
        bd = kt = None
    ca = conn.execute(
        "SELECT thoi_gian_bd, thoi_gian_kt FROM ca_lam_viec WHERE ma_bac_si = %s AND trang_thai <> 'HUY'"
        " AND thoi_gian_bd::date = %s ORDER BY thoi_gian_bd", (ma_bac_si, ngay)).fetchall()
    lich = conn.execute(
        "SELECT ma_lh, thoi_gian_bd, thoi_gian_kt, trang_thai FROM lich_hen"
        " WHERE ma_bac_si = %s AND thoi_gian_bd::date = %s AND trang_thai = ANY(%s) AND ma_lh <> %s"
        " ORDER BY thoi_gian_bd", (ma_bac_si, ngay, list(CON_HIEU_LUC), bo_qua or -1)).fetchall()
    bay_gio = datetime.now()

    def o_trong(tu, den):   # chia khoảng trống thành các ô chọn được
        kq = []
        while tu < den:
            sau = min(tu + buoc, den)
            kq.append({"loai": "qua" if tu < bay_gio else "trong", "gio": _gio(tu, sau)[6:],
                       "bd": tu.strftime("%Y-%m-%dT%H:%M"), "kt": sau.strftime("%Y-%m-%dT%H:%M"),
                       "chon": tu == bd and sau == kt})
            tu = sau
        return kq

    kq = []
    for c in ca:
        o, tu = [], c["thoi_gian_bd"]
        for l in lich:
            if l["thoi_gian_kt"] <= c["thoi_gian_bd"] or l["thoi_gian_bd"] >= c["thoi_gian_kt"]:
                continue
            o += o_trong(tu, l["thoi_gian_bd"])
            trung = bd is not None and l["thoi_gian_bd"] < kt and bd < l["thoi_gian_kt"]
            o.append({"loai": "trung" if trung else "ban", "gio": _gio(l["thoi_gian_bd"], l["thoi_gian_kt"])[6:],
                      "nhan": f"Lịch {l['ma_lh']} · {TRANG_THAI[l['trang_thai']]}"})
            tu = max(tu, l["thoi_gian_kt"])
        o += o_trong(tu, c["thoi_gian_kt"])
        kq.append({"gio": _gio(c["thoi_gian_bd"], c["thoi_gian_kt"])[6:], "o": o})
    return {"ngay": ngay.strftime("%d/%m/%Y"), "ca": kq}


def _loi_gio(e):
    return (e.diag.constraint_name or "").startswith("ex_lich_hen") or (e.diag.message_primary or "").startswith("BR-B01")


def _form(user, f, sua=None, **kw):
    with db.phien_lam_viec(user) as conn:
        bac_si = _bac_si(conn, phong=True)
        bn = sua or (f.get("sdt") and _tim_bn(conn, f["sdt"]))
        khung = _khung_gio(conn, f.get("ma_bac_si"), _ngay_kham(f), f.get("bd"), f.get("kt"), sua and sua["ma_lh"])
        phong = _phong(conn)
        giay = _giay(conn, bn["ma_bn"], sua and sua["ma_lh"], f.get("ma_giay")) if bn else None
        tai_kham = _tai_kham(conn, bn["ma_bn"]) if bn else []
    ten_bs = next((b for b in bac_si if str(b["ma_nv"]) == str(f.get("ma_bac_si"))), None)
    return render_template("lich_hen_dat.html", bac_si=bac_si, f=f, sua=sua, bn=bn, khung=khung, ten_bs=ten_bs,
                           ngay=_ngay_kham(f) or date.today().isoformat(),
                           phong=phong, giay=giay, tai_kham=tai_kham, BANG_GIA=BANG_GIA, NEN_TANG=NEN_TANG,
                           gia_co_san=[str(g["gia"]) for g in BANG_GIA], TRANG_THAI=TRANG_THAI,
                           **{"loi": None, "chi_tiet": None, "loi_gio": False, **kw})


@bp.get("/khung-gio")
@auth.can_vai_tro("LE_TAN")
def khung_gio():
    """Khung lịch bác sĩ (HTML) cho trang đặt/sửa lịch, gọi lại mỗi khi đổi bác sĩ hoặc ngày."""
    a = request.args
    with db.phien_lam_viec(session["user"]) as conn:
        khung = _khung_gio(conn, a.get("ma_bac_si"), a.get("ngay"), a.get("bd"), a.get("kt"), a.get("bo_qua", type=int))
        ten_bs = khung and conn.execute("SELECT ho_ten FROM nhan_vien WHERE ma_nv = %s",
                                        (int(a["ma_bac_si"]),)).fetchone()
    return render_template("_khung_gio.html", khung=khung, ten_bs=ten_bs)


def _tao_link():
    """Link phiên khám từ xa do app tự tạo (cùng dạng seed; tên miền .example, không trỏ tới dịch vụ thật)."""
    return "https://meet.phongkham.example/" + secrets.token_urlsafe(8)


def _gia_tri(f, link_cu=None):
    """Giá trị cột lịch hẹn từ form; lịch từ xa giữ link cũ (khi sửa) hoặc tạo link mới."""
    tu_xa = f["hinh_thuc"] == "TU_XA"
    return (f["bd"], f["kt"], f["ly_do"].strip(), f["hinh_thuc"], f["phi"],
            None if tu_xa else f["phong"].strip() or None,
            f["nen_tang"].strip() or None if tu_xa else None,
            (link_cu or _tao_link()) if tu_xa else None)


@bp.route("/dat", methods=["GET", "POST"])
@auth.can_vai_tro("LE_TAN")
def dat():
    user = session["user"]
    f = request.form if request.method == "POST" else request.args
    if request.method == "POST":
        if not (f.get("bd") and f.get("kt")):
            return _form(user, f, loi="Chưa chọn giờ khám: bấm một ô Trống ở khung giờ bác sĩ.", loi_gio=True)
        bn = None
        try:
            with db.phien_lam_viec(user) as conn:
                bn = _tim_bn(conn, f["sdt"])
                if bn is not None:
                    link = conn.execute(
                        "INSERT INTO lich_hen (thoi_gian_bd, thoi_gian_kt, ly_do_kham, hinh_thuc, phi_kham,"
                        " phong_kham, nen_tang, link_phien, ma_bn, ma_bac_si, ma_giay)"
                        " VALUES (%s::timestamp, %s::timestamp, %s, %s, %s, %s, %s, %s, %s, %s, %s)"
                        " RETURNING link_phien",
                        (*_gia_tri(f), bn["ma_bn"], f["ma_bac_si"], f.get("ma_giay") or None)).fetchone()["link_phien"]
            if bn is None:
                return _form(user, f, loi="Không tìm thấy bệnh nhân có số điện thoại này.")
            flash(f"Đã đặt lịch hẹn cho {bn['ho_ten']}." + (f" Link phiên: {link}" if link else ""), "ok")
            return redirect(url_for("lich_hen.danh_sach", ngay=f["bd"][:10]))
        except psycopg.Error as e:   # trigger BR-B01/B03/B05, EXCLUDE BR-B02, CHECK: giao dịch đã rollback
            return _form(user, f, loi="Không đặt được lịch: " + thong_bao_loi(e),
                         chi_tiet=thong_tin_them(user, f, e, bn and bn["ma_bn"]), loi_gio=_loi_gio(e))
    return _form(user, f)


@bp.route("/<int:ma_lh>/sua", methods=["GET", "POST"])
@auth.can_vai_tro("LE_TAN")
def sua(ma_lh):
    user = session["user"]
    with db.phien_lam_viec(user) as conn:
        lh = conn.execute(
            "SELECT l.*, bn.ho_ten, bn.gioi_tinh, bn.ngay_sinh, bn.sdt FROM lich_hen l JOIN benh_nhan bn USING (ma_bn)"
            " WHERE ma_lh = %s", (ma_lh,)).fetchone()
    if lh is None:
        abort(404)
    if request.method == "POST":
        f = request.form
        if not (f.get("bd") and f.get("kt")):
            return _form(user, f, sua=lh, loi="Chưa chọn giờ khám: bấm một ô Trống ở khung giờ bác sĩ.", loi_gio=True)
        try:
            with db.phien_lam_viec(user) as conn:   # bệnh nhân không đổi; lịch hủy, vắng mặt không chiếm giờ
                conn.execute(
                    "UPDATE lich_hen SET thoi_gian_bd = %s::timestamp, thoi_gian_kt = %s::timestamp,"
                    " ly_do_kham = %s, hinh_thuc = %s, phi_kham = %s, phong_kham = %s, nen_tang = %s,"
                    " link_phien = %s, ma_bac_si = %s, ma_giay = %s WHERE ma_lh = %s",
                    (*_gia_tri(f, lh["link_phien"]), f["ma_bac_si"], f.get("ma_giay") or None, ma_lh))
            flash(f"Đã cập nhật lịch hẹn {ma_lh}.", "ok")
            return redirect(url_for("lich_hen.danh_sach", ngay=f["bd"][:10]))
        except psycopg.Error as e:
            return _form(user, f, sua=lh, loi="Không sửa được lịch: " + thong_bao_loi(e),
                         chi_tiet=thong_tin_them(user, f, e, lh["ma_bn"], ma_lh), loi_gio=_loi_gio(e))
    if request.args:   # JS gửi lại form bằng GET khi cần tải lại
        f = request.args
    else:
        f = {"ma_bac_si": str(lh["ma_bac_si"]), "ly_do": lh["ly_do_kham"], "ngay": lh["thoi_gian_bd"].date().isoformat(),
             "bd": lh["thoi_gian_bd"].strftime("%Y-%m-%dT%H:%M"), "kt": lh["thoi_gian_kt"].strftime("%Y-%m-%dT%H:%M"),
             "hinh_thuc": lh["hinh_thuc"], "phong": lh["phong_kham"] or "", "nen_tang": lh["nen_tang"] or "",
             "phi": str(lh["phi_kham"]), "ma_giay": lh["ma_giay"] or ""}
    return _form(user, f, sua=lh)


@bp.post("/<int:ma_lh>/trang-thai")
@auth.can_vai_tro("LE_TAN")
def doi_trang_thai(ma_lh):
    moi = request.form["trang_thai"]
    try:
        with db.phien_lam_viec(session["user"]) as conn:
            conn.execute("UPDATE lich_hen SET trang_thai = %s WHERE ma_lh = %s", (moi, ma_lh))
        flash(f"Lịch hẹn {ma_lh} chuyển sang {TRANG_THAI.get(moi, moi)}.", "ok")
    except psycopg.Error as e:
        flash("Không đổi được trạng thái: " + thong_bao_loi(e))
    return redirect(request.referrer or url_for("lich_hen.danh_sach"))
