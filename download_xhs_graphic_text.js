const fs = require('fs');
const path = require('path');
const { chromium } = require('playwright');

(async () => {
  const URL = "https://www.xiaohongshu.com/goods-detail/68f06fa5d3eed200016ea1f0?xsec_token=XBM9ydkQiTnBtLStwiqZM0tR3Egq3UthVM-1tpZbJBm6E=&xsec_source=app_share&instation_link=xhsdiscover%3A%2F%2Fgoods_detail%2F68f06fa5d3eed200016ea1f0%3Ftrade_ext%3DeyJjaGFubmVsSW5mbyI6bnVsbCwiZHNUb2tlbkluZm8iOm51bGwsInNoYXJlTGluayI6Imh0dHBzOi8vd3d3LnhpYW9ob25nc2h1LmNvbS9nb29kcy1kZXRhaWwvNjhmMDZmYTVkM2VlZDIwMDAxNmVhMWYwP2FwcHVpZD01ZDMwNTQzYTAwMDAwMDAwMTIwMTA4YzciLCJsaXZlSW5mbyI6bnVsbCwic2hvcEluZm8iOm51bGwsImdvb2RzTm90ZUluZm8iOm51bGwsImNoYXRJbmZvIjpudWxsLCJzZWFyY2hJbmZvIjpudWxsLCJwcmVmZXIiOm51bGx9%26rate_limit_meta%3DitemId%253D68f06fa5d3eed200016ea1ef%26source%3D%26back_chain_id%3Dgoods_detail_share%26rn%3Dtrue&xhsshare=CopyLink&appuid=5d30543a00000000120108c7&apptime=1770953616&share_id=0231e2ac560b466daa25de8975ab4d55";
  const outDir = path.resolve(process.cwd(), "xiaohongshu_images");
  if (!fs.existsSync(outDir)) {
    fs.mkdirSync(outDir, { recursive: true });
  }

  const browser = await chromium.launch({ headless: true });
  const context = await browser.newContext();
  const page = await context.newPage();

  try {
    await page.goto(URL, { waitUntil: "networkidle" });

    // Allow dynamic content to render and initiate lazy loading
    await page.waitForTimeout(1000);

    // Scroll to trigger lazy-loaded images in the detail section
    for (let i = 0; i < 12; i++) {
      await page.evaluate(() => window.scrollBy(0, window.innerHeight * 0.8));
      await page.waitForTimeout(800);
    }

    // Collect image URLs inside the graphic-text detail container, if present
    const imageUrls = await page.evaluate(() => {
      // Try common containers for Xiaohongshu graphic-text sections
      const root = document.querySelector('.graphic-text-detail, .graphic-text, .goods-detail, [data-qa="goods-detail"], [data-hint="graphic-text"]');
      const imgs = root ? root.querySelectorAll('img') : Array.from(document.querySelectorAll('img'));
      const urls = Array.from(imgs).map(img => img.src).filter(Boolean);
      // De-duplicate
      const uniq = Array.from(new Set(urls));
      // Keep only HTTP(S) and common image extensions
      const filtered = uniq.filter(u => {
        try {
          const ext = (new URL(u).pathname.split('.').pop() || '').toLowerCase();
          return ['jpg','jpeg','png','webp','gif','bmp','svg'].includes(ext) || u.startsWith('http');
        } catch (e) {
          return false;
        }
      });
      return filtered;
    });

    const results = [];
    const writeFile = (dest, buf) => {
      fs.writeFileSync(dest, Buffer.from(buf));
    };

    for (const url of imageUrls) {
      try {
        const u = new URL(url);
        const ext = path.extname(u.pathname) || ".jpg";
        const safeName = "xhs_" + Buffer.from(url).toString("base64").replace(/[^a-z0-9]/gi, "_").slice(0, 24) + ext;
        const destPath = path.join(outDir, safeName);
        const resp = await context.request.get(url);
        const buf = await resp.body();
        if (buf && buf.length > 0) {
          writeFile(destPath, buf);
          // Verify non-empty
          const stat = fs.statSync(destPath);
          if (stat.size > 0) {
            results.push({ path: destPath, src: url });
          } else {
            fs.unlinkSync(destPath);
          }
        }
      } catch (e) {
        // skip any problematic image
        continue;
      }
    }

    console.log(JSON.stringify({ downloaded: results.length, files: results }, null, 2));
  } catch (err) {
    console.error(JSON.stringify({ error: err.message }));
  } finally {
    await context.close();
    await browser.close();
  }
})();
