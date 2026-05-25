#include <iostream>
#include <iomanip>
#include <verilated.h>
#include <verilated_vcd_c.h>
#include "Vsoc_top.h"
#include "Vsoc_top___024root.h" 

int main(int argc, char** argv) {
    Verilated::commandArgs(argc, argv);
    Vsoc_top* top = new Vsoc_top;
    Verilated::traceEverOn(true);
    VerilatedVcdC* tfp = new VerilatedVcdC;
    top->trace(tfp, 99);
    tfp->open("waveform.vcd");

    top->clk = 0; top->rst_n = 0;
    bool dma_ever_started = false;
    bool dma_finished = false;

    std::cout << "\033[1;34m[SIM] Starting MINI-MAC SoC Simulation...\033[0m" << std::endl;

    for (int i = 0; i < 50000; i++) {
        if (i == 100) top->rst_n = 1; 
        top->clk = !top->clk;
        top->eval();
        tfp->dump(i * 10);

        if (top->rootp->soc_top__DOT__dma_busy) dma_ever_started = true;
        else if (dma_ever_started) dma_finished = true;

        if (i % 10000 == 0 && top->rst_n) {
            std::cout << "[DEBUG] Cycle " << i 
                      << " | PC: 0x" << std::hex << top->rootp->soc_top__DOT__instr_addr 
                      << " | MAC State: " << (int)top->rootp->soc_top__DOT__mac_fsm_state << std::dec << std::endl;
        }
    }

    std::cout << "\n================================================" << std::endl;
    std::cout << "        MINI-MAC TELEMETRY DASHBOARD" << std::endl;
    std::cout << "================================================" << std::endl;
    
    if (top->rootp->soc_top__DOT__instr_addr > 0x0) std::cout << "1. CPU Boot Check:      \033[1;32mPASSED\033[0m" << std::endl;
    else std::cout << "1. CPU Boot Check:      \033[1;31mFAILED\033[0m" << std::endl;

    if (dma_ever_started && dma_finished) std::cout << "2. DMA Status Check:    \033[1;32mPASSED\033[0m" << std::endl;
    else std::cout << "2. DMA Status Check:    \033[1;31mFAILED\033[0m" << std::endl;

    if (top->rootp->soc_top__DOT__mac_done) std::cout << "3. MAC Status Check:    \033[1;32mPASSED (AI Inference Success!)\033[0m" << std::endl;
    else std::cout << "3. MAC Status Check:    \033[1;31mFAILED\033[0m" << std::endl;

    std::cout << "================================================" << std::endl;

    tfp->close(); delete top; return 0;
}
