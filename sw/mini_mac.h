#ifndef MINI_MAC_H
#define MINI_MAC_H

#include <stdint.h>

// Base Addresses (§12.3)
#define DMA_BASE      0x40000000
#define MAC_BASE      0x40010000
#define TELEM_BASE    0x40020000

// DMA Registers (§6.2)
typedef struct {
    volatile uint32_t SRC_ADDR;
    volatile uint32_t DST_ADDR;
    volatile uint32_t LENGTH;
    volatile uint32_t CONTROL;
    volatile uint32_t STATUS;
    volatile uint32_t IRQ_ACK;
} DMA_TypeDef;

// MAC Registers (§12.4)
typedef struct {
    volatile uint32_t CTRL;
    volatile uint32_t STATUS;
    volatile uint32_t DIM;
    volatile uint32_t SCALE;
    volatile uint32_t CFG;
    volatile uint32_t IRQ;
    volatile uint32_t PE_ADDR;
    volatile uint32_t PE_RESULT;
} MAC_TypeDef;

// Access Macros
#define DMA   ((DMA_TypeDef *)  DMA_BASE)
#define MAC   ((MAC_TypeDef *)  MAC_BASE)

#endif
