import cocotb
from cocotb.clock import Clock
from cocotb.triggers import RisingEdge, Timer

@cocotb.test()
async def sanity_test(dut):
    clock = Clock(dut.clk, 10, units="ns") 
    cocotb.start_soon(clock.start())

    dut.a.value = 5
    dut.b.value = 10
    await RisingEdge(dut.clk)
    await Timer(1, units="ns") # Small delay to see result
    
    assert dut.prod.value == 50
    dut._log.info(f"Sanity Passed: {dut.a.value} * {dut.b.value} = {dut.prod.value}")
