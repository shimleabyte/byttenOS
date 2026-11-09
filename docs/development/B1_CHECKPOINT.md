# byttenOS B1.1 checkpoint

**Milestone:** B1.1 — Multi-stage legacy BIOS boot foundation  
**Status:** Sources committed; assembly and emulator verification remain blocked by missing tools in the current execution environment.

## Implemented

- Defined the Stage 1 / Stage 2 real-mode handoff contract.
- Added Stage 1 with INT 13h EDD capability detection and AH=42h LBA read.
- Added independent Stage 2 diagnostic loader.
- Added generated Stage 2 sector-count include derived from the assembled binary.
- Added image builder with size, signature, capacity, generated-layout agreement, binary DAP agreement, alignment, and content checks.
- Added Makefile targets and README.

## Boot contract

- BIOS enters Stage 1 at physical address 0x7C00; DL contains the BIOS boot drive.
- Stage 1 initializes DS=ES=FS=GS=SS=0, uses SP=0x7C00, clears DF, saves DL, and requires EDD support.
- Stage 2 is stored at LBA 1 and loaded at physical address 0x8000 (0000:8000).
- Stage 2 entry: CS:IP=0000:8000, real mode, DS=ES=FS=GS=SS=0, SP=0x7C00, DL preserved.
- Stage 2 prints a diagnostic and halts.

## Memory layout

| Physical range | Allocation |
|---|---|
| 0x00000..0x003FF | IVT, untouched |
| 0x00400..0x004FF | BIOS data area, untouched |
| 0x05000..0x07BFF | Reserved low-memory workspace; real-mode stack grows downward from 0x7C00 |
| 0x07C00..0x07DFF | Stage 1 boot sector |
| 0x08000..0x0FFFF | Stage 2 load region, maximum 32 KiB |

Stage 2 does not overlap Stage 1 or the IVT/BIOS data area. Its transfer is capped at 64 sectors and ends at the 64 KiB boundary.

## Disk layout

- LBA 0: exactly 512-byte Stage 1.
- LBA 1..N: Stage 2 padded to N sectors.
- N is generated from Stage 2's assembled byte length and assembled directly into Stage 1's DAP. The image builder checks the actual DAP bytes against N.

## Build and verification status

- Available in this execution environment: GCC, GNU LD, objcopy, Make, Python 3.
- Missing: NASM and QEMU.
- Package installation was attempted but did not complete before the environment command timed out.
- Python source syntax checks passed.
- Synthetic image-builder test passed for sector padding and LBA placement.
- Negative synthetic test confirmed that a mismatched Stage 1 DAP is rejected.
- No NASM assembly, actual disk-image build, or QEMU boot has been verified.

## Outstanding work / exact next action

1. Install NASM and QEMU on the actual development host or provide an execution environment with both.
2. Run make clean && make boot && make image; fix any assembler/build failures.
3. Inspect Stage 1 bytes/signature and verify Stage 2 LBA placement.
4. Run make run and observe the Stage 2 diagnostic message.
5. Only then mark B1.1 complete. Do not start B2 before observed B1.1 success.
