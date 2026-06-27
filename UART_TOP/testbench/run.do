vlib  work
vlog  -f sourcefile.txt
vsim  -voptargs=+acc  work.UART_tb

do    wave.do
run   -all
