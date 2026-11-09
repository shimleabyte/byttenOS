; byttenOS Stage 2 - minimal real-mode diagnostic loader
; Loaded at physical 0x8000 by Stage 1. No CPU mode transition in B1.1.
BITS 16
ORG 0x8000

stage2_entry:
    cli
    xor ax, ax
    mov ds, ax
    mov es, ax
    mov fs, ax
    mov gs, ax
    mov ss, ax
    mov sp, 0x7C00
    sti

    ; Preserve the BIOS drive identifier passed by Stage 1.
    mov [boot_drive], dl

    mov si, stage2_message
    call print_string

    cli
.halt:
    hlt
    jmp .halt

print_string:
    lodsb
    test al, al
    jz .done
    mov ah, 0x0E
    mov bx, 0x0007
    push ax
    push bx
    push si
    push ds
    int 0x10
    pop ds
    pop si
    pop bx
    pop ax
    jmp print_string
.done:
    ret

boot_drive db 0
stage2_message db 'byttenOS Stage 2: loader execution confirmed.', 0x0D, 0x0A, 0
