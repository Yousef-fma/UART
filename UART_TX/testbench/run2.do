vlib work
vlog -work work ../UART_TX_FSM.v ../UART_TX_MUX.v ../UART_TX_parity_calc.v ../UART_TX_P_DATA_REG.v ../UART_TX_serializer.v ../UART_TX_top.v UART_TX_tb2.sv
vsim -voptargs=+acc work.UART_TX_tb2
do wave2.do
run -all
