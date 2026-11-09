; byttenOS Stage 1 - 16-bit BIOS boot sector
; Disk contract: LBA 0 = this sector; LBA 1..N = Stage 2.
; build/layout.inc is generated from the assembled Stage 2 binary.
BITS 16
ORG 0x7C00

%include "build/layout.inc"

STAGE2_LOAD_SEG equ 0x0000
STAGE2_LOAD_OFF equ 0x8000
BOOT_STACK_TOP  equ 0x7C00

start:
    cli
    xor ax, ax
    mov ds, ax
    mov es, ax
    mov ss, ax
    mov sp, BOOT_STACK_TOP
    sti

    mov [boot_drive], dl

    ; Require BIOS Enhanced Disk Drive (EDD) extensions.
    mov bx, 0x55AA
    mov ah, 0x41
    mov dl, [boot_drive]
    push ds
    int 0x13
    pop ds
    jc disk_error
    cmp bx, 0xAA55
    jne disk_error
    test cx, 0x0001
    jz disk_error

    ; Read the exact padded Stage 2 sector count, derived at build time.
    mov word [dap_sector_count], STAGE2_SECTORS
    mov si, disk_address_packet
    mov dl, [boot_drive]
    mov ah, 0x42
    push ds
    int 0x13
    pop ds
    jc disk_error

    ; Stage 2 contract: CS:IP = 0000:8000, DL = BIOS boot drive.
    mov dl, [boot_drive]
    jmp STAGE2_LOAD_SEG:STAGE2_LOAD_OFF

disk_error:
    mov si, disk_error_message
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

disk_error_message db 'byttenOS: Stage 2 disk read failed', 0x0D, 0x0A, 0

align 4
disk_address_packet:
    db 0x10                 ; DAP size
    db 0x00                 ; reserved
dap_sector_count:
    dw 0                    ; populated from generated layout
    dw STAGE2_LOAD_OFF      ; destination offset
    dw STAGE2_LOAD_SEG      ; destination segment
    dq 1                    ; first Stage 2 sector (LBA 1)

times 510 - ($ - $$) db 0
dw 0xAA55
