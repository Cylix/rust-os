    /* system boots in 32bits protected mode: instruct as to compile the code with that assumption */
    .code32

    /* kernel entrypoint, defined in .text section below */
    .global _start

    /*
     * reserve initial page tables space for identity mapping
     *   - 'a': section is allocatable
     *   - 'w': section is writable
     *   - @nobits: section does not contain data (only occupies space)
     *
     * refer to:
     *   - https://os.phil-opp.com/entering-longmode/#set-up-identity-paging
     *   - https://en.wikipedia.org/wiki/X86-64#Virtual_address_space_details
     */
    .section .page_tables, "aw", @nobits
    /* Page-Map Level-4 Table (PML4-table): one 4KiB table containing 512 8-bytes entries, each pointing to a PDP-table */
pml4_table:
    .skip 4096 /* 4 KiB */

    /* Page-Directory Pointer Table (PDP-table): one 4KiB table containing 512 8-bytes entries, each pointing to a PD-table */
pdp_table:
    .skip 4096 /* 4 KiB */

    /* Page-Directory Table (PD-table): one 4KiB table containing 512 8-bytes entries, each pointing to a P-table */
pd_table:
    .skip 4096 /* 4 KiB */

    /* Page Table (P-table): one 4KiB table containing 512 8-bytes entries, each pointing to a 4KiB physical memory page */
p_table:
    .skip 4096 /* 4 KiB */

    /*
     * reserve initial stack space
     *   - 'a': section is allocatable
     *   - 'w': section is writable
     *   - @nobits: section does not contain data (only occupies space)
     *
     * notice stack bottom is at the lower addresses, and stack top at the higher addresses
     * that's because the stack grows downwards
     */
    .section .stack, "aw", @nobits
stack_bottom:
    .skip 16384 /* 16 KiB */
stack_top:

    .section .text
_start:
    /* initialize stack pointer */
    mov $stack_top, %esp

    /* checks */
    call check_multiboot
    call check_cpuid
    call check_long_mode

    /* initial page table setup */
    call identity_mapping

    /* OK */
    jmp ok

/*
 * validate kernel was started by a multiboot-compliant bootloader, allowing us to use multiboot features
 * multiboot-compliant bootloaders must set eax to 0x36d76289 (magic code)
 *
 * refer to https://os.phil-opp.com/entering-longmode/#multiboot-check
 */
check_multiboot:
    cmp $0x36d76289, %eax
    jne no_multiboot
    ret

no_multiboot:
    mov $'0', %al
    jmp error

/*
 * validate CPUID is supported, allowing us to retrive CPU information
 * this is done by attempting to flip the ID bit (bit 21) in the FLAGS register
 * if we can flip it, CPUID is available
 *
 * refer to:
 *   - https://os.phil-opp.com/entering-longmode/#cpuid-check
 *   - https://wiki.osdev.org/CPUID
 */
check_cpuid:
    /*
     * copy FLAGS register:
     *   1. copy FLAGS register into the stack (pushfd)
     *   2. load it into ax register (pop)
     *   3. copy it into cx register (mov)
     */
    pushf
    pop %eax
    mov %ecx, %eax

    /* flip the CPUID bit (21st bit) */
    xor $1 << 21, %eax

    /* save updated FLAGS:
     *   1. copy FLAGS from ax into the stack (push)
     *   2. copy stack to FLAGS register (popfd)
     */
    push %eax
    popf

    /*
     * copy FLAGS register:
     *   1. copy FLAGS register into the stack (pushfd)
     *   2. load it into ax register (pop)
     *
     * if CPUID is supported, FLAGS will contain the persisted flipped bit
     */
    pushf
    pop %eax

    /*
     * restore FLAGS as it was before this check (undoing the bit flip if it worked)
     *   1. copy original FLAGS from cx into the stack (push)
     *   2. copy stack to FLAGS register (popfd)
     */
    push %ecx
    popf

    /*
     * check if CPUID is supported by comparing ax and cx
     *   - cx contains the FLAGS configuration before attempting to flip the bit
     *   - ax contains the FLAGS configuration after attempting to flip the bit
     *   => if they are equal then that means the bit wasn't flipped, and CPUID isn't supported
     */
    cmp %eax, %ecx
    je .no_cpuid
    ret

.no_cpuid:
    mov $'1', %al
    jmp error

/*
 * validate long mode is supported, allowing us to switch to 64-bits mode
 * this is done by checking if a specific bit is set in the information returned by cpuid
 * refer to:
 *   - https://os.phil-opp.com/entering-longmode/#long-mode-check
 *   - https://wiki.osdev.org/Setting_Up_Long_Mode#x86_or_x86-64
 */
