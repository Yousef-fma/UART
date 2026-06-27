
module UART_TX_serializer #(
    parameter [31:0] DATA_WIDTH     = 8,  // To determine the parallel input data bus width on the port 'P_DATA'.
    parameter SEND_MSB_FIRST = 0   // To choose if the serial date start from MSB or LSB (1: to start with MSB,  0 or any other number: to start with LSB)
) (
    input  wire [DATA_WIDTH-1 : 0] P_DATA_reg,    // The registered parallel input data bus.
    input  wire                    ser_en,        // The signal to start converting the parallel data to serial and sending the serial data.
    input  wire                    CLK,           // Clock signal.
    input  wire                    RST,           // Reset signal.
    output wire                    ser_done,      // To tell the UART_FSM module that the serialization has completed.
    output reg                     ser_data       // The signal that carry the serial data.
);

    /////////////////////////////
    // Find the counter width. //
    /////////////////////////////
    // function integer counter_width(
    //     input integer max_number
    // );
    //     integer bit_num          ; // To represent the bit number that have 1 (Ex: 5'b01000 --> bit_num = 3)
    //     integer two_power_bit_num; // To represent 2 power 'bit_num' (Ex: bit_num = 3 --> two_power_bit_num = 2^(3) = 8)
    //     begin
    //         bit_num           = 0;
    //         two_power_bit_num = 1;

    //         // Stay in this loop until 'bit_num' = number of bits can store 'max_number'
    //         while (two_power_bit_num <= max_number) 
    //             begin
    //                 two_power_bit_num = 1 << bit_num;  // 2^bit_num --> 2^(0) --> 2^(1) --> 2^(2) --> 2^(3) ...
    //                 bit_num = bit_num + 1;
    //             end

    //         counter_width = bit_num-1;
    //     end
    // endfunction

    // Initialize the 'counter'.
    // The counter count from 7(by default) down to 0 so, the max_number = 7(by default);
    reg [$clog2(DATA_WIDTH-1)-1 : 0] counter;

    ///////////////////////////
    // Counter always block. //
    ///////////////////////////
    generate
        if(SEND_MSB_FIRST == 1) begin : genblk_to_send_MSB_at_first
            always @(posedge CLK or negedge RST)
                begin
                    if(!RST)
                        begin
                            counter  <= DATA_WIDTH-1;
                        end
                    else if(ser_en && counter > 0) 
                        begin
                            counter  <= counter - 'd1;
                        end
                    else
                        begin
                            counter <= DATA_WIDTH-1;
                        end
                end
        end
        else begin : genblk_to_send_LSB_at_first
            always @(posedge CLK or negedge RST)
                begin
                    if(!RST)
                        begin
                            counter  <= 'd0;
                        end
                    else if(ser_en && counter < DATA_WIDTH-1) 
                        begin
                            counter  <= counter + 'd1;
                        end
                    else
                        begin
                            counter <= 'd0;
                        end
                end
        end
    endgenerate

    /////////////////////////////////////////////////////////
    // check if the serial data is transmitted completely. //
    /////////////////////////////////////////////////////////
    generate
        if (SEND_MSB_FIRST == 1) begin : gen_msb_done
            // Correct for MSB-first (counting down to 0)
            assign ser_done = (counter == 'd0);
        end
        else begin : gen_lsb_done
            // Correct for LSB-first (counting up to DATA_WIDTH-1)
            assign ser_done = (counter == DATA_WIDTH-1);
        end
    endgenerate

    ////////////////////////////////
    // Serial data always block.  //
    ////////////////////////////////
    always @(*)
        begin
            ser_data = P_DATA_reg[counter];
        end
endmodule