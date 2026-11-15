"""Dữ liệu trang chủ (dashboard) theo vai trò – thiết kế ở docs/8_giao-dien/trang-chu/.

Mọi truy vấn chạy trong phien_lam_viec, tức dưới role PostgreSQL của người dùng (sql/rbac.sql):
mỗi dashboard chỉ đọc được bảng/view vai trò đó được cấp. Hiện cài mảng B: lễ tân, quản trị tài khoản,
phần lịch hẹn của bệnh nhân; vai trò khác dùng trang chủ đơn giản cho tới khi mảng A, C bổ sung.
"""
from datetime import date, datetime, time

import config

O_PHUT = 30   # độ dài một ô lịch hẹn (phút), như form đặt lịch


def le_tan(conn, ngay):
    """Tình hình lịch hẹn trong `ngay`: số liệu, lịch sắp tới, bác sĩ còn nhiều ô trống."""
    bay_gio = datetime.now() if ngay == date.today() else datetime.combine(ngay, time.min)
    so = conn.execute(
        "SELECT count(*) FILTER (WHERE trang_thai NOT IN ('HUY', 'VANG_MAT')) AS tong,"
        "       count(*) FILTER (WHERE trang_thai = 'DA_DAT') AS cho_xac_nhan,"
        "       count(*) FILTER (WHERE trang_thai NOT IN ('HUY', 'VANG_MAT') AND hinh_thuc = 'TU_XA') AS tu_xa,"
        "       count(DISTINCT ma_bac_si) FILTER (WHERE trang_thai NOT IN ('HUY', 'VANG_MAT')) AS so_bac_si,"
        "       count(*) FILTER (WHERE trang_thai IN ('DA_DAT', 'DA_XAC_NHAN') AND thoi_gian_bd >= %(bg)s) AS con_lai"
        " FROM lich_hen WHERE thoi_gian_bd::date = %(d)s", {"d": ngay, "bg": bay_gio}).fetchone()
    # Ô 30 phút trong ca và số lịch còn hiệu lực của từng bác sĩ có ca trong ngày
    bac_si = conn.execute(
        "SELECT nv.ma_nv, nv.ho_ten, COALESCE(ck.ten_chuyen_khoa, 'Đa khoa') AS chuyen_khoa, c.o,"
        "       (SELECT count(*) FROM lich_hen l WHERE l.ma_bac_si = nv.ma_nv AND l.thoi_gian_bd::date = %(d)s"
        "          AND l.trang_thai NOT IN ('HUY', 'VANG_MAT')) AS da_dat"
        " FROM (SELECT ma_bac_si, (sum(extract(epoch FROM thoi_gian_kt - thoi_gian_bd)) / %(giay)s)::int AS o"
        "       FROM ca_lam_viec WHERE trang_thai = 'DA_XEP' AND thoi_gian_bd::date = %(d)s GROUP BY ma_bac_si) c"
        " JOIN nhan_vien nv ON nv.ma_nv = c.ma_bac_si"
        " LEFT JOIN bac_si_chuyen_khoa bck ON bck.ma_bac_si = nv.ma_nv"
        " LEFT JOIN chuyen_khoa ck ON ck.ma_chuyen_khoa = bck.ma_chuyen_khoa",
        {"d": ngay, "giay": O_PHUT * 60}).fetchall()
    tong_o = sum(b["o"] for b in bac_si)
    con_trong = sorted((b for b in bac_si if b["o"] > b["da_dat"]),
                       key=lambda b: (b["da_dat"] - b["o"], b["ho_ten"]))[:6]
    sap_toi = conn.execute(
        "SELECT l.ma_lh, l.thoi_gian_bd, l.trang_thai, l.hinh_thuc, COALESCE(l.phong_kham, l.nen_tang) AS noi_kham,"
        "       bn.ma_bn, bn.ho_ten AS ten_bn, bn.sdt, nv.ho_ten AS ten_bac_si"
        " FROM lich_hen l JOIN benh_nhan bn USING (ma_bn) JOIN nhan_vien nv ON nv.ma_nv = l.ma_bac_si"
        " WHERE l.thoi_gian_bd::date = %(d)s AND l.thoi_gian_bd >= %(bg)s AND l.trang_thai IN ('DA_DAT', 'DA_XAC_NHAN')"
        " ORDER BY l.thoi_gian_bd, l.trang_thai, l.ma_lh LIMIT 5", {"d": ngay, "bg": bay_gio}).fetchall()
    return {"so": so, "tong_o": tong_o, "con_trong": con_trong, "sap_toi": sap_toi,
            "bay_gio": bay_gio, "hom_nay": ngay == date.today()}


