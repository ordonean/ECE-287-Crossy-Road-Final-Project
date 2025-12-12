
/*
// this file is meant to recieve and process what the keys pressed mean, and then send to movement.v to move the sprite(s). 
// this is the next step after ps2_controller. 
// Flow: ps2_data_in --> ps2_controller --> keyboard???


//notes from GitHub:
// PULSE_OR_HOLD set high = operation on pulse mode (output for each is only one clock cycle when the key is pressed).

// Note: this only works when one button is held at a time, does not operate witht wo being held together

// note - uses hexidecimals!! .... Keyboard Scan Code Set 2

// note - uses both make and break code..  


// Decodes PS/2 scan codes into movement pulses for 2 players.
//  - Sprite 1 uses WASD
//  - Sprite 2 uses arrow keys
// Uses PS/2 Set 2 scan codes.

module keyboard (
    input  clk,
    input  rst,           // ACTIVE-LOW reset
    input  [7:0] scan_code,
    input  scan_ready,
    input  game_enable,

    // Sprite 1 = WASD
    output reg move_up_p1,
    output reg move_down_p1,
    output reg move_left_p1,
    output reg move_right_p1,

    // Sprite 2 = arrows
    output reg move_up_p2,
    output reg move_down_p2,
    output reg move_left_p2,
    output reg move_right_p2
);

    // PS2 Break Code
    localparam BREAK_CODE = 8'hF0;

    // Scan codes for WASD & arrow keys
    localparam SCAN_W     = 8'h3A;
		localparam SCAN_A     = 8'h38;
		localparam SCAN_S     = 8'h36;
		localparam SCAN_D     = 8'h86;   // from your measurement


    localparam SCAN_UP    = 8'hEA;
		localparam SCAN_DOWN  = 8'hE4;
		localparam SCAN_LEFT  = 8'hD6;
		localparam SCAN_RIGHT = 8'hE8;


    reg break_active; // 1 if previous code was BREAK_CODE

    always @(posedge clk or negedge rst) begin
        if (rst == 1'b0) begin
            break_active  <= 1'b0;

            // Sprite 1
            move_up_p1    <= 1'b0;
            move_down_p1  <= 1'b0;
            move_left_p1  <= 1'b0;
            move_right_p1 <= 1'b0;

            // Sprite 2
            move_up_p2    <= 1'b0;
            move_down_p2  <= 1'b0;
            move_left_p2  <= 1'b0;
            move_right_p2 <= 1'b0;
        end
        else begin
            if (scan_ready) begin
                if (scan_code == BREAK_CODE) begin
                    // Next scan code is a "key released"
                    break_active <= 1'b1;
                end
                else begin
                    if (!break_active && game_enable) begin
                        // Key pressed (MAKE)
                        case (scan_code)
                            // WASD (Player 1)
                            SCAN_W: move_up_p1    <= 1'b1;
                            SCAN_A: move_left_p1  <= 1'b1;
                            SCAN_S: move_down_p1  <= 1'b1;
                            SCAN_D: move_right_p1 <= 1'b1;

                            // Arrow keys (Player 2)
                            SCAN_UP:    move_up_p2    <= 1'b1;
                            SCAN_DOWN:  move_down_p2  <= 1'b1;
                            SCAN_LEFT:  move_left_p2  <= 1'b1;
                            SCAN_RIGHT: move_right_p2 <= 1'b1;
                        endcase
                    end
                    else begin
                        // Key released (BREAK)
                        case (scan_code)
                            // WASD (Player 1)
                            SCAN_W: move_up_p1    <= 1'b0;
                            SCAN_A: move_left_p1  <= 1'b0;
                            SCAN_S: move_down_p1  <= 1'b0;
                            SCAN_D: move_right_p1 <= 1'b0;

                            // Arrow keys (Player 2)
                            SCAN_UP:    move_up_p2    <= 1'b0;
                            SCAN_DOWN:  move_down_p2  <= 1'b0;
                            SCAN_LEFT:  move_left_p2  <= 1'b0;
                            SCAN_RIGHT: move_right_p2 <= 1'b0;
                        endcase
                    end

                    // Done handling this code; clear BREAK flag
                    break_active <= 1'b0;
                end
            end
        end
    end

endmodule
*/