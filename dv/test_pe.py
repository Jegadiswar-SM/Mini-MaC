import cocotb
from cocotb.clock import Clock
from cocotb.triggers import RisingEdge, Timer

@cocotb.test()
async def pe_basic_test(dut):
    # Start the clock (100MHz = 10ns period)
    clock = Clock(dut.clk, 10, units="ns")
    cocotb.start_soon(clock.start())

    # Reset
    dut.rst_n.value = 0
    await RisingEdge(dut.clk)
    dut.rst_n.value = 1
    await RisingEdge(dut.clk)

    # Inputs: a=5, w=10, acc_in=100
    # Expected result: 100 + (5 * 10) = 150
    dut.load_wgt.value = 1
    dut.w_in.value = 10
    await RisingEdge(dut.clk)
    dut.load_wgt.value = 0

    dut.a_in.value = 5
    dut.acc_in.value = 100

    # Wait 3 cycles (Pipeline depth = 3 per §8.1)
    await RisingEdge(dut.clk) # Cycle 1: Latch inputs
    await RisingEdge(dut.clk) # Cycle 2: Multiply
    await RisingEdge(dut.clk) # Cycle 3: Accumulate & Output
    
    await Timer(1, units="ns") # Small delay to stabilize
    
    result = int(dut.acc_out.value)
    expected = 150
    assert result == expected, f"Error: Expected {expected}, got {result}"
    
    dut._log.info(f"PE Test Passed: 100 + (5*10) = {result}")

    # Test signed math: a=-2, w=3, acc_in=10
    # Expected: 10 + (-2 * 3) = 4
    dut.load_wgt.value = 1
    dut.w_in.value = 3
    await RisingEdge(dut.clk)
    dut.load_wgt.value = 0

    dut.a_in.value = 0xFE # -2 in 8-bit hex
    dut.acc_in.value = 10
    for _ in range(3): await RisingEdge(dut.clk)
    await Timer(1, units="ns")
    
    assert int(dut.acc_out.value) == 4, f"Signed Test Failed: got {int(dut.acc_out.value)}"
    dut._log.info("PE Signed Test Passed!")
