module UART_RX_edge_bit_counter #(
    parameter DATA_WIDTH = 8
) ( 
    // Inputs.
    enable        , // To activate the counters that's needed to know the current edge and received serial bit.
    last_edge_flag, // To tell the edge counter to restart counting from 0.
    CLK           , // Clock signal. (fast clock and related to Prescale value)
    RST           , // Reset signal. (Asynchronous Active low reset)
    
    // Outputs.
    bit_cnt       , // The number of the received serial bits.
    edge_cnt        // The current edge counter value. 
);

    // Function to find the width of the bus 'bit_cnt';
    // function integer counter_width(input integer max_number);
    //     integer bits_num;
    //     begin
    //         bits_num = 0;
    //         for (bits_num = 0 ; max_number>0 ; bits_num = bits_num + 1) begin
    //             max_number = max_number >> 1;
    //         end
    //         counter_width = bits_num;
    //     end
    // endfunction

    input  wire                                     enable        ; // To activate the counters that's needed to know the current edge and received serial bit.
    input  wire                                     last_edge_flag; // To tell the edge counter to restart counting from 0.
    input  wire                                     CLK           ; // Clock signal. (fast clock and related to Prescale value)
    input  wire                                     RST           ; // Reset signal. (Asynchronous Active low reset)
    output reg  [$clog2(DATA_WIDTH+3)-1 : 0]        bit_cnt       ; // The number of the received serial bits.
    output reg  [5:0]                               edge_cnt      ; // The current edge counter value. 

    // count the samples per serial bit (edge number of the UART-RX clock. edge-to-edge period = (1/8) the input frame bit period by default)
    always @(posedge CLK or negedge RST) begin
        if(!RST) begin
            edge_cnt <= 'd0;
        end
        else if(enable && !last_edge_flag) begin
            edge_cnt <= edge_cnt + 1'd1;
        end 
        else begin
            edge_cnt <= 'd0;
        end
    end

    // count the number of serial bits. (the frame bit number)
    always @(posedge CLK or negedge RST) begin
        if(!RST) begin
            bit_cnt <= 'd0;
        end
        else if (enable && last_edge_flag) begin
            bit_cnt <= bit_cnt + 1'd1; 
        end 
        else if (!enable) begin
            bit_cnt <= 'd0;
        end
    end
endmodule