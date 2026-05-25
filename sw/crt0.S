.section .vectors, "ax"
.option norvc
.global _start

_start:
    /* 1. Setup Stack Pointer (§16.1) */
    la sp, _stack_top

    /* 2. Clear BSS (Zero out uninitialized variables) */
    la a0, _sbss
    la a1, _ebss
    bge a0, a1, end_bss
loop_bss:
    sw x0, 0(a0)
    addi a0, a0, 4
    blt a0, a1, loop_bss
end_bss:

    /* 3. Call Main */
    call main

    /* 4. Catch-all loop if main returns */
loop_forever:
    wfi
    j loop_forever
