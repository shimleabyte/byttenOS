#!/usr/bin/env python3
"""Construct and validate the raw BIOS disk image."""
import pathlib
import sys

if len(sys.argv) != 5:
    raise SystemExit("usage: mkimage.py STAGE1_BIN STAGE2_BIN LAYOUT_INC OUTPUT_IMG")

stage1_path, stage2_path, layout_path, image_path = map(pathlib.Path, sys.argv[1:])
stage1 = stage1_path.read_bytes()
stage2 = stage2_path.read_bytes()

if len(stage1) != 512:
    raise SystemExit(f"error: Stage 1 must be exactly 512 bytes (got {len(stage1)})")
if stage1[510:512] != b"\x55\xAA":
    raise SystemExit("error: invalid BIOS boot signature")
if not stage2:
    raise SystemExit("error: Stage 2 binary is empty")
if len(stage2) > 0x10000 - 0x8000:
    raise SystemExit("error: Stage 2 exceeds memory region 0x8000..0xFFFF")

sectors = (len(stage2) + 511) // 512
layout_text = layout_path.read_text(encoding="ascii")
expected_bytes = f"STAGE2_BYTES equ {len(stage2)}"
expected_sectors = f"STAGE2_SECTORS equ {sectors}"
if expected_bytes not in layout_text or expected_sectors not in layout_text:
    raise SystemExit("error: generated loader layout disagrees with the Stage 2 binary")
padded_stage2 = stage2.ljust(sectors * 512, b"\0")
image = stage1 + padded_stage2
image_path.parent.mkdir(parents=True, exist_ok=True)
image_path.write_bytes(image)

written = image_path.read_bytes()
if written[:512] != stage1 or written[512:512 + len(padded_stage2)] != padded_stage2:
    raise SystemExit("error: image contents do not match the expected LBA layout")
if len(written) != (1 + sectors) * 512:
    raise SystemExit("error: final image is not sector aligned")
print(f"Image: {image_path} ({len(written)} bytes, {1 + sectors} sectors)")
print(f"LBA 0: Stage 1; LBA 1..{sectors}: Stage 2 ({len(stage2)} bytes padded to {len(padded_stage2)})")
