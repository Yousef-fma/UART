
module UART_RX_deserializer #(
    parameter DATA_WIDTH        = 8, // The expected received serial data width.
    parameter RECEIVE_MSB_FIRST = 0  // To deal with the frame that has serial input data that start with MSB and LSB.(assign 1: if receive MSB at first, 0 or any other number: if receive LSB at first)
) (
    input  wire                  sampled_bit                 , // To receive the checked serial input value.
    input  wire                  deser_en                    , // To start de-serialization.
    input  wire                  oversampling_completion_flag, // To know if the sampling complete or not to know when to start de-serialization.
    input  wire                  CLK                         , // Clock signal. (fast clock and related to Prescale value)
    input  wire                  RST                         , // Reset signal. (Asynchronous Active low reset)
    output reg  [DATA_WIDTH-1:0] P_DATA
);

    generate
        if(RECEIVE_MSB_FIRST) begin : genblk_for_receiving_MSB_at_first

            always @(posedge CLK or negedge RST) begin
                if(!RST) begin
                    P_DATA <= 'd0;
                end
                else if(deser_en && oversampling_completion_flag) begin
                    P_DATA <= {P_DATA[DATA_WIDTH-2 : 0], sampled_bit};
                end
            end
        end
        else begin : genblk_for_receiving_LSB_at_first
            
            always @(posedge CLK or negedge RST) begin
                if(!RST) begin
                    P_DATA <= 'd0;
                end
                else if(deser_en && oversampling_completion_flag) begin
                    P_DATA <= {sampled_bit, P_DATA[DATA_WIDTH-1 : 1]};
                end
            end
        end
    endgenerate
endmodule