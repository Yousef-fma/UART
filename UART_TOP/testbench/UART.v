

module UART #(
    parameter DATA_WIDTH        = 8, // The bits number of the sent data word in each frame
    parameter SEND_MSB_FIRST    = 0, // To send the MSB of the data word first or the LSB first. (1: To send the MSB first, 0 or any other number: To send the LSB first).
    parameter RECEIVE_MSB_FIRST = 0  // To deal with the frame that has serial data that starts with MSB or LSB.(assign 1: if receive MSB at first, 0 or any other number: if receive LSB at first).
) (
    // Input Ports
    input  wire                    PAR_TYP , // Parity Type (1: Odd, 0: Even)
    input  wire                    PAR_EN  , // Parity_Enable (1: Enable, 0: Disable)
    input  wire [5 : 0]            Prescale, // Oversampling Prescale
    input  wire [DATA_WIDTH-1 : 0] TX_IN_P , // Input TX data word (= 1 byte by default)
    input  wire                    TX_IN_V , // Input TX data valid signal
    input  wire                    RX_IN_S , // Serial input RX UART frame
    input  wire                    TX_CLK  , // UART TX Clock Signal
    input  wire                    RX_CLK  , // UART RX Clock Signal
    input  wire                    RST     , // Synchronized reset signal

    // Output Ports
    output wire                    TX_OUT_S    , // TX Frame Serial Out.
    output wire                    TX_OUT_V    , // TX Out Valid signal. 
    output wire [DATA_WIDTH-1 : 0] RX_OUT_P    , // RX Out Data  (= 1 byte by default)
    output wire                    RX_OUT_V    , // RX Out Data Valid signal.
    output wire                    Parity_Error, // Parity Error Signal.
    output wire                    Stop_Error  , // Stop Error Signal.
    output wire                    last_bit_flag

);


    // + ================================================================= +
    // |             Instances of UART-TX and UART-RX Modules.             |
    // + ================================================================= +
    UART_TX_top #(
        .DATA_WIDTH    (DATA_WIDTH    ),
        .SEND_MSB_FIRST(SEND_MSB_FIRST)
    ) UART_TX (
        // Input Pins.
        .P_DATA    (TX_IN_P ), // The parallel input data bus port.
        .Data_Valid(TX_IN_V ), // To start the the new frame if the current state was IDLE or STOP_BIT.
        .PAR_EN    (PAR_EN  ), // To recognize if there will be a sent parity bit or not.
        .PAR_TYP   (PAR_TYP ), // To determine the parity type. (0: even parity, 1: odd parity)
        .CLK       (TX_CLK  ), // Clock signal.
        .RST       (RST     ), // Active Low Asynchronous reset signal.

        // Output Pins.
        .TX_OUT    (TX_OUT_S), // To transfer the result on this pin.
        .Busy      (TX_OUT_V),  // It's high as long as the current frame didn't finish.
        .last_bit_flag(last_bit_flag)
    );


    UART_RX_top #(
        .DATA_WIDTH       (DATA_WIDTH       ), // The expected received serial data width.
        .RECEIVE_MSB_FIRST(RECEIVE_MSB_FIRST)  // To deal with the frame that has serial input data that start with MSB and LSB.(assign 1: if receive MSB at first, 0 or any other number: if receive LSB at first)
    ) UART_RX (
        // Input Pins.
        .RX_IN       (RX_IN_S     ), // Serial Data IN
        .Prescale    (Prescale    ), // Oversampling Prescale
        .PAR_EN      (PAR_EN      ), // Parity_Enable
        .PAR_TYP     (PAR_TYP     ), // Parity Type
        .CLK         (RX_CLK      ), // UART RX Clock Signal
        .RST         (RST         ), // Synchronized reset signal

        // Output Pins.
        .P_DATA      (RX_OUT_P    ), // Frame Data Word (= 1 Byte by default)
        .Parity_Error(Parity_Error), // Frame Parity Error.     
        .Stop_Error  (Stop_Error  ), // Frame Stop Error.       
        .data_valid  (RX_OUT_V    )  // Data Byte Valid signal. The benefit of this Pin signal to confirm that the receive serial data is valid and the result on the 'P_DATA' is Correct.
    );

endmodule