check_long_mode:
    /*
     * cpu information is retrived by calling cpuid with a parameter in eax register
     * in return, cpuid responds with data sets in various registers
     *
     * cpuid can accept a different range of parameters depending on the processor
     * older processor only supports 0x80000000
     * newer processes supports values greater than 0x80000000 (extended processor info)
     *
     * long-mode can be checked by calling cpuid with 0x80000001 (extended processor info)
     * thus, we first need to check if the extended processor info is supported:
     *   1. set cpuid parameter to 0x80000000 in eax
     *   2. call cpuid: cpuid will set the maximum parameter it can support in eax
     *   3. ensure eax is at least 0x80000001
     */
    mov $0x80000000, %eax
    cpuid
    cmp $0x80000001, %eax
    jb no_long_mode

    /*
     * we can now request the extended processor info and check for long-mode:
     *   1. set cpuid parameter to 0x80000001 in eax
     *   2. call cpuid:  long-mode information will be set in the 29th lower bit of edx
     *   3. ensure long-mode is enabled (29th lower bit of edx is non-zero)
     */
    mov $0x80000001, %eax
    cpuid
    test $1 << 29, %edx
    jz no_long_mode
    ret

no_long_mode:
    mov $'2', %al
    jmp error

/*
 * set up initial page tables, with identity mapping of the first 2MiB of memory:
 *   - one 4KiB P-Table (starting at 'p_table'), with 512 8-bytes entries, each pointing to the first 512 4KiB physical memory pages
 *   - one 4KiB PD-Table (starting at 'pd_table'), with a single entry pointing to the P-Table ('p_table')
 *   - one 4KiB PDP-Table (starting at 'pdp_table'), with a single entry pointing to the PD-Table ('pd_table')
 *   - one 4KiB PML4-Table (starting at 'pml4_table'), with a single entry pointing to the PDP-Table ('pdp_table')
 *
 * 1 PML4-table entry * 1 PDP-table entry * 1 PD-table entry * 512 P-table entries * 4096-bytes memory page entries = 2MiB
 */
identity_mapping:
    /* map first PML4-Table entry to PDP-Table table */
    mov pdp_table, %eax
    or $0b11, %eax /* set bit 0 (page present) and bit 1 (page writable) */
    mov %eax, [pml4_table]

    /* map first PDP-Table entry to PD-Table table */
    mov pd_table, %eax
    or $0b11, %eax /* set bit 0 (page present) and bit 1 (page writable) */
    mov %eax, [pdp_table]

    /* map first PD-Table entry to P-Table table */
    mov p_table, %eax
    or $0b11, %eax /* set bit 0 (page present) and bit 1 (page writable) */
    mov %eax, [pd_table]

    /* map each P-Table entry to identity map the first 2MiB of memory */
    mov p_table, %ebx /* p_table address */
    mov $0, %ecx /* counter variable */

map_p_table:
    /* map ecx-th P-Table entry to a memory starting at 4KiB*ecx */
    mov $0x1000, %eax /* 4KiB */
    mul %ecx
    or $0b11, %eax /* set bit 0 (page present) and bit 1 (page writable) */
    mov %eax, (%ebx, %ecx, 8) /* p_table[entry_index * 8] (with p_table == ebx, entry_index == ecx, and 8 being the size of each p_table entry) */

    /* keep looping to populate all 512 P-Table entries */
    inc %ecx
    cmp $512, %ecx
    jne map_p_table

    ret

/*
 * print `OK` to screen
 *
 * VGA buffer starts at 0xb8000, but printing from the third line since Qemu window frame hides the two first lines...
 * each line is 80 characters, each represented with 2 bytes: 3rd line is at byte 320 (0x140)
 */
ok:
    movw $0x074f, 0xb8140 /* 'O' */
    movw $0x074b, 0xb8142 /* 'K' */
    hlt

/* print `ERR: ` and the given error code to screen, and hang
 * parameter: error code (in ascii) in al (lower 8 bits of eax register)
 *
 * VGA buffer starts at 0xb8000, but printing from the third line since Qemu window frame hides the two first lines...
 * each line is 80 characters, each represented with 2 bytes: 3rd line is at byte 320 (0x140)
 */
error:
    movw $0x4f45, 0xb8140 /* 'E' */
    movw $0x4f52, 0xb8142 /* 'R' */
    movw $0x4f52, 0xb8144 /* 'R' */
    movw $0x4f3a, 0xb8146 /* ':' */
    movw $0x4f20, 0xb8148 /* ' ' */
    movb %al, 0xb814a /* error code */
    movb $0x4f, 0xb814b /* red color for error code */
    hlt
