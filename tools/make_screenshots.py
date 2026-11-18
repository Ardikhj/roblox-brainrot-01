#!/usr/bin/env python3
"""Draw the three screenshots/ images for Brainrot Bay.

These are CONCEPT MOCKUPS drawn with PIL, NOT captures of the game running
in Roblox Studio: there is no Roblox Studio on Linux, and no Studio capture
can be made here. Each image says so on its face, and the README says so too.
They exist so the entry pipeline (main.ts -> dossier.json) can be exercised
end to end; they must be replaced with real Studio captures, and one of them
with the game's uploaded Roblox thumbnail, before any submission.
"""
from PIL import Image, ImageDraw, ImageFont

W, H = 1280, 720
BOLD = "/usr/share/fonts/truetype/dejavu/DejaVuSans-Bold.ttf"
REG = "/usr/share/fonts/truetype/dejavu/DejaVuSans.ttf"


def font(size):
    return ImageFont.truetype(BOLD, size)


def reg(size):
    return ImageFont.truetype(REG, size)


def banner(draw, text="CONCEPT MOCKUP - NOT A STUDIO CAPTURE"):
    draw.rectangle([0, H - 44, W, H], fill=(200, 30, 30))
    tw = draw.textlength(text, font=font(26))
    draw.text(((W - tw) / 2, H - 40), text, font=font(26), fill=(255, 255, 255))


def rounded(draw, box, radius, fill, outline=None, width=1):
    draw.rounded_rectangle(box, radius=radius, fill=fill, outline=outline, width=width)


def text_center(draw, cx, y, text, f, fill):
    tw = draw.textlength(text, font=f)
    draw.text((cx - tw / 2, y), text, font=f, fill=fill)


def character_card(draw, x, y, w, h, body, accent, name, rarity, rate, rcolor):
    rounded(draw, [x, y, x + w, y + h], 18, (24, 24, 38), outline=rcolor, width=4)
    # body + head + eyes, drawn as the 3D model would look
    draw.rounded_rectangle([x + w / 2 - 42, y + 46, x + w / 2 + 42, y + 130], radius=14, fill=body)
    draw.ellipse([x + w / 2 - 30, y + 14, x + w / 2 + 30, y + 74], fill=accent)
    draw.ellipse([x + w / 2 - 20, y + 34, x + w / 2 - 6, y + 48], fill=(20, 20, 20))
    draw.ellipse([x + w / 2 + 6, y + 34, x + w / 2 + 20, y + 48], fill=(20, 20, 20))
    text_center(draw, x + w / 2, y + 140, name, font(24), (255, 255, 255))
    text_center(draw, x + w / 2, y + 172, rarity, font(22), rcolor)
    text_center(draw, x + w / 2, y + 200, rate, font(26), (120, 255, 140))


def cover():
    img = Image.new("RGB", (W, H), (18, 20, 46))
    d = ImageDraw.Draw(img)
    # sky glow + ground
    d.rectangle([0, 430, W, H - 44], fill=(52, 140, 70))
    d.rectangle([560, 430, 720, H - 44], fill=(200, 200, 205))
    d.rectangle([556, 430, 560, H - 44], fill=(255, 200, 0))
    d.rectangle([720, 430, 724, H - 44], fill=(255, 200, 0))
    text_center(d, W / 2, 36, "BRAINROT BAY", font(96), (255, 255, 255))
    text_center(d, W / 2, 150, "STEAL  •  EARN  •  REBIRTH", font(36), (255, 210, 60))
    text_center(d, W / 2, 205, "18 absurd brainrots walk the belt. Buy them. Guard them. Outrun the wave.",
                font(26), (200, 220, 255))
    cards = [
        ((150, 110, 70), (255, 220, 90), "Sir Crocs-a-Lot", "Common", "$6/s", (120, 200, 90)),
        ((255, 225, 60), (250, 250, 250), "Banana Phone Boi", "Rare", "$25/s", (70, 140, 255)),
        ((255, 170, 60), (255, 240, 200), "Turbo Toaster Cat", "Epic", "$80/s", (170, 90, 230)),
        ((255, 140, 40), (255, 215, 0), "Sir Reginald III", "Legendary", "$300/s", (255, 190, 40)),
        ((140, 230, 255), (255, 255, 255), "Quantum Quokka", "Mythic", "$1,200/s", (255, 70, 120)),
    ]
    x = 55
    for body, accent, name, rarity, rate, rcolor in cards:
        character_card(d, x, 270, 224, 238, body, accent, name, rarity, rate, rcolor)
        x += 240
    text_center(d, W / 2, 540, "Hold E on the belt to buy  •  F to slap a thief  •  Lock your base before the tsunami",
                font(26), (255, 255, 255))
    banner(d)
    img.save("screenshots/1-thumbnail.jpg", quality=88)


