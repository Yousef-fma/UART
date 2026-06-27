
// To deal with clock period = 5 ns / frequency = 200 MHz
`timescale 1ns/10ps
module UART_TX_tb();
    localparam CLK_PERIOD        = 5;                   // 5ns ==> 200 MHz 
    localparam DATA_WIDTH        = 8;                   // parallel input data width
    localparam SERIAL_DATA_WIDTH = 11 + DATA_WIDTH + 3; // SERIAL_DATA_WIDTH = the last previous bits(11-bit) + Start bit + data width + parity bit + stop bit = 11 + 1 + 8 + 1 + 1 = 22-bit
    localparam reg SEND_MSB_FIRST= 0;                   // To send LSB at first. (0: send LSB at first, 1: send MSB at first)      
    reg [SERIAL_DATA_WIDTH-1 : 0]  serial_TX_OUT_expected = 0; // The expected serial TX_OUT output.
    reg [SERIAL_DATA_WIDTH-1 : 0]  serial_TX_OUT_real     = 0; // The real serial TX_OUT output.
    reg [SERIAL_DATA_WIDTH-1 : 0]  serial_Busy_expected   = 0; // The expected serial Busy output.
    reg [SERIAL_DATA_WIDTH-1 : 0]  serial_Busy_real       = 0; // The real serial Busy output.


    reg  [DATA_WIDTH-1 : 0] P_DATA_tb    ;   // The parallel input data bus port.
    reg                     Data_Valid_tb;   // To start the the new frame if the current state was IDLE or STOP_BIT.
    reg                     PAR_EN_tb    ;   // To recognize if there will be a sent parity bit or not.
    reg                     PAR_TYP_tb   ;   // To determine the parity type. (0: even parity, 1: odd parity)
    reg                     CLK_tb       ;   // Clock signal.
    reg                     RST_tb       ;   // Active Low Asynchronous reset signal.
    wire                    TX_OUT_tb    ;   // To transfer the result on.
    wire                    Busy_tb      ;   // Is high as long as the current frame didn't finish.

    //////////////////////////////////
    // DUT instantiation.           //
    //////////////////////////////////
    UART_TX_top #(
        .DATA_WIDTH    (DATA_WIDTH     ), // The width of the parallel data bus.
        .SEND_MSB_FIRST(SEND_MSB_FIRST)  // To send MSB at first. (1: send MSB at first, else send LSB at first)       
    ) UART_TX_DUT (
        .P_DATA    (P_DATA_tb    ),  // The parallel input data bus port.
        .Data_Valid(Data_Valid_tb),  // To start the the new frame if the current state was IDLE or STOP_BIT.
        .PAR_EN    (PAR_EN_tb    ),  // To recognize if there will be a sent parity bit or not.
        .PAR_TYP   (PAR_TYP_tb   ),  // To determine the parity type. (0: even parity, 1: odd parity)
        .CLK       (CLK_tb       ),  // Clock signal.
        .RST       (RST_tb       ),  // Active Low Asynchronous reset signal.
        .TX_OUT    (TX_OUT_tb    ),  // To transfer the result on.
        .Busy      (Busy_tb      ),  // Is high as long as the current frame didn't finish.
        .last_bit_flag()
    );

    

    //////////////////////////////////
    // Clock Generation.            //
    //////////////////////////////////
    initial 
        begin
            CLK_tb = 0;
            forever 
                begin
                    #(CLK_PERIOD/2.0) CLK_tb = ~CLK_tb;
                end
        end
    

    //   _____________________________________________________________________________________
    //  |                                                                                     |
    //  |            ___________ <<<     Store Serial Data      >>>  ___________              |
    //  |_____________________________________________________________________________________|
    task store_serial_data(
        input tx_out_expected,
        input busy_expected
    );
        begin
            serial_TX_OUT_expected = {serial_TX_OUT_expected[SERIAL_DATA_WIDTH-2 : 0], tx_out_expected};
            serial_TX_OUT_real     = {serial_TX_OUT_real    [SERIAL_DATA_WIDTH-2 : 0], TX_OUT_tb      };
            serial_Busy_expected   = {serial_Busy_expected  [SERIAL_DATA_WIDTH-2 : 0], busy_expected  };
            serial_Busy_real       = {serial_Busy_real      [SERIAL_DATA_WIDTH-2 : 0], Busy_tb        };
        end
    endtask
    


    //   _____________________________________________________________________________________
    //  |                          (Update the serial DATA & Busy)                            |
    //  |            ___________ <<<   Find The Current State    >>>  ___________             |
    //  |_____________________________________________________________________________________|
    integer serializer_counter = 0;
    typedef enum integer { 
        IDLE           = 0,
        START_BIT      = 1,
        DATA_TO_SERIAL = 2,
        PARITY_BIT     = 3,
        LAST_BIT       = 4
    } state_t;
    state_t current_state = IDLE;
    state_t next_state    = IDLE;
    reg [DATA_WIDTH-1 : 0] P_DATA_reg  = 0;
    reg                    PAR_EN_reg  = 0;
    reg                    PAR_TYP_reg = 0;
    task update_serial_data(
        input [DATA_WIDTH-1 : 0] P_DATA_var,     // The parallel input.
        input                    Data_Valid_var, // The valid signals.
        input                    PAR_EN_var,     // 0: disable the parity bit, 1: enable parity bit.         
        input                    PAR_TYP_var,    // 0: even parity bit,        1: odd parity bit.
        input                    RST_var
    );
        reg wire1;
        begin
            current_state = next_state;
            if(!RST_var) begin
                current_state = IDLE;
                next_state    = IDLE;
            end
            else begin
                case(current_state)
                    // In IDLE case:
                    IDLE: begin
                            if(Data_Valid_var) begin
                                next_state = START_BIT;

                                // Register the DUT module inputs data.
                                P_DATA_reg  = P_DATA_var;
                                PAR_EN_reg  = PAR_EN_var;
                                PAR_TYP_reg = PAR_TYP_var;
                            end 
                            else begin
                                next_state = IDLE;
                            end
                            store_serial_data( 1, 0); // store_serial_data (tx_out_expected, busy_expected);
                            serializer_counter = DATA_WIDTH-1;
                        end

                    // In START_BIT case:
                    START_BIT: begin
                            next_state = DATA_TO_SERIAL;
                            store_serial_data( 0, 1); // store_serial_data (tx_out_expected, busy_expected);
                            serializer_counter = DATA_WIDTH-1;
                        end

                    // In DATA_TO_SERIAL case:
                    DATA_TO_SERIAL: begin
                            if(serializer_counter > 0) begin
                                next_state = DATA_TO_SERIAL;
                            end 
                            else if(PAR_EN_reg) begin
                                next_state = PARITY_BIT;
                            end 
                            else begin
                                next_state = LAST_BIT;
                            end

                            // To set this code flixable with if the MSB is sent first or not.
                            if(SEND_MSB_FIRST) begin
                                store_serial_data( P_DATA_reg[serializer_counter], 1); // store_serial_data (tx_out_expected, busy_expected);
                            end
                            else begin
                                store_serial_data( P_DATA_reg[DATA_WIDTH-serializer_counter-1], 1); // store_serial_data (tx_out_expected, busy_expected);
                            end
                            serializer_counter = serializer_counter - 1;
                        end

                    // In PARITY_BIT case:
                    PARITY_BIT: begin
                            next_state = LAST_BIT;
                            wire1      = (PAR_TYP_reg == 0)? ^P_DATA_reg : ~^P_DATA_reg; 
                            store_serial_data(wire1 , 1); // store_serial_data (tx_out_expected, busy_expected);
                            serializer_counter = DATA_WIDTH-1;
                        end

                    // In LAST_BIT case:
                    LAST_BIT: begin
                            if(Data_Valid_var) begin
                                next_state = START_BIT;

                                // Register the DUT module inputs data.
                                P_DATA_reg  = P_DATA_var;
                                PAR_EN_reg  = PAR_EN_var;
                                PAR_TYP_reg = PAR_TYP_var;
                            end
                            else begin
                                next_state = IDLE;
                            end
                            store_serial_data(1 , 1); // store_serial_data (tx_out_expected, busy_expected);
                            serializer_counter = DATA_WIDTH-1;
                        end
                endcase
            end
        end
    endtask

    //   _____________________________________________________________________________________
    //  |                                                                                     |
    //  |            ___________ <<<       Reset Signals        >>>  ___________              |
    //  |_____________________________________________________________________________________|
    integer check_case_num = 0;
    task reset();
        begin
            P_DATA_tb     <= 0;
            Data_Valid_tb <= 0;
            PAR_EN_tb     <= 0;
            PAR_TYP_tb    <= 0;    
            RST_tb        <= 0;

            @(posedge CLK_tb);
            #(CLK_PERIOD/10);

            RST_tb  <= 1;
            // store_serial_data (tx_out_expected, busy_expected);
            store_serial_data    (       1       ,       0      );
            #(CLK_PERIOD/10); // assert the assignments. after the positive edge of the clock.
        end
    endtask
    



    //   _____________________________________________________________________________________
    //  |                                                                                     |
    //  |            ___________ <<<    Initialize Signals      >>>  ___________              |
    //  |_____________________________________________________________________________________|
    task initialize();
        begin
            P_DATA_tb          <= 0;
            Data_Valid_tb      <= 0;
            PAR_EN_tb          <= 0;
            PAR_TYP_tb         <= 0;
            RST_tb             <= 1;
            //serializer_counter <= 0;
            store_serial_data(1, 0); // store_serial_data (tx_out_expected, busy_expected);
            @(posedge CLK_tb);
            #(CLK_PERIOD/10);        // assert the assignments. after the positive edge of the clock.
        end
    endtask
    


//serializer_counter
    //   _____________________________________________________________________________________
    //  |                                                                                     |
    //  |            ___________ <<<         Send DATA          >>>  ___________              |
    //  |_____________________________________________________________________________________|
    task send_data(
        input [DATA_WIDTH-1 : 0] parallel_data    , // The parallel input.
        input integer            data_valid_seq   , // The sequence of the valid signals.
        input integer            parity_enable_seq, // 0: disable the parity bit, 1: enable parity bit.         
        input integer            parity_type_seq  , // 0: even parity bit,        1: odd parity bit.
        input integer            clocks_num         // The number of waited clock cycles
    );
        integer n;
        begin
            for(n = 0 ; n < clocks_num ; n = n + 1) 
                begin 
                    P_DATA_tb       <= parallel_data       ;
                    Data_Valid_tb   <= data_valid_seq   [n];
                    PAR_EN_tb       <= parity_enable_seq[n];
                    PAR_TYP_tb      <= parity_type_seq  [n];

                    @(posedge CLK_tb);
                    #(CLK_PERIOD/10); // assert the assignments. after the positive edge of the clock.
                    update_serial_data( 
                        .P_DATA_var    (parallel_data       ), 
                        .Data_Valid_var(data_valid_seq   [n]), 
                        .PAR_EN_var    (parity_enable_seq[n]),
                        .PAR_TYP_var   (parity_type_seq  [n]),
                        .RST_var       (1)
                    );
                end
        end
    endtask

    

    //   _____________________________________________________________________________________
    //  |                                                                                     |
    //  |            ___________ <<<       Check Result         >>>  ___________              |
    //  |_____________________________________________________________________________________|
    task check_result();
        begin
            check_case_num = check_case_num + 1;
            #(CLK_PERIOD/10); // assert the assignments. after the positive edge of the clock.
            if (serial_TX_OUT_expected == serial_TX_OUT_real &&   
                serial_Busy_expected   == serial_Busy_real)
                begin                    
                    $display("Case %3d: The last accepted inputs: P_data = %b, PAR_EN = %b, PAR_TYP = %b",
                    check_case_num, P_DATA_reg, PAR_EN_reg, PAR_TYP_reg);
                    $display("\t  serial_TX_OUT = %b,", serial_TX_OUT_real);
                    $display("\t  serial_Busy   = %b",  serial_Busy_real);
                    $display("\t  success...");
                end
            else
                begin
                    $display("Case %3d: The last accepted inputs: P_data = %b, PAR_EN = %b, PAR_TYP = %b",
                    check_case_num, P_DATA_reg, PAR_EN_reg, PAR_TYP_reg);
                    $display("            -->  serial_TX_OUT_real     = %b, serial_Busy_real     = %b", serial_TX_OUT_real, serial_Busy_real);
                    $display("            -->  serial_TX_OUT_expected = %b, serial_Busy_expected = %b", serial_TX_OUT_expected, serial_Busy_expected);
                    $display("\t Case %3d: Failure.\t\t\t         ----------------------  Problem  ----------------------", check_case_num);
                end
        end
    endtask



    //   _____________________________________________________________________________________
    //  |                                                                                     |
    //  |            ___________ <<<      Stimulus Signals      >>>  ___________              |
    //  |_____________________________________________________________________________________|
    initial
        begin
            $dumpfile("UART_TX_dump.vcd");
            $dumpvars();
            
            $display("_____________________________________________");
            // Test case 1:
            reset();        // reset signals.
            check_result(); // check the result.

            
            // Test case 2:
            initialize();   // initialize signals.
            check_result(); // check the result.

            
            // Test case 3:
            // send 'b0000_1111 then wait 11 CLKs to check.
            send_data(
                .parallel_data    ('b0000_1111), // The parallel input.
                .data_valid_seq   ('b0000_0001), // The sequence of the valid signals               (from Right (at the first clock) to Left (toward the last clock)).
                .parity_enable_seq('b0000_0001), // 0: disable the parity bit, 1: enable parity bit.(from Right (at the first clock) to Left (toward the last clock)).
                .parity_type_seq  ('b0000_0000), // 0: even parity bit,        1: odd parity bit.   (from Right (at the first clock) to Left (toward the last clock)).
                .clocks_num       (11)           // The number of waited clock cycles while implementing the input sequences.
            );
            //The result sequences are in this form: 
            //  (Previous pits) --> (Start bit) --> (form MSB of the Parallel data to LSB) --> (Parity bit (may be not found)) --> (Stop bit).
            check_result(); // check the result. 

            
            // Test case 4:
            // send 'b0000_0000 then wait 12 CLKs to check.
            send_data(
                .parallel_data    ('b0000_0000), // The parallel input.
                .data_valid_seq   ('b0110_0010), // The sequence of the valid signals.               (from Right (at the first clock) to Left (toward the last clock)).          
                .parity_enable_seq('b0101_0010), // 0: disable the parity bit, 1: enable parity bit. (from Right (at the first clock) to Left (toward the last clock)).         
                .parity_type_seq  ('b0101_0010), // 0: even parity bit,        1: odd parity bit.    (from Right (at the first clock) to Left (toward the last clock)). 
                .clocks_num       (12)           // The number of waited clock cycles
            );
            //The result sequences are in this form: 
            //  (Previous pits) --> (Start bit) --> (form MSB of the Parallel data to LSB) --> (Parity bit (may be not found)) --> (Stop bit).
            check_result(); // check the result.

            
            // Test case 5:
            // send 'b1010_1010 then wait 5 CLKs to check.
            send_data(
                .parallel_data    ('b1010_1010), // The parallel input.
                .data_valid_seq   ('b0010_0011), // The sequence of the valid signals.               (from Right (at the first clock) to Left (toward the last clock)).          
                .parity_enable_seq('b0101_0000), // 0: disable the parity bit, 1: enable parity bit. (from Right (at the first clock) to Left (toward the last clock)).         
                .parity_type_seq  ('b0101_0010), // 0: even parity bit,        1: odd parity bit.    (from Right (at the first clock) to Left (toward the last clock)). 
                .clocks_num       (12)           // The number of waited clock cycles
            );
            check_result(); // check the result.
            

            // Test case 6:
            // send 'b0000_0000 then wait 10 CLKs to check. (Here there still another process in UART_TX so, the data won't be accepted immediately)
            send_data(
                .parallel_data    ('b0000_0000), // The parallel input.
                .data_valid_seq   ('b0010_0011), // The sequence of the valid signals.               (from Right (at the first clock) to Left (toward the last clock)).          
                .parity_enable_seq('b0101_0000), // 0: disable the parity bit, 1: enable parity bit. (from Right (at the first clock) to Left (toward the last clock)).         
                .parity_type_seq  ('b0101_0010), // 0: even parity bit,        1: odd parity bit.    (from Right (at the first clock) to Left (toward the last clock)). 
                .clocks_num       (12)           // The number of waited clock cycles
            );
            check_result(); // check the result.


            // Test case 7:
            // send 'b1111_1111 then wait 10 CLKs to check. (Here the data won't be accepted, because there is no valid bit).
            send_data(
                .parallel_data    ('b1111_1111), // The parallel input.
                .data_valid_seq   ('b0000_0000), // The sequence of the valid signals.               (from Right (at the first clock) to Left (toward the last clock)).          
                .parity_enable_seq('b0101_0000), // 0: disable the parity bit, 1: enable parity bit. (from Right (at the first clock) to Left (toward the last clock)).         
                .parity_type_seq  ('b0101_0010), // 0: even parity bit,        1: odd parity bit.    (from Right (at the first clock) to Left (toward the last clock)). 
                .clocks_num       (12)           // The number of waited clock cycles
            );
            check_result(); // check the result.
        

            // Test case 8:
            // send 'b1111_1111 then wait 11 CLKs to check.
            send_data(
                .parallel_data    ('b1111_1111), // The parallel input.
                .data_valid_seq   ('b0000_0001), // The sequence of the valid signals.               (from Right (at the first clock) to Left (toward the last clock)).          
                .parity_enable_seq('b1010_0001), // 0: disable the parity bit, 1: enable parity bit. (from Right (at the first clock) to Left (toward the last clock)).         
                .parity_type_seq  ('b0100_0011), // 0: even parity bit,        1: odd parity bit.    (from Right (at the first clock) to Left (toward the last clock)). 
                .clocks_num       (11)           // The number of waited clock cycles
            );
            check_result(); // check the result.

            // Test case 9:
            // send 'b1100_0011 then wait 12 CLKs to check. (This signal will be sent directly after the previous one).
            send_data(
                .parallel_data    ('b1100_0011), // The parallel input.
                .data_valid_seq   ('b0001_0001), // The sequence of the valid signals.               (from Right (at the first clock) to Left (toward the last clock)).          
                .parity_enable_seq('b1010_0001), // 0: disable the parity bit, 1: enable parity bit. (from Right (at the first clock) to Left (toward the last clock)).         
                .parity_type_seq  ('b0100_0011), // 0: even parity bit,        1: odd parity bit.    (from Right (at the first clock) to Left (toward the last clock)). 
                .clocks_num       (12)           // The number of waited clock cycles
            );
            check_result(); // check the result.
        
            $display("_____________________________________________");
            $stop;
        end
        
endmodule
