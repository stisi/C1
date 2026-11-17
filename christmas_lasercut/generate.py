#!/usr/bin/env python3
"""Laser-cut Christmas ornament: "Frohe Weihnachten / wünscht / FF-Vorderthiersee".

Generates one single connected, cut-ready outline (units: mm).
Requires: fonttools, uharfbuzz, shapely (cairosvg for previews).
"""
import math, random, sys, os
import uharfbuzz as hb
from fontTools.ttLib import TTFont
from fontTools.pens.basePen import BasePen
from shapely.geometry import Polygon, MultiPolygon, LineString, Point, box
from shapely.ops import unary_union
from shapely import affinity

HERE = os.path.dirname(os.path.abspath(__file__))
FONTS = os.path.join(HERE, "fonts")
random.seed(7)

R_OUT, R_IN = 100.0, 94.0          # outer frame
R_RING_O, R_RING_I = 90.6, 89.2    # thin inner ring
KERF_CLEAN = 0.35                  # removes slivers / gaps < ~0.7 mm


# ---------------------------------------------------------------- helpers
def circle(cx, cy, r, n=180):
    return Point(cx, cy).buffer(r, quad_segs=max(8, n // 4))

def annulus(r1, r2):
    return circle(0, 0, r2, 720).difference(circle(0, 0, r1, 720))

def polar(r, deg):
    a = math.radians(deg)
    return (r * math.cos(a), r * math.sin(a))

def line(pts, w):
    return LineString(pts).buffer(w / 2, cap_style="round", join_style="round")

def taper(p0, p1, w0, w1):
    (x0, y0), (x1, y1) = p0, p1
    dx, dy = x1 - x0, y1 - y0
    L = math.hypot(dx, dy) or 1
    nx, ny = -dy / L, dx / L
    return Polygon([(x0 + nx * w0 / 2, y0 + ny * w0 / 2), (x1 + nx * w1 / 2, y1 + ny * w1 / 2),
                    (x1 - nx * w1 / 2, y1 - ny * w1 / 2), (x0 - nx * w0 / 2, y0 - ny * w0 / 2)]).union(
        circle(x1, y1, w1 / 2, 16))

def bezier(p0, p1, p2, p3=None, n=80):
    out = []
    for i in range(n + 1):
        t = i / n
        if p3 is None:
            x = (1 - t) ** 2 * p0[0] + 2 * (1 - t) * t * p1[0] + t * t * p2[0]
            y = (1 - t) ** 2 * p0[1] + 2 * (1 - t) * t * p1[1] + t * t * p2[1]
        else:
            x = (1-t)**3*p0[0] + 3*(1-t)**2*t*p1[0] + 3*(1-t)*t*t*p2[0] + t**3*p3[0]
            y = (1-t)**3*p0[1] + 3*(1-t)**2*t*p1[1] + 3*(1-t)*t*t*p2[1] + t**3*p3[1]
        out.append((x, y))
    return out

def star_pts(cx, cy, r_out, r_in, n=5, rot=-90):
    pts = []
    for i in range(2 * n):
        r = r_out if i % 2 == 0 else r_in
        pts.append(polar(r, rot + i * 180 / n))
    return [(cx + x, cy + y) for x, y in pts]


# ---------------------------------------------------------------- text
class FlatPen(BasePen):
    def __init__(self, gs):
        super().__init__(gs); self.contours = []; self.cur = []
    def _moveTo(self, p): self.cur = [p]
    def _lineTo(self, p): self.cur.append(p)
    def _curveToOne(self, p1, p2, p3):
        self.cur.extend(bezier(self.cur[-1], p1, p2, p3, 14)[1:])
    def _qCurveToOne(self, p1, p2):
        self.cur.extend(bezier(self.cur[-1], p1, p2, None, 10)[1:])
    def _closePath(self):
        if len(self.cur) > 2: self.contours.append(self.cur)
        self.cur = []
    _endPath = _closePath

def signed_area(c):
    return sum(c[i][0] * c[i - 1][1] - c[i - 1][0] * c[i][1] for i in range(len(c))) / 2

def glyph_geom(font, gname):
    gs = font.getGlyphSet(); pen = FlatPen(gs); gs[gname].draw(pen)
    cs = [c for c in pen.contours if abs(signed_area(c)) > 1e-6]
    if not cs: return None
    # non-zero winding approximation: contours oriented like the largest are filled
    ref = math.copysign(1, signed_area(max(cs, key=lambda c: abs(signed_area(c)))))
    fill = [Polygon(c).buffer(0) for c in cs if math.copysign(1, signed_area(c)) == ref]
    holes = [Polygon(c).buffer(0) for c in cs if math.copysign(1, signed_area(c)) != ref]
    g = unary_union(fill)
    if holes: g = g.difference(unary_union(holes))
    return g

def text(fontfile, s, size_mm, cx, baseline, features=None, tracking=0.0):
    """Shaped text, centred at cx, baseline y (SVG coords). size_mm = em size."""
    path = os.path.join(FONTS, fontfile)
    blob = hb.Blob.from_file_path(path); face = hb.Face(blob); hbf = hb.Font(face)
    buf = hb.Buffer(); buf.add_str(s); buf.guess_segment_properties()
    hb.shape(hbf, buf, features or {"kern": True, "liga": True})
    font = TTFont(path); order = font.getGlyphOrder(); upem = font["head"].unitsPerEm
    sc = size_mm / upem
    parts, x = [], 0.0
    for info, pos in zip(buf.glyph_infos, buf.glyph_positions):
        g = glyph_geom(font, order[info.codepoint])
        if g is not None:
            parts.append(affinity.translate(g, x + pos.x_offset, pos.y_offset))
        x += pos.x_advance + tracking / sc
    g = unary_union(parts)
    g = affinity.scale(g, sc, -sc, origin=(0, 0))
    w = x * sc - tracking
    return affinity.translate(g, cx - w / 2, baseline), w

def text_on_arc(fontfile, s, size_mm, radius, center_deg=90, tracking=0.0):
    """Text along the bottom arc, reading left->right, baseline on `radius`
    (letters stand inward, toward the centre)."""
    path = os.path.join(FONTS, fontfile)
    blob = hb.Blob.from_file_path(path); face = hb.Face(blob); hbf = hb.Font(face)
    buf = hb.Buffer(); buf.add_str(s); buf.guess_segment_properties()
    hb.shape(hbf, buf, {"kern": True})
    font = TTFont(path); order = font.getGlyphOrder(); sc = size_mm / font["head"].unitsPerEm
    glyphs, x = [], 0.0
    for info, pos in zip(buf.glyph_infos, buf.glyph_positions):
        adv = pos.x_advance * sc + tracking
        glyphs.append((order[info.codepoint], x, adv)); x += adv
    total = x - tracking
    out = []
    for gname, gx, adv in glyphs:
        g = glyph_geom(font, gname)
        if g is None: continue
        g = affinity.scale(g, sc, -sc, origin=(0, 0))           # y down, baseline y=0
        if gname == "hyphen":                                   # lengthen: joins F and V
            g = affinity.scale(g, 1.9, 1.0, origin=((adv - tracking) / 2, 0))
        mid = gx + (adv - tracking) / 2 - total / 2                          # arc-length offset of glyph centre
        g = affinity.translate(g, -(adv - tracking) / 2, 0)          # glyph centre at x=0
        ang = center_deg - math.degrees(mid / radius)           # bottom: angle decreases left->right
        # at the bottom (90deg) the glyph is upright with baseline on circle
        g = affinity.translate(g, 0, radius)
        g = affinity.rotate(g, ang - 90, origin=(0, 0))
        out.append(g)
    return unary_union(out)


# ---------------------------------------------------------------- ornaments
def fir_garland(pts, needle_len=6.0, spacing=1.75, stem=1.9):
    parts = [line(pts, stem)]
    ls = LineString(pts); L = ls.length
    d = 0.8
    while d < L - 0.8:
        p = ls.interpolate(d); q = ls.interpolate(min(L, d + 0.5))
        ang = math.degrees(math.atan2(q.y - p.y, q.x - p.x))
        taper_end = min(1.0, d / 10, (L - d) / 10)
        for side in (-1, 1):
            for layer, (a_off, lf) in enumerate(((56, 1.0), (30, 0.78))):
                a = ang + side * (a_off + random.uniform(-8, 8))
                ln = needle_len * lf * (0.55 + 0.45 * taper_end) * random.uniform(0.85, 1.12)
                tip = (p.x + ln * math.cos(math.radians(a)), p.y + ln * math.sin(math.radians(a)))
                parts.append(taper((p.x, p.y), tip, 1.35, 0.8))
        d += spacing
    return unary_union(parts)

def bauble(cx, cy, r, string_top, style=0):
    body = circle(cx, cy, r, 120)
    cap = box(cx - r * 0.32, cy - r - 2.6, cx + r * 0.32, cy - r + 0.6)
    loop = circle(cx, cy - r - 3.3, 1.5).difference(circle(cx, cy - r - 3.3, 0.6))
    s = line([(cx, string_top), (cx, cy - r - 4.4)], 1.0)
    g = unary_union([body, cap, loop, s])
    holes = []
    if style == 0:   # star + band
        holes.append(Polygon(star_pts(cx, cy + 0.3, r * 0.52, r * 0.22)))
        for k in (-1, 1):
            holes.append(affinity.scale(circle(cx, cy, r - 1.4, 120), 1, 1).intersection(
                box(cx - r, cy + k * r * 0.62 - 0.55, cx + r, cy + k * r * 0.62 + 0.55)))
    elif style == 1:  # lens slots (stripes)
        for k in (-0.45, 0, 0.45):
            lens = circle(cx, cy + k * r, r * 0.9).intersection(circle(cx, cy, r - 1.5, 120))
            holes.append(lens.intersection(box(cx - r, cy + k * r - 0.75, cx + r, cy + k * r + 0.75)))
        holes.append(circle(cx, cy - 0.45 * r - 2.4, 0.8)); holes.append(circle(cx, cy + 0.45 * r + 2.4, 0.8))
    elif style == 2:  # snowflake inside a ring
        holes.append(circle(cx, cy, r - 1.2, 100).difference(snowflake(cx, cy, r - 0.9, 0.95)))
    for h in holes: g = g.difference(h)
    # highlight crescent
    hl = circle(cx - r * 0.3, cy - r * 0.3, r * 0.42).difference(circle(cx - r * 0.18, cy - r * 0.18, r * 0.42))
    hl = hl.intersection(circle(cx, cy, r - 1.3))
    if style != 2: g = g.difference(hl.buffer(-0.15))
    return g

def snowflake(cx, cy, r, w=1.0):
    parts = []
    for i in range(6):
        a = i * 60 - 90
        tip = polar(r, a); parts.append(line([(cx, cy), (cx + tip[0], cy + tip[1])], w))
        for f, bl in ((0.5, 0.32), (0.78, 0.22)):
            base = polar(r * f, a)
            for s in (-1, 1):
                b = polar(r * bl, a + s * 50)
                parts.append(line([(cx + base[0], cy + base[1]), (cx + base[0] + b[0], cy + base[1] + b[1])], w * 0.9))
    parts.append(circle(cx, cy, w * 1.3))
    return unary_union(parts)

def faceted_star(cx, cy, r, n=5, rot=-90, border=0.75):
    pts = star_pts(cx, cy, r, r * 0.43, n, rot)
    star = Polygon(pts)
    holes = []
    for i in range(2 * n):
        if i % 2 == 0:  # every other facet cut -> light/dark 3D effect
            tri = Polygon([(cx, cy), pts[i], pts[(i + 1) % (2 * n)]])
            holes.append(tri.buffer(-border, join_style="mitre"))
    return star.difference(unary_union(holes))

def bow(cx, cy, s=1.0):
    parts, holes = [], []
    for side in (-1, 1):
        loop = affinity.rotate(affinity.scale(circle(0, 0, 1, 90), 7.2 * s, 4.2 * s), side * -14, origin=(0, 0))
        loop = affinity.translate(loop, cx + side * 7.0 * s, cy - 1.0 * s)
        inner = affinity.rotate(affinity.scale(circle(0, 0, 1, 90), 5.0 * s, 2.3 * s), side * -14, origin=(0, 0))
        inner = affinity.translate(inner, cx + side * 7.6 * s, cy - 1.0 * s)
        parts.append(loop); holes.append(inner)
        # tail
        t0 = (cx + side * 1.5 * s, cy + 1.5 * s)
        t1 = (cx + side * 7.5 * s, cy + 12.0 * s)
        tail = Polygon([t0, (t0[0] + side * 2.8 * s, t0[1] - 0.5 * s), (t1[0] + side * 2.6 * s, t1[1] - 0.8 * s),
                        (t1[0] + side * 0.6 * s, t1[1] - 2.2 * s), (t1[0] - side * 0.9 * s, t1[1] + 0.2 * s)])
        parts.append(tail)
    knot = affinity.scale(circle(cx, cy - 0.4 * s, 2.6 * s), 1.0, 1.15)
    g = unary_union(parts).difference(unary_union(holes)).union(knot)
    # fold lines on loops
    for side in (-1, 1):
        fold = line(bezier((cx + side * 3.0 * s, cy - 1.0 * s), (cx + side * 7 * s, cy - 2.5 * s),
                           (cx + side * 11.5 * s, cy - 1.0 * s), None, 20), 0.0)
    return g

def holly(cx, cy, ang, s=1.0):
    """Holly leaf, spiky, with cut vein."""
    pts = []
    n = 7
    L, W = 11 * s, 4.2 * s
    for i in range(n + 1):
        t = i / n; x = -L / 2 + t * L
        w = W * math.sin(math.pi * t) ** 0.8
        pts.append((x, -w - (1.0 * s if 0 < i < n else 0)))
        if i < n:
            tm = (i + 0.5) / n; xm = -L / 2 + tm * L
            pts.append((xm, -W * math.sin(math.pi * tm) ** 0.8 * 0.6))
    top = pts
    bot = [(x, -y) for x, y in reversed(top)]
    leaf = Polygon(top + bot).buffer(0)
    vein = LineString([(-L * 0.36, 0), (L * 0.36, 0)]).buffer(0.4)
    leaf = leaf.difference(vein)
    leaf = affinity.rotate(leaf, ang, origin=(0, 0))
    return affinity.translate(leaf, cx, cy)


# ---------------------------------------------------------------- landscape
def ridge(x, peaks, base):
    y = base
    for px, py, w in peaks:
        h = base - py
        d = abs(x - px) / w
        y = min(y, py + h * min(1.0, d ** 0.9))
    return y

def landscape():
    clip = circle(0, 0, R_IN + 1, 400).difference(ramp_ring(80.6, R_IN + 1, 200, ramp=10, zone=(51, 129)))
    x0, x1 = -95, 95
    xs = [x0 + i * 0.5 for i in range(int((x1 - x0) / 0.5) + 1)]
    # back range (Pendling massif + neighbours)
    back_pk = [(-40, 33.0, 30), (-14, 39.5, 16), (12, 37.0, 18), (44, 34.0, 26), (72, 46, 20), (-72, 46, 20)]
    front_pk = [(-55, 47.5, 24), (-26, 49.5, 18), (24, 48.5, 22), (56, 47.0, 22), (0, 52.5, 16)]
    def rough(x, k):
        return 0.7 * math.sin(x * 0.9 + k) + 0.4 * math.sin(x * 2.3 + 2 * k)
    back = Polygon([(x, ridge(x, back_pk, 60) + rough(x, 1)) for x in xs] + [(x1, 120), (x0, 120)]).buffer(0)
    front = Polygon([(x, ridge(x, front_pk, 64) + rough(x, 3) * 0.6) for x in xs] + [(x1, 120), (x0, 120)]).buffer(0)
    hills = Polygon([(x, 56.5 - 15 * (abs(x) / 88) ** 3 + 0.8 * math.sin(x * 0.21)) for x in xs] + [(x1, 120), (x0, 120)])
    body = back.union(front).union(hills).intersection(clip)
    cuts = []
    # separation line between ranges
    sep = front.exterior.buffer(0.45).intersection(back.buffer(-1.2)).intersection(clip.buffer(-1))
    sep = sep.intersection(box(-64, -200, 64, 200))
    # snow caps: zigzag lines a few mm under each back peak
    for px, py, w in back_pk[:4]:
        zz = []
        span = w * 0.58
        for i in range(13):
            t = i / 12; x = px - span + 2 * span * t
            y = ridge(x, back_pk, 60) + (3.0 if i % 2 == 0 else 6.2) + 0.8 * math.sin(i * 1.7)
            zz.append((x, y))
        cuts.append(LineString(zz).buffer(0.45, join_style="round").intersection(back.buffer(-1.3).difference(front.buffer(1.6))))
    # trees (negative silhouettes) along the foreground
    def tree(tx, ty, h):
        w = h * 0.42; tiers = 4; pts = []
        poly = []
        for i in range(tiers):
            t0 = ty - h + h * i / tiers * 0.95
            tw = w * (0.35 + 0.65 * (i + 1) / tiers)
            poly.append(Polygon([(tx, t0), (tx + tw / 2, t0 + h / tiers * 1.35), (tx - tw / 2, t0 + h / tiers * 1.35)]))
        poly.append(box(tx - h * 0.04, ty - h * 0.1, tx + h * 0.04, ty + h * 0.05))
        return unary_union(poly)
    trees = []
    for tx, h in [(-58, 12), (-51, 15.5), (-44, 11), (-37.5, 14), (-30.5, 10), (-23.5, 8),
                  (21.5, 8.5), (28, 11), (35, 15), (42, 11.5), (49, 14.5), (56, 10.5)]:
        ty = math.sqrt(80.6 ** 2 - tx ** 2) - 2.6
        trees.append(tree(tx, ty, h))
    tree_zone = unary_union(trees).buffer(1.1)
    lines = unary_union(cuts + [sep]).difference(tree_zone)
    cuts = [lines] + trees
    # Feuerwehrhaus with hose tower (outline slots + lit windows), centred
    hx, hy = 0, 75.5
    hall = Polygon([(hx - 11, hy), (hx - 11, hy - 8), (hx - 5, hy - 12.5), (hx + 1, hy - 8), (hx + 1, hy)])
    towr = Polygon([(hx + 1, hy), (hx + 1, hy - 17), (hx + 3.5, hy - 20.5), (hx + 6, hy - 17), (hx + 6, hy)])
    house = hall.union(towr)
    outline = LineString(list(house.exterior.coords)).buffer(0.45)
    outline = outline.difference(box(hx - 20, hy - 0.6, hx + 20, hy + 3))   # stays attached at the ground
    cuts.append(outline)
    # gates (two arched doors), windows, tower windows
    for gx in (hx - 9.2, hx - 4.6):
        d = box(gx, hy - 5.2, gx + 3.6, hy - 0.9).union(circle(gx + 1.8, hy - 5.2, 1.8).intersection(box(gx, hy - 8, gx + 3.6, hy - 5.2)))
        cuts.append(d)
    cuts.append(circle(hx - 5, hy - 9.1, 1.05))                            # round gable window
    for wy in (hy - 15.2, hy - 11.0, hy - 6.8):
        cuts.append(box(hx + 2.6, wy, hx + 4.4, wy + 2.4))
    # flag/star on tower top
    # ground snow line & lake ripples
    cuts.append(LineString(bezier((-75, 76.0), (-30, 79.5), (30, 79.5), (75, 76.0))).buffer(0.45).intersection(clip.buffer(-2.2)))
    keep_solid = clip.difference(clip.buffer(-4.5))       # no cuts near the rim -> no islands
    return body.difference(unary_union(cuts).difference(keep_solid)), body


# ---------------------------------------------------------------- build
TEXT_ZONE = (42, 138)      # degrees (y-down polar, 90 = bottom) kept free for the club name
R_BASE = 91.0              # baseline radius of the arced lettering

def wedge(a0, a1, r=130):
    pts = [(0, 0)] + [polar(r, a0 + (a1 - a0) * i / 60) for i in range(61)]
    return Polygon(pts)

def swash(p_from, p_to, bend, w0=1.9, w1=1.1, n=50):
    (x0, y0), (x1, y1) = p_from, p_to
    c1 = (x0 + (x1 - x0) * 0.35, y0 + bend)
    c2 = (x0 + (x1 - x0) * 0.7, y1 - bend * 0.6)
    pts = bezier(p_from, c1, c2, p_to, n)
    segs = [taper(pts[i], pts[i + 1], w0 + (w1 - w0) * i / n, w0 + (w1 - w0) * (i + 1) / n) for i in range(n)]
    return unary_union(segs + [circle(*p_from, w0 / 2)])

def extreme(g, side, ywin=None):
    pts = []
    polys = [g] if isinstance(g, Polygon) else list(g.geoms)
    for p in polys: pts += list(p.exterior.coords)
    if ywin: pts = [q for q in pts if ywin[0] <= q[1] <= ywin[1]]
    return max(pts, key=lambda q: side * q[0])

def ramp_ring(r_zone, r_out_zone, r_outer, ramp=10.0, zone=None):
    """Polar band: inner radius r_zone inside TEXT_ZONE, easing to r_out_zone outside it."""
    inner = []
    for i in range(721):
        a = i * 0.5
        z0, z1 = zone or TEXT_ZONE
        if z0 <= a <= z1: k = 1.0
        elif z0 - ramp < a < z0: k = 0.5 + 0.5 * math.cos(math.pi * (z0 - a) / ramp)
        elif z1 < a < z1 + ramp: k = 0.5 + 0.5 * math.cos(math.pi * (a - z1) / ramp)
        else: k = 0.0
        inner.append(polar(r_out_zone + (r_zone - r_out_zone) * k, a))
    return circle(0, 0, r_outer, 720).difference(Polygon(inner))

def frame():
    parts, holes = [], []
    parts.append(annulus(R_IN, R_OUT))
    for i in range(60):
        a = i * 6
        if TEXT_ZONE[0] - 7 < a < TEXT_ZONE[1] + 7: continue
        x, y = polar(R_IN, a); parts.append(circle(x, y, 2.5, 48))          # lace scallops
    for i in range(60):
        x, y = polar(97.0, i * 6 + 3); holes.append(circle(x, y, 1.0, 32))  # punched pearls
    parts.append(ramp_ring(R_BASE - 0.2, R_IN + 0.1, R_IN + 0.5, ramp=6))
    # hanger
    parts.append(circle(0, -104.2, 8.4, 120)); parts.append(box(-5, -104, 5, -96))
    holes.append(circle(0, -105.0, 4.2, 100))
    return unary_union(parts), holes

def build():
    fr, holes = frame()
    parts = [fr]
    R_LACE = R_IN - 0.6

    # --- garland swags with baubles
    top = (0, -86.0)
    for side in (-1, 1):
        end = polar(R_LACE + 0.8, -90 + side * 61)
        p = bezier(top, (side * 22, -58), (end[0] * 0.78, end[1] + 10), end, 110)
        parts.append(fir_garland(p))
        for t, drop, r, st in ((0.30, 6.0, 5.4, 2), (0.58, 11.0, 6.8, 0), (0.84, 4.5, 5.0, 1)):
            q = LineString(p).interpolate(t, normalized=True)
            parts.append(bauble(q.x, q.y + drop + r, r, q.y, st))
        bx, by = end[0] * 0.955, end[1] * 0.955
        for dx, dy, rr in ((0, 0, 1.9), (side * -2.6, 1.9, 1.6), (side * -0.4, 3.4, 1.5)):
            berry = circle(bx + dx, by + dy, rr, 40)
            parts.append(berry.difference(circle(bx + dx - 0.6, by + dy - 0.6, 0.45, 16)))
    parts.append(bow(0, -86.0, 1.0))

    # --- hanging star
    parts.append(line([(0, -82), (0, -71)], 1.0))
    parts.append(faceted_star(0, -59.5, 13.0))

    # --- lettering (script embolded for laser strength)
    EMB = 0.42
    t1, w1 = text("GreatVibes-Regular.ttf", "Frohe", 31, -2.5, -15.5); t1 = t1.buffer(EMB)
    t2, w2 = text("GreatVibes-Regular.ttf", "Weihnachten", 37.5, 0, 9.0); t2 = t2.buffer(EMB)
    t3, w3 = text("GreatVibes-Regular.ttf", "wünscht", 21, 0, 25.5); t3 = t3.buffer(EMB * 0.9)
    parts += [t1, t2, t3]
    # flourishes: Weihnachten swings out to the frame on both sides, wünscht gets its own swashes
    for side in (-1, 1):
        e = extreme(t2, side)
        tgt = (side * math.sqrt(R_LACE ** 2 - (e[1] + 3) ** 2) * 1.0, e[1] + 3)
        parts.append(swash((e[0] - side * 0.8, e[1]), tgt, -3 if side > 0 else 3, 1.6, 1.3))
        e3 = extreme(t3, side, (18, 26.5))
        tgt3 = (side * math.sqrt(R_LACE ** 2 - 24 ** 2), 24.0)
        parts.append(swash((e3[0] - side * 0.6, e3[1]), tgt3, 2.5, 1.6, 1.2))
        dx = e3[0] + side * 8
        dy = e3[1] + (24 - e3[1]) * 0.25 + 0.9
        parts.append(affinity.rotate(box(dx - 1.5, dy - 1.5, dx + 1.5, dy + 1.5), 45, origin=(dx, dy)))
    arc = text_on_arc("Cinzel-Bold.ttf", "FF-Vorderthiersee", 10.5, R_BASE, 90, tracking=1.1).buffer(0.1)
    parts.append(arc)

    # --- landscape
    land, _ = landscape()
    parts.append(land)

    g = unary_union(parts)
    g = g.difference(unary_union(holes))
    g = g.intersection(circle(0, 0, R_OUT, 900).union(circle(0, -104.2, 8.4, 120)).union(box(-5, -104, 5, -96)))
    # manufacturability: close tiny gaps, drop slivers
    g = g.buffer(KERF_CLEAN, join_style="round").buffer(-KERF_CLEAN, join_style="round")
    g = g.buffer(-0.3, join_style="round").buffer(0.3, join_style="round")
    return g


def bridge_islands(g, min_area=0.5):
    if isinstance(g, Polygon): return g
    polys = sorted(g.geoms, key=lambda p: -p.area)
    main = polys[0]
    out = [main]
    report = []
    for p in polys[1:]:
        from shapely.ops import nearest_points
        a, b = nearest_points(p, main)
        if p.area < min_area or (p.area < 12 and a.distance(b) > 3):
            report.append(("dropped", tuple(round(v, 1) for v in p.centroid.coords[0]), round(p.area, 2))); continue
        out.append(p); out.append(LineString([a, b]).buffer(0.55, cap_style="round"))
        report.append(("bridged", tuple(round(v, 1) for v in p.centroid.coords[0]), round(a.distance(b), 2), "area", round(p.area, 1)))
    return unary_union(out), report


def to_path(g):
    def ring(c):
        pts = list(c.coords)
        return "M" + " L".join(f"{x:.3f},{y:.3f}" for x, y in pts[:-1]) + " Z"
    polys = [g] if isinstance(g, Polygon) else list(g.geoms)
    d = []
    for p in polys:
        d.append(ring(p.exterior)); d += [ring(i) for i in p.interiors]
    return " ".join(d)


if __name__ == "__main__":
    g = build()
    g, rep = bridge_islands(g) if not isinstance(g, Polygon) else (g, [])
    for r in rep: print(*r)
    g = g.simplify(0.02)
    print("type:", g.geom_type, "holes:", len(g.interiors) if isinstance(g, Polygon) else "-")
    minx, miny, maxx, maxy = g.bounds
    pad = 2
    W, H = maxx - minx + 2 * pad, maxy - miny + 2 * pad
    vb = f"{minx - pad:.3f} {miny - pad:.3f} {W:.3f} {H:.3f}"
    d = to_path(g)
    head = (f'<?xml version="1.0" encoding="UTF-8"?>\n'
            f'<svg xmlns="http://www.w3.org/2000/svg" width="{W:.2f}mm" height="{H:.2f}mm" viewBox="{vb}">\n'
            f'<title>Frohe Weihnachten - FF-Vorderthiersee (Laser Cut)</title>\n')
    out = os.path.join(HERE, "Weihnachten_FF-Vorderthiersee_lasercut.svg")
    with open(out, "w") as f:
        f.write(head + f'<path fill="none" stroke="#FF0000" stroke-width="0.1" fill-rule="evenodd" d="{d}"/>\n</svg>\n')
    prev = os.path.join(HERE, "preview.svg")  # temp, converted to preview.png by render.sh
    with open(prev, "w") as f:
        f.write(head + '<defs><linearGradient id="w" x1="0" y1="0" x2="1" y2="1">'
                '<stop offset="0" stop-color="#d9a066"/><stop offset="1" stop-color="#b07a43"/></linearGradient>'
                '<filter id="s"><feDropShadow dx="0.8" dy="1.2" stdDeviation="0.8" flood-opacity="0.45"/></filter></defs>\n'
                f'<rect x="{minx-pad}" y="{miny-pad}" width="{W}" height="{H}" fill="#1f3b2d"/>\n'
                f'<path fill="url(#w)" filter="url(#s)" fill-rule="evenodd" d="{d}"/>\n</svg>\n')
    print("size mm:", round(W, 1), "x", round(H, 1))
