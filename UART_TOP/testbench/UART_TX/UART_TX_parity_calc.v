
module UART_TX_parity_calc #(
    parameter DATA_WIDTH = 8
) (
    input  wire [DATA_WIDTH-1 : 0] P_DATA_reg,  // The registered parallel input data bus.
    input  wire                    PAR_TYP_reg, // To determine the parity type. (0: even parity, 1: odd parity)
    output wire                    par_bit      // The final result of the parity bit signal calculation. 
);

    assign par_bit = (PAR_TYP_reg == 0)? ^P_DATA_reg : ~^P_DATA_reg; // For even parity or odd parity. (0: even parity,  1: odd parity).
endmodule