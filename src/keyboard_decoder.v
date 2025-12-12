module keyboard_decoder (
    input        clk,
    input        rst_n,           // active-low reset
    input  [7:0] scan_code,
    input        scan_ready,

    output reg move_up_p1,
    output reg move_down_p1,
    output reg move_left_p1,
    output reg move_right_p1,

    output reg move_up_p2,
    output reg move_down_p2,
    output reg move_left_p2,
    output reg move_right_p2
);

    localparam SCAN_W   = 8'h1D;
    localparam SCAN_A   = 8'h1C;
    localparam SCAN_S   = 8'h1B;
    localparam SCAN_D   = 8'h23;

    localparam SCAN_UP  = 8'h75;
    localparam SCAN_DN  = 8'h72;
    localparam SCAN_L   = 8'h6B;
    localparam SCAN_R   = 8'h74;

    always @(posedge clk or negedge rst_n) begin
        if (rst_n == 1'b0) begin                      // reset when rst_n = 0
            move_up_p1    <= 0;
            move_down_p1  <= 0;
            move_left_p1  <= 0;
            move_right_p1 <= 0;
            move_up_p2    <= 0;
            move_down_p2  <= 0;
            move_left_p2  <= 0;
            move_right_p2 <= 0;
        end else begin
            // default: no movement unless a new key says so
            move_up_p1    <= 0;
            move_down_p1  <= 0;
            move_left_p1  <= 0;
            move_right_p1 <= 0;
            move_up_p2    <= 0;
            move_down_p2  <= 0;
            move_left_p2  <= 0;
            move_right_p2 <= 0;

            if (scan_ready) begin
                case (scan_code)
                    SCAN_W:  move_up_p1    <= 1;
                    SCAN_S:  move_down_p1  <= 1;
                    SCAN_A:  move_left_p1  <= 1;
                    SCAN_D:  move_right_p1 <= 1;

                    SCAN_UP: move_up_p2    <= 1;
                    SCAN_DN: move_down_p2  <= 1;
                    SCAN_L:  move_left_p2  <= 1;
                    SCAN_R:  move_right_p2 <= 1;

                    default: ;  // no movement for other codes
                endcase
            end
        end
    end
endmodule

