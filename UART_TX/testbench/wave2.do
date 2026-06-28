# =============================================================================
# Waveform Configuration for UART_TX Demonstration
# This file displays the key signals in the exact order specified to show
# the parallel-to-serial conversion and back-to-back UART framing.
# =============================================================================

onerror {resume}
quietly WaveActivateNextPane {} 0

# 1. Continuous clock signal
add wave -noupdate -color {Spring Green} -itemcolor {Spring Green} /UART_TX_tb2/CLK

# 2. Transmit validation pulse (high for exactly 1 clock cycle)
add wave -noupdate -color {Spring Green} -itemcolor {Spring Green} /UART_TX_tb2/Data_Valid

# 3. External parallel input data bus
add wave -noupdate -radix hexadecimal -color Cyan -itemcolor Cyan /UART_TX_tb2/P_DATA

# 4. Internal registered parallel data bus
add wave -noupdate -radix hexadecimal -color Cyan -itemcolor Cyan /UART_TX_tb2/P_DATA_reg

# 5. Current FSM state of the transmitter (displays symbolic enum names)
add wave -noupdate -color {Light Blue} -itemcolor {Light Blue} /UART_TX_tb2/current_state

# 6. Serialized UART output stream (Idle = 1, Start = 0, LSB first data, Parity, Stop = 1)
add wave -noupdate -color Orange -itemcolor Orange /UART_TX_tb2/TX_OUT

# 7. Busy signal (high during transmission)
add wave -noupdate -color Cyan -itemcolor Cyan /UART_TX_tb2/Busy

# 8. Parity enable control signal (active high)
add wave -noupdate -color {Spring Green} -itemcolor {Spring Green} /UART_TX_tb2/PAR_EN

# 9. Parity type selection (constant 0 for even parity)
add wave -noupdate -color {Spring Green} -itemcolor {Spring Green} /UART_TX_tb2/PAR_TYP

# --- Waveform Window Configuration ---
TreeUpdate [SetDefaultTree]
WaveRestoreCursors {{Cursor 1} {0 ps} 0}
quietly wave cursor active 1
configure wave -namecolwidth 180
configure wave -valuecolwidth 100
configure wave -justifyvalue left
configure wave -signalnamewidth 1
configure wave -snapdistance 10
configure wave -datasetprefix 0
configure wave -rowmargin 4
configure wave -childrowmargin 2
configure wave -gridoffset 0
configure wave -gridperiod 1
configure wave -griddelta 40
configure wave -timeline 0
configure wave -timelineunits ns
update
WaveRestoreZoom {0 ns} {300 ns}
