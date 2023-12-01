    /* system boots in 32bits protected mode: instruct as to compile the code with that assumption */
    .code32

    /* specs: https://www.gnu.org/software/grub/manual/multiboot2/multiboot.html#Header-layout */
    .section .multiboot_header
header_start:
    /* magic number (multiboot 2) */
    .long 0xe85250d6
    /* architecture 0 (32-bit protected mode of i386) */
    .long 0
    /* header length */
    .long header_end - header_start
    /* checksum */
    .long 0x100000000 - (0xe85250d6 + 0 + (header_end - header_start))

    /* insert optional multiboot tags here */

    /* required end tag */
    /* type */
    .word 0
    /* flags */
    .word 0
    /* size */
    .long 8
header_end:
