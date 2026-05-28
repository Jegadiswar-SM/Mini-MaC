#include <iostream>
#include <iomanip>
#include <cstdint>
#include <verilated.h>
#include <verilated_vcd_c.h>
#include "Vmac_top.h"

vluint64_t main_time = 0;
double sc_time_stamp() { return main_time; }

struct PipelinedMem {
    uint32_t ram[2048] = {};

    void init() {
        // B = identity matrix (each column: 1,0,0,0 | 0,1,0,0 | ...)
        ram[0] = 0x00000001;  // col 0: 1,0,0,0
        ram[1] = 0x00000100;  // col 1: 0,1,0,0
        ram[2] = 0x00010000;  // col 2: 0,0,1,0
        ram[3] = 0x01000000;  // col 3: 0,0,0,1

        ram[0x10/4 + 0] = 0x04030201;  // row 0: 1,2,3,4
        ram[0x10/4 + 1] = 0x08070605;  // row 1: 5,6,7,8
        ram[0x10/4 + 2] = 0x0c0b0a09;  // row 2: 9,10,11,12
        ram[0x10/4 + 3] = 0x100f0e0d;  // row 3: 13,14,15,16
    }

    void write(uint32_t addr, uint32_t data) {
        uint32_t idx = (addr & 0x1FFF) >> 2;
        if (idx < 2048) ram[idx] = data;
    }

    uint32_t read(uint32_t addr) {
        uint32_t idx = (addr & 0x1FFF) >> 2;
        return (idx < 2048) ? ram[idx] : 0;
    }
};

void apb_write(Vmac_top* top, uint32_t addr, uint32_t data) {
    top->paddr  = addr;
    top->pwdata = data;
    top->pwrite = 1;
    top->psel   = 1;
    top->penable = 0;
    top->eval(); main_time += 5;
    top->clk = 0; top->eval(); main_time += 5;
    top->clk = 1; top->penable = 1; top->eval(); main_time += 5;
    top->clk = 0; top->eval(); main_time += 5;
    top->clk = 1; top->psel = 0; top->penable = 0; top->eval(); main_time += 5;
}

uint32_t apb_read(Vmac_top* top, uint32_t addr) {
    top->paddr  = addr;
    top->pwrite = 0;
    top->psel   = 1;
    top->penable = 0;
    top->eval(); main_time += 5;
    top->clk = 0; top->eval(); main_time += 5;
    top->clk = 1; top->penable = 1; top->eval(); main_time += 5;
    top->clk = 0; top->eval(); main_time += 5;
    uint32_t val = top->prdata;
    top->clk = 1; top->psel = 0; top->penable = 0; top->eval(); main_time += 5;
    return val;
}

