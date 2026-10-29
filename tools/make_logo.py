"""Monta o logo do Road Rush 3D a partir das peças renderizadas por tests/logo.tscn.

Uso: python3 tools/make_logo.py <pasta_com_pecas> <pasta_saida>
Peças esperadas: chicken.png, scene.png, coin.png (1024x1024, fundo transparente).
Gera: icon-1024.png, icon-512.png, icon_foreground.png (432), icon_background.png (432).
"""
import math
import sys
from PIL import Image, ImageDraw, ImageFilter

SIZE = 1024


def sunburst(size, c1, c2, rays=18, center=(0.5, 0.42)):
    img = Image.new("RGBA", (size, size), c1)
    d = ImageDraw.Draw(img)
    cx, cy = center[0] * size, center[1] * size
    r = size * 1.6
    for i in range(rays):
        if i % 2:
            continue
        a0 = 2 * math.pi * i / rays
        a1 = 2 * math.pi * (i + 1) / rays
        d.polygon([(cx, cy), (cx + r * math.cos(a0), cy + r * math.sin(a0)),
                   (cx + r * math.cos(a1), cy + r * math.sin(a1))], fill=c2)
    glow = Image.new("RGBA", (size, size), (0, 0, 0, 0))
    g = ImageDraw.Draw(glow)
    for k in range(12, 0, -1):
        rr = size * 0.05 * k
        g.ellipse([cx - rr, cy - rr, cx + rr, cy + rr], fill=(255, 250, 220, 16))
    img.alpha_composite(glow)
    return img


def crop_alpha(im):
    return im.crop(im.getbbox())


def sticker(im, outline=18, shadow=(0, 14), shadow_alpha=110):
    """Contorno branco + sombra suave, estilo adesivo."""
    pad = outline + 40
    base = Image.new("RGBA", (im.width + pad * 2, im.height + pad * 2), (0, 0, 0, 0))
    base.alpha_composite(im, (pad, pad))
    alpha = base.split()[3].point(lambda v: 255 if v > 20 else 0)
    grown = alpha.filter(ImageFilter.MaxFilter(outline * 2 + 1))
    sh = grown.filter(ImageFilter.GaussianBlur(10)).point(lambda v: v * shadow_alpha // 255)
    out = Image.new("RGBA", base.size, (0, 0, 0, 0))
    out.paste(Image.new("RGBA", base.size, (60, 30, 0, 255)), shadow, sh)
    out.paste(Image.new("RGBA", base.size, (255, 255, 255, 255)), (0, 0), grown)
    out.alpha_composite(base)
    return out


def scale_to(im, w):
    h = int(im.height * w / im.width)
    return im.resize((w, h), Image.LANCZOS)


def speed_lines(img, box, n=7, color=(255, 255, 255, 230)):
    d = ImageDraw.Draw(img)
    x0, y0, x1, y1 = box
    for i in range(n):
        y = y0 + (y1 - y0) * (i + 0.5) / n
        length = (x1 - x0) * (0.45 + 0.55 * ((i * 37) % 10) / 10)
        d.rounded_rectangle([x1 - length, y - 7, x1, y + 7], radius=7, fill=color)


def main(parts, out):
    chicken = crop_alpha(Image.open(f"{parts}/chicken.png").convert("RGBA"))
    scene = crop_alpha(Image.open(f"{parts}/scene.png").convert("RGBA"))
    coin = crop_alpha(Image.open(f"{parts}/coin.png").convert("RGBA"))

    bg = sunburst(SIZE, (255, 196, 46, 255), (255, 170, 20, 255))
    canvas = bg.copy()

    # Rua com faixa de pedestres e carro (parte de baixo)
    road = scale_to(scene, int(SIZE * 1.1))
    rx, ry = int(SIZE * 0.06), int(SIZE * 0.6)
    # linhas de velocidade atrás (à esquerda) do carro
    speed_lines(canvas, (0, ry + int(road.height * 0.02), rx + int(road.width * 0.03), ry + int(road.height * 0.38)), n=5)
    canvas.alpha_composite(road, (rx, ry))

    # Sombra da galinha no asfalto (ela está no ar)
    sh = Image.new("RGBA", (SIZE, SIZE), (0, 0, 0, 0))
    ImageDraw.Draw(sh).ellipse([SIZE * 0.5, SIZE * 0.86, SIZE * 0.82, SIZE * 0.93], fill=(0, 0, 0, 90))
    canvas.alpha_composite(sh.filter(ImageFilter.GaussianBlur(8)))

    # Galinha saltando, grande, com contorno de adesivo
    hen = sticker(scale_to(chicken, int(SIZE * 0.52)), outline=16)
    canvas.alpha_composite(hen, (int(SIZE * 0.4), int(SIZE * 0.06)))

    # Linhas de "pulo" atrás da galinha
    d = ImageDraw.Draw(canvas)
    for i, (x, y, l) in enumerate([(0.36, 0.3, 0.1), (0.33, 0.4, 0.13), (0.36, 0.5, 0.09)]):
        d.rounded_rectangle([SIZE * (x - l), SIZE * y - 8, SIZE * x, SIZE * y + 8], radius=8, fill=(255, 255, 255, 235))

    # Moeda brilhando
    c = sticker(scale_to(coin, int(SIZE * 0.17)), outline=10, shadow_alpha=80)
    canvas.alpha_composite(c, (int(SIZE * 0.08), int(SIZE * 0.08)))
    sp = ImageDraw.Draw(canvas)
    sx, sy = SIZE * 0.3, SIZE * 0.1
    sp.polygon([(sx, sy - 34), (sx + 9, sy - 9), (sx + 34, sy), (sx + 9, sy + 9), (sx, sy + 34),
                (sx - 9, sy + 9), (sx - 34, sy), (sx - 9, sy - 9)], fill=(255, 255, 255, 255))

    canvas = canvas.convert("RGB")
    canvas.save(f"{out}/icon-1024.png")
    canvas.resize((512, 512), Image.LANCZOS).save(f"{out}/icon-512.png")

    # Ícone adaptativo do Android: fundo (raios) + frente (galinha dentro da área segura)
    bg.convert("RGB").resize((432, 432), Image.LANCZOS).save(f"{out}/icon_background.png")
    fg = Image.new("RGBA", (432, 432), (0, 0, 0, 0))
    hen_fg = sticker(scale_to(chicken, 230), outline=8, shadow=(0, 6))
    fg.alpha_composite(hen_fg, ((432 - hen_fg.width) // 2, (432 - hen_fg.height) // 2))
    fg.save(f"{out}/icon_foreground.png")


if __name__ == "__main__":
    main(sys.argv[1], sys.argv[2])
