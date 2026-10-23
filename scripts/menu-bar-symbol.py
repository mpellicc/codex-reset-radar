#!/usr/bin/env python3
"""Draws the menu bar radar as an SF Symbols variable template (template v7).

Usage: scripts/menu-bar-symbol.py Resources/Assets.xcassets/RadarMenuBar.symbolset/RadarMenuBar.svg

The template has Ultralight, Regular and Black at small scale; the system interpolates every other
weight and scale. Each layer keeps the same path structure in every weight, which interpolation needs.

Layers, bottom to top:
  0-2  centre dot, inner ring, outer ring: variable colour lights them from the centre out.
  3    needle and blip.
The outer ring is open around the blip. It rotates with the needle around the radar's centre (the
rotate anchor), so the opening stays around the blip and reads as the blip's own halo. Xcode compiles
the catalog with the app (scripts/build-app.sh); the SF Symbols app opens the SVG for a preview.
"""
import math
import sys

K = 100/34.0             # template units per px of the original 36 px (@2x) menu bar glyph
CY = -35.23              # optical centre on the cap-height midpoint
R_OUT = 14*K             # centre line of the outer ring
ANG = math.radians(45)   # needle points up and to the right
BLIP_D = 16*K            # blip centre, just outside the outer ring
CLEARANCE = 1.1*K        # space between the blip and the ends of the outer ring
WEIGHTS = {              # name: (column centre x, stroke multiplier)
    "Ultralight": (559.711, 0.45),
    "Regular": (1449.84, 1.0),
    "Black": (2933.4, 1.4),
}


def f(v): return f"{v:.4f}".rstrip("0").rstrip(".")


def circle(cx, cy, r, ccw=False):
    # Four cubic quarter-circles. SVG arcs get split into a varying number of curves once their
    # endpoints are rounded, which breaks interpolation between weights; cubics always stay four.
    k = 0.5522847498 * r
    if not ccw:   # clockwise on screen (y down): right, bottom, left, top
        segs = [((cx+r, cy+k), (cx+k, cy+r), (cx, cy+r)), ((cx-k, cy+r), (cx-r, cy+k), (cx-r, cy)),
                ((cx-r, cy-k), (cx-k, cy-r), (cx, cy-r)), ((cx+k, cy-r), (cx+r, cy-k), (cx+r, cy))]
    else:         # counter-clockwise: right, top, left, bottom
        segs = [((cx+r, cy-k), (cx+k, cy-r), (cx, cy-r)), ((cx-k, cy-r), (cx-r, cy-k), (cx-r, cy)),
                ((cx-r, cy+k), (cx-k, cy+r), (cx, cy+r)), ((cx+k, cy+r), (cx+r, cy+k), (cx+r, cy))]
    d = f"M{f(cx+r)} {f(cy)}"
    for (a, b, c) in segs:
        d += f"C{f(a[0])} {f(a[1])} {f(b[0])} {f(b[1])} {f(c[0])} {f(c[1])}"
    return d + "Z"


def ring(r, w):
    return circle(0, CY, r+w/2) + circle(0, CY, r-w/2, ccw=True)


def arc_points(r, a0, a1, n):
    """Cubic segments of the arc from angle a0 to a1 (radians, counter-clockwise, y up), always n of them."""
    def P(a): return (r*math.cos(a), CY - r*math.sin(a))
    def T(a): return (-math.sin(a), -math.cos(a))   # tangent, in y-down coordinates
    step = (a1-a0)/n
    k = 4/3*math.tan(step/4)*r
    segs = []
    for i in range(n):
        s0, s1 = a0 + i*step, a0 + (i+1)*step
        p0, p1 = P(s0), P(s1)
        t0, t1 = T(s0), T(s1)
        segs.append(((p0[0]+k*t0[0], p0[1]+k*t0[1]), (p1[0]-k*t1[0], p1[1]-k*t1[1]), p1))
    return P(a0), segs


def gapped_ring(r, w, gap):
    """The ring with an opening of half-angle `gap` around the needle's direction."""
    a0, a1 = ANG + gap, ANG - gap + 2*math.pi
    start, outer = arc_points(r + w/2, a0, a1, 4)
    end, inner = arc_points(r - w/2, a1, a0, 4)
    d = f"M{f(start[0])} {f(start[1])}"
    for (a, b, c) in outer:
        d += f"C{f(a[0])} {f(a[1])} {f(b[0])} {f(b[1])} {f(c[0])} {f(c[1])}"
    d += f"L{f(end[0])} {f(end[1])}"
    for (a, b, c) in inner:
        d += f"C{f(a[0])} {f(a[1])} {f(b[0])} {f(b[1])} {f(c[0])} {f(c[1])}"
    return d + "Z"


def needle(w, blip_r):
    dx, dy = math.cos(ANG), -math.sin(ANG)
    nx, ny = -dy, dx
    h = w/2
    L = BLIP_D
    pts = [(nx*h, CY+ny*h), (dx*L+nx*h, CY+dy*L+ny*h), (dx*L-nx*h, CY+dy*L-ny*h), (-nx*h, CY-ny*h)]
    # Same winding as circle() (clockwise on screen), so overlaps add up instead of cancelling.
    area = sum(x0*y1-x1*y0 for (x0, y0), (x1, y1) in zip(pts, pts[1:]+pts[:1]))
    if area < 0:
        pts = pts[::-1]
    d = "M" + "L".join(f"{f(x)} {f(y)}" for x, y in pts) + "Z"
    return d + circle(dx*L, CY+dy*L, blip_r)


