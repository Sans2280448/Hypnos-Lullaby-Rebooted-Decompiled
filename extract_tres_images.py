#!/usr/bin/env python3
"""
Extract PNG images from Godot AtlasTexture .tres files.

Behavior:
- Recursively scans `images/**/*.tres` (fallback to `atlases/**/*.tres`)
- Reads atlas image path from `ext_resource ... path="res://..."`
- Reads crop rectangle from `region = Rect2(x, y, w, h)`
- Optionally restores transparent padding from `margin = Rect2(l, t, r, b)`
- Writes output PNG next to each .tres file using same base name
"""

from __future__ import annotations

import re
import sys
from pathlib import Path

from PIL import Image


EXT_RESOURCE_RE = re.compile(r'^\[ext_resource[^\]]*path="([^"]+)"')
RECT2_RE_TEMPLATE = r"^{key}\s*=\s*Rect2\(\s*([-0-9.]+)\s*,\s*([-0-9.]+)\s*,\s*([-0-9.]+)\s*,\s*([-0-9.]+)\s*\)"
SOURCE_FILE_RE = re.compile(r'^source_file="([^"]+)"')


def parse_rect2(text: str, key: str) -> tuple[float, float, float, float] | None:
    pattern = re.compile(RECT2_RE_TEMPLATE.format(key=re.escape(key)))
    for line in text.splitlines():
        match = pattern.match(line.strip())
        if match:
            return tuple(float(match.group(i)) for i in range(1, 5))
    return None


def parse_ext_resource_path(text: str) -> str | None:
    for line in text.splitlines():
        match = EXT_RESOURCE_RE.match(line.strip())
        if match:
            return match.group(1)
    return None


def resolve_res_path(project_root: Path, res_path: str) -> Path:
    if not res_path.startswith("res://"):
        raise ValueError(f"Unsupported resource path: {res_path}")
    return project_root / res_path.replace("res://", "", 1)


def parse_source_file_from_import(import_file: Path) -> str | None:
    try:
        text = import_file.read_text(encoding="utf-8", errors="ignore")
    except OSError:
        return None
    for line in text.splitlines():
        match = SOURCE_FILE_RE.match(line.strip())
        if match:
            return match.group(1)
    return None


def resolve_atlas_image_path(project_root: Path, atlas_res: str) -> tuple[Path | None, str | None]:
    atlas_path = resolve_res_path(project_root, atlas_res)
    if atlas_path.exists():
        return atlas_path, None

    import_path = Path(f"{atlas_path}.import")
    if import_path.exists():
        source_res = parse_source_file_from_import(import_path)
        if source_res:
            source_path = resolve_res_path(project_root, source_res)
            if source_path.exists():
                return source_path, None
        return (
            None,
            f"atlas source missing: {atlas_path} (found only import metadata: {import_path})",
        )

    return None, f"atlas image not found: {atlas_path}"


def clamp_int_rect(x: float, y: float, w: float, h: float) -> tuple[int, int, int, int]:
    xi, yi = int(round(x)), int(round(y))
    wi, hi = int(round(w)), int(round(h))
    if wi <= 0 or hi <= 0:
        raise ValueError(f"Invalid region size: ({wi}, {hi})")
    return xi, yi, wi, hi


def restore_margin(cropped: Image.Image, margin: tuple[float, float, float, float] | None) -> Image.Image:
    if margin is None:
        return cropped

    left, top, right, bottom = (int(round(v)) for v in margin)
    if min(left, top, right, bottom) < 0:
        # Negative margins are unusual; keep cropped image in this case.
        return cropped

    out_w = cropped.width + left + right
    out_h = cropped.height + top + bottom
    if out_w <= 0 or out_h <= 0:
        return cropped

    restored = Image.new("RGBA", (out_w, out_h), (0, 0, 0, 0))
    restored.paste(cropped, (left, top))
    return restored


def extract_one(tres_path: Path, project_root: Path) -> tuple[bool, str]:
    text = tres_path.read_text(encoding="utf-8", errors="ignore")

    atlas_res = parse_ext_resource_path(text)
    if not atlas_res:
        return False, "missing ext_resource path"

    region = parse_rect2(text, "region")
    if not region:
        return False, "missing region Rect2"

    margin = parse_rect2(text, "margin")

    atlas_path, path_error = resolve_atlas_image_path(project_root, atlas_res)
    if atlas_path is None:
        return False, path_error or "atlas image resolution failed"

    try:
        atlas_img = Image.open(atlas_path).convert("RGBA")
    except Exception as exc:  # noqa: BLE001
        return False, f"failed to open atlas: {exc}"

    try:
        x, y, w, h = clamp_int_rect(*region)
        cropped = atlas_img.crop((x, y, x + w, y + h))
        output = restore_margin(cropped, margin)
    except Exception as exc:  # noqa: BLE001
        return False, f"failed to crop: {exc}"

    output_path = tres_path.with_suffix(".png")
    output.save(output_path)
    return True, str(output_path)


def main() -> int:
    project_root = Path(__file__).resolve().parent
    candidates = [project_root / "assets", project_root / "atlases"]
    scan_root = next((path for path in candidates if path.exists()), None)
    if scan_root is None:
        print("[ERROR] scan root not found. Checked:")
        for candidate in candidates:
            print(f"  - {candidate}")
        return 1

    tres_files = sorted(scan_root.rglob("*.tres"))
    if not tres_files:
        print(f"[WARN] no .tres files found under: {scan_root}")
        return 0

    ok_count = 0
    fail_count = 0

    for tres_file in tres_files:
        ok, info = extract_one(tres_file, project_root)
        if ok:
            ok_count += 1
            print(f"[OK]   {tres_file} -> {info}")
        else:
            fail_count += 1
            print(f"[FAIL] {tres_file}: {info}")

    print(f"\nDone. success={ok_count}, failed={fail_count}, total={len(tres_files)}")
    return 0 if fail_count == 0 else 2


if __name__ == "__main__":
    sys.exit(main())
