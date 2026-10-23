#!/usr/bin/env python3
"""Draws the menu bar radar as an SF Symbols variable template (template v7).

Usage: scripts/menu-bar-symbol.py Resources/Assets.xcassets/RadarMenuBar.symbolset/RadarMenuBar.svg

The template has Ultralight, Regular and Black at small scale; the system interpolates every other
weight and scale. Each layer keeps the same path structure in every weight, which interpolation needs.

Layers, bottom to top:
  0-2  outer ring, inner ring, centre dot: variable colour lights them from the centre out.
  3    aura around the blip: clears what is under it, so the rings open around the blip.
  4    needle and blip.
The aura and the needle rotate together around the radar's centre (the rotate anchor), so the opening
in the rings follows the needle. scripts/build-app.sh compiles the catalog; the SF Symbols app opens
the SVG for a preview.
"""
import math
import sys

K = 100/34.0             # template units per px of the original 36 px (@2x) menu bar glyph
CY = -35.23              # optical centre on the cap-height midpoint
R_OUT, R_IN = 14*K, 8.5*K
ANG = math.radians(45)   # needle points up and to the right
BLIP_D = 16*K
AURA = 1.1*K             # clearance the blip cuts around itself in the rings
WEIGHTS = {              # name: (column centre x, stroke multiplier)
    "Ultralight": (559.711, 0.45),
    "Regular": (1449.84, 1.08),
    "Black": (2933.4, 1.6),
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

def needle(w, blip_r):
    dx, dy = math.cos(ANG), -math.sin(ANG)
    nx, ny = -dy, dx
    h = w/2
    L = BLIP_D
    pts = [(nx*h, CY+ny*h), (dx*L+nx*h, CY+dy*L+ny*h), (dx*L-nx*h, CY+dy*L-ny*h), (-nx*h, CY-ny*h)]
    # Same winding as circle() (clockwise on screen), so overlaps add up instead of cancelling.
    area = sum(x0*y1-x1*y0 for (x0,y0),(x1,y1) in zip(pts, pts[1:]+pts[:1]))
    if area < 0: pts = pts[::-1]
    d = "M" + "L".join(f"{f(x)} {f(y)}" for x,y in pts) + "Z"
    return d + circle(dx*L, CY+dy*L, blip_r)

def layers(m):
    # Later paths draw on top. The aura clears what is drawn before it, so the rings open around
    # the blip wherever the needle points, and the opening turns with the needle.
    w = 2.4*K*m
    blip_r = (2.7 + 0.8*m)*K
    bx, by = math.cos(ANG)*BLIP_D, CY - math.sin(ANG)*BLIP_D
    return [
        ring(R_OUT, w),                                     # 0 outer ring
        ring(R_IN, w),                                      # 1 inner ring
        circle(0, CY, (2.2 + 0.8*m)*K),                     # 2 centre dot
        circle(bx, by, blip_r + AURA),                      # 3 aura around the blip
        needle(2.0*K*m, blip_r),                            # 4 needle with its blip
    ]

HALF = lambda m: R_OUT + 2.4*K*m/2 + 3*K   # ring plus the blip overhang
style = {
    0: "-sfsymbols-variable-threshold:0.68;-sfsymbols-motion-group:1",
    1: "-sfsymbols-variable-threshold:0.34;-sfsymbols-motion-group:1",
    2: "-sfsymbols-variable-threshold:0.0;-sfsymbols-motion-group:1",
    3: "opacity:0.0;-sfsymbols-clear-behind:true;-sfsymbols-motion-group:0;-sfsymbols-always-rotates:true",
    4: "-sfsymbols-motion-group:0;-sfsymbols-always-rotates:true",
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
