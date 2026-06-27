
module UART_TX_P_DATA_REG #(
    parameter DATA_WIDTH = 8
) (
    input  wire [DATA_WIDTH-1 : 0] P_DATA,        // The parallel input data bus port. 
    input  wire                    PAR_EN,        // The signal that gives an indication if there will be a sent parity bit or not.    
    input  wire                    PAR_TYP,       // To register the parity type. (0: even parity, 1: odd parity)
    input  wire                    Data_Valid,    // The input port that asserts the receiving operation of the UART_TX. It's important to know when the serializer shall register the parallel data from 'P_DATA'.
    input  wire                    Busy_feedback, // The feedback of the output port 'Busy'of the UART_TX.               It's important to know when the serializer shall register the parallel data from 'P_DATA'.
    input  wire                    last_bit_flag, // To check if the previous sent frame is sending the last its bit or not.
    input  wire                    CLK,           // Clock Signal.
    input  wire                    RST,           // Reset Signal.
    output reg  [DATA_WIDTH-1 : 0] P_DATA_reg,    // The registered parallel input data bus. 
    output reg                     PAR_EN_reg,    // The registered parity bit enable 'PAR_EN'.    
    output reg                     PAR_TYP_reg    // The registered parity bit type 'PAR_TYP'. (0: even parity, 1: odd parity)
);
    ///////////////////////////////////////////////////////////////////////////////////////////
    // To register the inputs: the parallel data 'P_DATA', 'PAR_EN_reg', and 'PAR_TYP_reg'.  //
    // The operation happens in parallel with sending the START BIT on TX_OUT port.          //
    ///////////////////////////////////////////////////////////////////////////////////////////
    // reg last_bit_flag_reg;
    // always @(posedge CLK or negedge RST) begin
    //     if(!RST) begin 
    //         last_bit_flag_reg <= 0;
    //     end 
    //     else begin
    //         last_bit_flag_reg <= last_bit_flag;
    //     end
    // end

    always @(posedge CLK or negedge RST) 
        begin
            if(!RST) 
                begin
                    P_DATA_reg  <= 'd0;
                    PAR_EN_reg  <= 'd0;
                    PAR_TYP_reg <= 'd0;
                end

            // To store the inputs (except Data_Valid).
            // We store the data if the current state is after the LAST_BIT state (START_BIT or IDLE) of the frame or if the state is IDLE.
            else if (Data_Valid & (!Busy_feedback || last_bit_flag)) 
                begin
                    P_DATA_reg  <= P_DATA;
                    PAR_EN_reg  <= PAR_EN;
                    PAR_TYP_reg <= PAR_TYP;
                end
        end
endmodule