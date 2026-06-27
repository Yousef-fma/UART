module UART_TX_FSM #(
    parameter IDLE_SELECTION           = 2'b00, // The IDLE state number in the UART_TX_MUX module.
    parameter START_BIT_SELECTION      = 2'b01, // The START BIT state number in the UART_TX_MUX module.
    parameter DATA_TO_SERIAL_SELECTION = 2'b10, // The SERIAL DATA state number in the UART_TX_MUX module.
    parameter PARITY_BIT_SELECTION     = 2'b11  // The PARITY BIT state number in the UART_TX_MUX module.
) (
    input  wire       Data_Valid, // To start the the new frame if the current state was IDLE or STOP_BIT.
    input  wire       PAR_EN,     // To recognize if there will be a sent parity bit or not.
    input  wire       ser_done,   // To recognize if the serializer block finished processing the parallel data to serial or not. (0: is not finished, 1: finished)
    input  wire       CLK,        // Clock signal.
    input  wire       RST,        // Active Low Asynchronous reset signal.
    output reg        ser_en,     // To enable the serializer block to start processing the parallel data to serial or not. (0: is disabled, 1: is enabled)
    output reg  [1:0] mux_sel,    // To control the UART_TXs_MUX selection. (Tell MUX which frame bit will get out (start bit, serial bits, parity bit, or stop bit))
    output reg        Busy,       // Is high as long as the current frame didn't finish.
    output wire       last_bit_flag // To know if the current state is in the LAST BIT of the frame. We need this signal in 'UART_TX_P_DATA_REG' module
);

    localparam IDLE           = 3'b000; // IDLE state.
    localparam START_BIT      = 3'b001; // start bit of the frame.
    localparam DATA_TO_SERIAL = 3'b010; // serial data (from serializer block) of the frame.
    localparam PARITY_BIT     = 3'b011; // parity bit of the frame.
    localparam STOP_BIT       = 3'b100; // stop bit of the frame. (I need it to set the 'Busy' port high at this clock cycle)

    reg [2:0] current_state, next_state;

    // Get the flag of if the sent bit of the frame is the last frame bit or not. 
    assign last_bit_flag = (current_state == STOP_BIT);

    // output. (Current State)
    always @(posedge CLK, negedge RST)
    begin
        // Reset the registers
        if(~RST) 
            begin
                current_state <= IDLE;
            end
        else 
            begin
                current_state <= next_state;
            end
    end

    // Next state. (State Transition)
    always @(*)
        begin
            case(current_state)
                // IDLE state.
                IDLE:   begin
                        if(Data_Valid)
                            begin
                                next_state = START_BIT;
                            end
                        else
                            begin
                                next_state = current_state;
                            end
                    end
                
                // Send the start bit of the frame.
                START_BIT:  begin
                        next_state = DATA_TO_SERIAL;
                    end

                // Send the serial data bits of the frame.
                DATA_TO_SERIAL: begin
                        if(~ser_done)
                            begin
                                next_state = current_state;
                            end
                        else if(PAR_EN)
                            begin
                                next_state = PARITY_BIT;
                            end
                        else
                            begin
                                next_state = STOP_BIT;
                            end
                    end
                
                // Send the parity bit of the frame.
                PARITY_BIT: begin
                        next_state = STOP_BIT;
                    end

                // Send the stop bit of the frame.
                STOP_BIT: begin
                        if(Data_Valid)
                            begin
                                next_state = START_BIT;
                            end
                        else
                            begin
                                next_state = IDLE;
                            end
                    end

                // To clear my conscience.
                default: begin
                        next_state = IDLE;
                    end
            endcase         
        end

        
    // The Moore result.
    always @(*)
        begin
            case(current_state)
                // IDLE state.
                IDLE:   begin
                        ser_en  = 1'b0;
                        mux_sel = IDLE_SELECTION;
                        Busy    = 0;
                    end

                // Send the start bit of the frame.
                START_BIT:  begin
                        ser_en  = 1'b0;
                        mux_sel = START_BIT_SELECTION;
                        Busy    = 1;
                    end

                // Send the serial data bits of the frame.
                DATA_TO_SERIAL: begin
                        ser_en  = 1'b1;
                        mux_sel = DATA_TO_SERIAL_SELECTION;
                        Busy    = 1;
                    end

                // Send the parity bit of the frame.
                PARITY_BIT: begin
                        ser_en  = 1'b0;
                        mux_sel = PARITY_BIT_SELECTION;
                        Busy    = 1;
                    end
                    
                // Send the stop bit of the frame.
                STOP_BIT: begin
                        ser_en  = 1'b0;
                        mux_sel = IDLE_SELECTION;
                        Busy    = 1;
                    end

                // To clear my conscience
                default: begin
                        ser_en  = 1'b0;
                        mux_sel = IDLE_SELECTION; // The 'IDLE_SELECTION' is equivalent to "STOP_SELECTION", so there is no "STOP_SELECTION", just 'IDLE_SELECTION'
                        Busy    = 0;
                    end
            endcase         
        end
        
endmodule