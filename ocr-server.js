const express = require('express');
const Tesseract = require('tesseract.js');
const { pdf } = require('pdf-to-img');
const multer = require('multer');
const fs = require('fs');

const app = express();
const upload = multer({ storage: multer.memoryStorage() });
const port = process.env.PORT || 3001;

app.post('/ocr-pdf', upload.single('file'), async (req, res) => {
  try {
    const pdfBuffer = req.file.buffer;
    fs.writeFileSync('temp.pdf', pdfBuffer);

    let fullText = '';
    let pageNum = 1;

    try {
      for await (const image of await pdf('temp.pdf', { scale: 3 })) {
        const { data: { text } } = await Tesseract.recognize(image, 'eng+tha');
        fullText += `--- Page ${pageNum++} ---\n${fixThaiText(text.trim())}\n\n`;
      }
    } finally {
      if (fs.existsSync('temp.pdf')) fs.unlinkSync('temp.pdf');
    }

    res.json({ success: true, text: fullText });
  } catch (err) {
    res.status(500).json({ success: false, error: err.message });
  }
});

app.post('/ocr-image', upload.single('file'), async (req, res) => {
  try {
    const imageBuffer = req.file.buffer;
    const { data: { text } } = await Tesseract.recognize(imageBuffer, 'eng+tha');
    res.json({ success: true, text: fixThaiText(text.trim()) });
  } catch (err) {
    res.status(500).json({ success: false, error: err.message });
  }
});

function fixThaiText(text) {
  return text
    .replace(/([ก-๙])\s+(?=[ก-๙\u0E00-\u0E7F])/g, '$1')
    .replace(/([ก-๙])\s+([\u0E30-\u0E4E])/g, '$1$2')
    .trim();
}

app.listen(port, () => console.log(`OCR server ready at http://localhost:${port}`));