
module UART_RX_FSM #(
    parameter DATA_WIDTH = 8    
) (
    // Input ports and signals.
    RX_IN                , // Serial input port.
    PAR_EN               , // Parity enable signal. (0: To disable frame parity bit,  1: To enable frame parity bit)
    bit_cnt              , // Counter to know the number of the current receive serial bit on 'RX_IN'.
    last_edge_flag       , // To check if the edge counter 'edge_cnr' reached to last value. 
    before_last_edge_flag, // To check if the edge counter 'edge_cnr' reached to the value before last value.
    strt_glitch          , // To find if the start bit was a glitch or not.
    par_err              , // To find if there is an error in the receive parity bit value.
    stp_err              , // To find if there is an error in the receive stop bit value.
    CLK                  , // Clock signal. (fast clock and related to Prescale value)
    RST                  , // Reset signal. (Asynchronous Active low reset)

    // output port and signals.
    data_valid           , // Output port signal to confirm that the receive serial data is valid.
    dat_samp_en          , // To request serial data sampling. 
    enable               , // To enable the counters that operate the sampling (for the module 'edge_bit_counter' and its dependant modules).
    strt_chk_en          , // To request a check on the start bit.
    deser_en             , // To request operating the deserializer. 
    par_chk_en           , // To request a check on parity serial bit.
    stp_chk_en           , // To request a check on the stop serial bit. 
    enable_changing_prescale // To allow changing the prescale value.
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

    // Inputs.
    input  wire                                     RX_IN                       ; // Serial input port.
    input  wire                                     PAR_EN                      ; // Parity enable signal. (0: To disable frame parity bit,  1: To enable frame parity bit)
    input  wire [$clog2(DATA_WIDTH+3)-1 : 0]         bit_cnt                     ; // Counter to know the number of the current receive serial bit on 'RX_IN'.    
    input  wire                                     last_edge_flag              ; // To check if the edge counter 'edge_cnr' reached the last value.                              
    input  wire                                     before_last_edge_flag       ; // To check if the edge counter 'edge_cnr' reached the value before the last value.                   
    input  wire                                     strt_glitch                 ; // To find if the start bit was a glitch or not.   
    input  wire                                     par_err                     ; // To find if there is an error in the receive parity bit value.                     
    input  wire                                     stp_err                     ; // To find if there is an error in the receive stop bit value.  
    input  wire                                     CLK                         ; // Clock signal. (fast clock and related to Prescale value) 
    input  wire                                     RST                         ; // Reset signal. (Asynchronous Active low reset)                  
                                
    // Outputs.
    output reg                                      data_valid                  ; // Output port signal to confirm that the receive serial data is valid.                  
    output reg                                      dat_samp_en                 ; // To request serial data sampling.          
    output reg                                      enable                      ; // To enable the counters that operate the sampling (for the module 'edge_bit_counter' and its dependant modules).      
    output reg                                      strt_chk_en                 ; // To request a check on the start bit.
    output reg                                      deser_en                    ; // To request operating the deserializer.      
    output reg                                      par_chk_en                  ; // To request a check on parity serial bit.
    output reg                                      stp_chk_en                  ; // To request a check on the stop serial bit.
    output reg                                      enable_changing_prescale    ; // To allow changing the prescale value.
  
    localparam IDLE        = 0;
    localparam START_BIT   = 1;
    localparam SERIAL_DATA = 2;
    localparam PARITY_BIT  = 3;
    localparam STOP_BIT    = 4;
    localparam STOP_ERROR  = 5;

    reg [2:0] current_state;
    reg [2:0] next_state   ;

    wire data_valid_after_check; // To assign the 'data_valid' true value after completing the oversampling.

    always @(posedge CLK or negedge RST) begin
        if(!RST) begin
            current_state <= IDLE;
        end
        else begin
            current_state <= next_state;
        end
    end

    always @(*) begin
        case(current_state)
            // IDLE case.
            IDLE: begin
                    next_state = (RX_IN == 1'b1)? current_state : START_BIT; 
                end

            // At the start bit.
            START_BIT: begin
                    // (bit_cnt == 'd0 && last_edge_flag) means before (bit_cnt == 'd1) by 1 clock cycle.
                    if(bit_cnt == 'd0 && last_edge_flag) begin
                        if(strt_glitch) begin
                            next_state = IDLE;
                        end
                        else begin
                            next_state = SERIAL_DATA;
                        end 
                    end
                    else begin
                        next_state = current_state;
                    end
                end

            // To retrieve serial data. 
            SERIAL_DATA: begin
                    // (bit_cnt == DATA_WIDTH && last_edge_flag) means before (bit_cnt = DATA_WIDTH+1 [= 9 by default]) by 1 clock cycle.
                    if((bit_cnt == DATA_WIDTH && last_edge_flag) && PAR_EN) begin
                        next_state = PARITY_BIT;
                    end

                    // (bit_cnt == DATA_WIDTH && last_edge_flag) means before (bit_cnt = DATA_WIDTH+1 [= 9 by default]) by 1 clock cycle.
                    else if((bit_cnt == DATA_WIDTH && last_edge_flag) && !PAR_EN)  begin
                        next_state = STOP_BIT;
                    end
                    else begin
                        next_state = current_state;
                    end
                end

            // At parity bit.
            PARITY_BIT: begin
                    
                    // (bit_cnt == DATA_WIDTH+1 && last_edge_flag) means before (bit_cnt = DATA_WIDTH+2 [= 10 by default]) by 1 clock cycle.
                    if(bit_cnt == DATA_WIDTH +'d1 && last_edge_flag) begin
                        if(par_err) begin
                            next_state = IDLE;
                        end
                        else begin
                            next_state = STOP_BIT;
                        end
                    end
                    else begin
                        next_state = current_state;
                    end
                end

            // At stop bit
            STOP_BIT: begin
                    if(before_last_edge_flag) begin
                        next_state = STOP_ERROR;
                    end
                    else begin
                        next_state = current_state;
                    end
                end

            STOP_ERROR: begin
                    if(!RX_IN) begin
                        next_state = START_BIT;
                    end
                    else begin
                        next_state = IDLE;
                    end
                end
                
            default: begin
                    next_state = IDLE;
                end
        endcase 
    end
        
        
    always @(*) begin
        case(current_state)
            IDLE: begin
                    dat_samp_en = 1'b0; // To de-activate the sampling using "data_sampling" module.
                    enable      = 1'b0; // To de-activate the "edge_bit_counter" module.
                    strt_chk_en = 1'b0; // To de-activate the "start_check" module.
                    deser_en    = 1'b0; // To de-activate the "deserializer" module.
                    par_chk_en  = 1'b0; // To de-activate the "parity_check" module.
                    stp_chk_en  = 1'b0; // To de-activate the "stop_check" module.
                    data_valid  = 1'b0; // To confirm that the output "P_DATA" is wrong.
                    enable_changing_prescale = 1'b1; // To enable the prescale changing.
                end
            START_BIT: begin
                    dat_samp_en = 1'b1; // To    activate the sampling using "data_sampling" module.
                    enable      = 1'b1; // To    activate the "edge_bit_counter" module.
                    strt_chk_en = 1'b1; // To    activate the "start_check" module.
                    deser_en    = 1'b0; // To de-activate the "deserializer" module.
                    par_chk_en  = 1'b0; // To de-activate the "parity_check" module.
                    stp_chk_en  = 1'b0; // To de-activate the "stop_check" module.
                    data_valid  = 1'b0; // To confirm that the output "P_DATA" is wrong.
                    enable_changing_prescale = 1'b0; // To disable the prescale changing.
                end
            SERIAL_DATA: begin
                    dat_samp_en = 1'b1; // To    activate the sampling using "data_sampling" module.
                    enable      = 1'b1; // To    activate the "edge_bit_counter" module.
                    strt_chk_en = 1'b0; // To de-activate the "start_check" module.
                    deser_en    = 1'b1; // To    activate the "deserializer" module.
                    par_chk_en  = 1'b0; // To de-activate the "parity_check" module.
                    stp_chk_en  = 1'b0; // To de-activate the "stop_check" module.
                    data_valid  = 1'b0; // To confirm that the output "P_DATA" isn't prepared yet.
                    enable_changing_prescale = 1'b0; // To disable the prescale changing.
                end
            PARITY_BIT: begin
                    dat_samp_en = 1'b1; // To    activate the sampling using "data_sampling" module.
                    enable      = 1'b1; // To    activate the "edge_bit_counter" module.
                    strt_chk_en = 1'b0; // To de-activate the "start_check" module.
                    deser_en    = 1'b0; // To de-activate the "deserializer" module.
                    par_chk_en  = 1'b1; // To    activate the "parity_check" module.
                    stp_chk_en  = 1'b0; // To de-activate the "stop_check" module.
                    data_valid  = 1'b0; // To confirm that the output "P_DATA" is wrong.
                    enable_changing_prescale = 1'b0; // To disable the prescale changing.
                end
            STOP_BIT: begin
                    dat_samp_en = 1'b1; // To    activate the sampling using "data_sampling" module.
                    enable      = 1'b1; // To    activate the "edge_bit_counter" module.
                    strt_chk_en = 1'b0; // To de-activate the "start_check" module.
                    deser_en    = 1'b0; // To de-activate the "deserializer" module.
                    par_chk_en  = 1'b0; // To de-activate the "parity_check" module.
                    stp_chk_en  = 1'b1; // To    activate the "stop_check" module.
                    data_valid  = 1'b0; // To confirm that the output "P_DATA" isn't prepared and checked yet.
                    enable_changing_prescale = 1'b0; // To disable the prescale changing.
                end
            STOP_ERROR: begin
                    dat_samp_en = 1'b0; // To    activate the sampling using "data_sampling" module.
                    enable      = 1'b0; // To    activate the "edge_bit_counter" module.
                    strt_chk_en = 1'b0; // To de-activate the "start_check" module.
                    deser_en    = 1'b0; // To de-activate the "deserializer" module.
                    par_chk_en  = 1'b0; // To de-activate the "parity_check" module.
                    stp_chk_en  = 1'b1; // To    activate the "stop_check" module.
                    data_valid  = data_valid_after_check; // To confirm that the output "P_DATA" is correct.
                    enable_changing_prescale = 1'b1; // To determine the moment that you can change the prescale.
                end
            default: begin
                    dat_samp_en = 1'b0; // To de-activate the sampling using "data_sampling" module.
                    enable      = 1'b0; // To de-activate the "edge_bit_counter" module.
                    strt_chk_en = 1'b0; // To de-activate the "start_check" module.
                    deser_en    = 1'b0; // To de-activate the "deserializer" module.
                    par_chk_en  = 1'b0; // To de-activate the "parity_check" module.
                    stp_chk_en  = 1'b0; // To de-activate the "stop_check" module.
                    data_valid  = 1'b0; // To confirm that the output "P_DATA" is wrong.
                    enable_changing_prescale = 1'b1; // To enable the prescale changing.
                end
        endcase
    end


    assign data_valid_after_check = (last_edge_flag && !stp_err)? 1'b1 : 1'b0;


endmodule