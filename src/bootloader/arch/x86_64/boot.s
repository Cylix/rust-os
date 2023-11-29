    /* kernel entrypoint, defined in .text section below */
    .global _start

    /*
     * reserve a stack for the initial thread
     *   - 'a': section is allocatable
     *   - 'w': section is writable
     *   - @nobits: section does not contain data (only occupies space)
     *
     * notice stack bottom is at the lower addresses, and stack top at the higher addresses
     * that's because the stack grows downwards
     */
    .section .stack, "aw", @nobits
stack_bottom:
    .skip 16384 # 16 KiB
stack_top:

    .section .text
_start:
    /* initialize stack pointer */
    movl $stack_top, %esp

    /* checks */
    call check_multiboot

    /* OK */
    jmp ok

/*
 * Validate kernel was started by a multiboot-compliant bootloader, allowing us to use multiboot features
 * Multiboot-compliant bootloaders must set eax to 0x36d76289 (magic code)
 */
check_multiboot:
    cmp $0x36d76288, %eax
    jne no_multiboot
    ret

no_multiboot:
    mov $'0', %al
    jmp error

/*
 * print `OK` to screen
 *
 * Note
 * VGA buffer starts at 0xb8000, but printing from the third line since Qemu window frame hides the two first lines...
 * Each line is 80 characters, each represented with 2 bytes: 3rd line is at byte 320 (0x140)
 */
ok:
    mov $0x074f, 0xb8140 /* 'O' */
    mov $0x074b, 0xb8142 /* 'K' */
    hlt

/* print `ERR: ` and the given error code to screen, and hang
 * parameter: error code (in ascii) in al
 *
 * Note
 * VGA buffer starts at 0xb8000, but printing from the third line since Qemu window frame hides the two first lines...
 * Each line is 80 characters, each represented with 2 bytes: 3rd line is at byte 320 (0x140)
 */
error:
    mov $0x4f45, 0xb8140 /* 'E' */
    mov $0x4f52, 0xb8142 /* 'R' */
    mov $0x4f52, 0xb8144 /* 'R' */
    mov $0x4f3a, 0xb8146 /* ':' */
    mov $0x4f20, 0xb8148 /* ' ' */
    movb %al, 0xb814a /* error code */
    movb $0x4f, 0xb814b /* red color for error code */
    hlt
