#!/usr/bin/env python3
"""
Generates the extended isometric tile atlas (384x128, 3 cols x 2 rows of 128x64 tiles)
for Mobile Fortress (U9 sub-pass 3).

Atlas layout:
(0, 0): Coast / Farmland (Ming grassy soil)
(1, 0): Deep Ocean (Navy indigo waters)
(2, 0): Ocean Shoals / Reef (Turquoise waters with ukiyo-e wave foam)
(0, 1): Raid Path (Stone & packed dirt road)
(1, 1): Tidal Marsh / Wetland (Brackish estuary with marsh reeds)
(2, 1): Fortress Bastion / Elevation (Cinnabar stone masonry)
"""

from PIL import Image, ImageDraw

TILE_W = 128
TILE_H = 64
COLS = 3
ROWS = 2

img = Image.new("RGBA", (COLS * TILE_W, ROWS * TILE_H), (0, 0, 0, 0))
draw = ImageDraw.Draw(img)

def get_diamond(col: int, row: int, inset: float = 0.0):
    cx = col * TILE_W + TILE_W / 2
    cy = row * TILE_H + TILE_H / 2
    hw = (TILE_W / 2) - inset
    hh = (TILE_H / 2) - inset
    return [
        (cx, cy - hh),
        (cx + hw, cy),
        (cx, cy + hh),
        (cx - hw, cy),
    ]

# 1. Tile (0,0): Ming Coast / Farmland
poly = get_diamond(0, 0)
draw.polygon(poly, fill=(68, 102, 68, 255), outline=(48, 80, 48, 255))
# Add subtle grassy texture
cx, cy = 0 * TILE_W + 64, 0 * TILE_H + 32
draw.line([(cx - 16, cy - 4), (cx - 12, cy - 12)], fill=(90, 130, 80, 255), width=2)
draw.line([(cx - 12, cy - 12), (cx - 8, cy - 4)], fill=(90, 130, 80, 255), width=2)
draw.line([(cx + 8, cy + 4), (cx + 12, cy - 4)], fill=(90, 130, 80, 255), width=2)
draw.line([(cx + 12, cy - 4), (cx + 16, cy + 4)], fill=(90, 130, 80, 255), width=2)

# 2. Tile (1,0): Deep Ocean
poly = get_diamond(1, 0)
draw.polygon(poly, fill=(36, 66, 90, 255), outline=(24, 46, 68, 255))
# Darker wave troughs
cx, cy = 1 * TILE_W + 64, 0 * TILE_H + 32
draw.arc([cx - 24, cy - 10, cx - 4, cy + 6], start=30, end=150, fill=(24, 48, 70, 255), width=2)
draw.arc([cx + 4, cy - 6, cx + 24, cy + 10], start=30, end=150, fill=(24, 48, 70, 255), width=2)

# 3. Tile (2,0): Ocean Shoals / Shallow Reef
poly = get_diamond(2, 0)
draw.polygon(poly, fill=(58, 101, 125, 255), outline=(40, 78, 98, 255))
# Turquoise water with white wave foam crests
cx, cy = 2 * TILE_W + 64, 0 * TILE_H + 32
draw.arc([cx - 20, cy - 12, cx + 4, cy + 4], start=20, end=160, fill=(230, 235, 230, 240), width=2)
draw.arc([cx - 4, cy - 4, cx + 20, cy + 12], start=20, end=160, fill=(230, 235, 230, 240), width=2)
draw.point([(cx - 10, cy - 8), (cx + 12, cy + 6)], fill=(255, 255, 255, 255))

# 4. Tile (0,1): Raid Path
poly = get_diamond(0, 1)
draw.polygon(poly, fill=(125, 117, 101, 255), outline=(95, 87, 75, 255))
# Cobblestone / path markers
cx, cy = 0 * TILE_W + 64, 1 * TILE_H + 32
draw.line([(cx - 20, cy), (cx + 20, cy)], fill=(145, 137, 120, 255), width=2)
draw.line([(cx - 10, cy - 8), (cx + 10, cy + 8)], fill=(100, 92, 80, 255), width=1)

# 5. Tile (1,1): Tidal Marsh / Estuary
poly = get_diamond(1, 1)
draw.polygon(poly, fill=(72, 94, 78, 255), outline=(50, 70, 56, 255))
# Muddy wetland with green reed stalks
cx, cy = 1 * TILE_W + 64, 1 * TILE_H + 32
draw.line([(cx - 14, cy + 6), (cx - 16, cy - 8)], fill=(110, 145, 95, 255), width=2)
draw.line([(cx - 10, cy + 8), (cx - 8, cy - 6)], fill=(110, 145, 95, 255), width=2)
draw.arc([cx + 2, cy - 4, cx + 22, cy + 8], start=20, end=160, fill=(50, 75, 65, 255), width=2)

# 6. Tile (2,1): Fortress Bastion / Elevation Foundation
poly = get_diamond(2, 1)
draw.polygon(poly, fill=(138, 75, 56, 255), outline=(100, 50, 36, 255))
# Stone battlement / foundation masonry
cx, cy = 2 * TILE_W + 64, 1 * TILE_H + 32
draw.polygon([
    (cx - 18, cy - 4),
    (cx, cy - 12),
    (cx + 18, cy - 4),
    (cx, cy + 6),
], fill=(160, 95, 75, 255), outline=(100, 50, 36, 255))
draw.line([(cx, cy - 12), (cx, cy + 6)], fill=(115, 60, 45, 255), width=2)

img.save("game/assets/iso_tiles.png")
print("Saved 384x128 iso_tiles.png with 6 distinct terrain tiles")
