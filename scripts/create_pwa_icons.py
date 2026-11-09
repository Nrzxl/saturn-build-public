#!/usr/bin/env python3
"""Create consistent SATURN PNG PWA icons with Python stdlib (no external tools).

These are generated build assets, not source secrets or user data.
"""
from __future__ import annotations

import math
import struct
import zlib
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1] / "web"


def chunk(tag: bytes, data: bytes) -> bytes:
    return (
        struct.pack(">I", len(data))
        + tag
        + data
        + struct.pack(">I", zlib.crc32(tag + data) & 0xFFFFFFFF)
    )


def draw(size: int, destination: Path, *, maskable: bool = False) -> None:
    destination.parent.mkdir(parents=True, exist_ok=True)
    scale = 0.75 if maskable else 0.93
    raw = bytearray()
    stars = ((-0.56, -0.57, .014), (.53, -.6, .011),
             (.62, .47, .012), (-.6, .55, .009))
    c, s = math.cos(-.39), math.sin(-.39)
    for y in range(size):
        raw.append(0)
        py = (2 * (y + .5) / size - 1)
        for x in range(size):
            px = (2 * (x + .5) / size - 1)
            gradient = max(0.0, 1.0 - math.hypot(px, py) / 1.4)
            rgb = [int(23 + 33 * gradient),
                   int(17 + 20 * gradient),
                   int(33 + 29 * gradient)]
            u, v = px / scale, py / scale
            # Saturn's ring is rendered behind, then in front of the planet.
            xr, yr = (u*c + v*s), (-u*s + v*c)
            ellipse = math.hypot(xr / .80, yr / .29)
            ring = abs(ellipse - 1) < .033
            if ring:
                rgb = [int(130 + 67*gradient),
                       int(99 + 62*gradient),
                       int(112 + 34*gradient)]
            radius = math.hypot(u, v + .015)
            if radius < .37:
                highlight = max(0.0, 1.0 - math.hypot(u+.16, v+.18) / .47)
                rgb = [int(77 + 108*highlight),
                       int(38 + 73*highlight),
                       int(79 + 77*highlight)]
                rim = max(0.0, (radius-.34)/.03)
                if rim:
                    rgb = [int(a*(1-.25*rim)) for a in rgb]
            if ring and yr > .025:
                rgb = [224, 191, 140]
            for sx, sy, sr in stars:
                if math.hypot(px-sx, py-sy) < sr:
                    rgb = [248, 216, 170]
                    break
            raw.extend((max(0,min(255,n)) for n in rgb))
            raw.append(255)
    ihdr = struct.pack(">IIBBBBB", size, size, 8, 6, 0, 0, 0)
    png = (b"\x89PNG\r\n\x1a\n" + chunk(b"IHDR", ihdr)
           + chunk(b"IDAT", zlib.compress(raw, 9))
           + chunk(b"IEND", b""))
    destination.write_bytes(png)
    print(f"Generated {destination.name}: {size}x{size} ({len(png)} bytes)")


def main() -> None:
    for size in (192, 512):
        draw(size, ROOT / "icons" / f"Icon-{size}.png")
        draw(size, ROOT / "icons" / f"Icon-maskable-{size}.png",
             maskable=True)
    draw(180, ROOT / "apple-touch-icon.png")
    draw(32, ROOT / "favicon.png")


if __name__ == "__main__":
    main()
