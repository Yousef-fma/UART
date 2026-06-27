
module UART_RX_start_check(
    // Inputs.
    input wire sampled_bit                 , // To get the sampled checked bit.
    input wire oversampling_completion_flag, // To know if the sampled_bit is checked or not.
    input wire strt_chk_en                 , // To start the check.
    input wire is_Prescale_equal_4         , // To know if the prescaler is equal to 4 or not.
    input wire CLK                         , // Clock signal.
    input wire RST                         , // Asynchronous Active Low Reset.

    // Outputs.
    output wire strt_glitch                  // To assign if there is a glitch.
);
    reg  strt_glitch_seq ; // Sequential logic to store the updated flag 'strt_glitch' after oversampling completion.
    wire strt_glitch_comb; // Combinational logic to assign the flag 'strt_glitch'. Note the "UART_RX_FSM" module may read its value after the 4th positive adge of the CLK.

    always @(posedge CLK or negedge RST) begin
        if(!RST) begin
            strt_glitch_seq <= 1'b0;
        end
        else begin
            strt_glitch_seq <= strt_glitch_comb;
        end
    end

    // To check if there is a glitch in combinational logic. 
    assign strt_glitch_comb = (strt_chk_en && sampled_bit == 1'b1 && oversampling_completion_flag);
    
    // To handle the case when the oversampling = 4 (Prescale = 4).
    // When the oversampling = 4, the oversampling_completion_flag will be 1'b1 after the 4th positive edge of the CLK.
    // That means 'strt_glitch_seq' will be updated in the 5th CLK; which be in the next bit of the frame (In first bit of SERIAL_DATA state).
    // I need to solve this problem by checking if the sampled_bit is 1'b1 in the 4th CLK to discover if the next state is 'SERIAL_DATA' or 'IDLE' through the same 4th CLK.
    assign strt_glitch = (is_Prescale_equal_4)? strt_glitch_comb : strt_glitch_seq;
endmodule


