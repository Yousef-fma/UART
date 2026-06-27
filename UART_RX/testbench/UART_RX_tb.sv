

`timescale 1ps/1ps
module UART_RX_tb();
    localparam      DATA_WIDTH          = 8             ; // The Width of the data that UART protocol send.
    localparam      UART_TX_FRAME_BITS  = DATA_WIDTH + 3; // The Frame Width including the parity bit: width = 1(start bit) + DATA_WIDTH(serial data) + 1(parity bit) + 1(stop bit) = DATA_WIDTH + 3
    localparam time TX_CLK_PERIOD       = 8680555.6     ; // The clock period for the 'UART_TX' module.
    
    reg [DATA_WIDTH-1 : 0] p_data_expected       [1:0]; // To store the 'P_DATA_TX'       signal as an expected value for the comparison in the 'check_result' task.
    reg [DATA_WIDTH-1 : 0] p_data_rx_dut         [1:0]; // To store the 'P_DATA_TX'       signal as a dut value       for the comparison in the 'check_result' task.
    reg                    data_valid_expected   [1:0]; // To store the 'data_valid'      signal as an expected value for the comparison in the 'check_result' task.
    reg                    data_valid_rx_dut     [1:0]; // To store the 'data_valid'      signal as a dut value       for the comparison in the 'check_result' task.
    reg                    Parity_Error_RX_rx_dut[1:0]; // To store the 'Parity_Error_RX' signal as a dut value       for the comparison in the 'check_result' task.
    reg                    Stop_Error_RX_rx_dut  [1:0]; // To store the 'Stop_Error_RX'   signal as a dut value       for the comparison in the 'check_result' task.

    integer test_case_counter =0 ; // To count the test cases in the 'check_result' task.
    integer error_count = 0, success_count = 0 ;

    // ==============   UART-RX ports  ==============
    // Inputs.
    wire                     RX_IN          ;
    reg  [5:0]               Prescale       ;
    reg                      PAR_EN         ;
    reg                      PAR_TYP        ;
    reg                      CLK_RX         ;
    reg                      RST            ;

    // Outputs.
    wire  [DATA_WIDTH-1 : 0] P_DATA_RX      ;
    wire                     Parity_Error_RX;
    wire                     Stop_Error_RX  ;
    wire                     data_valid_RX  ;



    // ==============   UART-TX ports  ==============
    // Inputs.
    reg  [DATA_WIDTH-1 : 0] P_DATA_TX    ; // The parallel input data bus port.
    reg                     Data_Valid_TX; // To start the the new frame if the current state was IDLE or STOP_BIT.
  //reg                     PAR_EN       ; // To recognize if there will be a sent parity bit or not.
  //reg                     PAR_TYP      ; // To determine the parity type. (0: even parity, 1: odd parity)
    reg                     CLK_TX       ; // Clock signal.
  //reg                     RST          ; // Active Low Asynchronous reset signal.

    // Outputs. 
    wire                    TX_OUT       ; // To transfer the result on.
  //wire                    Busy         ; // Is high as long as the current frame didn't finish.


    // UART-RX FSM States:
    enum reg[2:0] { 
        IDLE        = 0,
        START_BIT   = 1,
        SERIAL_DATA = 2,
        PARITY_BIT  = 3,
        STOP_BIT    = 4
    } current_state;

    initial begin
        forever begin
            @(posedge CLK_RX);
            case(UART_RX_DUT.UART_RX_FSM.current_state)
                0: current_state = IDLE       ;
                1: current_state = START_BIT  ;
                2: current_state = SERIAL_DATA;
                3: current_state = PARITY_BIT ;
                4: current_state = STOP_BIT   ;
            endcase
        end
    end



    //////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
    //     _________________________________________________________________________________________________________    //
    //   /_________________________________________________________________________________________________________/|   //
    //  |                                                                                                         | |   //
    //  |              ---------------   *****       DUT Instantiation       *****   ---------------              | |   //
    //  |_________________________________________________________________________________________________________|/    //
    //                                                                                                                  //
    //////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

    //        ========================   UART-TX   ========================
    UART_TX_top #(
        .DATA_WIDTH    (DATA_WIDTH), // The expected received serial data width.
        .SEND_MSB_FIRST(0         )   // To choose if the serial date start from MSB or LSB (1: to start with MSB,  0: to start with LSB).
    ) UART_TX_DUT (
        .P_DATA     (P_DATA_TX    ), // The parallel input data bus port.
        .Data_Valid (Data_Valid_TX), // To start the the new frame if the current state was IDLE or STOP_BIT.
        .PAR_EN     (PAR_EN       ), // To recognize if there will be a sent parity bit or not.
        .PAR_TYP    (PAR_TYP      ), // To determine the parity type. (0: even parity, 1: odd parity)
        .CLK        (CLK_TX       ), // Clock signal.
        .RST        (RST          ), // Active Low Asynchronous reset signal.
        .TX_OUT     (TX_OUT       ), // To transfer the result on.
        .Busy       (Busy_TX      ), // Is high as long as the current frame didn't finish.
        .last_bit_flag()
    );


    //        ========================   UART-RX   ========================
    assign RX_IN = TX_OUT;

    UART_RX_top #(
        .DATA_WIDTH       (DATA_WIDTH), // The expected received serial data width.
        .RECEIVE_MSB_FIRST(0         )  // To deal with the frame that has serial input data that start with MSB and LSB.(assign 1: if receive MSB at first, 0 or any other number: if receive LSB at first)
    ) UART_RX_DUT (
        .RX_IN       (RX_IN          ),  // connected with UART-RX port: 'RX_OUT'
        .Prescale    (Prescale       ),
        .PAR_EN      (PAR_EN         ),  // connected with UART-RX port: 'PAR_EN'
        .PAR_TYP     (PAR_TYP        ),  // connected with UART-RX port: 'PAR_TYP'
        .CLK         (CLK_RX         ),
        .RST         (RST            ),  // connected with UART-RX port: 'RST'

        .P_DATA      (P_DATA_RX      ),
        .Parity_Error(Parity_Error_RX),
        .Stop_Error  (Stop_Error_RX  ),
        .data_valid  (data_valid_RX  )
    );

    //////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
    //     _________________________________________________________________________________________________________    //
    //   /_________________________________________________________________________________________________________/|   //
    //  |                                                                                                         | |   //
    //  |              ---------------   *****       Clock Generation        *****   ---------------              | |   //
    //  |_________________________________________________________________________________________________________|/    //
    //                                                                                                                  //
    //////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

    //        ========================   UART-TX Clock   ========================
    initial begin
        CLK_TX = 0;
        forever begin
            #(TX_CLK_PERIOD / 2.0) CLK_TX = ~CLK_TX;
        end
    end
    
    //        ========================   UART-RX Clock   ========================
    initial begin
        CLK_RX = 0;
        forever begin
            #1step;
            case (Prescale)
                32: #((TX_CLK_PERIOD/32.0) / 2.0) CLK_RX = ~CLK_RX;
                16: #((TX_CLK_PERIOD/16.0) / 2.0) CLK_RX = ~CLK_RX;
                8 : #((TX_CLK_PERIOD/8.0)  / 2.0) CLK_RX = ~CLK_RX;
            endcase
        end
    end

// ==================================================================================================================== //
//  //-------------------------------------------     /           \     --------------------------------------------\\  //
// ||                                              >      TASKS      <                                               || //
//  \\-------------------------------------------     \           /     ------------------------------------------- //  //
// ==================================================================================================================== //


    //__________________________________________________________________________________________________________
    //|                                                                                                         |
    //|              ---------------   *****       set_oversampling        *****   ---------------              |
    //|_________________________________________________________________________________________________________|
    task set_oversampling(input reg [5:0] samples_num);
        begin
            Prescale = samples_num;
            $display("\n\t\t____________________________  Start Oversampling By (%0d)  ____________________________", samples_num);
        end
    endtask


    //__________________________________________________________________________________________________________
    //|                                                                                                         |
    //|              ---------------   *****             reset             *****   ---------------              |
    //|_________________________________________________________________________________________________________|
    task reset();
        begin
            RST           = 'd0;
            Prescale      = 'd8;
            PAR_EN        = 'd0;
            PAR_TYP       = 'd0;
            P_DATA_TX     = 'd0; 
            Data_Valid_TX = 'd0; 

            p_data_expected        = '{0, 0}; // To use in comparison in 'reset' task
            p_data_rx_dut          = '{0, 0}; // To use in comparison in 'reset' task
            data_valid_expected    = '{0, 0}; // To use in comparison in 'reset' task  
            data_valid_rx_dut      = '{0, 0}; // To use in comparison in 'reset' task  
            Parity_Error_RX_rx_dut = '{0, 0};
            Stop_Error_RX_rx_dut   = '{0, 0};

            
            @(posedge CLK_RX);
            $display("\n\n   =================                ****    Reset    ****                =================");
            #1step; // To assert the assignment in the DUT's.
            RST           = 'd1;
        end
    endtask


    //__________________________________________________________________________________________________________
    //|                                                                                                         |
    //|              ---------------   *****          initialize           *****   ---------------              |
    //|_________________________________________________________________________________________________________|

    task initialize();
        begin
            RST            = 'd1;
            Prescale       = 'd8;
            PAR_EN         = 'd0;
            PAR_TYP        = 'd0;
            P_DATA_TX      = 'd0; 
            Data_Valid_TX  = 'd0; 

            @(posedge CLK_RX);
            #1step;
        end
    endtask



    //__________________________________________________________________________________________________________
    //|                                                                                                         |
    //|      *****   set_even_parity_mode  -- && --  set_odd_parity_mode -- && -- set_no_parity_mode   *****    |
    //|_________________________________________________________________________________________________________|
    task set_even_parity_mode();
        begin
            PAR_EN      = 'd1;
            PAR_TYP     = 'd0;            
        end
    endtask

    task set_odd_parity_mode();
        begin
            PAR_EN       = 'd1;
            PAR_TYP      = 'd1;            
        end
    endtask

    task set_no_parity_mode();
        begin
            PAR_EN  = 'd0;         
        end
    endtask




    //__________________________________________________________________________________________________________
    //|                                                                                                         |
    //|               ---------------   *****           put_data          *****   ---------------               |
    //|_________________________________________________________________________________________________________|

    task put_data(
            input [DATA_WIDTH-1 : 0] p_data_var,
            input                    data_valid_var
        );
        integer i;
        reg exit_flag;
        begin
            P_DATA_TX      = p_data_var;
            Data_Valid_TX  = data_valid_var;
            exit_flag      = 0;

            @(posedge CLK_TX);  #1step; // To assert the assignment in the UART-TX module.
            Data_Valid_TX = 0;          // Remove the valid signal after 1 clock;

            ///////////////   --------    Wait UART-RX    --------   ///////////////
            @(posedge CLK_RX); // To get rid of the phase shift between CLK_RX and CLK_TX to start count the needed number of clocks of 'CLK_RX'.
            if(PAR_EN) begin
                for(i=0; i < ((UART_TX_FRAME_BITS * Prescale) - 1) ; i = i + 1) begin 
                    @(posedge CLK_RX); 
                    if(data_valid_RX) begin 
                        exit_flag=1;
                    end 
                end
            end 
            else begin
                for(i=0; i < (((UART_TX_FRAME_BITS-1) * Prescale) - 1) ; i = i + 1) begin 
                    @(posedge CLK_RX); 
                    if(data_valid_RX) begin 
                        exit_flag=1 ;
                    end 
                end
            end
            
            if(data_valid_var == 1 && exit_flag == 0) begin
                wait(data_valid_RX);
            end
            #1step;

            data_valid_expected   [1] = data_valid_var ;
            p_data_expected       [1] = p_data_var     ;
            data_valid_rx_dut     [1] = data_valid_RX  ;
            Parity_Error_RX_rx_dut[1] = Parity_Error_RX;  
            Stop_Error_RX_rx_dut  [1] = Stop_Error_RX  ;
            p_data_rx_dut         [1] = P_DATA_RX      ;
            @(posedge CLK_TX); 
        end
    endtask

    //__________________________________________________________________________________________________________
    //|                                                                                                         |
    //|               ---------------   *****      put_data_sequence      *****   ---------------               |
    //|_________________________________________________________________________________________________________|
    reg check_previous_frame = 0;
    task put_data_sequence(
            input [DATA_WIDTH-1 : 0] p_data_var1    ,
            input                    data_valid_var1,
            input [DATA_WIDTH-1 : 0] p_data_var2    ,
            input                    data_valid_var2
        );
        integer i;
        reg exit_flag;
        begin
            ///////////////   ----------   First Frame   ----------   ///////////////
            P_DATA_TX      = p_data_var1;
            Data_Valid_TX  = data_valid_var1;
            exit_flag      = 0;

            @(posedge CLK_TX);  #1step; // To assert the assignment in the UART-TX module.
            Data_Valid_TX = 0;          // Remove the valid signal after 1 clock;

           ////   --------    Wait UART-RX    --------   ////
            @(posedge CLK_RX); // To get rid of the phase shift between CLK_RX and CLK_TX to start count the needed number of clocks of 'CLK_RX'.
            if(PAR_EN) begin
                for(i=0; i < ((UART_TX_FRAME_BITS * Prescale) - 1) ; i = i + 1) begin 
                    @(posedge CLK_RX); 
                    if(data_valid_RX) begin 
                        exit_flag=1;
                    end 
                end
            end 
            else begin
                for(i=0; i < (((UART_TX_FRAME_BITS-1) * Prescale) - 1) ; i = i + 1) begin 
                    @(posedge CLK_RX); 
                    if(data_valid_RX) begin 
                        exit_flag=1 ;
                    end 
                end
            end
            
            if(data_valid_var1 == 1 && exit_flag == 0) begin
                wait(data_valid_RX);
            end

            data_valid_expected   [0] = data_valid_var1;
            p_data_expected       [0] = p_data_var1    ;
            data_valid_rx_dut     [0] = data_valid_RX  ;
            Parity_Error_RX_rx_dut[0] = Parity_Error_RX;  
            Stop_Error_RX_rx_dut  [0] = Stop_Error_RX  ;
            p_data_rx_dut         [0] = P_DATA_RX      ;
            check_previous_frame      = 1              ; // check this frame in the 'check_result' task.
            @(posedge CLK_RX); // Note : The sent frame must wait other clock cycle 'CLK_RX' to be sent completely.


            ///////////////   ----------   Second Frame   ----------   ///////////////
            P_DATA_TX      = p_data_var2;
            Data_Valid_TX  = data_valid_var2;
            exit_flag      = 0;

            @(posedge CLK_TX);  #1step; // To assert the assignment in the UART-TX module.
            Data_Valid_TX = 0;          // Remove the valid signal after 1 clock;

            ////   --------    Wait UART-RX    --------   ////
            @(posedge CLK_RX); // To get rid of the phase shift between CLK_RX and CLK_TX to start count the needed number of clocks of 'CLK_RX'.
            if(PAR_EN) begin
                for(i=0; i < ((UART_TX_FRAME_BITS * Prescale) - 1) ; i = i + 1) begin 
                    @(posedge CLK_RX); 
                    if(data_valid_RX) begin 
                        exit_flag=1;
                    end 
                end
            end 
            else begin
                for(i=0; i < (((UART_TX_FRAME_BITS-1) * Prescale) - 1) ; i = i + 1) begin 
                    @(posedge CLK_RX); 
                    if(data_valid_RX) begin 
                        exit_flag=1 ;
                    end 
                end
            end
            
            if(data_valid_var2 == 1 && exit_flag == 0) begin
                wait(data_valid_RX);
            end

            data_valid_expected   [1] = data_valid_var2;
            p_data_expected       [1] = p_data_var2    ;
            data_valid_rx_dut     [1] = data_valid_RX  ;
            Parity_Error_RX_rx_dut[1] = Parity_Error_RX;  
            Stop_Error_RX_rx_dut  [1] = Stop_Error_RX  ;
            p_data_rx_dut         [1] = P_DATA_RX      ;
            @(posedge CLK_RX); // Note : The sent frame must wait other clock cycle 'CLK_RX' to be sent completely.
        end
    endtask
    

    //__________________________________________________________________________________________________________
    //|                                                                                                         |
    //|              ---------------   *****          check_result         *****   ---------------              |
    //|_________________________________________________________________________________________________________|
    task check_result();
        begin
            #1step;
            test_case_counter = test_case_counter + 1'b1;

            ///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
            // for 'put_data_sequence' task functionality.                                                                                                           //
            if(check_previous_frame) begin                                                                                                                           //
                check_previous_frame = 0;                                                                                                                            //
                                                                                                                                                                     //
                if((p_data_rx_dut         [0] == p_data_expected[0]     &&                                                                                           //
                    Parity_Error_RX_rx_dut[0] == 1'd0                   &&                                                                                           //
                    Stop_Error_RX_rx_dut  [0] == 1'd0                   &&                                                                                           //
                    data_valid_rx_dut     [0] == data_valid_expected[0]) ||                                                                                          //
                    (data_valid_rx_dut    [0] == 'b0 && data_valid_expected[0] == 'b0) )                                                                             //
                begin                                                                                                                                                //
                    success_count = success_count + 1;                                                                                                               //
                    $display("\t time: %11.3t ns: P_DATA_TX = %b ---> P_DATA_RX = %b     (Accepted)", $time/1000.0, p_data_expected[0], p_data_rx_dut[0]);           //
                    $display("     First Frame Success...");                                                                                                         //
                end                                                                                                                                                  //
                else begin                                                                                                                                           //
                    error_count = error_count + 1;                                                                                                                   //
                    $display("\t time: %11.3t ns:", $time/1000.0);                                                                                                   //
                    $display("\t\t P_DATA_RX       = %08b  --->  But the expected P_DATA = %b", p_data_rx_dut[0], p_data_expected[0]        );                       // 
                    $display("\t\t Parity_Error_RX = %-8b  --->  But the expected 0"          , Parity_Error_RX_rx_dut[0]                   );                       //
                    $display("\t\t Stop_Error_RX   = %-8b  --->  But the expected 0"          , Stop_Error_RX_rx_dut[0]                     );                       //
                    $display("\t\t data_valid_RX   = %-8b  --->  But the expected %0b"        , data_valid_rx_dut[0], data_valid_expected[0]);                       //
                    $display("     First Frame Fail...   <<======================================  ERROR  ===================================>>");                   //
                end                                                                                                                                                  //
            end                                                                                                                                                      //
            ///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////


            if((p_data_rx_dut         [1] == p_data_expected[1]     &&
                Parity_Error_RX_rx_dut[1] == 1'd0                   &&
                Stop_Error_RX_rx_dut  [1] == 1'd0                   &&
                data_valid_rx_dut     [1] == data_valid_expected[1]) ||
                (data_valid_rx_dut    [1] == 'b0 && data_valid_expected[1] == 'b0) )
            begin
                success_count = success_count + 1;
                $display("\t time: %11.3t ns: P_DATA_TX = %b ---> P_DATA_RX = %b     (Accepted)", $time/1000.0, p_data_expected[1], p_data_rx_dut[1]);
                $display("Test Case (%2d): Success...", test_case_counter);
            end
            else begin
                error_count = error_count + 1;
                $display("\t time: %11.3t ns:", $time/1000.0);
                $display("\t\t P_DATA_RX       = %08b  --->  But the expected P_DATA = %b",  p_data_rx_dut[1], p_data_expected[1]        );
                $display("\t\t Parity_Error_RX = %-8b  --->  But the expected 0"          ,  Parity_Error_RX_rx_dut[1]                   );
                $display("\t\t Stop_Error_RX   = %-8b  --->  But the expected 0"          ,  Stop_Error_RX_rx_dut[1]                     );
                $display("\t\t data_valid_RX   = %-8b  --->  But the expected %0b"        ,  data_valid_rx_dut[1], data_valid_expected[1]);
                $display("Test Case (%2d): Fail...   <<======================================  ERROR  ===================================>>", test_case_counter);
            end
        end
    endtask


    //__________________________________________________________________________________________________________
    //|                                                                                                         |
    //|              ---------------   *****      Stimulus Generation      *****   ---------------              |
    //|_________________________________________________________________________________________________________|
    integer prescale_count;
    initial begin
        $dumpfile("UART_RX_dump.vcd");
        $dumpvars();

        // Reset signals.
        reset();
        check_result();

        // Initialize.
        initialize();

        for(prescale_count = 0 ; prescale_count < 3 ; prescale_count = prescale_count + 1'b1) begin
            case (prescale_count%3)
                // ===============  When 'Prescale' = 8 =============== //
                0: set_oversampling(.samples_num(8));

                // ===============  When 'Prescale' = 16 =============== //
                1: set_oversampling(.samples_num(16));
                
                // ===============  When 'Prescale' = 32 =============== //
                2: set_oversampling(.samples_num(32));
            endcase

            repeat(30) begin
                // Even parity case:
                set_even_parity_mode();
                put_data(
                    .p_data_var    ('b0000_1111),
                    .data_valid_var('b1       )
                );
                check_result();

                
                // Test Odd Parity Case:
                set_odd_parity_mode();
                put_data(
                    .p_data_var    ('b1000_0001),
                    .data_valid_var('b1        )
                );
                check_result();
                

                // Test No-Parity Bit Case:
                set_no_parity_mode();
                put_data(
                    .p_data_var    ('b0011_0011),
                    .data_valid_var('b1        )
                );
                check_result();


                // Test Data Not Valid Case:
                set_odd_parity_mode();
                put_data(
                    .p_data_var    ('b1010_1010),
                    .data_valid_var('b0        )
                );
                check_result();

                // Test sending 2 adjacent frames
                put_data_sequence(
                    .p_data_var1    ('b1111_1111),
                    .data_valid_var1('b1        ),
                    .p_data_var2    ('b0011_1100),
                    .data_valid_var2('b1        )
                );
                check_result();
            end
            
        end
        
        $display("\n\n\t\t success count = %5d,  error count = %5d\n\n", success_count,  error_count);
        $stop;
    end
    
endmodule