int main(int argc, char** argv) {
    Verilated::commandArgs(argc, argv);
    Vmac_top* top = new Vmac_top;
    Verilated::traceEverOn(true);
    VerilatedVcdC* tfp = new VerilatedVcdC;
    top->trace(tfp, 99);
    tfp->open("mac_waveform.vcd");

    PipelinedMem mem;
    mem.init();

    top->clk = 0;
    top->rst_n = 0;
    top->paddr = 0; top->pwdata = 0;
    top->pwrite = 0; top->psel = 0; top->penable = 0;
    top->m_gnt_i = 0; top->m_rvalid_i = 0; top->m_rdata_i = 0;
    top->eval();

    for (int i = 0; i < 10; i++) {
        top->clk = 0; top->eval(); main_time += 5;
        top->clk = 1; top->eval(); main_time += 5;
    }
    top->rst_n = 1;

    std::cout << "[TB] Reset done. Programming MAC registers..." << std::endl;

    apb_write(top, 0x20, 0x10000000);  // WGT_ADDR
    apb_write(top, 0x24, 0x10000010);  // ACT_ADDR
    apb_write(top, 0x28, 0x10000020);  // RES_ADDR
    apb_write(top, 0x08, 0x00040404);  // DIM: M=4 K=4 N=4

    std::cout << "[TB] Registers written. Triggering MAC start..." << std::endl;
    apb_write(top, 0x00, 0x01);

    std::cout << "[TB] MAC started. Running simulation..." << std::endl;

    uint32_t pending_addr = 0;
    bool     pending_req  = false;
    bool     pending_we   = false;
    uint32_t pending_wdata = 0;

    uint32_t cycles = 0;
    const uint32_t MAX_CYCLES = 300;

    while (cycles < MAX_CYCLES) {
        if (pending_req) {
            top->m_rvalid_i = 1;
            if (pending_we) {
                mem.write(pending_addr, pending_wdata);
                top->m_rdata_i = 0;
            } else {
                top->m_rdata_i = mem.read(pending_addr);
            }
        } else {
            top->m_rvalid_i = 0;
            top->m_rdata_i  = 0;
        }

        pending_req   = top->m_req_o;
        pending_addr  = top->m_addr_o;
        pending_we    = top->m_we_o;
        pending_wdata = top->m_wdata_o;

        top->m_gnt_i = top->m_req_o;

        top->clk = 0;
        top->eval();
        main_time += 5;

        top->clk = 1;
        top->eval();
        main_time += 5;

        cycles++;

        if (cycles % 50 == 0) {
            std::cout << "[TB] Cycle " << cycles
                      << " | FSM: " << (int)top->fsm_state_o
                      << " | Done: " << (int)top->done_o
                      << " | REQ: " << (int)top->m_req_o
                      << " | ADDR: 0x" << std::hex << top->m_addr_o << std::dec
                      << std::endl;
        }

        if (top->done_o) break;
    }

    std::cout << "\n========================================" << std::endl;
    std::cout << "   MAC AUTONOMOUS TEST RESULTS" << std::endl;
    std::cout << "========================================" << std::endl;

    bool mac_done = top->done_o;
    if (mac_done) {
        std::cout << " MAC Operation: \033[1;32mCOMPLETE\033[0m (" << cycles << " cycles)" << std::endl;
    } else {
        std::cout << " MAC Operation: \033[1;31mINCOMPLETE (timeout)\033[0m" << std::endl;
    }

    std::cout << "\n Result Matrix (A x I):" << std::endl;
    bool all_correct = true;
    for (int r = 0; r < 4; r++) {
        std::cout << "  Row " << r << ": ";
        for (int w = 0; w < 4; w++) {
            uint32_t idx = (0x20 / 4) + r * 4 + w;
            uint32_t got = mem.ram[idx];
            uint32_t expected = 0x04030201 + 0x04040404 * r;
            uint32_t exp_byte = (expected >> (w * 8)) & 0xFF;
            uint32_t exp_word = exp_byte;  // each result is the byte extended to 32-bit
            std::cout << "0x" << std::hex << std::setw(8) << std::setfill('0')
                      << got << " ";
            if (got != exp_word) all_correct = false;
        }
        std::cout << std::dec << std::endl;
    }

    std::cout << "\n PE_RESULT readback via APB (last row's captured values):" << std::endl;
    int last_row = 3;
    uint32_t last_row_base = 0x04030201 + 0x04040404 * last_row;
    for (int i = 0; i < 4; i++) {
        apb_write(top, 0x18, i);
        uint32_t pe_val = apb_read(top, 0x1C);
        uint32_t exp_byte = (last_row_base >> (i * 8)) & 0xFF;
        std::cout << "  PE_ADDR=" << i << " -> PE_RESULT=0x"
                  << std::hex << std::setw(8) << std::setfill('0') << pe_val << std::dec;
        if (pe_val == exp_byte) {
            std::cout << " \033[1;32mOK\033[0m";
        } else {
            std::cout << " \033[1;31m(expected " << exp_byte << ")\033[0m";
            all_correct = false;
        }
        std::cout << std::endl;
    }

    if (all_correct) {
        std::cout << "\n \033[1;32mALL RESULTS CORRECT\033[0m" << std::endl;
    } else {
        std::cout << "\n \033[1;31mSOME RESULTS INCORRECT\033[0m" << std::endl;
    }

    tfp->close();
    delete top;
    return (mac_done && all_correct) ? 0 : 1;
}
