    /* kernel entrypoint, defined in .text section below */
    .global _start

    .section .text
_start:
    /* print `Hi` to screen */
    /* VGA buffer starts at 0xb800, but printing farther away since Qemu window frame hides the first line... */
    movl $0x07690748, 0xb81F4
    hlt
