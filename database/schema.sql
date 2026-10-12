-- PostgreSQL schema สำหรับขั้นตอนปัจจุบันของโปรเจกต์
-- ID ใช้ prefix ที่อ่านง่าย แทน UUID แบบสุ่ม

CREATE SEQUENCE IF NOT EXISTS source_file_id_seq START WITH 1;
CREATE SEQUENCE IF NOT EXISTS document_id_seq START WITH 1;

CREATE OR REPLACE FUNCTION next_source_file_id()
RETURNS varchar
LANGUAGE sql
AS $$
    SELECT 'FILE-' || lpad(nextval('source_file_id_seq')::text, 6, '0');
$$;

CREATE OR REPLACE FUNCTION next_document_id(document_kind varchar)
RETURNS varchar
LANGUAGE sql
AS $$
    SELECT CASE document_kind
        WHEN 'QUOTATION' THEN 'QUO'
        WHEN 'INVOICE' THEN 'INV'
        WHEN 'BILLING_NOTE' THEN 'BIL'
        WHEN 'RECEIPT' THEN 'REC'
        ELSE 'DOC'
    END || '-' || lpad(nextval('document_id_seq')::text, 6, '0');
$$;

CREATE OR REPLACE FUNCTION assign_document_id()
RETURNS trigger
LANGUAGE plpgsql
AS $$
BEGIN
    -- n8n ตรวจ schema ก่อน INSERT และต้องเห็น DEFAULT จึงจะยอมเว้นช่อง document_id
    -- DEFAULT เป็นข้อความว่างชั่วคราว ส่วน trigger นี้จะแทนด้วย ID จริงก่อนบันทึก
    IF NEW.document_id IS NULL OR btrim(NEW.document_id) = '' THEN
        NEW.document_id := next_document_id(NEW.document_type);
    END IF;
    RETURN NEW;
END;
$$;

CREATE TABLE IF NOT EXISTS source_files (
    source_file_id      varchar(20) PRIMARY KEY DEFAULT next_source_file_id(),
    original_filename   text NOT NULL,
    mime_type           varchar(100),
    page_count          integer CHECK (page_count IS NULL OR page_count > 0),
    created_at          timestamptz NOT NULL DEFAULT now()
);

CREATE TABLE IF NOT EXISTS documents (
    document_id             varchar(20) PRIMARY KEY DEFAULT '',
    source_file_id          varchar(20) NOT NULL REFERENCES source_files(source_file_id) ON DELETE CASCADE,
    document_type           varchar(30) NOT NULL CHECK (
                                document_type IN (
                                    'QUOTATION', 'INVOICE', 'BILLING_NOTE', 'RECEIPT'
                                )
                            ),
    document_number         varchar(100),
    issue_date              date,

    issuer_name             text,
    issuer_address          text,
    issuer_phone            varchar(100),

    customer_name           text,
    customer_tax_id         varchar(50),
    customer_branch_code    varchar(50),
    customer_address        text,
    customer_phone          varchar(100),

    total_amount            numeric(18,2),
    amount_text             text,
    processing_status       varchar(30) NOT NULL DEFAULT 'EXTRACTED' CHECK (
                                processing_status IN ('EXTRACTED', 'NEEDS_REVIEW')
                            ),
    created_at              timestamptz NOT NULL DEFAULT now(),
    updated_at              timestamptz NOT NULL DEFAULT now()
);

DROP TRIGGER IF EXISTS documents_assign_id ON documents;
CREATE TRIGGER documents_assign_id
BEFORE INSERT ON documents
FOR EACH ROW
EXECUTE FUNCTION assign_document_id();

CREATE INDEX IF NOT EXISTS documents_source_file_idx
    ON documents (source_file_id);

CREATE INDEX IF NOT EXISTS documents_type_number_idx
    ON documents (document_type, document_number);

-- รายการย่อยใช้ document_id + line_number เป็นรหัสร่วมกัน
CREATE TABLE IF NOT EXISTS document_line_items (
    document_id         varchar(20) NOT NULL REFERENCES documents(document_id) ON DELETE CASCADE,
    line_number         integer NOT NULL CHECK (line_number > 0),
    description         text,
    quantity            numeric(18,4),
    unit_name           varchar(50),
    goods_unit_price    numeric(18,2),
    labor_unit_price    numeric(18,2),
    line_total          numeric(18,2),
    created_at          timestamptz NOT NULL DEFAULT now(),
    PRIMARY KEY (document_id, line_number)
);

-- ใช้เฉพาะเมื่อ document_type เป็น BILLING_NOTE
CREATE TABLE IF NOT EXISTS billing_note_entries (
    document_id                 varchar(20) NOT NULL REFERENCES documents(document_id) ON DELETE CASCADE,
    line_number                 integer NOT NULL CHECK (line_number > 0),
    invoice_number              varchar(100),
    invoice_date                date,
    purchase_order_contract_no  varchar(100),
    amount                      numeric(18,2),
    created_at                  timestamptz NOT NULL DEFAULT now(),
    PRIMARY KEY (document_id, line_number)
);
