# vibe-coding/scripts

Small utilities and scaffolds used during development.

## Deploy as a website (GitHub Pages)

This repo includes a Flutter web app scaffold in `capy_flutter_scaffold/`.

Publish steps (one-time):

1. Push this repo to GitHub (default branch: `main`).
2. In GitHub repo settings:
   - `Settings` -> `Pages`
   - `Build and deployment` -> `Source`: select `GitHub Actions`
3. Push to `main` and wait for the workflow `Deploy Flutter Web to GitHub Pages`.

The site URL will be:
- Project pages: `https://<owner>.github.io/<repo>/`
- If the repo name ends with `.github.io`, it will deploy as a user site: `https://<owner>.github.io/`

## Node scripts (Playwright)

Prereqs:
- Node.js 18+ recommended

Install deps:

```bash
npm ci
```

First-time Playwright setup (installs browser binaries):

```bash
npx playwright install
```

Run scripts:

```bash
node download_images_from_list.js
node download_xhs_graphic_text.js
```

Inputs/outputs:
- `urls.json` is an input list (tracked).
- Generated outputs like `download_result.json` are ignored by git.

## Flutter scaffold

See `capy_flutter_scaffold/README.md`.
