vlib  work
vlog  *.*v
vsim  -voptargs=+acc  work.UART_TX_tb
#add   wave *
do wave.do
run   -all