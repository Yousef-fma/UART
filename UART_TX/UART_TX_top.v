
module UART_TX_top #(
    parameter DATA_WIDTH     = 8,
    parameter SEND_MSB_FIRST = 0
) (
    input  wire [DATA_WIDTH-1 : 0] P_DATA,     // The parallel input data bus port.
    input  wire                    Data_Valid, // To start the the new frame if the current state was IDLE or STOP_BIT.
    input  wire                    PAR_EN,     // To recognize if there will be a sent parity bit or not.
    input  wire                    PAR_TYP,    // To determine the parity type. (0: even parity, 1: odd parity)
    input  wire                    CLK,        // Clock signal.
    input  wire                    RST,        // Active Low Asynchronous reset signal.
    output wire                    TX_OUT,     // To transfer the result on this port.
    output wire                    Busy,       // Is high as long as the current frame didn't finish.
    output wire                    last_bit_flag
);

    
    localparam IDLE_SELECTION           = 2'b00; // The IDLE state number in the UART_TX_MUX module.
    localparam START_BIT_SELECTION      = 2'b01; // The START BIT state number in the UART_TX_MUX module.
    localparam DATA_TO_SERIAL_SELECTION = 2'b10; // The SERIAL DATA state number in the UART_TX_MUX module.
    localparam PARITY_BIT_SELECTION     = 2'b11; // The PARITY BIT state number in the UART_TX_MUX module.

    wire [DATA_WIDTH-1 : 0] P_DATA_reg;    // connection between 'P_DATA_REG_inst' & 'UART_TX_serializer' and also 'UART_TX_parity_calc'
    wire                    PAR_EN_reg;    // connection between 'P_DATA_REG_inst' & 'UART_TX_FSM'
    wire                    PAR_TYP_reg;   // connection between 'P_DATA_REG_inst' & 'UART_TX_parity_calc'
    wire [1:0]              mux_sel;       // connection between 'UART_TX_MUX' & 'UART_TX_FSM'
    wire                    ser_data;      // connection between 'UART_TX_MUX' & 'UART_TX_serializer'
    wire                    par_bit;       // connection between 'UART_TX_MUX' & 'UART_TX_parity_calc'
    wire                    ser_done;      // connection between 'UART_TX_FSM' & 'UART_TX_serializer'
    wire                    ser_en;        // connection between 'UART_TX_FSM' & 'UART_TX_serializer'
    // wire                    last_bit_flag; // connection between 'UART_TX_FSM' & 'UART_TX_P_DATA_REG'

    //__________________________________________________________________________________________________________
    //|                                                                                                         |
    //|              ---------------   *****        P_DATA_REG_inst        *****   ---------------              |
    //|_________________________________________________________________________________________________________|
    UART_TX_P_DATA_REG #(
        .DATA_WIDTH(DATA_WIDTH)
    ) P_DATA_REG_inst (
        .P_DATA       (P_DATA       ), // The parallel input data bus port. 
        .PAR_EN       (PAR_EN       ), // The signal that gives an indication if there will be a sent parity bit or not.
        .PAR_TYP      (PAR_TYP      ), // To register the parity type. (0: even parity, 1: odd parity)
        .Data_Valid   (Data_Valid   ), // The input port that asserts the receiving operation of the UART_TX. It's important to know when the serializer shall register the parallel data from 'P_DATA'.
        .Busy_feedback(Busy         ), // The feedback of the output port 'Busy'of the UART_TX.               It's important to know when the serializer shall register the parallel data from 'P_DATA'.
        .last_bit_flag(last_bit_flag), // To check if the previous sent frame is sending the last its bit or not.
        .CLK          (CLK          ), // Clock Signal.
        .RST          (RST          ), // Reset Signal.
        .P_DATA_reg   (P_DATA_reg   ), // The registered parallel input data bus. 
        .PAR_EN_reg   (PAR_EN_reg   ), // The registered parity bit enable 'PAR_EN'.    
        .PAR_TYP_reg  (PAR_TYP_reg  )  // The registered parity bit type 'PAR_TYP'. (0: even parity, 1: odd parity)
    );
    
    

    //__________________________________________________________________________________________________________
    //|                                                                                                         |
    //|              ---------------   *****        serializer_inst        *****   ---------------              |
    //|_________________________________________________________________________________________________________|
    UART_TX_serializer #(
        .DATA_WIDTH    (DATA_WIDTH    ),  // To determine the parallel input data bus width on the port 'P_DATA'.
        .SEND_MSB_FIRST(SEND_MSB_FIRST)   // To choose if the serial date start from MSB or LSB (1: to start with MSB,  0: to start with LSB)
    ) serializer_inst (
        .P_DATA_reg   (P_DATA_reg   ), // The parallel input data bus port.
        .ser_en       (ser_en       ), // The signal to start converting the parallel data to serial and sending the serial data.
        .CLK          (CLK          ), // Clock signal.
        .RST          (RST          ), // Reset signal.
        .ser_done     (ser_done     ), // To tell the UART_FSM module that the serialization has completed.
        .ser_data     (ser_data     )  // The signal that carry the serial data. 
    );


    //__________________________________________________________________________________________________________
    //|                                                                                                         |
    //|              ---------------   *****            FSM_inst           *****   ---------------              |
    //|_________________________________________________________________________________________________________|
    UART_TX_FSM #(
        .IDLE_SELECTION          (IDLE_SELECTION          ), // The IDLE state number in the UART_TX_MUX module.
        .START_BIT_SELECTION     (START_BIT_SELECTION     ), // The START BIT state number in the UART_TX_MUX module.
        .DATA_TO_SERIAL_SELECTION(DATA_TO_SERIAL_SELECTION), // The SERIAL DATA state number in the UART_TX_MUX module.
        .PARITY_BIT_SELECTION    (PARITY_BIT_SELECTION    )  // The PARITY BIT state number in the UART_TX_MUX module.
    ) FSM_inst (
        .Data_Valid   (Data_Valid),   // To start the the new frame if the current state was IDLE or STOP_BIT.
        .PAR_EN       (PAR_EN_reg),   // To recognize if there will be a sent parity bit or not.
        .ser_done     (ser_done  ),   // To recognize if the serializer block finished processing the parallel data to serial or not. (0: is not finished, 1: finished)
        .CLK          (CLK       ),   // Clock signal.
        .RST          (RST       ),   // Active Low Asynchronous reset signal.
        .ser_en       (ser_en    ),   // To enable the serializer block to start processing the parallel data to serial or not. (0: is disabled, 1: is enabled)
        .mux_sel      (mux_sel   ),   // To control the UART_TXs_MUX selection. (Tell MUX which frame bit will get out (start bit, serial bits, parity bit, or stop bit))
        .Busy         (Busy      ),   // Is high as long as the current frame didn't finish.
        .last_bit_flag(last_bit_flag) // To know if the current state is in the LAST BIT of the frame. We need this signal in 'UART_TX_P_DATA_REG' module
    );



    //__________________________________________________________________________________________________________
    //|                                                                                                         |
    //|              ---------------   *****        parity_calc_inst       *****   ---------------              |
    //|_________________________________________________________________________________________________________|
    UART_TX_parity_calc #(
        .DATA_WIDTH(DATA_WIDTH)
    ) parity_calc_inst (
        .P_DATA_reg (P_DATA_reg ),  // The registered parallel input data bus port.
        .PAR_TYP_reg(PAR_TYP_reg),  // To determine the parity type. (0: even parity, 1: odd parity).
        .par_bit    (par_bit    )   // The final result of the parity bit signal calculation. 
    );



    //__________________________________________________________________________________________________________
    //|                                                                                                         |
    //|              ---------------   *****            MUX_inst           *****   ---------------              |
    //|_________________________________________________________________________________________________________|
    UART_TX_MUX #(
        .IDLE_SELECTION          (IDLE_SELECTION          ), // The IDLE state number in the UART_TX_MUX module.
        .START_BIT_SELECTION     (START_BIT_SELECTION     ), // The START BIT state number in the UART_TX_MUX module.
        .DATA_TO_SERIAL_SELECTION(DATA_TO_SERIAL_SELECTION), // The SERIAL DATA state number in the UART_TX_MUX module.
        .PARITY_BIT_SELECTION    (PARITY_BIT_SELECTION    )  // The PARITY BIT state number in the UART_TX_MUX module.
    ) MUX_inst (
        .mux_sel (mux_sel ), // To control the UART_TX_MUX selection. (Tell MUX which frame bit will get out (start bit, serial bits, parity bit, or stop bit))
        .ser_data(ser_data), // To get the serial data.
        .par_bit (par_bit ), // To get the parity bit value. 
        .TX_OUT  (TX_OUT  )  // To transfer the result on.
    );




endmodule