def play_map():
    img = Image.new("RGB", (W, H), (30, 90, 40))
    d = ImageDraw.Draw(img)
    # HUD top bar
    rounded(d, [340, 16, 940, 76], 12, (20, 20, 30))
    d.text((360, 26), "$12,480", font=font(30), fill=(120, 255, 140))
    d.text((560, 30), "$1,240/s  •  6/10 on base", font=font(24), fill=(255, 255, 255))
    d.text((760, 30), "Rebirth 1 • x1.5", font=font(24), fill=(255, 210, 60))
    # belt
    d.rectangle([600, 90, 680, 620], fill=(200, 200, 205))
    d.rectangle([596, 90, 600, 620], fill=(255, 200, 0))
    d.rectangle([680, 90, 684, 620], fill=(255, 200, 0))
    text_center(d, 640, 96, "BELT", font(22), (40, 40, 40))
    # brainrots on the belt
    for i, (y, body, name) in enumerate([(150, (150, 110, 70), "Crocs"), (260, (255, 225, 60), "Banana"),
                                         (380, (255, 170, 60), "Toaster"), (500, (140, 230, 255), "Quokka")]):
        d.rounded_rectangle([612, y, 668, y + 56], radius=10, fill=body)
        d.text((688, y + 14), name, font=font(20), fill=(255, 255, 255))
    # bases
    for i, (x, y) in enumerate([(180, 130), (180, 300), (180, 470), (920, 130), (920, 300), (920, 470)]):
        color = [(255, 90, 90), (90, 160, 255), (90, 220, 120), (255, 200, 60),
                 (190, 110, 255), (255, 140, 200)][i]
        rounded(d, [x, y, x + 220, y + 130], 12, (24, 24, 38), outline=color, width=4)
        text_center(d, x + 110, y + 8, f"BASE {i + 1}", font(24), color)
        for r in range(2):
            for c in range(5):
                px = x + 18 + c * 38
                py = y + 44 + r * 40
                d.rounded_rectangle([px, py, px + 30, py + 30], radius=6,
                                    fill=color if (r * 5 + c) < (3 if i == 0 else 0) else (70, 70, 90))
        if i == 0:
            d.text((x + 18, y + 100), "YOUR BASE - LOCKED", font=font(18), fill=(120, 255, 140))
    # wave arrow + spawn tunnel
    d.polygon([(640, 640), (620, 668), (660, 668)], fill=(90, 180, 255))
    text_center(d, 640, 600, "", font(20), (255, 255, 255))
    d.text((60, 640), "SPAWN TUNNEL (north)", font=font(20), fill=(255, 255, 255))
    d.text((980, 640), "WAVE COMES FROM NORTH", font=font(20), fill=(90, 180, 255))
    rounded(d, [1020, 96, 1252, 150], 10, (20, 80, 160))
    d.text((1034, 108), "TSUNAMI 0:42", font=font(22), fill=(255, 255, 255))
    banner(d)
    img.save("screenshots/2-play.jpg", quality=88)


def base_view():
    img = Image.new("RGB", (W, H), (24, 24, 38))
    d = ImageDraw.Draw(img)
    rounded(d, [340, 16, 940, 76], 12, (20, 20, 30))
    d.text((360, 26), "$48,920", font=font(30), fill=(120, 255, 140))
    d.text((580, 30), "$2,180/s", font=font(24), fill=(255, 255, 255))
    d.text((760, 30), "Rebirth 2 • x2.0", font=font(24), fill=(255, 210, 60))
    text_center(d, W / 2, 100, "YOUR BASE — 6 BRAINROTS EARNING", font(34), (255, 255, 255))
    slots = [
        ((150, 110, 70), (255, 220, 90), "Sir Crocs-a-Lot", "$6/s"),
        ((255, 225, 60), (250, 250, 250), "Banana Phone Boi", "$25/s"),
        ((255, 170, 60), (255, 240, 200), "Turbo Toaster Cat", "$80/s"),
        ((255, 140, 40), (255, 215, 0), "Sir Reginald III", "$300/s"),
        ((140, 230, 255), (255, 255, 255), "Quantum Quokka", "$1,200/s"),
        ((255, 120, 180), (255, 255, 255), "Grandma's Revenge", "$3,500/s"),
    ]
    x = 70
    for body, accent, name, rate in slots:
        character_card(d, x, 170, 190, 238, body, accent, name, "", rate, (255, 255, 255))
        x += 200
    # lock + rebirth buttons
    rounded(d, [300, 460, 580, 530], 12, (60, 180, 90))
    text_center(d, 440, 478, "LOCKED 0:47", font(30), (255, 255, 255))
    rounded(d, [700, 460, 980, 530], 12, (170, 90, 230))
    text_center(d, 840, 478, "REBIRTH — $250K", font(30), (255, 255, 255))
    text_center(d, W / 2, 560, "A thief is coming! Your base is locked — he bounces off. Slap him anyway. (F)",
                font(26), (255, 210, 60))
    text_center(d, W / 2, 606, "Next wave in 1:12 — everything on the belt washes away. Dash home!",
                font(24), (90, 180, 255))
    banner(d)
    img.save("screenshots/3-base.jpg", quality=88)


if __name__ == "__main__":
    cover()
    play_map()
    base_view()
    print("screenshots written")
