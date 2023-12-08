/*
 * link object files into an ELF-formatted executable
 * refer to https://os.phil-opp.com/multiboot-kernel/#building-the-executable
 */

/* bootloader entry point: _start symbol */
ENTRY(_start)

/*
 * explicitly define program headers and permissions
 * this prevents 'ld' from merging some sections together (e.g.: .text, .rodata, and .data), leading to unsafe RWE (read-write-exec) segments
 *
 * alternatively, the following can be done:
 *   - invoke 'ld' with `-z separate-code` to force some sections to be separated, but this may still merge some sections (e.g.: .rodata and .data)
 *   - call '. = ALIGN(4K)' between each section, but that's kinda hacky
 *
 * if needed, headers and segments can be inspected with 'readelf -lW <binary> | less'
 *
 * refer to:
 *   - https://www.redhat.com/en/blog/linkers-warnings-about-executable-stacks-and-segments
 *   - https://metebalci.com/blog/solution-to-load-segment-with-rwx-permissions-warning-with-cmsis/
 *   - https://ftp.gnu.org/old-gnu/Manuals/ld-2.9.1/html_chapter/ld_3.html
 *   - https://www.man7.org/linux/man-pages/man5/elf.5.html
 *   - https://docs.oracle.com/cd/E19683-01/816-1386/6m7qcoblk/index.html#chapter6-tbl-39
 */
PF_R = 0x4; /* read */
PF_W = 0x2; /* write */
PF_X = 0x1; /* execute */

PHDRS
{
  text   PT_LOAD FLAGS(PF_R | PF_X);
  rodata PT_LOAD FLAGS(PF_R);
  data   PT_LOAD FLAGS(PF_R | PF_W);
}

/* sections of the object files that will be put in the final kernel image. */
SECTIONS {
    /*
     * begin sections at 1 MiB, conventional place to load a kernel
     * that is because there are many special memory areas below the 1MB mark (e.g.: VGA buffer at 0xb8000)
     */
    . = 1M;

    .text ALIGN(4K) :
    {
        /* ensure that the multiboot header is at the beginning */
        *(.multiboot_header)
        *(.text)
    } : text

    /* read-only data. */
    .rodata ALIGN(4K) :
    {
        *(.rodata)
        *(.global_descriptor_table)
    } : rodata

    /* read-write data (initialized) */
    .data ALIGN(4K) :
    {
        *(.data)
    } : data

    /* read-write data (uninitialized) and stack */
    .bss ALIGN(4K) :
    {
        *(COMMON)
        *(.bss)
        *(.page_tables)
        *(.stack)
    } : data
}
