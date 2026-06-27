
module UART_TX_MUX #(
    parameter IDLE_SELECTION           = 2'b00, // The IDLE state number in the UART_TX_MUX module.
    parameter START_BIT_SELECTION      = 2'b01, // The START BIT state number in the UART_TX_MUX module.
    parameter DATA_TO_SERIAL_SELECTION = 2'b10, // The SERIAL DATA state number in the UART_TX_MUX module.
    parameter PARITY_BIT_SELECTION     = 2'b11  // The PARITY BIT state number in the UART_TX_MUX module.
) (
    input  wire [1:0] mux_sel,  // To control the UART_TX_MUX selection. (Tell MUX which frame bit will get out (start bit, serial bits, parity bit, or stop bit))
    input  wire       ser_data, // To get the serial data.
    input  wire       par_bit,  // To get the parity bit value. 
    output reg        TX_OUT    // To transfer the result on.
);
    localparam STOP_BIT  = 1'b1;
    localparam START_BIT = 1'b0;

    always @(*)
        begin
            case(mux_sel)
                IDLE_SELECTION:           TX_OUT = STOP_BIT; 
                START_BIT_SELECTION:      TX_OUT = START_BIT;
                DATA_TO_SERIAL_SELECTION: TX_OUT = ser_data;
                PARITY_BIT_SELECTION:     TX_OUT = par_bit;
                // default:                  TX_OUT = STOP_BIT;
            endcase
        end
endmodule