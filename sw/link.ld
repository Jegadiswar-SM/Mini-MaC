OUTPUT_ARCH(riscv)

MEMORY
{
    /* Boot ROM: Instructions and Constants (§16.2) */
    rom (rx)  : ORIGIN = 0x00000000, LENGTH = 4K
    /* SRAM: Data, BSS, and Stack (§16.2) */
    ram (rwx) : ORIGIN = 0x20000000, LENGTH = 8K
}

STACK_SIZE = 2K;

SECTIONS
{
    /* Code goes into ROM */
    .text : {
        _stext = .;
        KEEP(*(.vectors))   /* Interrupt vectors at the very start */
        *(.text .text.*)
        _etext = .;
    } > rom

    /* Read-only data (weights, constants) */
    .rodata : {
        *(.rodata .rodata.*)
    } > rom

    /* Initialized data (copied to RAM at boot) */
    .data : {
        _sdata = .;
        *(.data .data.*)
        _edata = .;
    } > ram AT > rom

    /* Uninitialized data (cleared to zero at boot) */
    .bss : {
        _sbss = .;
        *(.bss .bss.*)
        *(COMMON)
        _ebss = .;
    } > ram

    /* Stack grows downward from the top of RAM */
    .stack : {
        . = ALIGN(16);
        . += STACK_SIZE;
        _stack_top = .;
    } > ram
}
