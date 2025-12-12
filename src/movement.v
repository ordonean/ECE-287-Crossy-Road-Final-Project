/* // movement module for sprites... will get instatiated in cross_road.v and sprite 1 & 2's initial position will be stated in tp module 
// parameterized module header !!!


// Attempt #2 
/*module movement #(
    parameter START_X = 4,   // default offset to be overwritten in top module
    parameter START_Y = 4    // default offset to be overwritten in top module
)(
    input        clk,
    input        rst,        // active-low reset
    input        move_up,
    input        move_down,
    input        move_left,
    input        move_right,
	 input		  blocked, 
	 input 		  game_enable,
    output reg [3:0] player_x,
    output reg [3:0] player_y
);

    // Remember previous value of each move signal
    reg prev_move_up;
    reg prev_move_down;
    reg prev_move_left;
    reg prev_move_right;

    // One-clock pulses when key first becomes pressed
    wire up_pulse    =  move_up   & ~prev_move_up;
    wire down_pulse  =  move_down & ~prev_move_down;
    wire left_pulse  =  move_left & ~prev_move_left;
    wire right_pulse =  move_right& ~prev_move_right;

    always @(posedge clk or negedge rst) begin
        if (rst == 1'b0) begin
            // On reset, place player at starting position
            player_x       <= START_X;
            player_y       <= START_Y;

            // Clear history of movement keys
            prev_move_up    <= 1'b0;
            prev_move_down  <= 1'b0;
            prev_move_left  <= 1'b0;
            prev_move_right <= 1'b0;
        end 
		  else begin  
				// ---- UPDATE PREVIOUS STATE ----
				prev_move_up <= move_up; 
				prev_move_down <= move_down; 
				prev_move_left <= move_left; 
				prev_move_right <= move_right;  
				
				if(game_enable == 1 && blocked == 1'b0)
				begin
					// ---- POSITION UPDATES ----
					// Each pulse = move exactly 1 grid cell,
					// respecting the 16x12 grid (x: 0–15, y: 0–11)

					// sprite moving up
					if (up_pulse && player_y > 0)
						 player_y <= player_y - 1;

					// sprite moving down
					if (down_pulse && player_y < 4'd11)
						 player_y <= player_y + 1;

					// sprite moving left
					if (left_pulse && player_x > 0)
						 player_x <= player_x - 1;

					// sprite moving right
					if (right_pulse && player_x < 4'd15)
						 player_x <= player_x + 1;

					// ---- UPDATE PREVIOUS STATE ----
					// These assignments happen after the pulses are computed
					//prev_move_up    <= move_up;
					//prev_move_down  <= move_down;
					//prev_move_left  <= move_left;
					//prev_move_right <= move_right;
				end 
		  end
    end

endmodule


*/






/*



// Attempt #3
module movement #(parameter START_X = 4'd7,
						parameter START_Y = 4'd11
) (
    input        CLOCK_50,
    input        rst,        							// active-low reset
	 input		  reset_active, 						// if reset_active = 1, KEY[3]'s reset function has been deactivated and movement can now happen 
	 input 		  player_en, 							// select signal that activates FSM
	 input		  [3:0]KEY,   							// movement logic for the sprites 
	 input 		  [3:0]current_x, 
	 input 		  [3:0]current_y, 
	 //input		  [3:0]grid_y,							
	 // movement commands sent to top module 
	 output		  reg move_up, 
	 output		  reg move_down, 
	 output 	  	  reg move_left, 
	 output 		  reg move_right,
	 output 		  reg reached_top); 					// = 1 @ EXIT, signalling the sprite is at y = 0 / reached the top of the screen

	 
reg[2:0]S; 						
reg[2:0]NS; 

parameter START = 3'd0, 
			 PLAYER_IDLE = 3'd1, 
			 HEIGHT_COND = 3'd2,
			 MOVEMENT = 3'd3, 
			 EXIT = 3'd4, 
			 ERROR = 3'd7; 
			 
// 1st always block 
always @ (posedge CLOCK_50 or negedge rst)
	begin 
	if(rst == 1'b0)
		S <= START; 
	else 
		S <= NS; 
	end 
		
// 2nd always block 
always @ (*)
begin 
	case(S)
		START: 
			begin 
				if(reset_active == 1 && player_en == 1)
					NS <= PLAYER_IDLE; 
				else 
					NS <= START; 
			end 
		PLAYER_IDLE:
			begin 
				NS <= HEIGHT_COND; 
			end 
		HEIGHT_COND: 
			begin 
				if(current_y > 0)
					NS <= MOVEMENT; 
				else 
					NS <= EXIT; 
			end 
		MOVEMENT: 
			begin 
				NS <= PLAYER_IDLE; 
			end 
		EXIT: 
			begin 
				NS <= START; 
			end 
		default: 
			begin 
			NS <= START; 
			end 
	endcase 
end 

// 3rd always block 
always @ (posedge CLOCK_50 or negedge rst)
begin 
	if(rst == 1'b0)
	begin 
		move_up <= 0; 
		move_down <= 0; 
		move_left <= 0; 
		move_right <= 0; 
		reached_top <= 0; 
	end
	else 
	begin 
		move_up <= 0; 
		move_down <= 0; 
		move_left <= 0; 
		move_right <= 0; 
		reached_top <= 0; 
		case(S)
			MOVEMENT: 
			begin
				if(KEY[3] == 0)
					move_left <= 1;  
				if(KEY[2] == 0)
					move_up <= 1;  
				if(KEY[1] == 0)
					move_down <= 1; 
				if(KEY[0] == 0)
					move_right <= 1;  
			end	
			EXIT: 
			begin
				reached_top <= 1; 
			end
		
		endcase 
	end 
end 	


endmodule 


				
			
			  
	 
	 
*/	 
	 
	 
	 
	 
	 
	 
	 
	 
	 
	 
	 
	 
	 
	 
	 
	 
	 
	 
	 
	 
	 
	 
	 
	 
	 
	 
	 
	 
	 
	 
	 

