#include "mini_mac.h"

#define N 4

static uint32_t pack(const uint8_t d[4]) {
    return ((uint32_t)d[3] << 24) |
           ((uint32_t)d[2] << 16) |
           ((uint32_t)d[1] <<  8) |
           ((uint32_t)d[0]);
}

int main(void) {
    uint32_t *sram = (uint32_t *)SRAM_BASE;

    uint8_t a_rows[4][4] = {
        { 1, 2, 3, 4},
        { 5, 6, 7, 8},
        { 9,10,11,12},
        {13,14,15,16}
    };
    for (int r = 0; r < N; r++)
        sram[0x10 / 4 + r] = pack(a_rows[r]);

    uint8_t b_cols[4][4] = {
        {1,0,0,0},
        {0,1,0,0},
        {0,0,1,0},
        {0,0,0,1}
    };
    for (int c = 0; c < N; c++)
        sram[c] = pack(b_cols[c]);

    MAC->WGT_ADDR = 0x10000000;
    MAC->ACT_ADDR = 0x10000010;
    MAC->RES_ADDR = 0x10000020;
    MAC->DIM      = (4 << 16) | (4 << 8) | 4;

    MAC->CTRL = 1;

    volatile uint32_t timeout = 0;
    while (!(MAC->STATUS & MAC_STATUS_DONE_MASK)) {
        if (++timeout > 100000) break;
    }

    MAC->PE_ADDR = 7;
    volatile uint32_t pe7 = MAC->PE_RESULT;

    volatile uint32_t *res = (uint32_t *)0x10000020;
    (void)res; (void)pe7;

    return 0;
}
