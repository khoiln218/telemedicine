import os

from dotenv import load_dotenv

load_dotenv()

DATABASE_URL = os.environ.get("DATABASE_URL", "postgresql://localhost:5432/telemedicine")
SECRET_KEY = os.environ.get("SECRET_KEY", "dev")

# vai_tro trong tai_khoan -> role PostgreSQL (sql/rbac.sql) và tên hiển thị
VAI_TRO = {
    "QUAN_TRI_NHAN_SU": ("r_quan_tri_nhan_su", "Quản trị nhân sự"),
    "QUAN_TRI_TAI_KHOAN": ("r_quan_tri_tai_khoan", "Quản trị tài khoản"),
    "QUAN_TRI_DANH_MUC": ("r_quan_tri_danh_muc", "Quản trị danh mục"),
    "BAC_SI": ("r_bac_si", "Bác sĩ"),
    "LE_TAN": ("r_le_tan", "Lễ tân"),
    "BENH_NHAN": ("r_benh_nhan", "Bệnh nhân"),
}

# Menu theo vai trò, khớp bản thiết kế docs/8_giao-dien: (nhãn, endpoint Flask).
# Trang chủ đứng đầu, Đổi mật khẩu đứng cuối ở mọi vai trò. Mục có endpoint chưa cài thì tạm ẩn:
# màn hình mảng A (T48) đặt endpoint bac_si.danh_sach thì mục Bác sĩ tự hiện.
MENU = {
    "LE_TAN": [("Lịch hẹn", "lich_hen.danh_sach"), ("Đặt lịch", "lich_hen.dat"),
               ("Bệnh nhân", "benh_nhan.danh_sach"), ("Bác sĩ", "bac_si.danh_sach")],
    "BAC_SI": [("Lịch hẹn", "lich_hen.danh_sach"), ("Bệnh nhân", "benh_nhan.danh_sach"),
               ("Bác sĩ", "bac_si.danh_sach")],
    "QUAN_TRI_NHAN_SU": [("Bác sĩ & lịch làm việc", "bac_si.danh_sach")],
    "QUAN_TRI_TAI_KHOAN": [("Tài khoản", "tai_khoan.danh_sach")],
    "QUAN_TRI_DANH_MUC": [],
    "BENH_NHAN": [("Lịch hẹn & hồ sơ của tôi", "lich_hen.danh_sach")],
}
