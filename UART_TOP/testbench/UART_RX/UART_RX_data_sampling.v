
module UART_RX_data_sampling #(
    parameter DATA_WIDTH = 8
) (
    input  wire       RX_IN                       , // The input serial data port.
    input  wire [5:0] Prescale                    , // To know what is the oversampling number per input clock cycle (per input bit).
    input  wire       dat_samp_en                 , // To get the indication to start data sampling.
    input  wire [5:0] edge_cnt                    , // To know the start of the receive bit of the input serial data.
    input  wire       CLK                         , // Clock signal. (fast clock and related to Prescale value)
    input  wire       RST                         , // Reset signal. (Asynchronous Active low reset)

    output reg        sampled_bit                 , // To send on the sampled data bit after oversampling.
    output wire       oversampling_completion_flag, // To propose if the sampling is completed or not.
    output wire       last_edge_flag              , // To check if the current clock is the last clock for the current state of the FSM.  
    output wire       before_last_edge_flag         // To check if the current clock is the clock before the last clock for the current state of the FSM.
);

    
    reg        sample[0:2]            ; // To store the 3 samples in.
    wire [4:0] first_stored_edge_num  ; // Name the value of the first  stored sample number.
    wire [4:0] second_stored_edge_num ; // Name the value of the second stored sample number.
    wire [4:0] third_stored_edge_num  ; // Name the value of the third  stored sample number.

    assign first_stored_edge_num        = (Prescale>>1)-'d1; // The number of the first  sampled edge.
    assign second_stored_edge_num       = (Prescale>>1)    ; // The number of the second sampled edge.
    assign third_stored_edge_num        = (Prescale>>1)+'d1; // The number of the third  sampled edge. 

    assign oversampling_completion_flag = (edge_cnt == third_stored_edge_num); // To know if the oversampling is done completely.
    assign last_edge_flag               = (edge_cnt == Prescale - 1'd1      ); // To know if this moment is before the next received serial 'RX_IN'.(when the 'bit_cnt' is 7).
    assign before_last_edge_flag        = (edge_cnt == Prescale - 2'd2      ); // To know if this moment is before the last received serial 'RX_IN'.(when the 'bit_cnt' is 6).
    always @(posedge CLK or negedge RST) begin
        if(!RST) begin
            sample[0]   <= 1'd0;
            sample[1]   <= 1'd0;
            sample[2]   <= 1'd0;
        end
        else if(dat_samp_en && edge_cnt == first_stored_edge_num) begin
            sample[0] <= RX_IN;
        end
        else if(dat_samp_en && edge_cnt == second_stored_edge_num) begin
            sample[1] <= RX_IN;
        end
        else if(dat_samp_en && edge_cnt == third_stored_edge_num) begin
            sample[2] <= RX_IN;
        end
    end

    always @(*) begin
        case({sample[0], sample[1], sample[2]})
            3'b111,
            3'b011,
            3'b101,
            3'b110:  sampled_bit = 1'b1;
            default: sampled_bit = 1'b0;
        endcase
    end

endmodule