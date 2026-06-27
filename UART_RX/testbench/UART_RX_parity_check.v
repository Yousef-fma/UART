
module UART_RX_parity_check #(
    parameter DATA_WIDTH = 8    
) (
    // Inputs.
    input  wire [DATA_WIDTH-1 : 0] P_DATA                      , // The output port Parallel data.
    input  wire                    PAR_TYP                     , // The expected parity type. (0: Even parity bit,  1: Odd parity bit)
    input  wire                    par_chk_en                  , // To check parity if enable.
    input  wire                    oversampling_completion_flag, // Know if final sample is ready.
    input  wire                    sampled_bit                 , // The sampled bit.
    input  wire                    is_Prescale_equal_4         , // To know if the prescaler is equal to 4 or not.
    input  wire                    CLK                         , // Clock signal. (fast clock and related to Prescale value)
    input  wire                    RST                         , // Reset signal. (Asynchronous Active low reset)


    // Outputs.
    output wire                    par_err                        // To tell FSM if there is a parity error in a sequential logic.      
);
    reg  par_err_seq ; // Sequential logic to store the updated flag 'par_err' after oversampling completion.
    reg  par_err_comb; // Combinational logic to assign the flag 'par_err' after oversampling completion. Note the "UART_RX_FSM" module may read its value after the 4th positive adge of the CLK.


    always @(posedge CLK or negedge RST) begin
        if(!RST) begin
            par_err_seq <= 'd0;
        end

        // Update the parity error flag whether it was even parity or odd parity.
        else if(par_chk_en && oversampling_completion_flag) begin
            par_err_seq <= par_err_comb;
        end

        // return to default value 'par_err' = 0 to deal with new serial input data.
        else if(!par_chk_en) begin
            par_err_seq <= 1'b0;
        end
    end

    always @(*) begin
        // Check if even parity.
        if(PAR_TYP == 1'b0) begin
            par_err_comb = (^P_DATA != sampled_bit) & par_chk_en;
        end

        // Check if odd parity
        else begin
            par_err_comb = (~^P_DATA != sampled_bit) & par_chk_en; 
        end
    end
    
    
    // To handle the case when the oversampling = 4 (Prescale = 4).
    // When the oversampling = 4, the oversampling_completion_flag will be 1'b1 after the 4th positive edge of the CLK.
    // That means 'par_err_seq' will be updated in the 5th CLK; which be in the next state of the frame (In STOP_BIT state).
    // I need to solve this problem by checking if the sampled_bit is updated in the 4th CLK to discover if the next state is 'STOP_BIT' or 'IDLE' through the same 4th CLK.
    assign par_err = (is_Prescale_equal_4  &&  oversampling_completion_flag) ? par_err_comb :
                     (is_Prescale_equal_4  && !oversampling_completion_flag) ? 1'b0         : par_err_seq;

endmodule