def stroke(m): return 3.0*K*m


def layers(m):
    # Later paths draw on top. Dot, inner ring and outer ring are equally spaced: the gaps between
    # them match, and the outer ring keeps its size in every weight.
    w = stroke(m)
    dot = (2.5 + 1.0*m)*K
    gap = (R_OUT - dot - 1.5*w) / 2
    r_in = dot + gap + w/2
    blip_r = (2.7 + 0.8*m)*K
    # The opening in the outer ring keeps CLEARANCE between the blip and the ring's ends.
    reach = blip_r + CLEARANCE + w/2
    cos_half = (BLIP_D**2 + R_OUT**2 - reach**2) / (2*BLIP_D*R_OUT)
    half = math.acos(max(-1.0, min(1.0, cos_half)))
    return [
        circle(0, CY, dot),                                 # 0 centre dot
        ring(r_in, w),                                      # 1 inner ring
        gapped_ring(R_OUT, w, half),                        # 2 outer ring, open around the blip
        needle(2.2*K*m, blip_r),                            # 3 needle with its blip
    ]


def HALF(m): return R_OUT + stroke(m)/2 + 3*K   # ring plus the blip overhang


# The outer ring turns with the needle, so its opening stays around the blip.
style = {
    0: "-sfsymbols-variable-threshold:0.0;-sfsymbols-motion-group:1",
    1: "-sfsymbols-variable-threshold:0.34;-sfsymbols-motion-group:1",
    2: "-sfsymbols-variable-threshold:0.68;-sfsymbols-motion-group:0;-sfsymbols-always-rotates:true",
    3: "-sfsymbols-motion-group:0;-sfsymbols-always-rotates:true",
}
css = ".defaults {-sfsymbols-rotates-clockwise:true}\n\n"
css += "\n".join(f".monochrome-{i} {{{s}}}" for i,s in style.items()) + "\n\n"
css += "\n".join(f".multicolor-{i}:tintColor {{{s}}}" for i,s in style.items()) + "\n\n"
css += "\n".join(f".hierarchical-{i}:primary {{{s}}}" for i,s in style.items()) + "\n\n"
css += ".SFSymbolsPreviewWireframe {fill:none;opacity:1.0;stroke:black;stroke-width:0.5}\n"

guides, groups, anchors = [], [], []
for wname,(cx,m) in WEIGHTS.items():
    half = HALF(m)
    left, right = cx-half, cx+half
    guides.append(f'  <line id="right-margin-{wname}-S" style="fill:none;stroke:#00AEEF;stroke-width:0.5;opacity:1.0;" x1="{f(right)}" x2="{f(right)}" y1="600.785" y2="720.121"/>')
    guides.append(f'  <line id="left-margin-{wname}-S" style="fill:none;stroke:#FF3B30;stroke-width:0.5;opacity:1.0;" x1="{f(left)}" x2="{f(left)}" y1="600.785" y2="720.121"/>')
    paths = "\n".join(
        f'   <path class="monochrome-{i} multicolor-{i}:tintColor hierarchical-{i}:primary SFSymbolsPreviewWireframe" d="{d}"/>'
        for i,d in enumerate(layers(m)))
    # The needle sweeps around the radar's centre, not the middle of its own bounds.
    anchors.append(f'  <circle cx="{f(cx)}" cy="{f(696 + CY)}" id="{wname}-S-rotate-anchor" r="1" style="fill:#FFCC00; opacity:1.0;"/>')
    groups.append(f'  <g id="{wname}-S" transform="matrix(1 0 0 1 {f(cx)} 696)">\n{paths}\n  </g>')

line = lambda i,y: f'  <line id="{i}" style="fill:none;stroke:#27AAE1;opacity:1;stroke-width:0.5;" x1="263" x2="3036" y1="{y}" y2="{y}"/>'
svg = f'''<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE svg PUBLIC "-//W3C//DTD SVG 1.1//EN" "http://www.w3.org/Graphics/SVG/1.1/DTD/svg11.dtd">
<svg version="1.1" xmlns="http://www.w3.org/2000/svg" xmlns:xlink="http://www.w3.org/1999/xlink" viewBox="0 0 3300 2200">
 <!--glyph: "", point size: 100.0, font version: "", template writer version: "138.0.0"-->
 <style>{css}</style>
 <g id="Notes">
  <rect height="2200" id="artboard" style="fill:white;opacity:1" width="3300" x="0" y="0"/>
  <text id="template-version" style="stroke:none;fill:black;font-family:sans-serif;font-size:13;text-anchor:end;" transform="matrix(1 0 0 1 3036 1933)">Template v.7.0</text>
  <text id="descriptive-name" style="stroke:none;fill:black;font-family:sans-serif;font-size:13;text-anchor:end;" transform="matrix(1 0 0 1 3036 1969)">Codex Reset Radar menu bar glyph</text>
 </g>
 <g id="Guides">
{line("Baseline-S", 696)}
{line("Capline-S", 625.541)}
{line("Baseline-M", 1126)}
{line("Capline-M", 1055.54)}
{line("Baseline-L", 1556)}
{line("Capline-L", 1485.54)}
{chr(10).join(guides)}
 </g>
 <g id="Symbols">
{chr(10).join(groups)}
 </g>
 <g id="Anchors">
{chr(10).join(anchors)}
 </g>
</svg>
'''
open(sys.argv[1],"w").write(svg)
