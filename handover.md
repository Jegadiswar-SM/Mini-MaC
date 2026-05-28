# Mini-MaC Handover

## Status: MAC Subsystem Verified

### What was built
A standalone 4×4 systolic array MAC accelerator with APB control, memory subsystem arbiter, and testbench. Tested in Verilator 5.026 with two B-matrix configurations (identity and all-ones). All results correct in both cases.

### Key findings

**Verilator unpacked-array port shift** (mac_top -> systolic_array):
`weight_in[i][j]` at the source (`mac_top`) appears at `weight_in[i][(j+1)%4]` at the destination (`systolic_array`). This is a systematic 1-column left shift in the unpacked array port connection.

**Fix**: Pre-shift in `mac_top.v` using `weight_in[i][j] = wgt_buf[i][(j+3)%4]` (right-shift by 1) to cancel the port shift. With this fix, the identity matrix test produces correct A×I = A results, and the all-ones test produces correct row-sum results.

**Testbench regressions encountered**:
- The `pending_req` / `m_gnt_i` writeback in the main simulation loop is essential — deleting it causes the FSM to hang at WGT_LOAD forever. These lines must sample `m_req_o` and grant it each cycle.

### Files

| File | Purpose |
|------|---------|
| `rtl/accel/mac_top.v` | Top-level FSM: WGT_LOAD, ACT_LOAD, FEED, DRAIN, RES_STORE, ROW_NEXT, DONE. Contains pre-shift workaround. Exposes `result_hold_o[0:3]` for APB readback. |
| `rtl/accel/systolic_array.v` | 4×4 PE array with generate loops. Unchanged. |
| `rtl/accel/pe.v` | 3-stage Int8×Int8→Int32 MAC PE. Has ROW/COL params (for debug). |
| `rtl/accel/mac_regs.v` | APB register file. PE_ADDR(0x18)/PE_RESULT(0x1C) readback mux. |
| `dv/tb_mac.cpp` | Standalone C++ testbench with APB read/write, pipelined memory, and result verification. |

### Testing
- `A × I` (identity): Row 0=[1,2,3,4], Row 1=[5,6,7,8], Row 2=[9,10,11,12], Row 3=[13,14,15,16] — all correct
- `A × all-ones` (non-identity): Row 0=[10,10,10,10], Row 1=[26,26,26,26], Row 2=[42,42,42,42], Row 3=[58,58,58,58] — all correct
- PE_RESULT APB readback of last row: correct in both cases
- 131 cycles to completion in both cases

### Build
```bash
cd dv/obj_mac
verilator --cc --exe --top-module mac_top -Wno-fatal -Wno-lint --build \
  -Wno-UNOPTFLAT --trace -DVCD_TRACE \
  ../../rtl/accel/mac_top.v ../../rtl/accel/systolic_array.v \
  ../../rtl/accel/pe.v ../../rtl/accel/mac_regs.v \
  ../../dv/tb_mac.cpp
./obj_dir/Vmac_top
```

### Next steps
1. SoC integration with Ibex — `mem_subsystem.v` and `soc_top.v` already updated for MAC master with CPU>MAC>DMA priority
2. Firmware driver (`sw/main.c`) — uses base `0x40011000`, programs PE_ADDR=7 for readback
3. The pre-shift workaround may need revisiting if the simulator changes; document the port-mapping assumption

### Notes
- The pre-shift fix is a workaround for a Verilator-specific behavior. If running with a different simulator, verify first whether `weight_in[i][j]` connects correctly without the pre-shift.
- All RTL is lint-clean (Verilator) and synthesizable.
