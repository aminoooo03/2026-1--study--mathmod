const puppeteer = require('puppeteer');
const path = require('path');

(async () => {
  const browser = await puppeteer.launch({
    executablePath: 'D:\\puppeteer-cache\\chrome\\win64-148.0.7778.97\\chrome-win64\\chrome.exe',
    headless: 'new',
    args: ['--no-sandbox', '--disable-gpu']
  });

  const page = await browser.newPage();
  await page.setViewport({ width: 1280, height: 720 });

  const htmlPath = path.join(process.cwd(), '_output', 'mathmod-lab08-presentation.html');
  const url = `file:///${htmlPath.replace(/\\/g, '/')}?print-pdf`;

  console.log('Открываю:', url);
  await page.goto(url, { waitUntil: 'networkidle0', timeout: 60000 });
  await new Promise(r => setTimeout(r, 5000));

  const pdfPath = path.join(process.cwd(), '_output', 'mathmod-lab08-presentation.pdf');
  await page.pdf({
    path: pdfPath,
    width: '1280px',
    height: '720px',
    printBackground: true,
    landscape: true,
    margin: { top: 0, right: 0, bottom: 0, left: 0 }
  });

  console.log('PDF сохранён:', pdfPath);
  await browser.close();
})();