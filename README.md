# Intelligent Document Processing

รับ PDF/รูปภาพ → Typhoon OCR → n8n AI Agent จัด JSON → PostgreSQL
รองรับใบเสนอราคา ใบแจ้งหนี้ ใบเสร็จรับเงิน และใบวางบิล

## สิ่งที่ต้องติดตั้ง

- Docker Desktop พร้อม Docker Compose
- NVIDIA GPU และการใช้งาน GPU ใน Docker สำหรับ Ollama ตาม compose นี้
- โมเดล Typhoon OCR 3B และ Typhoon2 8B (ดาวน์โหลดในขั้นตอนด้านล่าง)

## เริ่มใช้งาน

1. คัดลอก `.env.example` เป็น `.env` แล้วตั้ง `POSTGRES_PASSWORD`
2. เปิด Docker Desktop และเริ่ม Ollama:

   ```powershell
   docker compose up -d ollama
   docker compose exec ollama ollama pull scb10x/typhoon-ocr1.5-3b:latest
   docker compose exec ollama ollama pull scb10x/llama3.1-typhoon2-8b-instruct:latest
   ```

3. เริ่มบริการทั้งหมด:

   ```powershell
   docker compose up -d --build
   ```

4. เปิด `http://localhost:5678` สร้างบัญชี n8n แล้วนำเข้า
   `n8n/typhoon-document-workflow-before-benchmarks.json`
5. ตั้ง Ollama/PostgreSQL credentials ตาม [คู่มือ workflow](n8n/README.md)
6. เปิดรับ test event ใน workflow และส่งเอกสาร:

   ```powershell
   curl.exe -X POST -F "file=@C:/path/document.pdf" http://localhost:5678/webhook-test/typhoon-ocr
   ```

ไฟล์ `.env` และข้อมูลเอกสารใช้เฉพาะในเครื่อง ฐานข้อมูลและโมเดลเก็บใน Docker volumes
`database/schema.sql` สร้าง 4 ตารางเมื่อ PostgreSQL volume เริ่มใช้งานครั้งแรก
หากใช้ volume ที่มี schema เก่าอยู่แล้ว ให้ตรวจชื่อคอลัมน์กับ schema ก่อนนำเข้า workflow

## โครงสร้างโค้ด

| ไฟล์/โฟลเดอร์ | หน้าที่ |
|---|---|
| `ocr-service/` | รับไฟล์ แปลง PDF เป็นรูป และเรียก Typhoon OCR |
| `database/schema.sql` | ตารางไฟล์ เอกสาร รายการสินค้า และรายการใบวางบิล |
| `n8n/` | Workflow ที่ใช้ Typhoon และ PostgreSQL พร้อมวิธีตั้งค่า |
| `docker-compose.yml` | n8n, OCR service, PostgreSQL และ Ollama |

ดู [OCR service](ocr-service/README.md) และ [ฐานข้อมูล](database/README.md)
ทดสอบโค้ดด้วย `npm install` แล้ว `npm test`
