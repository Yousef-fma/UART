// =============================================================================
// Module Name: UART_TX_tb2
// Description: A simple, educational testbench designed to demonstrate the
//              UART transmitter operation. It serializes two frames:
//              1. Parallel data 8'h0F (Parity enabled, Even parity)
//              2. Parallel data 8'h01 (Parity enabled, Even parity)
//              The second frame is requested while the first one is finishing
//              to demonstrate back-to-back transmission.
// =============================================================================

`timescale 1ns/10ps

module UART_TX_tb2;

    // --- Simulation Constants ---
    localparam DATA_WIDTH = 8;
    localparam CLK_PERIOD = 10; // 10ns clock period (100 MHz clock frequency)

    // --- Testbench Stimulus and Monitoring Signals ---
    reg [DATA_WIDTH-1 : 0] P_DATA       ; // External parallel input data bus
    reg                    Data_Valid   ; // Asserted to request a new transmission frame
    reg                    PAR_EN       ; // Parity enable signal
    reg                    PAR_TYP      ; // Parity type (0: even parity, 1: odd parity)
    reg                    CLK          ; // Clock signal
    reg                    RST          ; // Asynchronous active-low reset

    wire                   TX_OUT       ; // Serialized output stream
    wire                   Busy         ; // High during transmission
    wire                   last_bit_flag; // Debug flag for last frame bit

    // --- Symbolic State Decoding for Waveform Display ---
    typedef enum logic [2:0] {
        IDLE           = 3'b000,
        START_BIT      = 3'b001,
        DATA_TO_SERIAL = 3'b010,
        PARITY_BIT     = 3'b011,
        STOP_BIT       = 3'b100
    } state_e;

    state_e                 current_state; // Symbolic representation of the FSM state
    wire [DATA_WIDTH-1 : 0] P_DATA_reg   ; // Internal registered parallel data

    // --- DUT Instantiation ---
    UART_TX_top #(
        .DATA_WIDTH    (DATA_WIDTH),
        .SEND_MSB_FIRST(0         ) // Default: LSB first
    ) u_UART_TX_top (
        .P_DATA       (P_DATA       ),
        .Data_Valid   (Data_Valid   ),
        .PAR_EN       (PAR_EN       ),
        .PAR_TYP      (PAR_TYP      ),
        .CLK          (CLK          ),
        .RST          (RST          ),
        .TX_OUT       (TX_OUT       ),
        .Busy         (Busy         ),
        .last_bit_flag(last_bit_flag)
    );

    // --- Internal Signals Assignment for Waveform ---
    assign current_state = state_e'(u_UART_TX_top.FSM_inst.current_state);
    assign P_DATA_reg    = u_UART_TX_top.P_DATA_reg;

    // --- Clock Generation ---
    // Generates a continuous square wave with a period of 10 ns.
    always #(CLK_PERIOD / 2) CLK = ~CLK;

    // --- Stimulus Sequence ---
    initial begin
        // Initialize signals to default/unknown states
        CLK        = 1'b0;
        RST        = 1'b0;
        Data_Valid = 1'b0;
        PAR_EN     = 1'b0;
        PAR_TYP    = 1'b0;
        P_DATA     = 8'h00;

        // Hold reset for 1.5 clock cycles, then release it asynchronously
        #(CLK_PERIOD * 1.5);
        RST        = 1;

        // ---------------------------------------------------------------------
        // Frame 1: Transmission of 8'h0F (Even parity = 0)
        // ---------------------------------------------------------------------
        // Align with the rising edge and add a small delay to avoid race conditions.
        @(posedge CLK); #1;
        // OR use this instead: @(negedge CLK);

        P_DATA     = 8'h0F;
        PAR_EN     = 1'b1 ;  // Enable parity
        PAR_TYP    = 1'b0 ;  // 0: Even parity (Even parity of 8'h0F is 0)
        Data_Valid = 1'b1 ;  // Pulse Data_Valid high for one clock cycle

        // 1 clock cycle after asserting Data_Valid:
        // The UART transmitter registers the parallel data and transitions to START_BIT.
        @(posedge CLK); #1;
        // OR use this instead: @(negedge CLK);

        Data_Valid = 1'b0 ;
        PAR_EN     = 1'b0 ;
        P_DATA     = 8'h00; // UART shouldn't depend on P_DATA after registration

        // ---------------------------------------------------------------------
        // Frame 2: Back-to-Back Transmission of 8'h01 (Even parity = 1)
        // ---------------------------------------------------------------------
        // The first frame takes:
        // - START_BIT (1 clock cycle)
        // - DATA_TO_SERIAL (8 clock cycles)
        // - PARITY_BIT (1 clock cycle)
        // Total = 10 clock cycles from the first Data_Valid sampling edge to the start of STOP_BIT.
        // We wait for these 10 clock cycles to assert the second Data_Valid request during STOP_BIT.
        repeat(1+8+1) begin @(posedge CLK); #1; end
        // OR use this instead: repeat(10) @(negedge CLK);

        P_DATA     = 8'h01;
        PAR_EN     = 1'b1 ;
        PAR_TYP    = 1'b0 ;
        Data_Valid = 1'b1 ;

        // 1 clock cycle after asserting the second Data_Valid:
        // Since a new frame request is pending, the FSM transitions directly from STOP_BIT to START_BIT.
        @(posedge CLK); #1;
        Data_Valid = 1'b0 ;
        PAR_EN     = 1'b0 ;
        P_DATA     = 8'h00;

        // Wait for the second frame to finish:
        // - START_BIT (1 clock cycle)
        // - DATA_TO_SERIAL (8 clock cycles)
        // - PARITY_BIT (1 clock cycle)
        // - STOP_BIT (1 clock cycle)
        // Plus 2 clock cycles to transition to IDLE and settle.
        repeat(1+8+1+1+2) @(posedge CLK);

        // Stop the simulation
        $stop;
    end

endmodule
