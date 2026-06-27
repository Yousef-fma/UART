
module UART_RX_top #(
    parameter DATA_WIDTH        = 8,    // The expected received serial data width.
    parameter RECEIVE_MSB_FIRST = 0,    // To deal with the frame that has serial input data that start with MSB and LSB.(assign 1: if receive MSB at first, 0 or any other number: if receive LSB at first)
    parameter PRESCALE_DEFAULT  = 6'd32 // Default value of the prescaler is 32 (oversampling = 8).
) (
    input wire                     RX_IN       , // Serial Data IN
    input wire [5:0]               Prescale    , // Oversampling Prescale
    input wire                     PAR_EN      , // Parity_Enable
    input wire                     PAR_TYP     , // Parity Type
    input wire                     CLK         , // UART RX Clock Signal
    input wire                     RST         , // Synchronized reset signal

    output wire [DATA_WIDTH-1 : 0] P_DATA      , // Frame Data Word (= 1 Byte by default)
    output wire                    Parity_Error, // Frame Parity Error
    output wire                    Stop_Error  , // Frame Stop Error
    output wire                    data_valid    // Data Byte Valid signal
);

    // // Function to find the width of the bus 'bit_cnt';
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

    wire [$clog2(DATA_WIDTH+3)-1 : 0]        bit_cnt                     ; // Bus  from 'UART_RX_edge_bit_counter' module to 'UART_RX_data_sampling' & 'UART_RX_FSM' modules.
    wire                                     oversampling_completion_flag; // wire from 'UART_RX_data_sampling' module    to 'UART_RX_parity_check' & 'UART_RX_start_check' & 'UART_RX_stop_check' & 'UART_RX_deserializer' modules.
    wire                                     last_edge_flag              ; // wire from 'UART_RX_data_sampling' module    to 'UART_RX_FSM' & 'UART_RX_edge_bit_counter'. 
    wire                                     before_last_edge_flag       ; // wire from 'UART_RX_data_sampling' module    to 'UART_RX_FSM'.                 
    wire                                     strt_glitch                 ; // wire from 'UART_RX_start_check' module      to 'UART_RX_FSM'.                      
    wire                                     par_err                     ; // wire from 'UART_RX_parity_check' module     to 'UART_RX_FSM'.                      
    wire                                     stp_err                     ; // wire from 'UART_RX_stop_check' module       to 'UART_RX_FSM'.  
    wire                                     strt_chk_en                 ; // wire from 'UART_RX_start_check' module      to 'UART_RX_FSM'.     
    wire                                     dat_samp_en                 ; // wire from 'UART_RX_FSM' module              to 'UART_RX_data_sampling'.                   
    wire                                     enable                      ; // wire from 'UART_RX_FSM' module              to 'UART_RX_edge_bit_counter'.          
    wire                                     deser_en                    ; // wire from 'UART_RX_FSM' module              to 'UART_RX_deserializer'.  
    wire                                     par_chk_en                  ; // wire from 'UART_RX_FSM' module              to 'UART_RX_parity_check'.      
    wire                                     stp_chk_en                  ; // wire from 'UART_RX_FSM' module              to 'UART_RX_stop_check'.
    wire [5:0]                               edge_cnt                    ; // Bus  from 'UART_RX_edge_bit_counter'        to 'UART_RX_data_sampling'.
    wire                                     sampled_bit                 ; // Wire from 'UART_RX_data_sampling'           to 'UART_RX_parity_check' & 'UART_RX_start_check' & 'UART_RX_stop_check' & 'UART_RX_deserializer'.
    wire                                     is_Prescale_equal_4         ; // Wire to 'UART_RX_start_check' & 'UART_RX_parity_check' & 'UART_RX_stop_check'.
    reg  [5:0]                               Prescale_reg                ;
    wire                                     enable_changing_prescale    ; // Wire from 'UART_RX_FSM' to always block to update the Prescale registered value in (Prescale_reg).

    assign is_Prescale_equal_4 = (Prescale_reg == 4'd4) ? 1'b1 : 1'b0;

    //+===================================================================+
    //|                   Register 'Prescale' value.                      |
    //+===================================================================+  
    always @(posedge CLK or negedge RST) begin
        if(!RST) begin
            Prescale_reg <= PRESCALE_DEFAULT; // Default value of the prescaler is 32.
        end
        else if(enable_changing_prescale) begin
            Prescale_reg <= Prescale;
        end
    end







    //+===================================================================+
    //|                                FSM                                |
    //+===================================================================+  
    UART_RX_FSM #(
        .DATA_WIDTH(DATA_WIDTH)
    ) UART_RX_FSM (
        // Input ports and signals.
        .RX_IN                       (RX_IN                       ), // Serial input port.
        .PAR_EN                      (PAR_EN                      ), // Parity enable signal. (0: To disable frame parity bit,  1: To enable frame parity bit)
        .bit_cnt                     (bit_cnt                     ), // Counter to know the number of the current receive serial bit on 'RX_IN'.
        .last_edge_flag              (last_edge_flag              ), // To check if the edge counter 'edge_cnr' reached to last value. 
        .before_last_edge_flag       (before_last_edge_flag       ), // To check if the edge counter 'edge_cnr' reached to the value before last value.
        .strt_glitch                 (strt_glitch                 ), // To find if the start bit was a glitch or not.
        .par_err                     (par_err                     ), // To find if there is an error in the receive parity bit value.
        .stp_err                     (stp_err                     ), // To find if there is an error in the receive stop bit value.
        .CLK                         (CLK                         ), // Clock signal. (fast clock and related to Prescale value)
        .RST                         (RST                         ), // Reset signal. (Asynchronous Active low reset)

        // output port and signals.
        .data_valid                  (data_valid                  ), // Output port signal to confirm that the receive serial data is valid.
        .dat_samp_en                 (dat_samp_en                 ), // To request serial data sampling. 
        .enable                      (enable                      ), // To enable the counters that operate the sampling (for the module 'edge_bit_counter' and its dependant modules).
        .strt_chk_en                 (strt_chk_en                 ), // To request a check on the start bit.
        .deser_en                    (deser_en                    ), // To request operating the deserializer. 
        .par_chk_en                  (par_chk_en                  ), // To request a check on parity serial bit.
        .stp_chk_en                  (stp_chk_en                  ), // To request a check on the stop serial bit.
        .enable_changing_prescale    (enable_changing_prescale    ) // To request changing the prescale value.
    );


    
    //+===================================================================+
    //|                          edge_bit_counter                         |
    //+===================================================================+ 
    UART_RX_edge_bit_counter #(
        .DATA_WIDTH(DATA_WIDTH)
    ) edge_bit_counter_inst (
        // Inputs.
        .enable        (enable        ), // To activate the counters that's needed to know the current edge and received serial bit.
        .last_edge_flag(last_edge_flag), // To tell the edge counter to restart counting from 0.
        .CLK           (CLK           ), // Clock signal. (fast clock and related to Prescale value)
        .RST           (RST           ), // Reset signal. (Asynchronous Active low reset)
                                           
        // Outputs.
        .bit_cnt       (bit_cnt       ), // The number of the received serial bits.
        .edge_cnt      (edge_cnt      )  // The current edge counter value. 
    );


    //+===================================================================+
    //|                           data_sampling                           |
    //+===================================================================+ 
    UART_RX_data_sampling #(
        .DATA_WIDTH(DATA_WIDTH)
    ) data_sampling_inst (
        // Inputs.
        .RX_IN                       (RX_IN                       ), // The input serial data port.
        .Prescale                    (Prescale_reg                ), // To know what is the oversampling number per input clock cycle (per input bit).
        .dat_samp_en                 (dat_samp_en                 ), // To get the indication to start data sampling.
        .edge_cnt                    (edge_cnt                    ), // To know the start of the receive bit of the input serial data.
        .CLK                         (CLK                         ), // Clock signal. (fast clock and related to Prescale value)
        .RST                         (RST                         ), // Reset signal. (Asynchronous Active low reset)

        // Outputs.
        .sampled_bit                 (sampled_bit                 ), // To send on the sampled data bit after oversampling.
        .oversampling_completion_flag(oversampling_completion_flag), // To propose if the sampling is completed or not.
        .last_edge_flag              (last_edge_flag              ), // To propose is the current clock is the last clock for the current state of the FSM.  
        .before_last_edge_flag       (before_last_edge_flag       )  // To know if this moment is before the last serial 'RX_IN' of the frame.(when the 'bit_cnt' is 6).
    );



    //+===================================================================+
    //|                           deserializer                            |
    //+===================================================================+ 
    UART_RX_deserializer #(
        .DATA_WIDTH       (DATA_WIDTH       ),
        .RECEIVE_MSB_FIRST(RECEIVE_MSB_FIRST)
    ) deserializer_inst (
        // Input.
        .sampled_bit                 (sampled_bit                 ), // To receive the checked serial input value.
        .deser_en                    (deser_en                    ), // To start de-serialization.
        .oversampling_completion_flag(oversampling_completion_flag), // To know if the sampling complete or not to know when to start de-serialization.
        .CLK                         (CLK                         ), // Clock signal. (fast clock and related to Prescale value)
        .RST                         (RST                         ), // Reset signal. (Asynchronous Active low reset)

        // Output.
        .P_DATA                      (P_DATA                      )  // The output port Parallel data.
    );

    


    //+===================================================================+
    //|                           parity_check                            |
    //+===================================================================+ 
    UART_RX_parity_check #(
        .DATA_WIDTH(DATA_WIDTH)    
    ) parity_check_inst (
        // Inputs.
        .P_DATA                      (P_DATA                       ), // The output port Parallel data.
        .PAR_TYP                     (PAR_TYP                      ), // The expected parity type. (0: Even parity bit,  1: Odd parity bit)
        .par_chk_en                  (par_chk_en                   ), // To check parity if enable.
        .oversampling_completion_flag(oversampling_completion_flag ), // Know if final sample is ready.
        .sampled_bit                 (sampled_bit                  ), // The sampled bit.
        .is_Prescale_equal_4         (is_Prescale_equal_4         ), // To know if the prescaler is equal to 4 or not.
        .CLK                         (CLK                          ), // Clock signal. (fast clock and related to Prescale value)
        .RST                         (RST                          ), // Reset signal. (Asynchronous Active low reset)

        // Outputs.                                               
        .par_err                     (par_err                      )  // To propose on the output of the is a parity Error (as a sequential logic).
    );

    assign Parity_Error = (last_edge_flag)? par_err : 0;



    //+===================================================================+
    //|                            start_check                            |
    //+===================================================================+ 
    UART_RX_start_check start_check_inst (
        // Inputs.
        .sampled_bit                 (sampled_bit                 ), // To get the sampled checked bit.
        .oversampling_completion_flag(oversampling_completion_flag), // To know if the sampled_bit is checked or not.
        .strt_chk_en                 (strt_chk_en                 ), // To start the check.
        .is_Prescale_equal_4         (is_Prescale_equal_4         ), // To know if the prescaler is equal to 4 or not.
        .CLK                         (CLK                         ), // Clock Signal.
        .RST                         (RST                         ), // Asynchronous Active Low Reset.

        // Output.
        .strt_glitch                 (strt_glitch                 )  // To assign if there is a glitch.
    );




    //+===================================================================+
    //|                            stop_check                             |
    //+===================================================================+ 
    UART_RX_stop_check stop_check_inst (
        // Inputs.
        .sampled_bit                 (sampled_bit                 ), // To get the sampled checked bit.
        .oversampling_completion_flag(oversampling_completion_flag), // To know if the sampled_bit is checked or not.
        .stp_chk_en                  (stp_chk_en                  ), // To start the check.
        .is_Prescale_equal_4         (is_Prescale_equal_4         ), // To know if the prescaler is equal to 4 or not.
        .CLK                         (CLK                         ), // Clock Signal.
        .RST                         (RST                         ), // Asynchronous Active Low Reset.

        // Output.
        .stp_err                     (stp_err                     ) // To assign if there is an error.
    );
    
    assign Stop_Error = (last_edge_flag)? stp_err : 0;

endmodule