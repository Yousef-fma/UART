# UART Verification and Simulation Guide

> [!IMPORTANT]
> **Strict Folder Separation:**
> There are 3 main folders in this repository: [UART_RX](./UART_RX), [UART_TX](./UART_TX), and [UART_TOP](./UART_TOP). Each folder is completely separated from the others. Any edits made within a folder are fully self-contained and will not affect the other folders.

---

## Directory Overview

Each module contains its own dedicated `testbench` folder with a Questasim compilation script (`run.do`) and waveform layout configurations (`wave.do`). The modules are packaged with local copies of dependencies to maintain absolute isolation.

* **[UART_RX](./UART_RX):** Contains the UART Receiver design. Its testbench utilizes a local copy of helper TX components located inside its own testbench directory.
* **[UART_TX](./UART_TX):** Contains the UART Transmitter design. It compiles its files locally in the testbench directory.
* **[UART_TOP](./UART_TOP):** Integrates the UART RX and TX blocks. Its testbench uses local copies of RX and TX design files nested inside its own testbench directory.

---

## How to Run Simulations on Questasim

You can run the simulation using either the **Questasim Graphical User Interface (GUI)** or the **Command Line (CLI)**.

### Method 1: Using the Questasim GUI (Recommended)

1. **Launch Questasim / ModelSim**.
2. Locate the **Transcript / Command Console** window at the bottom of the interface.
3. Change the active directory to the specific testbench directory you want to run (relative to the repository root):
   * **To run RX Testbench:**
     ```tcl
     cd ./UART_RX/testbench
     ```
   * **To run TX Testbench:**
     ```tcl
     cd ./UART_TX/testbench
     ```
   * **To run TOP Testbench:**
     ```tcl
     cd ./UART_TOP/testbench
     ```
4. Run the DO script to compile design files, load the testbench, configure the wave viewer, and start the simulation:
   ```tcl
   do run.do
   ```

---

### Method 2: Using the Command Line (Terminal/PowerShell)

If Questasim is added to your system's Environment Variables (`PATH`), you can launch the simulation directly from a terminal.

1. **Open your terminal** (PowerShell or Command Prompt).
2. Change the directory to the desired testbench folder:
   * **For UART Receiver (RX):**
     ```powershell
     cd ./UART_RX/testbench
     ```
   * **For UART Transmitter (TX):**
     ```powershell
     cd ./UART_TX/testbench
     ```
   * **For UART Top-Level Integration:**
     ```powershell
     cd ./UART_TOP/testbench
     ```
3. Run one of the following commands:
   * **To run in GUI Mode (Opens Questasim GUI and runs the DO script automatically):**
     ```powershell
     vsim -do run.do
     ```
   * **To run in Batch/Command-Line Mode (Runs the simulation directly in the terminal without GUI):**
     ```powershell
     vsim -c -do run.do
     ```

---

## Details of Each Testbench Script

### 1. UART Receiver (`UART_RX`)
* **Testbench File:** [UART_RX_tb.sv](./UART_RX/testbench/UART_RX_tb.sv)
* **Execution Script:** [run.do](./UART_RX/testbench/run.do)
* **What it does:**
  1. Creates the `work` library.
  2. Compiles helper TX source files from the nested `UART_TX` subdirectory.
  3. Compiles design and testbench files listed in the local `sourcefile.txt`.
  4. Loads the `UART_RX_tb` top module.
  5. Executes `wave.do` and runs the simulation.

### 2. UART Transmitter (`UART_TX`)
* **Testbench File:** [UART_TX_tb.sv](./UART_TX/testbench/UART_TX_tb.sv)
* **Execution Script:** [run.do](./UART_TX/testbench/run.do)
* **What it does:**
  1. Creates the `work` library.
  2. Compiles all design and testbench files locally.
  3. Loads the `UART_TX_tb` top module.
  4. Executes `wave.do` and runs the simulation.

### 3. UART Top Level (`UART_TOP`)
* **Testbench File:** [UART_tb.v](./UART_TOP/testbench/UART_tb.v)
* **Execution Script:** [run.do](./UART_TOP/testbench/run.do)
* **What it does:**
  1. Creates the `work` library.
  2. Compiles helper TX files from the nested `UART_TX` subdirectory.
  3. Compiles helper RX files from the nested `UART_RX` subdirectory.
  4. Compiles top-level files `UART.v` and `UART_tb.v`.
  5. Loads the `UART_tb` top module.
  6. Executes `wave.do` and runs the simulation.
