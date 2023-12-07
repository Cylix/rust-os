    /* kernel 64-bits entrypoint, defined in .text section below */
    .global _start_long_mode

    .section .text
_start_long_mode:
    mov $0x2f592f412f4b2f4f, %rax
    mov %rax, 0xb8140
    hlt
