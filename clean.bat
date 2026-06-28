@echo off
REM ============================================================
REM  Removes QuestaSim simulation artifacts from all testbenches
REM  Run from the UART/ directory
REM ============================================================

echo Cleaning simulation artifacts...

for %%D in (.\ UART_TX\testbench UART_RX\testbench UART_TOP\testbench) do (
    if exist "%%D\work" rmdir /s /q "%%D\work"
    if exist "%%D\transcript" del /q "%%D\transcript"
    if exist "%%D\vsim.wlf" del /q "%%D\vsim.wlf"
    del /q "%%D\*.vcd" 2>nul
)

echo Done.
