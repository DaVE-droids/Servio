"""Draws Servio's placeholder brand images from the same geometry as
lib/core/widgets/brand_mark.dart, so the app icon, splash, favicon, and the
in-app mark always match.

Run once after changing the mark (needs Pillow: `pip install pillow`):
    python3 tool/generate_brand_assets.py
then regenerate the platform icons and splash:
    dart run flutter_launcher_icons
    dart run flutter_native_splash:create
See docs/BRANDING.md. When the final logo arrives, replace the PNGs in
assets/brand/ with the designer's files instead and run the two commands.
"""

from pathlib import Path

from PIL import Image, ImageDraw

INK = (0x16, 0x36, 0x5C, 255)
SKY = (0xBF, 0xE5, 0xEE, 255)
BLUSH = (0xF6, 0xD0, 0xEA, 255)
WHITE = (255, 255, 255, 255)
SS = 4  # supersampling factor for smooth edges

ROOT = Path(__file__).resolve().parent.parent


def _bezier(p0, p1, p2, p3, steps=400):
    for i in range(steps + 1):
        t = i / steps
        mt = 1 - t
        x = mt**3 * p0[0] + 3 * mt**2 * t * p1[0] + 3 * mt * t**2 * p2[0] + t**3 * p3[0]
        y = mt**3 * p0[1] + 3 * mt**2 * t * p1[1] + 3 * mt * t**2 * p2[1] + t**3 * p3[1]
        yield x, y


def _draw_route(draw, x0, y0, s, route_color):
    """The route, start stop, and finish ring inside an s-by-s box at (x0, y0)."""
    stroke = s * 0.095
    r = stroke / 2
    pts = [(x0 + s * a, y0 + s * b) for a, b in [(0.30, 0.70), (0.30, 0.44), (0.70, 0.56), (0.70, 0.33)]]
    for x, y in _bezier(*pts):
        draw.ellipse([x - r, y - r, x + r, y + r], fill=route_color)
    dot = s * 0.085
    cx, cy = x0 + s * 0.30, y0 + s * 0.72
    draw.ellipse([cx - dot, cy - dot, cx + dot, cy + dot], fill=SKY)
    cx, cy = x0 + s * 0.70, y0 + s * 0.28
    ring = stroke * 0.8
    draw.ellipse([cx - dot - ring / 2, cy - dot - ring / 2, cx + dot + ring / 2, cy + dot + ring / 2], fill=BLUSH)
    inner = dot - ring / 2
    draw.ellipse([cx - inner, cy - inner, cx + inner, cy + inner], fill=INK if route_color == WHITE else WHITE)


def render(size, *, tile_fraction=1.0, rounded=True, background=None, route_only=False):
    """Returns an RGBA image of `size` px with the mark centred.

    tile_fraction: share of the canvas the tile occupies.
    rounded: rounded tile corners (False for full-bleed icons the OS masks).
    background: fill for the whole canvas, or None for transparent.
    route_only: draw only the route (Android adaptive icon foreground).
    """
    big = size * SS
    img = Image.new("RGBA", (big, big), background or (0, 0, 0, 0))
    draw = ImageDraw.Draw(img)
    tile = big * tile_fraction
    off = (big - tile) / 2
    if not route_only:
        if rounded:
            draw.rounded_rectangle([off, off, off + tile, off + tile], radius=tile * 0.28, fill=INK)
        else:
            draw.rectangle([off, off, off + tile, off + tile], fill=INK)
    _draw_route(draw, off, off, tile, WHITE)
    return img.resize((size, size), Image.LANCZOS)


def main():
    brand = ROOT / "assets" / "brand"
    web = ROOT / "web"
    brand.mkdir(parents=True, exist_ok=True)

    # Square, rounded mark for in-app/marketing use.
    render(1024).save(brand / "mark.png")
    # iOS/Android legacy icon: full-bleed ink square, no transparency.
    render(1024, rounded=False, background=INK).convert("RGB").save(brand / "app_icon.png")
    # Android adaptive icon foreground: route only, inside the 66% safe zone.
    render(1024, tile_fraction=0.62, route_only=True).save(brand / "app_icon_foreground.png")
    # Splash: mark at 384px on a 1152px transparent canvas (96dp at 4x), which
    # also fits inside Android 12's circular splash mask.
    render(1152, tile_fraction=384 / 1152).save(brand / "splash_mark.png")

    # Web.
    render(48).save(web / "favicon.png")
    icons = web / "icons"
    icons.mkdir(exist_ok=True)
    for px in (192, 512):
        render(px).save(icons / f"Icon-{px}.png")
        # Maskable: full-bleed ink so any mask shape looks intentional.
        render(px, tile_fraction=0.7, rounded=False, background=INK).save(icons / f"Icon-maskable-{px}.png")
    render(180, rounded=False, background=INK).convert("RGB").save(icons / "apple-touch-icon.png")
    print("Brand images written to assets/brand and web/.")


if __name__ == "__main__":
    main()
