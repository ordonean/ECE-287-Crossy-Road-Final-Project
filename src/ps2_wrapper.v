module ps2_wrapper (
    input        clk,
    input        rst_n,
    input  [15:0] hexo,        // from ps2 core
    output reg [7:0] scan_code,
    output reg       scan_ready
);

    reg [15:0] prev_hexo;
	 
	 wire in_changed;
	 wire in_stable;

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            prev_hexo   <= 16'd0;
            scan_code   <= 8'd0;
            scan_ready  <= 1'b0;
        end else begin
            // default: no new code
            scan_ready <= 1'b0;

            if (hexo != prev_hexo) begin
                prev_hexo  <= hexo;
                scan_code  <= hexo[7:0];   // use low byte of sequence
                scan_ready <= 1'b1;        // pulse for one cycle
            end
        end
    end

endmodule
