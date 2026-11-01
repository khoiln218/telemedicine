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
