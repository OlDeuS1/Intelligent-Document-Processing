const express = require('express');
const Tesseract = require('tesseract.js');
const { pdf } = require('pdf-to-img');
const fs = require('fs');

const app = express();
app.use(express.json({ limit: '50mb' }));

app.post('/ocr-pdf', async (req, res) => {
  try {
    const { file } = req.body;
    const pdfBuffer = Buffer.from(file, 'base64');

    // บันทึก PDF ชั่วคราว
    fs.writeFileSync('temp.pdf', pdfBuffer);

    // แปลง PDF → รูป แล้ว OCR
    let fullText = '';
    let pageNum = 1;

    for await (const image of await pdf('temp.pdf', { scale: 3 })) {
      const { data: { text } } = await Tesseract.recognize(image, 'eng+tha');
      fullText += `--- Page ${pageNum++} ---\n${fixThaiText(text)}\n\n`;
    }

    fs.unlinkSync('temp.pdf'); // ลบไฟล์ชั่วคราว
    res.json({ success: true, text: fullText });
  } catch (err) {
    res.status(500).json({ success: false, error: err.message });
  }
});

app.listen(3001, () => console.log('OCR server ready at http://localhost:3001'));

function fixThaiText(text) {
  return text
    .replace(/([ก-๙])\s+(?=[ก-๙\u0E00-\u0E7F])/g, '$1') // ลบ space ระหว่างอักษรไทย
    .replace(/([ก-๙])\s+([\u0E30-\u0E4E])/g, '$1$2')      // ลบ space ระหว่างตัวอักษรกับสระ/วรรณยุกต์
    .trim();
}