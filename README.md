# byttenOS

byttenOS is an experimental x86-64 operating-system project. Its current boot foundation targets legacy BIOS and uses NASM. B1.1 deliberately stops in 16-bit real mode; it does not enter protected mode or long mode and does not contain a kernel.

## B1.1 architecture

- **Stage 1** (`boot/stage1/boot.asm`) is a 512-byte BIOS boot sector. It preserves the BIOS drive number, checks for INT 13h Extensions, reads Stage 2 with the EDD LBA read service (AH=42h), and jumps to its fixed entry address only after a successful read.
- **Stage 2** (`boot/stage2/loader.asm`) is a separately assembled real-mode binary. It establishes its segment registers and stack, preserves the boot drive number, prints a diagnostic confirmation through BIOS video services, and halts.

## Disk and memory layout

| Disk LBA | Contents |
|---|---|
| 0 | Stage 1, exactly 512 bytes |
| 1 through N | Stage 2, padded to N 512-byte sectors |

N is generated from the assembled Stage 2 byte length. Stage 1 loads Stage 2 at physical `0x8000` (`0000:8000`). The allocated Stage 2 region is `0x8000..0xFFFF` (32 KiB, at most 64 sectors), which does not overlap the boot sector at `0x7C00..0x7DFF`, the IVT, or the BIOS data area. Both stages use a real-mode stack with `SS=0`, `SP=0x7C00`, growing downward below the boot sector. The generated sector count is shared with Stage 1 through `build/layout.inc`; it is not maintained separately.

Stage 2 entry contract: `CS:IP = 0000:8000`, real mode, `DS=ES=FS=GS=SS=0`, `SP=0x7C00`, and `DL` contains the BIOS boot drive identifier. Stage 2 does not depend on other BIOS register values.

## Requirements

- NASM
- Python 3
- GNU Make
- QEMU x86 system emulator (for `make run`)

## Build and run

```sh
make boot
make image
make run
make clean
```

`make boot` assembles both stages and validates Stage 1's size and signature. `make image` constructs and checks a sector-aligned raw image, including agreement between the generated Stage 1 sector count and the actual Stage 2 size. `make run` starts QEMU with a PC BIOS machine and raw IDE disk.

## Status and limitations

B1.1 implements only the BIOS-to-Stage-2 handoff. The image requires BIOS INT 13h Extensions. There is no filesystem, protected-mode transition, long-mode transition, page table, C kernel, native device driver, or shell. A successful build is not evidence of a successful emulator boot; record QEMU execution only after observing the Stage 2 diagnostic message.

## Next milestone

B1.1 must first pass binary validation and an observed QEMU boot. Only then begin B2: a controlled protected-mode/long-mode transition with CPU capability checks, A20 handling, GDT, page tables, and a deliberate stack. A freestanding C kernel remains a later milestone.