def quan_tri_tai_khoan(conn):
    """Tài khoản theo vai trò, tài khoản đang khóa, nhân viên chưa có tài khoản (BR-B09, BR-B10)."""
    theo_vai_tro = conn.execute(
        "SELECT vai_tro, count(*) AS so, count(*) FILTER (WHERE trang_thai = 'KHOA') AS khoa"
        " FROM tai_khoan GROUP BY vai_tro").fetchall()
    dem = {r["vai_tro"]: r for r in theo_vai_tro}
    bang = [{"ten": ten, "so": dem[k]["so"] if k in dem else 0, "khoa": dem[k]["khoa"] if k in dem else 0}
            for k, (_, ten) in config.VAI_TRO.items()]
    bang.sort(key=lambda r: -r["so"])
    dang_khoa = conn.execute(
        "SELECT t.ten_dang_nhap, t.vai_tro, t.ma_bn, nv.ho_ten FROM tai_khoan t"
        " LEFT JOIN nhan_vien nv ON nv.ma_nv = t.ma_nv WHERE t.trang_thai = 'KHOA'"
        " ORDER BY t.vai_tro = 'BENH_NHAN', t.ten_dang_nhap LIMIT 5").fetchall()
    chua_co = conn.execute(
        "SELECT nv.ho_ten, nv.loai_nv FROM nhan_vien nv"
        " WHERE NOT EXISTS (SELECT 1 FROM tai_khoan t WHERE t.ma_nv = nv.ma_nv) ORDER BY nv.ho_ten").fetchall()
    return {"bang": bang, "dang_khoa": dang_khoa, "chua_co": chua_co,
            "nhan_vien": sum(r["so"] for r in theo_vai_tro if r["vai_tro"] != "BENH_NHAN"),
            "benh_nhan": dem["BENH_NHAN"]["so"] if "BENH_NHAN" in dem else 0,
            "so_khoa": sum(r["khoa"] for r in theo_vai_tro)}


def benh_nhan(conn):
    """Lịch hẹn của chính bệnh nhân qua view v_lich_hen_cua_toi (BR-B08). Đơn thuốc, dị ứng: mảng C (T50)."""
    rows = conn.execute(
        "SELECT ma_lh, thoi_gian_bd, thoi_gian_kt, trang_thai, hinh_thuc, link_phien,"
        "       phong_hoac_nen_tang AS noi_kham, ten_bac_si, chuyen_khoa, ly_do_kham"
        " FROM v_lich_hen_cua_toi ORDER BY thoi_gian_bd DESC").fetchall()
    bay_gio = datetime.now()
    sap_toi = sorted((r for r in rows if r["thoi_gian_kt"] >= bay_gio and r["trang_thai"] in ("DA_DAT", "DA_XAC_NHAN")),
                     key=lambda r: r["thoi_gian_bd"])
    da_qua = [r for r in rows if r["thoi_gian_kt"] < bay_gio][:4]
    return {"sap_toi": sap_toi, "da_qua": da_qua,
            "da_kham": sum(r["trang_thai"] == "HOAN_THANH" for r in rows), "tong": len(rows)}


def du_lieu(conn, user, ngay):
    """Dữ liệu dashboard của vai trò; None nếu vai trò chưa có dashboard."""
    vai_tro = user["vai_tro"]
    if vai_tro == "LE_TAN":
        return le_tan(conn, ngay)
    if vai_tro == "QUAN_TRI_TAI_KHOAN":
        return quan_tri_tai_khoan(conn)
    if vai_tro == "BENH_NHAN":
        return benh_nhan(conn)
    return None
