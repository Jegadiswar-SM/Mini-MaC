#include "mini_mac.h"

int main() {
    // 1. Initialize Memory with small patterns
    uint32_t *sram = (uint32_t *)0x10000000;
    sram[0] = 0x01010101; 

    // 2. Trigger MAC (Autonomous fetch)
    MAC->DIM  = (4 << 16) | (4 << 8) | 4;
    MAC->CTRL = 0x1; 

    // 3. Polling with timeout
    for(int i=0; i<1000; i++) {
        if (MAC->STATUS & 0x8) break;
    }

    return 0;
}
