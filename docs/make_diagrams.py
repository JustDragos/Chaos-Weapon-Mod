"""Concept diagrams for the Chaos Weapon Mod README (SVG, fixed colours on a dark card)."""
import math, os, sys

OUT = sys.argv[1]
BG, CARD, EDGE = "#15131a", "#1d1a24", "#3a3445"
TEXT, MUTED = "#ece8f4", "#a7a1b5"
EMPTY = "#2a2632"
VIOLET, VIOLET_LO = "#8e4fd6", "#4e2f78"
RED, RED_LO = "#c2413b", "#6e2724"
GOLD, BLUE, GREY = "#d9a93a", "#3f7fc4", "#5d5868"
FONT = "font-family='Segoe UI, Helvetica, Arial, sans-serif'"


def hex_points(cx, cy, r):
    return " ".join(f"{cx + r * math.cos(math.radians(60 * i)):.1f},{cy + r * math.sin(math.radians(60 * i)):.1f}" for i in range(6))


def axial_to_px(q, r, size, ox, oy):
    # flat-top hexes
    x = size * 1.5 * q
    y = size * math.sqrt(3) * (r + q / 2)
    return ox + x, oy + y


def dist(a, b):
    (q1, r1), (q2, r2) = a, b
    return (abs(q1 - q2) + abs(r1 - r2) + abs((q1 + r1) - (q2 + r2))) // 2


def grid(radius):
    return [(q, r) for q in range(-radius, radius + 1) for r in range(-radius, radius + 1) if dist((q, r), (0, 0)) <= radius]


def text(x, y, s, size=13, color=TEXT, anchor="middle", weight="normal"):
    s = s.replace("&", "&amp;").replace("<", "&lt;")
    return f"<text x='{x:.1f}' y='{y:.1f}' {FONT} font-size='{size}' fill='{color}' text-anchor='{anchor}' font-weight='{weight}'>{s}</text>"


def hexcell(cx, cy, size, fill, label="", sub="", stroke=EDGE, label_color=TEXT):
    out = [f"<polygon points='{hex_points(cx, cy, size - 1.5)}' fill='{fill}' stroke='{stroke}' stroke-width='1.5'/>"]
    if label:
        out.append(text(cx, cy + (0 if sub else 4.5), label, 12.5 if len(label) <= 5 else 10, label_color, weight="bold"))
    if sub:
        out.append(text(cx, cy + 14, sub, 10.5, label_color))
    return "".join(out)


def svg(w, h, body, title):
    return (f"<svg xmlns='http://www.w3.org/2000/svg' width='{w}' height='{h}' viewBox='0 0 {w} {h}' role='img' aria-label='{title}'>"
            f"<rect width='{w}' height='{h}' rx='14' fill='{BG}'/>{body}</svg>")


def legend(x, y, items):
    out = []
    for i, (color, label) in enumerate(items):
        yy = y + i * 22
        out.append(f"<rect x='{x}' y='{yy - 11}' width='14' height='14' rx='3' fill='{color}' stroke='{EDGE}'/>")
        out.append(text(x + 22, yy, label, 12.5, TEXT, "start"))
    return "".join(out)


def save(name, content):
    open(os.path.join(OUT, name), "w", encoding="utf-8").write(content)


