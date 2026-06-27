onerror {resume}
quietly WaveActivateNextPane {} 0
add wave -noupdate -expand -group {Test bench} -radix unsigned /UART_tb/testcase_count
add wave -noupdate -expand -group {Test bench} -radix unsigned /UART_tb/RST
add wave -noupdate -expand -group {Test bench} -radix unsigned /UART_tb/TX_CLK
add wave -noupdate -expand -group {Test bench} -radix unsigned /UART_tb/RX_CLK
add wave -noupdate -expand -group {Test bench} -radix unsigned /UART_tb/Prescale
add wave -noupdate -expand -group {Test bench} -radix unsigned /UART_tb/TX_OUT_S
add wave -noupdate -expand -group {Test bench} -color Magenta -itemcolor Magenta -radix unsigned /UART_tb/RX_OUT_V
add wave -noupdate -expand -group {Test bench} -radix unsigned /UART_tb/RX_IN_S
add wave -noupdate -expand -group {Test bench} -radix unsigned /UART_tb/RX_OUT_P
add wave -noupdate -expand -group {Test bench} -radix unsigned /UART_tb/TX_IN_P
add wave -noupdate -expand -group {Test bench} -radix unsigned /UART_tb/rx_out_p_result
add wave -noupdate -expand -group {Test bench} -color Cyan -itemcolor Cyan -radix unsigned /UART_tb/TX_IN_V
add wave -noupdate -expand -group {Test bench} -radix unsigned /UART_tb/TX_OUT_V
add wave -noupdate -expand -group {Test bench} -color {Orange Red} -itemcolor {Orange Red} -radix unsigned /UART_tb/tx_out_v_error
add wave -noupdate -expand -group {Test bench} -radix unsigned /UART_tb/PAR_EN
add wave -noupdate -expand -group {Test bench} -radix unsigned /UART_tb/PAR_TYP
add wave -noupdate -expand -group {Test bench} -color {Indian Red} -itemcolor {Indian Red} -radix decimal /UART_tb/error_count
add wave -noupdate -expand -group {Test bench} -radix decimal /UART_tb/success_count
add wave -noupdate -expand -group UART-RX-FSM -radix unsigned /UART_tb/TX_CLK
add wave -noupdate -expand -group UART-RX-FSM -color Magenta -itemcolor Magenta -radix unsigned /UART_tb/RX_OUT_V
add wave -noupdate -expand -group UART_TOP -radix unsigned /UART_tb/UART_1/DATA_WIDTH
add wave -noupdate -expand -group UART_TOP -radix unsigned /UART_tb/UART_1/PAR_EN
add wave -noupdate -expand -group UART_TOP -radix unsigned /UART_tb/UART_1/PAR_TYP
add wave -noupdate -expand -group UART_TOP -radix unsigned /UART_tb/UART_1/Parity_Error
add wave -noupdate -expand -group UART_TOP -radix unsigned /UART_tb/UART_1/Prescale
add wave -noupdate -expand -group UART_TOP -radix unsigned /UART_tb/UART_1/RECEIVE_MSB_FIRST
add wave -noupdate -expand -group UART_TOP -radix unsigned /UART_tb/UART_1/RST
add wave -noupdate -expand -group UART_TOP -radix unsigned /UART_tb/UART_1/RX_CLK
add wave -noupdate -expand -group UART_TOP -radix unsigned /UART_tb/UART_1/RX_IN_S
add wave -noupdate -expand -group UART_TOP -radix unsigned /UART_tb/UART_1/RX_OUT_P
add wave -noupdate -expand -group UART_TOP -radix unsigned /UART_tb/UART_1/RX_OUT_V
add wave -noupdate -expand -group UART_TOP -radix unsigned /UART_tb/UART_1/SEND_MSB_FIRST
add wave -noupdate -expand -group UART_TOP -radix unsigned /UART_tb/UART_1/Stop_Error
add wave -noupdate -expand -group UART_TOP -radix unsigned /UART_tb/UART_1/TX_CLK
add wave -noupdate -expand -group UART_TOP -radix unsigned /UART_tb/UART_1/TX_IN_P
add wave -noupdate -expand -group UART_TOP -radix unsigned /UART_tb/UART_1/TX_IN_V
add wave -noupdate -expand -group UART_TOP -radix unsigned /UART_tb/UART_1/TX_OUT_S
add wave -noupdate -expand -group UART_TOP -radix unsigned /UART_tb/UART_1/TX_OUT_V
TreeUpdate [SetDefaultTree]
WaveRestoreCursors {{Cursor 1} {42823869651 ps} 0}
quietly wave cursor active 1
configure wave -namecolwidth 247
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
WaveRestoreZoom {42819085791 ps} {42842139045 ps}
