#!/usr/bin/env python3
"""
Generate invite QR codes with center emoji badges.

Outputs:
- assets/qr/qr-normal-dog.png
- assets/qr/qr-bibbione-island.png

Examples:
  python3 tool/generate_invite_qr.py \\
    --normal-url 'https://appclip.apple.com/id?p=com.artrosicase.artrosicane.Clip&location=normal' \\
    --bibbione-url 'https://appclip.apple.com/id?p=com.artrosicase.artrosicane.Clip&location=bibione'
"""

from __future__ import annotations

import argparse
import pathlib
import secrets
import sys
import urllib.parse
import urllib.request

from PIL import Image, ImageDraw, ImageOps

try:
    import qrcode
except ImportError as exc:  # pragma: no cover
    raise SystemExit(
        "Missing dependency 'qrcode'.\n"
        "Create a venv and install with:\n"
        "  python3 -m venv .venv\n"
        "  . .venv/bin/activate\n"
        "  pip install qrcode[pil]"
    ) from exc


TWEMOJI_BASE = "https://cdn.jsdelivr.net/gh/twitter/twemoji@14.0.2/assets/72x72"


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser(description="Generate 2 invite QR codes.")
    parser.add_argument(
        "--domain",
        default="artrosicane.vercel.app",
        help="Invite domain host (default: artrosicane.vercel.app)",
    )
    parser.add_argument(
        "--normal-token",
        default=f"test-normal-{secrets.token_urlsafe(8)}",
        help="Token for normal QR",
    )
    parser.add_argument(
        "--bibbione-token",
        default=f"test-bibbione-{secrets.token_urlsafe(8)}",
        help="Token for Bibbione QR",
    )
    parser.add_argument(
        "--out-dir",
        default="assets/qr",
        help="Output directory",
    )
    parser.add_argument(
        "--normal-url",
        help="Explicit URL to embed in the normal QR. Overrides token/domain options.",
    )
    parser.add_argument(
        "--bibbione-url",
        help="Explicit URL to embed in the Bibbione QR. Overrides token/domain options.",
    )
    parser.add_argument(
        "--url-format",
        choices=("path", "query"),
        default="path",
        help="Invite URL format. 'path' => /i/{token}/{location?}, 'query' => /i?t=...&location=... (default: path)",
    )
    return parser.parse_args()


def build_url(domain: str, token: str, location: str | None = None, *, url_format: str = "path") -> str:
    if url_format == "path":
        base = f"https://{domain}/i/{urllib.parse.quote(token, safe='')}"
        if location:
            base += f"/{urllib.parse.quote(location, safe='')}"
        return base

    params = {"t": token}
    if location:
        params["location"] = location
    return f"https://{domain}/i?{urllib.parse.urlencode(params)}"


def emoji_to_filename(codepoints: list[int]) -> str:
    return "-".join(f"{cp:x}" for cp in codepoints) + ".png"


def load_twemoji(emoji: str, cache_dir: pathlib.Path) -> Image.Image:
    cache_dir.mkdir(parents=True, exist_ok=True)
    cps = [ord(ch) for ch in emoji]
    variants = [
        cps,
        [cp for cp in cps if cp != 0xFE0F],  # fallback without variation selector
    ]

    for variant in variants:
        if not variant:
            continue
        filename = emoji_to_filename(variant)
        cached = cache_dir / filename
        if not cached.exists():
            url = f"{TWEMOJI_BASE}/{filename}"
            try:
                urllib.request.urlretrieve(url, cached)
            except Exception:
                continue
        return Image.open(cached).convert("RGBA")

    raise RuntimeError(f"Unable to download emoji asset for '{emoji}'")


def make_qr_with_emoji(url: str, emoji: str, out_path: pathlib.Path, cache_dir: pathlib.Path) -> None:
    qr = qrcode.QRCode(
        error_correction=qrcode.constants.ERROR_CORRECT_H,
        box_size=16,
        border=4,
    )
    qr.add_data(url)
    qr.make(fit=True)
    img = qr.make_image(fill_color="black", back_color="white").convert("RGBA")

    icon = load_twemoji(emoji, cache_dir)
    size = img.size[0]
    badge_size = int(size * 0.24)
    icon_size = int(size * 0.16)

    badge = Image.new("RGBA", (badge_size, badge_size), (255, 255, 255, 0))
    draw = ImageDraw.Draw(badge)
    draw.ellipse((0, 0, badge_size - 1, badge_size - 1), fill=(255, 255, 255, 255), outline=(0, 0, 0, 32), width=2)

    icon = ImageOps.contain(icon, (icon_size, icon_size))
    badge.paste(icon, ((badge_size - icon.width) // 2, (badge_size - icon.height) // 2), icon)

    x = (size - badge_size) // 2
    y = (size - badge_size) // 2
    img.paste(badge, (x, y), badge)

    out_path.parent.mkdir(parents=True, exist_ok=True)
    img.save(out_path)


def main() -> int:
    args = parse_args()
    out_dir = pathlib.Path(args.out_dir)
    cache_dir = out_dir / ".emoji-cache"

    normal_url = args.normal_url or build_url(
        args.domain,
        args.normal_token,
        url_format=args.url_format,
    )
    bibbione_url = args.bibbione_url or build_url(
        args.domain,
        args.bibbione_token,
        "bibione",
        url_format=args.url_format,
    )

    normal_file = out_dir / "qr-normal-dog.png"
    bibbione_file = out_dir / "qr-bibbione-island.png"

    make_qr_with_emoji(normal_url, "🐶", normal_file, cache_dir)
    make_qr_with_emoji(bibbione_url, "🏝️", bibbione_file, cache_dir)

    print(f"Normal QR:    {normal_file}")
    print(f"Bibbione QR:  {bibbione_file}")
    print("")
    print("Embedded URLs:")
    print(f"- normal:   {normal_url}")
    print(f"- bibbione: {bibbione_url}")
    return 0


if __name__ == "__main__":
    sys.exit(main())
