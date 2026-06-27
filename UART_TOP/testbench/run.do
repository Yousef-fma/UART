
vlib  work
vlog  -f .//UART_TX//sourcefile.txt
vlog  -f .//UART_RX//sourcefile.txt
vlog  UART.v  UART_tb.v
vsim  -voptargs=+acc  work.UART_tb

do    wave.do
run   -all
