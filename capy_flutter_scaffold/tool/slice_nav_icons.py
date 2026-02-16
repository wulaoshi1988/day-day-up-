from __future__ import annotations

from pathlib import Path
import sys


def main() -> int:
    try:
        from PIL import Image
    except Exception:
        print("Pillow is required: pip install pillow")
        return 1

    source = Path(sys.argv[1]) if len(sys.argv) > 1 else Path("assets/icons/nav/nav_source.png")
    out_dir = Path("assets/icons/nav")
    out_dir.mkdir(parents=True, exist_ok=True)

    if not source.exists():
        print(f"Source image not found: {source}")
        print("Usage: python tool/slice_nav_icons.py <source-image-path>")
        return 1

    img = Image.open(source).convert("RGBA")
    w, h = img.size

    # Layout based on provided 1024x560 design:
    # top row: 3 cards, bottom row: 2 cards centered.
    # Boxes are normalized to keep script robust across resized inputs.
    boxes = {
        "nav_plan_active.png": (0.00, 0.00, 0.32, 0.49),
        "nav_timer_active.png": (0.34, 0.00, 0.66, 0.49),
        "nav_parent_active.png": (0.68, 0.00, 1.00, 0.49),
        "nav_score_active.png": (0.17, 0.52, 0.49, 1.00),
        "nav_growth_active.png": (0.51, 0.52, 0.83, 1.00),
    }

    for name, (x1, y1, x2, y2) in boxes.items():
        crop = img.crop((int(w * x1), int(h * y1), int(w * x2), int(h * y2)))
        icon = crop.resize((96, 96), Image.Resampling.LANCZOS)
        icon.save(out_dir / name)

    print("Generated nav icons:")
    for filename in sorted(boxes):
        print(f"- {out_dir / filename}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
