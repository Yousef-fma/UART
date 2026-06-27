vlib  work
vlog  -f .//UART_TX//sourcefile.txt
vlog  -f sourcefile.txt
vsim  -voptargs=+acc  work.UART_RX_tb

do    wave.do
run   -all