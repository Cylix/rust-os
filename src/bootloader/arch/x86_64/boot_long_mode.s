    /* kernel 64-bits entrypoint, defined in .text section below */
    .global _start_long_mode

    .section .text
_start_long_mode:
    /* finalize long-mode setup by cleaning up registers from outdated entries */
    call reset_registers

    /* doing some 64-bits stuff: print 'okay' to the screen using %rax */
    mov $0x2f592f412f4b2f4f, %rax
    mov %rax, 0xb8140
    hlt

/*
 * reset registers for long-mode
 *   - the data segment registers (ss, ds, es, fs, and gs) still contain the data segment offsets of the old GDT
 *   - these registers are ignored by almost all instructions in 64-bit mode, but some instructions expect a valid data segment descriptor (or the null descriptor)
 *
 * refer to:
 *   - https://os.phil-opp.com/entering-longmode/#one-last-thing
 *   - https://wiki.osdev.org/Setting_Up_Long_Mode
 */
reset_registers:
    /* clear the interrupt flag */
    cli

    /* load the kernel data segment into all data segment registers */
    mov $gdt64_kernel_mode_data_segment_descriptor_offset, %ax
    mov %ax, %ss
    mov %ax, %ds
    mov %ax, %es
    mov %ax, %fs
    mov %ax, %gs

    ret
