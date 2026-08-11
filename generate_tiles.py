from PIL import Image, ImageDraw

def create_diamond(color, outline, size=(128, 64)):
    img = Image.new('RGBA', size, (0, 0, 0, 0))
    draw = ImageDraw.Draw(img)
    w, h = size
    # Diamond coordinates
    poly = [(w//2, 0), (w, h//2), (w//2, h), (0, h//2)]
    draw.polygon(poly, fill=color, outline=outline)
    return img

# Create atlas 256x128 (2x2 grid of 128x64 tiles)
atlas = Image.new('RGBA', (256, 128), (0, 0, 0, 0))

# 1. Grass (Land)
grass = create_diamond((100, 200, 100, 255), (50, 100, 50, 255))
atlas.paste(grass, (0, 0))

# 2. Water (Sea)
water = create_diamond((100, 150, 220, 255), (50, 100, 180, 255))
atlas.paste(water, (128, 0))

# 3. Path/Blocked (Cobblestone/Dirt)
path = create_diamond((150, 150, 150, 255), (100, 100, 100, 255))
atlas.paste(path, (0, 64))

atlas.save("core/assets/iso_tiles.png")
print("Saved core/assets/iso_tiles.png")
