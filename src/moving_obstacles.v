// this module deals with all moving obstacles (i.e. cars, trains, moving railroad crossing, etc)

 // This module is for moving obstacles (e.g., a train)
// It tells you if a given grid cell (blocked_x, blocked_y) is currently
// occupied by a moving obstacle.

module moving_obstacles #(
    parameter GRID_WIDTH   = 16,  // columns
    parameter GRID_HEIGHT  = 12,  // rows
    parameter TRAIN_ROW    = 4'd6, // which row (y) the train lives on
    parameter TRAIN_LENGTH = 4'd3, // how many tiles long the train is
    parameter integer TRAIN_DIV = 25_000_000 // speed divider for train movement
)(
    input        clk,
    input        rst,
    input  [3:0] blocked_x,
    input  [3:0] blocked_y,

    output reg   is_moving_obstacle,      // 1 if this cell is currently occupied by the train
    output [3:0] train_head_x_out        // optional: expose train head for VGA drawing if you want
);

    // train head X position (left-most tile of train)
    reg [3:0] train_head_x;

    // simple divider for train movement
    reg [31:0] train_counter;

    // expose for outside world (e.g., VGA)
    assign train_head_x_out = train_head_x;

    // -------------------------
    // Train movement (state)
    // -------------------------
    always @(posedge clk or negedge rst) begin
        if (rst == 1'b0) begin
            train_counter <= 32'd0;
            train_head_x  <= 4'd0; // start at left edge
        end
        else begin
            if (train_counter == TRAIN_DIV - 1) begin
                train_counter <= 32'd0;

                // move train right, wrap before falling off the edge
                if (train_head_x >= (GRID_WIDTH[3:0] - TRAIN_LENGTH[3:0]))
                    train_head_x <= 4'd0;
                else
                    train_head_x <= train_head_x + 4'd1;
            end
            else begin
                train_counter <= train_counter + 32'd1;
            end
        end
    end

    // -------------------------
    // Collision check
    // -------------------------
    always @(*) begin
        is_moving_obstacle = 1'b0;

        // only care about the train row
        if (blocked_y == TRAIN_ROW) begin
            // train occupies [train_head_x .. train_head_x + TRAIN_LENGTH - 1]
            if (blocked_x >= train_head_x &&
                blocked_x <  (train_head_x + TRAIN_LENGTH))
                is_moving_obstacle = 1'b1;
        end
    end

endmodule
