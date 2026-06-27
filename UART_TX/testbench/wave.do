onerror {resume}
quietly WaveActivateNextPane {} 0
add wave -noupdate -expand -group Testbench /UART_TX_tb/check_case_num
add wave -noupdate -expand -group Testbench /UART_TX_tb/CLK_PERIOD
add wave -noupdate -expand -group Testbench -color Magenta -itemcolor Magenta /UART_TX_tb/CLK_tb
add wave -noupdate -expand -group Testbench -color Violet -itemcolor Magenta /UART_TX_tb/next_state
add wave -noupdate -expand -group Testbench -color Violet -itemcolor Magenta /UART_TX_tb/current_state
add wave -noupdate -expand -group Testbench /UART_TX_tb/Busy_tb
add wave -noupdate -expand -group Testbench /UART_TX_tb/Data_Valid_tb
add wave -noupdate -expand -group Testbench /UART_TX_tb/DATA_WIDTH
add wave -noupdate -expand -group Testbench /UART_TX_tb/P_DATA_reg
add wave -noupdate -expand -group Testbench /UART_TX_tb/P_DATA_tb
add wave -noupdate -expand -group Testbench /UART_TX_tb/PAR_EN_reg
add wave -noupdate -expand -group Testbench /UART_TX_tb/PAR_EN_tb
add wave -noupdate -expand -group Testbench /UART_TX_tb/PAR_TYP_reg
add wave -noupdate -expand -group Testbench /UART_TX_tb/PAR_TYP_tb
add wave -noupdate -expand -group Testbench /UART_TX_tb/RST_tb
add wave -noupdate -expand -group Testbench /UART_TX_tb/serial_Busy_expected
add wave -noupdate -expand -group Testbench /UART_TX_tb/serial_Busy_real
add wave -noupdate -expand -group Testbench /UART_TX_tb/serial_TX_OUT_expected
add wave -noupdate -expand -group Testbench /UART_TX_tb/serial_TX_OUT_real
add wave -noupdate -expand -group Testbench /UART_TX_tb/serializer_counter
add wave -noupdate -expand -group Testbench /UART_TX_tb/TX_OUT_tb
add wave -noupdate -expand -group FSM_inst -color Magenta -itemcolor Magenta /UART_TX_tb/UART_TX_DUT/FSM_inst/CLK
add wave -noupdate -expand -group FSM_inst /UART_TX_tb/UART_TX_DUT/FSM_inst/RST
add wave -noupdate -expand -group FSM_inst -color Violet -itemcolor Magenta /UART_TX_tb/UART_TX_DUT/FSM_inst/next_state
add wave -noupdate -expand -group FSM_inst -color Violet -itemcolor Magenta /UART_TX_tb/UART_TX_DUT/FSM_inst/current_state
add wave -noupdate -expand -group FSM_inst /UART_TX_tb/UART_TX_DUT/FSM_inst/Busy
add wave -noupdate -expand -group FSM_inst /UART_TX_tb/UART_TX_DUT/FSM_inst/last_bit_flag
add wave -noupdate -expand -group FSM_inst /UART_TX_tb/UART_TX_DUT/FSM_inst/Data_Valid
add wave -noupdate -expand -group FSM_inst -color Violet -itemcolor Magenta /UART_TX_tb/UART_TX_DUT/FSM_inst/mux_sel
add wave -noupdate -expand -group FSM_inst /UART_TX_tb/UART_TX_DUT/FSM_inst/PAR_EN
add wave -noupdate -expand -group FSM_inst /UART_TX_tb/UART_TX_DUT/FSM_inst/ser_done
add wave -noupdate -expand -group FSM_inst /UART_TX_tb/UART_TX_DUT/FSM_inst/ser_en
add wave -noupdate -expand -group MUX_inst -color Violet -itemcolor Magenta /UART_TX_tb/UART_TX_DUT/MUX_inst/mux_sel
add wave -noupdate -expand -group MUX_inst /UART_TX_tb/UART_TX_DUT/MUX_inst/par_bit
add wave -noupdate -expand -group MUX_inst -color Coral -itemcolor Coral /UART_TX_tb/UART_TX_DUT/MUX_inst/ser_data
add wave -noupdate -expand -group MUX_inst /UART_TX_tb/UART_TX_DUT/MUX_inst/TX_OUT
add wave -noupdate -expand -group Serializer_inst /UART_TX_tb/UART_TX_DUT/serializer_inst/P_DATA_reg
add wave -noupdate -expand -group Serializer_inst /UART_TX_tb/UART_TX_DUT/serializer_inst/ser_en
add wave -noupdate -expand -group Serializer_inst -color Magenta -itemcolor Magenta /UART_TX_tb/UART_TX_DUT/serializer_inst/CLK
add wave -noupdate -expand -group Serializer_inst /UART_TX_tb/UART_TX_DUT/serializer_inst/RST
add wave -noupdate -expand -group Serializer_inst /UART_TX_tb/UART_TX_DUT/serializer_inst/ser_done
add wave -noupdate -expand -group Serializer_inst -color Coral -itemcolor Coral /UART_TX_tb/UART_TX_DUT/serializer_inst/ser_data
add wave -noupdate -expand -group Serializer_inst /UART_TX_tb/UART_TX_DUT/serializer_inst/counter
add wave -noupdate -expand -group Top_DUT_inst /UART_TX_tb/UART_TX_DUT/Busy
add wave -noupdate -expand -group Top_DUT_inst -color Magenta -itemcolor Magenta /UART_TX_tb/UART_TX_DUT/CLK
add wave -noupdate -expand -group Top_DUT_inst /UART_TX_tb/UART_TX_DUT/Data_Valid
add wave -noupdate -expand -group Top_DUT_inst /UART_TX_tb/UART_TX_DUT/last_bit_flag
add wave -noupdate -expand -group Top_DUT_inst -color Violet -itemcolor Magenta /UART_TX_tb/UART_TX_DUT/mux_sel
add wave -noupdate -expand -group Top_DUT_inst /UART_TX_tb/UART_TX_DUT/P_DATA
add wave -noupdate -expand -group Top_DUT_inst /UART_TX_tb/UART_TX_DUT/P_DATA_reg
add wave -noupdate -expand -group Top_DUT_inst /UART_TX_tb/UART_TX_DUT/par_bit
add wave -noupdate -expand -group Top_DUT_inst /UART_TX_tb/UART_TX_DUT/PAR_EN
add wave -noupdate -expand -group Top_DUT_inst /UART_TX_tb/UART_TX_DUT/PAR_EN_reg
add wave -noupdate -expand -group Top_DUT_inst /UART_TX_tb/UART_TX_DUT/PAR_TYP
add wave -noupdate -expand -group Top_DUT_inst /UART_TX_tb/UART_TX_DUT/PAR_TYP_reg
add wave -noupdate -expand -group Top_DUT_inst /UART_TX_tb/UART_TX_DUT/RST
add wave -noupdate -expand -group Top_DUT_inst -color Coral -itemcolor Coral /UART_TX_tb/UART_TX_DUT/ser_data
add wave -noupdate -expand -group Top_DUT_inst /UART_TX_tb/UART_TX_DUT/ser_done
add wave -noupdate -expand -group Top_DUT_inst /UART_TX_tb/UART_TX_DUT/ser_en
add wave -noupdate -expand -group Top_DUT_inst /UART_TX_tb/UART_TX_DUT/TX_OUT
TreeUpdate [SetDefaultTree]
WaveRestoreCursors {{Cursor 1} {161950 ps} 0}
quietly wave cursor active 1
configure wave -namecolwidth 284
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
WaveRestoreZoom {0 ps} {414640 ps}
