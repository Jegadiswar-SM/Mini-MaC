#ifndef MINI_MAC_H
#define MINI_MAC_H

#include <stdint.h>

#define SRAM_BASE     0x10000000
#define MAC_BASE      0x40011000

typedef struct {
    volatile uint32_t CTRL;      // 0x00 — WO: write 1 to start
    volatile uint32_t STATUS;    // 0x04 — RO: bit[7]=done, bit[2:0]=fsm_state
    volatile uint32_t DIM;       // 0x08 — RW: M[23:16] K[15:8] N[7:0]
    uint32_t         _pad0[3];   // 0x0C–0x14
    volatile uint32_t PE_ADDR;   // 0x18 — WO: index 0-15
    volatile uint32_t PE_RESULT; // 0x1C — RO: result_hold[pe_addr[1:0]]
    volatile uint32_t WGT_ADDR;  // 0x20
    volatile uint32_t ACT_ADDR;  // 0x24
    volatile uint32_t RES_ADDR;  // 0x28
} MAC_TypeDef;

#define MAC  ((MAC_TypeDef *) MAC_BASE)

#define MAC_STATUS_DONE_MASK  0x80
#define MAC_STATUS_FSM_MASK   0x07

#endif
