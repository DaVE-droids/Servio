# Swapping in the real logo

Everything branded today comes from one placeholder mark: a route curving
from a start stop to a finishing ring (the placement journey). Replacing it
takes two commands.

## Where the mark appears

| Place | Source |
|---|---|
| Inside the app (sign-in panel, app bar, sidebar, splash) | `BrandMark` / `BrandLockup`, drawn in code: `lib/core/widgets/brand_mark.dart` |
| App icons (iOS + Android) | `assets/brand/app_icon.png`, `assets/brand/app_icon_foreground.png` |
| Native launch screen | `assets/brand/splash_mark.png` |
| Browser tab and web app icons | `web/favicon.svg`, `web/favicon.png`, `web/icons/*` |
| The instant loading screen on the website | an inline SVG copy in `web/index.html` |

## With a designer's files

1. Replace these, keeping the names and sizes:
   - `assets/brand/app_icon.png` — 1024×1024, **no transparency**, no
     rounded corners (each OS masks its own shape).
   - `assets/brand/app_icon_foreground.png` — 1024×1024, transparent, with
     the artwork inside the middle ~66% (Android crops the rest).
   - `assets/brand/splash_mark.png` — 1152×1152, transparent, artwork about
     380px in the centre (Android 12 masks it to a circle).
   - `web/favicon.svg`, `web/favicon.png` (48×48),
     `web/icons/Icon-192.png`, `Icon-512.png`, the two `Icon-maskable-*`,
     and `icons/apple-touch-icon.png` (180×180, opaque).
2. Regenerate the platform files:
   ```bash
   dart run flutter_launcher_icons
   dart run flutter_native_splash:create
   ```
3. Update the in-app mark: either repaint `BrandMark` to match the new logo
   or swap it for `Image.asset('assets/brand/mark.png')`, and paste the new
   SVG into the `#app-loader` block in `web/index.html` so the loading
   screen matches.
4. If the brand colours change, update `lib/app/theme/app_colors.dart`,
   `flutter_native_splash.color` and `adaptive_icon_background` in
   `pubspec.yaml`, and `theme_color`/`background_color` in
   `web/manifest.json`.

## Just tweaking the placeholder

The generator draws every image from the same geometry as the in-app mark:

```bash
python3 -m venv .venv && .venv/bin/pip install pillow
.venv/bin/python tool/generate_brand_assets.py
dart run flutter_launcher_icons
dart run flutter_native_splash:create
```

Edit `tool/generate_brand_assets.py` (and `BrandMark` to match) and re-run.
