// Lightweight image downloader (no Playwright required)
// Reads a JSON file of image URLs and downloads them to /xiaohongshu_images if writable,
// otherwise falls back to ./xiaohongshu_images. Preserves file extensions and deduplicates.

const fs = require('fs');
const path = require('path');
const urlModule = require('url');
const http = require('http');
const https = require('https');

async function downloadImage(src, dest) {
  const url = new urlModule.URL(src);
  const proto = url.protocol === 'https:' ? https : http;
  return new Promise((resolve, reject) => {
    const req = proto.get(src, (res) => {
      if (res.statusCode && res.statusCode >= 400) {
        res.resume();
        return reject(new Error(`HTTP ${res.statusCode} for ${src}`));
      }
      const out = fs.createWriteStream(dest);
      res.pipe(out);
      out.on('finish', () => {
        out.close(() => resolve(true));
      });
    });
    req.on('error', (e) => reject(e));
  });
}

async function main() {
  const inputFile = process.argv[2] || path.resolve(process.cwd(), 'urls.json');
  let urls = [];
  try {
    const raw = fs.readFileSync(inputFile, 'utf8');
    const data = JSON.parse(raw);
    if (Array.isArray(data)) {
      urls = data.map(item => typeof item === 'string' ? { src: item } : item).filter(i => !!i.src);
    }
  } catch (e) {
    console.error('Failed to load input URLs:', e.message);
    process.exit(2);
  }
  // Deduplicate by URL
  const uniq = Array.from(new Map(urls.map(u => [u.src, u])).values());

  const outDirRoot = '/xiaohongshu_images';
  const outDirAlt = path.resolve(process.cwd(), 'xiaohongshu_images');
  let outputDir;
  try {
    if (!fs.existsSync('/')) {
      // unlikely in Node on Windows, but keep logic simple
    }
  } catch {}
  // Try absolute root first (if writable)
  try {
    if (!fs.existsSync(outDirRoot)) fs.mkdirSync(outDirRoot, { recursive: true });
    outputDir = outDirRoot;
  } catch {
    // Fallback to workspace-relative folder
    try {
      if (!fs.existsSync(outDirAlt)) fs.mkdirSync(outDirAlt, { recursive: true });
      outputDir = outDirAlt;
    } catch (e) {
      console.error('Failed to create output directory in both root and workspace.');
      process.exit(3);
    }
  }

  const results = [];
  for (const item of uniq) {
    try {
      const src = item.src;
      if (!src) continue;
      const u = new URL(src);
      const extFromPath = path.extname(u.pathname) || '';
      const ext = extFromPath || '.jpg';
      const safeName = 'xhs_' + Buffer.from(src).toString('base64').replace(/[^a-z0-9]/gi, '_').slice(0, 24) + ext;
      const destPath = path.join(outputDir, safeName);
      // Skip if already exists and non-empty
      if (fs.existsSync(destPath)) {
        const stat = fs.statSync(destPath);
        if (stat.size > 0) {
          results.push({ path: destPath, src });
          continue;
        } else {
          fs.unlinkSync(destPath);
        }
      }
      await downloadImage(src, destPath);
      const stat = fs.statSync(destPath);
      if (stat.size > 0) {
        results.push({ path: destPath, src });
      } else {
        fs.unlinkSync(destPath);
      }
    } catch (e) {
      // ignore individual failures but continue
      continue;
    }
  }

  console.log(JSON.stringify({ downloaded: results.length, files: results }, null, 2));
}

main().catch(err => {
  console.error('Fatal error:', err.message);
  process.exit(1);
});
