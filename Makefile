NASM ?= nasm
PYTHON ?= python3
QEMU ?= qemu-system-x86_64
BUILD := build
STAGE1 := $(BUILD)/stage1.bin
STAGE2 := $(BUILD)/stage2.bin
LAYOUT := $(BUILD)/layout.inc
IMAGE := $(BUILD)/byttenOS.img

.PHONY: all boot image run clean
all: image

$(BUILD):
	mkdir -p $@

$(STAGE2): boot/stage2/loader.asm | $(BUILD)
	$(NASM) -f bin $< -o $@

$(LAYOUT): $(STAGE2) scripts/gen_layout.py
	$(PYTHON) scripts/gen_layout.py $(STAGE2) $@

$(STAGE1): boot/stage1/boot.asm $(LAYOUT)
	$(NASM) -I ./ -f bin $< -o $@

boot: $(STAGE1) $(STAGE2)
	$(PYTHON) -c 'from pathlib import Path; p=Path("$(STAGE1)").read_bytes(); assert len(p)==512, f"Stage 1 size: {len(p)}"; assert p[510:512]==b"\x55\xaa", "invalid boot signature"; print("Stage 1: 512 bytes; boot signature valid")'

$(IMAGE): $(STAGE1) $(STAGE2) $(LAYOUT) scripts/mkimage.py
	$(PYTHON) scripts/mkimage.py $(STAGE1) $(STAGE2) $(LAYOUT) $@

image: $(IMAGE)

run: $(IMAGE)
	$(QEMU) -machine pc -drive format=raw,file=$(IMAGE),if=ide -boot c

clean:
	rm -rf $(BUILD)
