# Typhoon OCR service

บริการ OCR หลักของโปรเจกต์ใช้ Typhoon OCR ผ่าน Ollama เพียงตัวเดียว

## ลำดับการทำงาน

1. `ocr-server.js` รับ PDF หรือรูปภาพจาก n8n
2. `pdf-image-utils.js` แปลง PDF เป็น PNG ทีละหน้า
3. `typhoon-ocr.js` ส่งแต่ละหน้าให้ Typhoon OCR
4. รวมข้อความทุกหน้าแล้วคืน JSON ให้ n8n AI Agent

## Endpoint

```text
POST /typhoon-ocr
multipart field: file
รองรับ: PDF และรูปภาพ
```

ตัวอย่าง response:

```json
{
  "success": true,
  "filename": "document.pdf",
  "model": "scb10x/typhoon-ocr1.5-3b:latest",
  "page_count": 1,
  "text": "ข้อความ OCR"
}
```

## Flow

```text
PDF/รูปภาพ
    |
    v
ocr-server.js
    |
    v
pdf-image-utils.js
    |
    v
typhoon-ocr.js
    |
    v
JSON response -> n8n AI Agent
```

ตั้งค่า `OLLAMA_URL` ได้เมื่อรันนอก Docker (ค่าเริ่มต้น `http://ollama:11434`)
และตั้งค่า `TYPHOON_OCR_MODEL` ได้เมื่อต้องการระบุชื่อ Typhoon checkpoint
ขนาดไฟล์สูงสุดเริ่มต้น 20 MB ปรับได้ด้วย `MAX_FILE_SIZE_MB`

ทดสอบโค้ดด้วย `npm test` และตรวจบริการด้วย `GET /health`
