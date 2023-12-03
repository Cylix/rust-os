/* link object files into an ELF-formatted executable */
/* refer to https://os.phil-opp.com/multiboot-kernel/#building-the-executable */

/* bootloader entry point: _start symbol */
ENTRY(_start)

/* sections of the object files that will be put in the final kernel image. */
SECTIONS {
    /* begin sections at 1 MiB, conventional place to load a kernel */
    /* that is because there are many special memory areas below the 1MB mark (e.g.: VGA buffer at 0xb8000) */
    . = 1M;

    .text : ALIGN(4K)
    {
        /* ensure that the multiboot header is at the beginning */
        *(.multiboot_header)
        *(.text)
    }

    /* Read-only data. */
    .rodata BLOCK(4K) : ALIGN(4K)
    {
        *(.rodata)
    }

    /* Read-write data (initialized) */
    .data BLOCK(4K) : ALIGN(4K)
    {
        *(.data)
    }

    /* Read-write data (uninitialized) and stack */
    .bss BLOCK(4K) : ALIGN(4K)
    {
        *(COMMON)
        *(.bss)
        *(.page_tables)
        *(.stack)
    }

    /* create variable whose address refers to the end of kernel address space */
    /* ensure that variable is 4096-bytes aligned */
    end_kernel = ALIGN(4K);
}