# 1. Black cloud + curse --------------------------------------------------------------------------
def cloud_and_curse():
    size = 23
    body = []
    # Panel A: black cloud around the target
    ox, oy = 205, 238
    body.append(f"<rect x='16' y='16' width='378' height='448' rx='12' fill='{CARD}' stroke='{EDGE}'/>")
    body.append(text(205, 46, "Black cloud: every hit spreads", 16, TEXT, weight="bold"))
    body.append(text(205, 66, "around the target, friend or foe", 12.5, MUTED))
    wielder = (-1, 1)
    for c in grid(3):
        d = dist(c, (0, 0))
        x, y = axial_to_px(*c, size, ox, oy)
        if c == (0, 0):
            body.append(hexcell(x, y, size, "#e9e4f2", "TARGET", "100%", label_color="#1d1a24"))
        elif c == wielder:
            body.append(hexcell(x, y, size, GOLD, "YOU", "spared", label_color="#1d1a24"))
        elif d == 1:
            body.append(hexcell(x, y, size, VIOLET, "50%"))
        elif d == 2:
            body.append(hexcell(x, y, size, VIOLET_LO, "25%"))
        else:
            body.append(hexcell(x, y, size, EMPTY))
    body.append(legend(40, 412, [(VIOLET, "1 tile away: 50% of the hit"), (VIOLET_LO, "2 tiles away: 25% of the hit")]))

    # Panel B: curse around the wielder
    ox2, oy2 = 606, 238
    body.append(f"<rect x='410' y='16' width='392' height='448' rx='12' fill='{CARD}' stroke='{EDGE}'/>")
    body.append(text(606, 46, "Curse: every hit also strikes", 16, TEXT, weight="bold"))
    body.append(text(606, 66, "your own brothers near you", 12.5, MUTED))
    for c in grid(3):
        d = dist(c, (0, 0))
        x, y = axial_to_px(*c, size, ox2, oy2)
        if c == (0, 0):
            body.append(hexcell(x, y, size, GOLD, "YOU", label_color="#1d1a24"))
        elif d <= 2:
            body.append(hexcell(x, y, size, RED_LO if d == 2 else RED, "200%"))
        else:
            body.append(hexcell(x, y, size, EMPTY))
    body.append(legend(434, 412, [(RED, "allies within 2 tiles: 200% of the hit"), (EMPTY, "3+ tiles away: safe")]))
    body.append(text(410, 490, "Armor applies to both. Brothers with Chaos Protection are immune to the cloud and the curse.", 12.5, MUTED))
    save("concept_black_cloud_curse.svg", svg(818, 508, "".join(body), "Black cloud and curse"))


# 2. Chaos Circle --------------------------------------------------------------------------------
def chaos_circle():
    size = 27
    body = [f"<rect x='16' y='16' width='786' height='398' rx='12' fill='{CARD}' stroke='{EDGE}'/>",
            text(409, 48, "Chaos Circle: a Geist's scream, sharpened by your Resolve", 16, TEXT, weight="bold")]
    ox, oy = 250, 240
    caster = (-3, 1)
    for c in grid(3):
        x, y = axial_to_px(*c, size, ox, oy)
        d = dist(c, (0, 0))
        if c == (0, 0):
            body.append(hexcell(x, y, size, VIOLET, "CENTRE", "full gap"))
        elif d == 1:
            body.append(hexcell(x, y, size, VIOLET_LO, "RING", "half gap"))
        elif c == caster:
            body.append(hexcell(x, y, size, GOLD, "YOU", label_color="#1d1a24"))
        else:
            body.append(hexcell(x, y, size, EMPTY))
    cx, cy = axial_to_px(*caster, size, ox, oy)
    tx, ty = axial_to_px(0, 0, size, ox, oy)
    body.append(f"<line x1='{cx + 20:.1f}' y1='{cy - 10:.1f}' x2='{tx - 26:.1f}' y2='{ty + 8:.1f}' stroke='{GOLD}' stroke-width='2' stroke-dasharray='6 5'/>")
    body.append(f"<rect x='{cx - 40:.1f}' y='{cy + 30:.1f}' width='80' height='20' rx='6' fill='{BG}' stroke='{GOLD}'/>")
    body.append(text(cx, cy + 44, "range 1-5", 12, GOLD, weight="bold"))

    x0 = 480
    lines = [
        ("Their Resolve for the check drops by the gap", TEXT, "bold"),
        ("between yours and theirs:", TEXT, "bold"),
        ("", TEXT, ""),
        ("Example: you have 80 Resolve", MUTED, ""),
        ("  40-Resolve brigand in the centre  ->  checks with 0", TEXT, ""),
        ("  40-Resolve brigand on the ring     ->  checks with 20", TEXT, ""),
        ("  90-Resolve knight anywhere          ->  no change", TEXT, ""),
        ("", TEXT, ""),
        ("Lasts 3 rounds. Anyone standing in it pays", TEXT, ""),
        ("+1 AP and +3 fatigue per tile moved.", TEXT, ""),
        ("", TEXT, ""),
        ("6 AP, 30 fatigue, once every 3 turns.", MUTED, ""),
        ("Spares you and Chaos Protection holders.", MUTED, ""),
    ]
    for i, (s, col, wt) in enumerate(lines):
        body.append(text(x0, 108 + i * 22, s, 13, col, "start", wt or "normal"))
    save("concept_chaos_circle.svg", svg(818, 430, "".join(body), "Chaos Circle"))


