////////////////////////////////////////////////////////////////////////////////////////////////////
/*
Implements a linear feedback shift register for pseudo-random generation.
This module is used to introduce 'randomness' into obstacle behavior that we use with the cars in the top module
*/
////////////////////////////////////////////////////////////////////////////////////////////////////


module lfsr(
    input  clk,
    input  rst,
    output reg [7:0] rnd
);
    wire feedback = rnd[7] ^ rnd[5] ^ rnd[4] ^ rnd[3];  // taps

    always @(posedge clk or negedge rst) begin
        if (rst == 1'b0)
            rnd <= 8'hA5;       // non-zero random seed
        else
            rnd <= {rnd[6:0], feedback};
    end

endmodule

