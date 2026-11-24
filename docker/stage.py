#!/usr/bin/env python3
"""Stage a subset of the map into docker/subset/ for the `subset` image target.

Copies only what the style needs: the style JSONs, berlin/metadata.json, the font stacks the style uses
(prebuilt glyph .pbf ranges), the berlin sprites (1x and 2x) and the vector tiles inside a bbox and zoom range.
It never writes to the source and never deletes anything. Run it from the repo root:

  python3 -I docker/stage.py                                       # cm-frontend map bounds, zoom 0-14
  python3 -I docker/stage.py --bbox 13.40,52.49,13.59,52.56        # small area for fast tests

To change the subset, delete docker/subset/ first; the script only adds files.
"""
import argparse
import json
import math
import os
import shutil
import sys

REPO = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))

# map bounds of cm-frontend (appConfig.bounds, the map's maxBounds)
DEFAULT_BBOX = (12.583801, 52.154557, 14.117298, 52.869959)
STYLES = ("culturemap.json", "culturemap-local.json")


def lon2x(lon, z):
    return int((lon + 180.0) / 360.0 * (1 << z))


def lat2y(lat, z):
    r = math.radians(lat)
    return int((1.0 - math.asinh(math.tan(r)) / math.pi) / 2.0 * (1 << z))


def copy(src, dst):
    os.makedirs(os.path.dirname(dst), exist_ok=True)
    if os.path.exists(dst) and os.path.getsize(dst) == os.path.getsize(src):
        return 0
    shutil.copyfile(src, dst)
    return 1


def fontstacks(style):
    stacks = set()

    def walk(v):
        if isinstance(v, list):
            if v and all(isinstance(s, str) for s in v) and v[0] not in ("literal", "get", "case", "match", "step"):
                stacks.add(",".join(v))
            for i in v:
                walk(i)

    for layer in style["layers"]:
        tf = layer.get("layout", {}).get("text-font")
        if tf is not None:
            walk(tf)
    return stacks


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--src", default=REPO)
    ap.add_argument("--out", default=os.path.join(REPO, "docker", "subset"))
    ap.add_argument("--bbox", default=",".join(map(str, DEFAULT_BBOX)), help="W,S,E,N")
    ap.add_argument("--minzoom", type=int, default=0)
    ap.add_argument("--maxzoom", type=int, default=14)
    ap.add_argument("--extra-font", action="append", default=["Berlin Type Bold"],
                    help="font stacks that app code (cm-frontend) uses in addition to the style")
    a = ap.parse_args()
    src, out = os.path.abspath(a.src), os.path.abspath(a.out)
    if out.startswith(src + os.sep) and os.path.relpath(out, src).split(os.sep)[0] != "docker":
        sys.exit("refusing to write inside the source data; use a folder under docker/")
    w, s, e, n = map(float, a.bbox.split(","))

    stacks = set(a.extra_font)
    for f in STYLES:
        copy(os.path.join(src, f), os.path.join(out, f))
        stacks |= fontstacks(json.load(open(os.path.join(src, f))))
    copy(os.path.join(src, "berlin/metadata.json"), os.path.join(out, "berlin/metadata.json"))

    for stack in sorted(stacks):
        if "," in stack:
            print(f"WARNING: multi-font stack {stack!r} cannot be served statically", file=sys.stderr)
            continue
        d = os.path.join(src, "fonts", stack)
        for f in os.listdir(d):
            copy(os.path.join(d, f), os.path.join(out, "fonts", stack, f))

    for f in os.listdir(os.path.join(src, "sprites")):
        if f.startswith("berlin") and f.endswith((".json", ".png")):
            copy(os.path.join(src, "sprites", f), os.path.join(out, "sprites", f))

    total = nbytes = 0
    for z in range(a.minzoom, a.maxzoom + 1):
        x0, x1 = lon2x(w, z), lon2x(e, z)
        y0, y1 = lat2y(n, z), lat2y(s, z)
        cnt = 0
        for x in range(x0, x1 + 1):
            for y in range(y0, y1 + 1):
                p = os.path.join(src, "berlin", str(z), str(x), f"{y}.pbf")
                if os.path.exists(p):
                    copy(p, os.path.join(out, "berlin", str(z), str(x), f"{y}.pbf"))
                    cnt += 1
                    nbytes += os.path.getsize(p)
        total += cnt
        print(f"z{z}: {cnt} tiles")
    print(f"fonts: {sorted(stacks)}")
    print(f"tiles: {total}, {nbytes / 1e6:.1f} MB")


if __name__ == "__main__":
    main()
