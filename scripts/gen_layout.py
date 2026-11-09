#!/usr/bin/env python3
"""Generate the NASM layout include from the actual Stage 2 binary size."""
import pathlib
import sys

if len(sys.argv) != 3:
    raise SystemExit("usage: gen_layout.py STAGE2_BIN OUTPUT_INC")

stage2 = pathlib.Path(sys.argv[1])
output = pathlib.Path(sys.argv[2])
size = stage2.stat().st_size
sector_size = 512
load_address = 0x8000
region_end = 0x10000
capacity = region_end - load_address

if size <= 0:
    raise SystemExit("error: Stage 2 binary is empty")
if size > capacity:
    raise SystemExit(f"error: Stage 2 is {size} bytes; maximum is {capacity} bytes")
sectors = (size + sector_size - 1) // sector_size
if sectors > capacity // sector_size:
    raise SystemExit("error: Stage 2 sector transfer exceeds its allocated region")

output.parent.mkdir(parents=True, exist_ok=True)
output.write_text(
    "; Generated from the assembled Stage 2 binary. Do not edit.\n"
    f"STAGE2_BYTES equ {size}\n"
    f"STAGE2_SECTORS equ {sectors}\n",
    encoding="ascii",
)
print(f"Stage 2: {size} bytes, {sectors} sectors (LBA 1..{sectors})")
