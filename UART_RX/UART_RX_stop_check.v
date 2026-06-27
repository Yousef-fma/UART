
module UART_RX_stop_check(
    // Inputs.
    input wire  sampled_bit                 , // To get the sampled checked bit.
    input wire  oversampling_completion_flag, // To know if the sampled_bit is checked or not.
    input wire  stp_chk_en                  , // To start the check.
    input wire  is_Prescale_equal_4         , // To know if the Prescaler is equal to 4 or not.
    input wire  CLK                         , // Clock signal.
    input wire  RST                         , // Asynchronous Active Low Reset.
    
    // Outputs.
    output wire stp_err                       // To assign if there is an error.
);    
    reg  stp_err_seq ; // Sequential logic to retain the updated flag 'stp_err' after oversampling completion.
    wire stp_err_comb; // Combinational logic to assign the flag 'stp_err' after oversampling completion. Note the "UART_RX_FSM" module may read its value after the 4th positive adge of the CLK.


    always @(posedge CLK or negedge RST) begin
        if(!RST) begin
            stp_err_seq <= 1'b0;
        end
        else if(oversampling_completion_flag && stp_chk_en) begin
            stp_err_seq <= ~sampled_bit;
        end
        else if(!stp_chk_en) begin
            stp_err_seq <= 0;
        end
    end

    assign stp_err_comb = (stp_chk_en && !sampled_bit);

    // To handle the case when the oversampling = 4 (Prescale = 4).
    // When the oversampling = 4, the oversampling_completion_flag will be 1'b1 after the 4th positive edge of the CLK.
    // That means 'stp_err_seq' will be updated in the 5th CLK; which be in the next state of the frame (In START_BIT state).
    // I need to solve this problem by checking if the sampled_bit is updated in the 4th CLK to discover if the next state is 'START_BIT' or 'IDLE' through the same 4th CLK.
    assign stp_err = (is_Prescale_equal_4 &&  oversampling_completion_flag)? stp_err_comb : 
                     (is_Prescale_equal_4 && !oversampling_completion_flag)? 1'b0         : stp_err_seq;

endmodule

/*

module UART_RX_stop_check(
    // Inputs.
    input wire  sampled_bit                 , // To get the sampled checked bit.
    input wire  oversampling_completion_flag, // To know if the sampled_bit is checked or not.
    input wire  stp_chk_en                  , // To start the check.

    // Outputs.
    output reg  stp_err                      // To assign if there is an error.
);

    //assign Stop_Error = stp_err; // I Don't need to register it because it is removed directly after the transition to new input bit.
    always @(*) begin
        if(oversampling_completion_flag && stp_chk_en) begin
            stp_err = ~sampled_bit;
        end
        else if(!stp_chk_en) begin
            stp_err = 1'b0;
        end
    end

endmodule

*/