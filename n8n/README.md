# n8n workflow

ระบบหลักใช้ Typhoon OCR เพียง workflow เดียว

```text
Webhook -> Typhoon OCR -> AI Agent -> Validate Document -> Normalize Date
        -> Insert Source File -> Insert Document
        -> แยกใบวางบิล/เอกสารทั่วไป
        -> Split รายการ -> Insert รายการ -> Return Result
```

- OCR: `scb10x/typhoon-ocr1.5-3b:latest`
- AI Agent: `scb10x/llama3.1-typhoon2-8b-instruct:latest`
- Structured Output Parser: บังคับรูปแบบ JSON ก่อนบันทึก
- PostgreSQL: ใช้ Insert operation และ map ค่าจาก JSON ตามคอลัมน์
- ไฟล์นำเข้า workflow: `typhoon-document-workflow-before-benchmarks.json`

## การตรวจข้อมูลก่อนบันทึก

- ใช้หัวเอกสารจากข้อความ OCR เป็นหลักในการกำหนดประเภท
- ป้องกัน AI นำชื่อไฟล์หรือหัวตารางมาใช้เป็นเลขเอกสาร
- ไม่คำนวณยอดรวมขึ้นมาเมื่อเอกสารไม่ได้พิมพ์ยอดรวม
- ตั้ง `NEEDS_REVIEW` เมื่อข้อมูลสำคัญหายหรือยอดรวมไม่ตรงกับผลรวมรายการ
- ใบวางบิลมี fallback อ่านแถวตาราง HTML เมื่อ AI ไม่คืนรายการ

## ตารางที่บันทึก

1. `source_files`
2. `documents`
3. `document_line_items`
4. `billing_note_entries`

ใบเสนอราคา ใบแจ้งหนี้ และใบเสร็จบันทึกรายการใน
`document_line_items` ส่วนใบวางบิลบันทึก invoice ใน
`billing_note_entries`

## นำเข้าและตั้งค่า

เปิด n8n แล้วเลือกเมนู `⋯ → Import from File` และเลือกไฟล์ workflow ข้างต้น
จากนั้นสร้าง credentials และเลือกให้ nodes ดังนี้:

- `Typhoon2 8B - JSON Model`: Ollama Base URL `http://ollama:11434`
- `Insert Source File`, `Insert Document`, `Insert Line Items`, `Insert Billing Entries`:
  PostgreSQL Host `postgres`, Port `5432`, Database `idp`, User `idp`,
  Password ตาม `POSTGRES_PASSWORD` ใน `.env` และ SSL ปิดสำหรับ Docker ภายในเครื่อง

Workflow มี 18 nodes และใช้ `source_file_id` / `document_id` ตรงกับ schema
ฐานข้อมูลสร้าง ID ให้เอง ไม่ต้องใส่ ID ว่างในช่อง mapping ของ Insert

เลือก `Listen for test event` (หรือ `Execute workflow` ตามเวอร์ชัน n8n)
แล้วส่งไฟล์เป็น multipart field ชื่อ `file` ไปที่
`http://localhost:5678/webhook-test/typhoon-ocr`

เมื่อเผยแพร่/เปิดใช้งาน workflow ให้ใช้
`http://localhost:5678/webhook/typhoon-ocr`
