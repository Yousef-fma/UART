# UART Verification and Simulation Guide

## Directory Overview

```
UART/
├── UART_TX/               ← RTL source files for the Transmitter
│   ├── testbench/         ← TX testbench (UART_TX_tb.sv, run.do, sourcefile.txt, wave.do)
│   └── *.v
├── UART_RX/               ← RTL source files for the Receiver
│   ├── testbench/         ← RX testbench (UART_RX_tb.sv, run.do, sourcefile.txt, wave.do)
│   └── *.v
└── UART_TOP/              ← RTL top-level integration (UART.v)
    └── testbench/         ← TOP testbench (UART_tb.v, run.do, sourcefile.txt, wave.do)
```

> [!NOTE]
> All RTL `.v` files live **only** in their respective module folders (`UART_TX/`, `UART_RX/`, `UART_TOP/`).
> The `testbench/` directories contain **only** testbench and simulation script files — no RTL copies.

---

## Understanding the Simulation Scripts

Every `testbench/` folder contains two key files that work together to run the simulation:

### `sourcefile.txt` — The File List

This is a plain-text list of every `.v` / `.sv` file that needs to be compiled for the simulation. Each line is a path to one source file, written **relative to the `testbench/` folder**.

- A path starting with `../` means *"go up one level"* (into the module's own RTL folder).
- A path starting with `../../` means *"go up two levels"* (into a sibling module's RTL folder).
- A filename with no path prefix means the file sits directly inside the `testbench/` folder (i.e., the testbench file itself).

**Example — `UART_TX/testbench/sourcefile.txt`:**

```
../UART_TX_FSM.v          ← RTL file from UART_TX/
../UART_TX_MUX.v
../UART_TX_parity_calc.v
../UART_TX_P_DATA_REG.v
../UART_TX_serializer.v
../UART_TX_top.v
UART_TX_tb.sv             ← Testbench file (lives here in testbench/)
```

**Example — `UART_RX/testbench/sourcefile.txt`:**

```
../UART_RX_data_sampling.v       ← RX RTL files from UART_RX/
../UART_RX_deserializer.v
../UART_RX_edge_bit_counter.v
../UART_RX_FSM.v
../UART_RX_parity_check.v
../UART_RX_start_check.v
../UART_RX_stop_check.v
../UART_RX_top.v
../../UART_TX/UART_TX_FSM.v      ← TX RTL files from UART_TX/ (needed by the RX TB)
../../UART_TX/UART_TX_MUX.v
../../UART_TX/UART_TX_parity_calc.v
../../UART_TX/UART_TX_P_DATA_REG.v
../../UART_TX/UART_TX_serializer.v
../../UART_TX/UART_TX_top.v
UART_RX_tb.sv                    ← Testbench file (lives here in testbench/)
```

> **To add or remove a design file from a simulation**, simply add or remove its path in `sourcefile.txt`. No other file needs to change.

---

### `run.do` — The Simulation Script

This is a QuestaSim TCL script that runs the full simulation flow in one command. All three testbenches use the same structure:

```tcl
vlib  work                            ← Create the simulation library
vlog  -f sourcefile.txt               ← Compile all files listed in sourcefile.txt
vsim  -voptargs=+acc  work.<tb_name>  ← Load the top-level testbench module
do    wave.do                         ← Set up the waveform viewer
run   -all                            ← Run the simulation to completion
```

| Line                                 | What it does                                               |
| ------------------------------------ | ---------------------------------------------------------- |
| `vlib work`                          | Creates (or resets) the `work` compilation library         |
| `vlog -f sourcefile.txt`             | Compiles every file listed in `sourcefile.txt` into `work` |
| `vsim -voptargs=+acc work.<tb_name>` | Loads the compiled testbench top module into the simulator |
| `do wave.do`                         | Applies the pre-configured waveform layout                 |
| `run -all`                           | Starts the simulation and runs until it finishes           |

You never need to modify `run.do`. It is identical across all three testbenches — only the top module name (`UART_TX_tb`, `UART_RX_tb`, `UART_tb`) differs.

---

## Quick Run Commands

> All commands below assume your current directory is `UART/`.

### QuestaSim GUI — Transcript Commands

Open QuestaSim, then paste into the **Transcript** window:

**UART TX:**

```tcl
cd ./UART_TX/testbench; do run.do; cd ../../
```

**UART RX:**

```tcl
cd ./UART_RX/testbench; do run.do; cd ../../
```

**UART TOP:**

```tcl
cd ./UART_TOP/testbench; do run.do; cd ../../
```

---

### Terminal — GUI Mode

```powershell
# TX
cd ./UART_TX/testbench; vsim -do run.do; cd ../../

# RX
cd ./UART_RX/testbench; vsim -do run.do; cd ../../

# TOP
cd ./UART_TOP/testbench; vsim -do run.do; cd ../../
```

### Terminal — Batch Mode (No GUI)

```powershell
# TX
cd ./UART_TX/testbench; vsim -c -do run.do; cd ../../

# RX
cd ./UART_RX/testbench; vsim -c -do run.do; cd ../../

# TOP
cd ./UART_TOP/testbench; vsim -c -do run.do; cd ../../
```

---

## Cleanup

Running simulations generates temporary files (`work/`, `transcript`, `vsim.wlf`, `*.vcd`). To remove them from all testbenches, run from the `UART/` directory:

```powershell
.\clean.bat
```
