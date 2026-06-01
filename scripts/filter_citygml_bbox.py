#!/usr/bin/env python3
"""Filter a large CityGML stream to cityObjectMember blocks intersecting a bbox."""

from __future__ import annotations

import argparse
import re
import sys
from pathlib import Path


MEMBER_OPEN = re.compile(r"<(?:\w+:)?cityObjectMember\b")
MEMBER_CLOSE = re.compile(r"</(?:\w+:)?cityObjectMember>")
BUILDING_OPEN = re.compile(r"<bldg:Building\b")
ENVELOPE_RE = re.compile(
    r"<gml:lowerCorner>(.*?)</gml:lowerCorner>.*?"
    r"<gml:upperCorner>(.*?)</gml:upperCorner>",
    re.DOTALL,
)
POS_RE = re.compile(r"<gml:pos(?:List)?[^>]*>(.*?)</gml:pos(?:List)?>", re.DOTALL)
FLOAT_RE = re.compile(r"[-+]?(?:\d+(?:\.\d*)?|\.\d+)(?:[Ee][-+]?\d+)?")


def numbers(text: str) -> list[float]:
    return [float(match.group(0)) for match in FLOAT_RE.finditer(text)]


def ranges_intersect(
    xmin: float,
    ymin: float,
    xmax: float,
    ymax: float,
    bbox: tuple[float, float, float, float],
) -> bool:
    bxmin, bymin, bxmax, bymax = bbox
    return xmax >= bxmin and xmin <= bxmax and ymax >= bymin and ymin <= bymax


def block_intersects_bbox(block: str, bbox: tuple[float, float, float, float]) -> bool:
    if not BUILDING_OPEN.search(block):
        return False

    # Building-level envelopes are cheap and reliable in this dataset.
    for lower, upper in ENVELOPE_RE.findall(block):
        low = numbers(lower)
        high = numbers(upper)
        if len(low) >= 2 and len(high) >= 2:
            if ranges_intersect(low[0], low[1], high[0], high[1], bbox):
                return True

    # Fallback for CityGML variants without envelopes.
    xs: list[float] = []
    ys: list[float] = []
    for text in POS_RE.findall(block):
        values = numbers(text)
        if len(values) < 2:
            continue
        stride = 3 if len(values) % 3 == 0 else 2
        for i in range(0, len(values) - 1, stride):
            xs.append(values[i])
            ys.append(values[i + 1])

    return bool(xs) and ranges_intersect(min(xs), min(ys), max(xs), max(ys), bbox)


def filter_stream(output: Path, bbox: tuple[float, float, float, float]) -> int:
    count = 0
    in_member = False
    wrote_root = False
    buffer: list[str] = []

    with output.open("w", encoding="utf-8", newline="") as dst:
        for raw in sys.stdin.buffer:
            line = raw.decode("utf-8", errors="replace")

            if not in_member and MEMBER_OPEN.search(line):
                in_member = True
                wrote_root = True
                buffer = [line]
                if MEMBER_CLOSE.search(line):
                    block = "".join(buffer)
                    if block_intersects_bbox(block, bbox):
                        dst.write(block)
                        count += 1
                    in_member = False
                continue

            if in_member:
                buffer.append(line)
                if MEMBER_CLOSE.search(line):
                    block = "".join(buffer)
                    if block_intersects_bbox(block, bbox):
                        dst.write(block)
                        count += 1
                        if count % 250 == 0:
                            print(f"{count} buildings kept...", file=sys.stderr, flush=True)
                    in_member = False
                    buffer = []
                continue

            if not wrote_root:
                dst.write(line)

        dst.write("</CityModel>\n")

    return count


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument("--bbox", nargs=4, type=float, metavar=("XMIN", "YMIN", "XMAX", "YMAX"), required=True)
    parser.add_argument("--output", type=Path, required=True)
    args = parser.parse_args()

    kept = filter_stream(args.output, tuple(args.bbox))
    print(f"Kept {kept} buildings in {args.output}", file=sys.stderr)
    return 0 if kept else 2


if __name__ == "__main__":
    raise SystemExit(main())