# 3. Sacrifices ----------------------------------------------------------------------------------
def sacrifices():
    size = 28
    body = []
    # Brother Sacrifice
    body.append(f"<rect x='16' y='16' width='392' height='330' rx='12' fill='{CARD}' stroke='{EDGE}'/>")
    body.append(text(212, 46, "Brother Sacrifice", 16, TEXT, weight="bold"))
    body.append(text(212, 66, "4 AP, 10 fatigue: one adjacent brother", 12.5, MUTED))
    ox, oy = 212, 190
    for c in grid(2):
        x, y = axial_to_px(*c, size, ox, oy)
        if c == (0, 0):
            body.append(hexcell(x, y, size, GOLD, "YOU", label_color="#1d1a24"))
        elif c == (1, 0):
            body.append(hexcell(x, y, size, RED, "DIES"))
        elif dist(c, (0, 0)) == 1:
            body.append(hexcell(x, y, size, BLUE if c in [(0, -1), (-1, 1)] else EMPTY, "safe" if c in [(0, -1), (-1, 1)] else ""))
        else:
            body.append(hexcell(x, y, size, EMPTY))
    body.append(text(212, 318, "Full blade strike, ignores armor, always kills.", 12.5, TEXT))
    # Mass Sacrifice
    body.append(f"<rect x='424' y='16' width='392' height='330' rx='12' fill='{CARD}' stroke='{EDGE}'/>")
    body.append(text(620, 46, "Mass Sacrifice", 16, TEXT, weight="bold"))
    body.append(text(620, 66, "6 AP, 25 fatigue: every adjacent brother", 12.5, MUTED))
    ox, oy = 620, 190
    for c in grid(2):
        x, y = axial_to_px(*c, size, ox, oy)
        d = dist(c, (0, 0))
        if c == (0, 0):
            body.append(hexcell(x, y, size, GOLD, "YOU", label_color="#1d1a24"))
        elif c == (0, -1):
            body.append(hexcell(x, y, size, GREY, "WARD", "skipped"))
        elif d == 1:
            body.append(hexcell(x, y, size, RED, "DIES"))
        else:
            body.append(hexcell(x, y, size, EMPTY))
    body.append(text(620, 318, "WARD = Chaos Protection: can't be sacrificed.", 12.5, TEXT))
    # Shared consequences
    body.append(f"<rect x='16' y='362' width='800' height='120' rx='12' fill='{CARD}' stroke='{EDGE}'/>")
    rows = [
        "Each death: +1 blade kill, and all his hitpoints become Carnal Storage energy (4 HP = 1).",
        "Every other brother on the field is Terrified: Fleeing, and can't rally until the battle ends.",
        "  (spared: you, Only Chaos Matters, Chaos Protection)",
        "Every other brother's mood drops if you have Only Chaos Matters. 500+ kills: you turn Confident.",
    ]
    for i, s in enumerate(rows):
        body.append(text(36, 392 + i * 24, s, 13, TEXT if not s.startswith("  ") else MUTED, "start"))
    save("concept_sacrifices.svg", svg(832, 498, "".join(body), "Brother and Mass Sacrifice"))


