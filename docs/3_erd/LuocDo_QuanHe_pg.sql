-- Lược đồ quan hệ sinh tự động từ catalog PostgreSQL (pg_class, pg_attribute, pg_constraint),
-- nên luôn khớp với sql/schema.sql: mọi bảng, cột, kiểu dữ liệu, khóa chính (gạch chân), khóa ngoại (#),
-- NOT NULL (*); mũi tên đi từ bảng có khóa ngoại lên bảng được tham chiếu (bố cục dọc cho trang A4 đứng). Màu theo mảng A, B, C; bảng danh mục màu vàng.
-- Xuất ảnh (chạy trên CSDL đã nạp sql/schema.sql):
--   psql -At -f docs/3_erd/LuocDo_QuanHe_pg.sql > docs/3_erd/LuocDo_QuanHe_pg.dot
--   dot -Tpng -Gdpi=200 docs/3_erd/LuocDo_QuanHe_pg.dot -o docs/3_erd/LuocDo_QuanHe_pg.png
\set QUIET on
\pset footer off
WITH mang(bang, mau, cum) AS (VALUES
    ('nhan_vien', '#dae8fc', 'A'), ('bac_si', '#dae8fc', 'A'), ('bac_si_da_khoa', '#dae8fc', 'A'),
    ('bac_si_chuyen_khoa', '#dae8fc', 'A'), ('ca_lam_viec', '#dae8fc', 'A'), ('chuyen_khoa', '#fff2cc', 'A'),
    ('benh_nhan', '#d5e8d4', 'B'), ('giay_chuyen_khoa', '#d5e8d4', 'B'), ('lich_hen', '#d5e8d4', 'B'),
    ('tai_khoan', '#d5e8d4', 'B'),
    ('lan_kham', '#ffe6cc', 'C'), ('chan_doan', '#ffe6cc', 'C'), ('don_thuoc', '#ffe6cc', 'C'),
    ('chi_tiet_don_thuoc', '#ffe6cc', 'C'), ('thuoc_hoat_chat', '#ffe6cc', 'C'), ('di_ung', '#ffe6cc', 'C'),
    ('ma_icd10', '#fff2cc', 'C'), ('thuoc', '#fff2cc', 'C'), ('hoat_chat', '#fff2cc', 'C')),
bang AS (
    SELECT c.oid, c.relname, coalesce(m.mau, '#eeeeee') AS mau, coalesce(m.cum, '?') AS cum
    FROM pg_class c
    JOIN pg_namespace n ON n.oid = c.relnamespace AND n.nspname = 'public'
    LEFT JOIN mang m ON m.bang = c.relname
    WHERE c.relkind = 'r'),
cot AS (
    SELECT b.relname, a.attnum,
           format('<TR><TD ALIGN="LEFT">%s%s%s</TD><TD ALIGN="LEFT"><FONT COLOR="#666666" POINT-SIZE="9">%s</FONT></TD></TR>',
                  CASE WHEN fk.f THEN '#' ELSE '' END,
                  CASE WHEN pk.p THEN '<U>' || a.attname || '</U>' ELSE a.attname END,
                  CASE WHEN a.attnotnull AND NOT pk.p THEN '*' ELSE '' END,
                  replace(replace(format_type(a.atttypid, a.atttypmod),
                          'character varying', 'varchar'), 'timestamp without time zone', 'timestamp')) AS dong
    FROM bang b
    JOIN pg_attribute a ON a.attrelid = b.oid AND a.attnum > 0 AND NOT a.attisdropped
    CROSS JOIN LATERAL (SELECT EXISTS (SELECT 1 FROM pg_constraint k WHERE k.conrelid = b.oid
                                       AND k.contype = 'p' AND a.attnum = ANY (k.conkey))) AS pk(p)
    CROSS JOIN LATERAL (SELECT EXISTS (SELECT 1 FROM pg_constraint k WHERE k.conrelid = b.oid
                                       AND k.contype = 'f' AND a.attnum = ANY (k.conkey))) AS fk(f)),
nut AS (
    SELECT b.cum, format('    %s [label=<<TABLE BORDER="1" CELLBORDER="0" CELLSPACING="0" CELLPADDING="2">'
                         '<TR><TD COLSPAN="2" BGCOLOR="%s"><B>%s</B></TD></TR>%s</TABLE>>];',
                         b.relname, b.mau, upper(b.relname),
                         (SELECT string_agg(c.dong, '' ORDER BY c.attnum) FROM cot c WHERE c.relname = b.relname)) AS dong
    FROM bang b),
canh AS (
    -- mỗi khóa ngoại một mũi tên nối hai bảng; khóa ngoại ghép ghi tên các cột
    SELECT format('  %s -> %s%s;', k.conrelid::regclass, k.confrelid::regclass,
                  CASE WHEN array_length(k.conkey, 1) > 1
                       THEN format(' [xlabel="(%s)", fontsize=8]',
                                   (SELECT string_agg(attname, ', ' ORDER BY ord) FROM unnest(k.conkey) WITH ORDINALITY u(n, ord)
                                    JOIN pg_attribute x ON x.attrelid = k.conrelid AND x.attnum = u.n))
                       ELSE '' END) AS dong
    FROM pg_constraint k
    JOIN bang b ON b.oid = k.conrelid
    WHERE k.contype = 'f')
SELECT 'digraph LuocDoQuanHe {' || E'\n'
    || '  graph [rankdir=BT, splines=ortho, nodesep=0.2, ranksep=0.45, fontname="Helvetica", pad=0.2];' || E'\n'
    || '  node  [shape=plain, fontname="Helvetica", fontsize=10];' || E'\n'
    || '  edge  [arrowsize=0.6, color="#555555", fontname="Helvetica"];' || E'\n'
    || (SELECT string_agg(dong, E'\n' ORDER BY cum, dong) FROM nut) || E'\n'
    || (SELECT string_agg(dong, E'\n' ORDER BY dong) FROM canh) || E'\n'
    || '}';
