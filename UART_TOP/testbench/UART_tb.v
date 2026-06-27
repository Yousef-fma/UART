
`timescale 1ns/1ps
module UART_tb();
    localparam DATA_WIDTH        = 8; // The bits number of the sent data word in each frame
    localparam SEND_MSB_FIRST    = 0; // To send the MSB of the data word first or the LSB first. (1: To send the MSB first, 0 or any other number: To send the LSB first).
    localparam RECEIVE_MSB_FIRST = 0; // To deal with the frame that has serial data that starts with MSB or LSB.(assign 1: if receive MSB at first, 0 or any other number: if receive LSB at first).
    localparam TX_CLK_PERIOD     = 8680.555; // TX_CLK Frequency = 115.2 KHz  ==>  TX_CLK Period = 8680.555 ns
    // Input Ports
    reg                     PAR_TYP ; // Parity Type (1: Odd, 0: Even)
    reg                     PAR_EN  ; // Parity_Enable (1: Enable, 0: Disable)
    reg  [5 : 0]            Prescale; // Oversampling Prescale
    reg  [DATA_WIDTH-1 : 0] TX_IN_P ; // Input TX data word (= 1 byte by default)
    reg                     TX_IN_V ; // Input TX data valid signal
    wire                    RX_IN_S ; // Input RX UART frame
    reg                     TX_CLK  ; // UART TX Clock Signal
    reg                     RX_CLK  ; // UART RX Clock Signal
    reg                     RST     ; // Synchronized reset signal

    // Output Ports
    wire                    TX_OUT_S; // TX Frame Serial Out
    wire                    TX_OUT_V; // TX Out Valid signal
    wire [DATA_WIDTH-1 : 0] RX_OUT_P; // RX Out Data  (= 1 byte by default)
    wire                    RX_OUT_V; // RX Out Data Valid signal

    integer                testcase_count ; // To count the test cases.
    integer                counter        ; // To loop on all Prescale values. 
    integer                error_count    ; // To count the occurred error times.
    integer                success_count  ; // To count the occurred success times.
    reg                    tx_out_v_error ; // To check if there was an unexpected value of 'TX_OUT_V' signal.
    reg [DATA_WIDTH-1 : 0] rx_out_p_result; // To store the result of 'RX_OUT_V' at the moment after RX_OUT_V = 1 directly.
    
    //////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
    //     _________________________________________________________________________________________________________    //
    //   /_________________________________________________________________________________________________________/|   //
    //  |                                                                                                         | |   //
    //  |              ---------------   *****    UART DUT Instantiation     *****   ---------------              | |   //
    //  |_________________________________________________________________________________________________________|/    //
    //                                                                                                                  //
    //////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
    UART #(
        .DATA_WIDTH       (DATA_WIDTH       ), // The bits number of the sent data word in each frame
        .SEND_MSB_FIRST   (SEND_MSB_FIRST   ), // To send the MSB of the data word first or the LSB first. (1: To send the MSB first, 0 or any other number: To send the LSB first).
        .RECEIVE_MSB_FIRST(RECEIVE_MSB_FIRST)  // To deal with the frame that has serial data that starts with MSB or LSB.(assign 1: if receive MSB at first, 0 or any other number: if receive LSB at first).
    ) UART_1 (
        // Input Ports
        .PAR_TYP (PAR_TYP ), // Parity Type (1: Odd, 0: Even)
        .PAR_EN  (PAR_EN  ), // Parity_Enable (1: Enable, 0: Disable)
        .Prescale(Prescale), // Oversampling Prescale
        .TX_IN_P (TX_IN_P ), // Input TX data word (= 1 byte by default)
        .TX_IN_V (TX_IN_V ), // Input TX data valid signal
        .RX_IN_S (RX_IN_S ), // Input RX UART frame
        .TX_CLK  (TX_CLK  ), // UART TX Clock Signal
        .RX_CLK  (RX_CLK  ), // UART RX Clock Signal
        .RST     (RST     ), // Synchronized reset signal

        // Output Ports
        .TX_OUT_S(TX_OUT_S), // TX Frame Serial Out
        .TX_OUT_V(TX_OUT_V), // TX Out Valid signal
        .RX_OUT_P(RX_OUT_P), // RX Out Data  (= 1 byte by default)
        .RX_OUT_V(RX_OUT_V), // RX Out Data Valid signal
        .Parity_Error (), // Parity Error Signal.
        .Stop_Error   (), // Stop Error Signal.
        .last_bit_flag() // Last Bit (of the frame) Flag Signal.
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
        TX_CLK = 0;
        forever begin
            #(TX_CLK_PERIOD / 2.0) TX_CLK = ~TX_CLK;
        end
    end
    
    //        ========================   UART-RX Clock   ========================
    initial begin
        RX_CLK = 0;
        forever begin
            #1;
            case (Prescale)
                32: #(((TX_CLK_PERIOD/32.0) / 2.0) - 1) RX_CLK = ~RX_CLK;
                16: #(((TX_CLK_PERIOD/16.0) / 2.0) - 1) RX_CLK = ~RX_CLK;
                8 : #(((TX_CLK_PERIOD/8.0)  / 2.0) - 1) RX_CLK = ~RX_CLK;
                4 : #(((TX_CLK_PERIOD/4.0)  / 2.0) - 1) RX_CLK = ~RX_CLK;
            endcase
        end
    end




    //   _________________________________________________________________________________________________________
    //  |                                                                                                         |
    //  |              ---------------   *****          Test Cases           *****   ---------------              |
    //  |_________________________________________________________________________________________________________|

    // Test cases idea:
    //      1) Connect the output 'TX_OUT_S' with the input 'RX_IN_S'
    //      2) Send any number from the bus 'TX_IN_P' and  wait till 'RX_OUT_V' = 1 
    //      3) Compare the received data with the sent data.
    initial begin

        reset();
        initialize();

        for(counter = 0 ; counter < 4 ; counter = counter + 1) begin
            // Change the prescale by every loop. Don't set the prescale increments in ascending order or decrements in de-ascending order
            case (counter)
                0: set_prescale(32);
                1: set_prescale(4);
                2: set_prescale(16);
                3: set_prescale(8);
            endcase
            reset();
            send_dummy_bits(5);

            repeat(1000)begin
                // Test Case 1:
                set_parity(1, 1); // parity_enable = 1, parity_type = 1 (1: Odd, 0: Even).
                send_data(25);
                check_result();

                // Test Case 2:
                set_parity(1, 0); // parity_enable = 1, parity_type = 0 (1: Odd, 0: Even).
                //send_dummy_bits(1);
                send_data(30);
                check_result();

                // Test Case 3:
                set_parity(0, 0); // parity_enable = 0, parity_type = 0 (1: Odd, 0: Even).
                send_data(255);
                check_result();

                // Test Case 4:
                set_parity(0, 1); // parity_enable = 0, parity_type = 1 (1: Odd, 0: Even).
                send_data(0);
                check_result();
                
                // Test Case 5:
                set_parity(1, 1); // parity_enable = 1, parity_type = 1 (1: Odd, 0: Even).
                send_data(100);
                check_result();
                
                // Test Case 6:
                set_parity(1, 1); // parity_enable = 1, parity_type = 1 (1: Odd, 0: Even).
                send_data(6);
                check_result();
            end
        end

        $display("\t\t The error count = %0d,  The success count = %0d\n", error_count, success_count);        
        $stop;
    end


    //   _________________________________________________________________________________________________________
    //  |                                                                                                         |
    //  |              ---------------   *****          Reset Task           *****   ---------------              |
    //  |_________________________________________________________________________________________________________|

    task reset();
        begin
            PAR_TYP = 0;
            PAR_EN  = 0;
            TX_IN_P = 0;
            TX_IN_V = 0;
            RST     = 0;

            #1;
            RST     = 1;
            #1step;
        end
    endtask
    

    //   _________________________________________________________________________________________________________
    //  |                                                                                                         |
    //  |              ---------------   *****        Initialize Task        *****   ---------------              |
    //  |_________________________________________________________________________________________________________|

    task initialize();
        begin
            PAR_TYP         = 0;
            PAR_EN          = 0;
            Prescale        = 32;
            TX_IN_P         = 0;
            TX_IN_V         = 0;
            testcase_count  = 1;
            rx_out_p_result = 0;
            tx_out_v_error  = 0;
            error_count     = 0;
            success_count   = 0;
            #1step;
        end
    endtask
    

    //   _________________________________________________________________________________________________________
    //  |                                                                                                         |
    //  |              ---------------   *****        send_data Task         *****   ---------------              |
    //  |_________________________________________________________________________________________________________|

    assign RX_IN_S = TX_OUT_S; // To update the next input value of UART-RX

    task send_data(input reg [DATA_WIDTH-1:0] num);
        integer i;
        integer frame_width;
        begin : send_data_task
            TX_IN_P = num;
            TX_IN_V = 1;
            tx_out_v_error = 0;

            // frame width = (the transition from the previous state (This bit wastes 1 clock)) + (start bit) + (DATA_WIDTH) + (parity bit) + (end bit)
            frame_width = (PAR_EN)? (1 + 1 + DATA_WIDTH + 1 + 1) : (1 + 1 + DATA_WIDTH + 0 + 1);

            // Wait 10 or 11 clock of TX_CLK to send the frame.
            // After 1st clock of TX_CLK deactivate 'TX_IN_V'.
            @(posedge TX_CLK); #1step;
            TX_IN_V = 0;

            // (clk_num < ((frame_width-1) + 0.5)*Prescale*2.0) 
            // Then complete the whole frame_width clocks.
            for(i=0 ; (TX_OUT_V == 1) ; i = i + 1'd1) begin  
                
                // Check if the 'TX_OUT_V' has unexpected value. It should = 1.
                if(TX_OUT_V == 0) begin
                    tx_out_v_error = 1;
                    $display("Error @ time = %0t, tx_out_v_error = 1 (TX_OUT_V = %0d = 0)", $time, TX_OUT_V);
                end

                // Store the valid value of RX_OUT_P
                if(RX_OUT_V) begin
                    rx_out_p_result = RX_OUT_P;
                end

                case(Prescale)
                    4:  #((TX_CLK_PERIOD/4.0 )/2.0);
                    8:  #((TX_CLK_PERIOD/8.0 )/2.0);
                    16: #((TX_CLK_PERIOD/16.0)/2.0);
                    32: #((TX_CLK_PERIOD/32.0)/2.0);
                endcase
            end 

            for(i=0 ; i<(Prescale)+2 ; i = i+1) begin

                // Store the valid value of RX_OUT_P
                if(RX_OUT_V) begin
                    rx_out_p_result = RX_OUT_P;
                end

                case(Prescale)
                    4:  #((TX_CLK_PERIOD/4.0 ) /2.0);
                    8:  #((TX_CLK_PERIOD/8.0 ) /2.0);
                    16: #((TX_CLK_PERIOD/16.0) /2.0);
                    32: #((TX_CLK_PERIOD/32.0) /2.0);
                endcase
            end
        end
    endtask



    //   _________________________________________________________________________________________________________
    //  |                                                                                                         |
    //  |              ---------------   *****     send_dummy_bits Task      *****   ---------------              |
    //  |_________________________________________________________________________________________________________|
    reg tx_out_v_error2;
    task send_dummy_bits(input integer bits_count);
        integer i;
        begin
            TX_IN_V = 0;

            // Wait 10 clocks of TX_CLK period. Note (10) of TX_CLK = (10*Prescale) of RX_CLK.
            for(i = 0 ; i < bits_count ; i = i + 1) begin
                #(TX_CLK_PERIOD);
            end
        end
    endtask


    //   _________________________________________________________________________________________________________
    //  |                                                                                                         |
    //  |              ---------------   *****      set_prescale Task        *****   ---------------              |
    //  |_________________________________________________________________________________________________________|
   task set_prescale(input integer value);
        begin
            Prescale = value;
            $display("    ___________________ (Prescale is set to %d) ___________________", Prescale);
        end
    endtask


    //   _________________________________________________________________________________________________________
    //  |                                                                                                         |
    //  |              ---------------   *****      set_prescale Task        *****   ---------------              |
    //  |_________________________________________________________________________________________________________|
    task set_parity (input reg parity_enable, parity_type);
        begin
            PAR_EN  = parity_enable;
            PAR_TYP = parity_type;
        end
    endtask


    //   _________________________________________________________________________________________________________
    //  |                                                                                                         |
    //  |              ---------------   *****      check_result Task        *****   ---------------              |
    //  |_________________________________________________________________________________________________________|

    task check_result();
        begin
            if(rx_out_p_result != TX_IN_P || tx_out_v_error) begin
                error_count = error_count + 1;
                $display("[Time=%0t] Test Case (%3d): ERROR number %3d:   TX_IN_P = %3d  while  RX_OUT_P (or rx_out_p_result) = %3d", ($time/1000),  testcase_count, error_count, TX_IN_P,  rx_out_p_result);
            end
            else begin
                success_count = success_count + 1;
                $display("[Time=%0t] Test Case (%3d): Success: TX_IN_P = RX_OUT_V = %3d", ($time/1000), testcase_count, rx_out_p_result);
            end

            
            testcase_count = testcase_count + 1;
        end
    endtask

endmodule