# 4. Kill milestones -----------------------------------------------------------------------------
def milestones():
    W, H = 900, 380
    x0, x1, ybar = 130, 780, 150
    def X(k):
        return x0 + (x1 - x0) * k / 520
    body = [f"<rect x='16' y='16' width='{W - 32}' height='{H - 32}' rx='12' fill='{CARD}' stroke='{EDGE}'/>",
            text(W / 2, 48, "The blade grows with every life it takes", 16, TEXT, weight="bold")]
    # damage gradient bar
    body.append("<defs><linearGradient id='g' x1='0' x2='1'><stop offset='0' stop-color='#3b2557'/><stop offset='1' stop-color='#b06cff'/></linearGradient></defs>")
    body.append(f"<rect x='{x0}' y='{ybar - 9}' width='{x1 - x0}' height='18' rx='9' fill='url(#g)'/>")
    marks = [
        (8, "8", "Claimed at The Frozen Eye", "(8 offered lives)"),
        (100, "100", "The Devourer", "Soul Arrow + Black Skull I"),
        (200, "200", "Black Skull II", ""),
        (350, "350", "Champion chance", "caps at +35%"),
        (500, "500", "Gorged form", "Black Skull III, new look"),
    ]
    for i, (k, lab, a, b) in enumerate(marks):
        x = X(k)
        up = i % 2 == 0
        body.append(f"<circle cx='{x:.1f}' cy='{ybar}' r='9' fill='{GOLD}' stroke='{BG}' stroke-width='3'/>")
        # Above the bar for even marks, below for odd ones: kills, then what happens.
        ys = (ybar - 62, ybar - 44, ybar - 27) if up else (ybar + 34, ybar + 52, ybar + 69)
        body.append(text(x, ys[0], lab + " kills", 13, GOLD, weight="bold"))
        body.append(text(x, ys[1], a, 12.5, TEXT))
        if b:
            body.append(text(x, ys[2], b, 11.5, MUTED))
    # formula rows
    rows = [
        ("Damage", "+1% for every 10 kills, no cap", "(500 kills: +50%)"),
        ("Champions", "+2% chance per enemy for every 20 kills", "(max +35%)"),
        ("Chaos Armor", "+1 Melee and Ranged Defense per +1% damage", "(perk, no cap)"),
        ("Black Skull", "+0.1 / 0.25 / 0.5 max fatigue per +1% damage", "(after part I / II / III)"),
    ]
    for i, (a, b, c) in enumerate(rows):
        y = 262 + i * 24
        body.append(text(60, y, a, 13, VIOLET.replace('8e4fd6', 'b48cf0'), "start", "bold"))
        body.append(text(190, y, b, 13, TEXT, "start"))
        body.append(text(560, y, c, 12.5, MUTED, "start"))
    save("concept_kill_milestones.svg", svg(W, H, "".join(body), "Kill milestones"))


# 5. Black Skull reward chart --------------------------------------------------------------------
def reward_chart():
    W, H = 700, 360
    gx0, gy0, gx1, gy1 = 80, 70, 640, 290
    body = [f"<rect x='16' y='16' width='{W - 32}' height='{H - 32}' rx='12' fill='{CARD}' stroke='{EDGE}'/>",
            text(W / 2, 46, "Black Skull reward: extra max fatigue while wielding Chaos Mind", 15, TEXT, weight="bold")]
    maxk, maxv = 700, 35
    def P(k, v):
        return gx0 + (gx1 - gx0) * k / maxk, gy1 - (gy1 - gy0) * v / maxv
    for v in range(0, maxv + 1, 5):
        x, y = P(0, v)
        body.append(f"<line x1='{gx0}' y1='{y:.1f}' x2='{gx1}' y2='{y:.1f}' stroke='{EDGE}' stroke-width='1'/>")
        body.append(text(gx0 - 10, y + 4, str(v), 11, MUTED, "end"))
    for k in range(0, maxk + 1, 100):
        x, y = P(k, 0)
        body.append(text(x, gy1 + 18, str(k), 11, MUTED))
    body.append(text((gx0 + gx1) / 2, gy1 + 38, "blade kills", 12, MUTED))
    series = [(0.1, 100, "#7fb3e6", "after part I (0.1)"), (0.25, 200, "#b48cf0", "after part II (0.25)"), (0.5, 500, GOLD, "after part III (0.5)")]
    for rate, start, color, label in series:
        pts = []
        for k in range(start, maxk + 1, 10):
            pts.append(P(k, math.floor(rate * (k // 10))))
        d = " ".join(f"{x:.1f},{y:.1f}" for x, y in pts)
        body.append(f"<polyline points='{d}' fill='none' stroke='{color}' stroke-width='2.5'/>")
        lx, ly = pts[-1]
        body.append(text(lx - 4, ly - 8, label, 11.5, color, "end", "bold"))
    save("concept_black_skull_reward.svg", svg(W, H, "".join(body), "Black Skull reward chart"))


cloud_and_curse()
chaos_circle()
sacrifices()
milestones()
reward_chart()
print("diagrams written to", OUT)
