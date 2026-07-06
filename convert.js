const fs = require('fs');
const { execSync } = require('child_process');

const filePath = process.argv[2];
const fileBuffer = fs.readFileSync(filePath);
const base64 = fileBuffer.toString('base64');

// เขียนไฟล์ชั่วคราวแล้ว clip
fs.writeFileSync('temp_base64.txt', base64);
execSync('clip < temp_base64.txt');
fs.unlinkSync('temp_base64.txt');

console.log('Copied to clipboard!');