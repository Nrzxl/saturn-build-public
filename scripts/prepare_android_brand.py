#!/usr/bin/env python3
"""Install the established SATURN PWA logo as the native Android launcher.

Flutter's Android directory is generated during CI. We regenerate launcher
assets from SATURN's existing, offline, stdlib-only PWA pixel renderer, then
install a white monochrome notification icon and the Android method channel.
No API keys or external icon resources are needed.
"""
from __future__ import annotations

from pathlib import Path
import shutil
import xml.etree.ElementTree as ET

from create_pwa_icons import draw

ROOT = Path(__file__).resolve().parents[1]
RES = ROOT / "android/app/src/main/res"
ANDROID_NS = "http://schemas.android.com/apk/res/android"
ET.register_namespace("android", ANDROID_NS)


def main() -> None:
    source = ROOT / "web/saturn-icon.svg"
    if not source.is_file() or "SATURN" not in source.read_text(encoding="utf-8"):
        raise SystemExit("SATURN's canonical visual reference is missing")
    manifest = ROOT / "android/app/src/main/AndroidManifest.xml"
    if not manifest.is_file():
        raise SystemExit("Run flutter create --platforms=android first")

    # Same image generator as the installed PWA, at each Android density.
    for density, size in (("mdpi", 48), ("hdpi", 72), ("xhdpi", 96),
                          ("xxhdpi", 144), ("xxxhdpi", 192)):
        draw(size, RES / f"mipmap-{density}" / "ic_launcher.png")

    drawable = RES / "drawable"
    drawable.mkdir(parents=True, exist_ok=True)
    (drawable / "ic_stat_saturn.xml").write_text(
        """<vector xmlns:android="http://schemas.android.com/apk/res/android"
 android:width="24dp" android:height="24dp"
 android:viewportWidth="24" android:viewportHeight="24">
 <path android:fillColor="#FFFFFFFF"
  android:pathData="M12,6a6,6 0,1 0,0 12a6,6 0,1 0,0 -12" />
 <path android:fillColor="#00000000" android:strokeColor="#FFFFFFFF"
  android:strokeWidth="2" android:strokeLineCap="round"
  android:pathData="M2,15 C6,20 18,18 22,9" />
</vector>
""", encoding="utf-8")
    tree = ET.parse(manifest)
    root = tree.getroot()
    tag = "{" + ANDROID_NS + "}"
    attribute = tag + "name"
    existing = {node.get(attribute)
                for node in root.findall("uses-permission")}
    for permission in ("android.permission.INTERNET",
                       "android.permission.POST_NOTIFICATIONS"):
        if permission not in existing:
            ET.SubElement(root, "uses-permission", {attribute: permission})
    app = root.find("application")
    if app is None:
        raise SystemExit("Unexpected AndroidManifest: application missing")
    app.set(tag + "label", "SATURN")
    app.set(tag + "icon", "@mipmap/ic_launcher")
    app.set(tag + "roundIcon", "@mipmap/ic_launcher")
    tree.write(manifest, encoding="utf-8", xml_declaration=True)

    native = ROOT / "tool/android/SaturnMainActivity.kt"
    target = ROOT / "android/app/src/main/kotlin/com/example/saturn_app/MainActivity.kt"
    target.parent.mkdir(parents=True, exist_ok=True)
    shutil.copyfile(native, target)
    print("SATURN installed: identical PWA/APK icon and native notice channel")


if __name__ == "__main__":
    main()
