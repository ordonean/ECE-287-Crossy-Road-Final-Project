////////////////////////////////////////////////////////////////////////////////////////////////////
/*

TOP-level module that integrates the entire game system.
Wires together VGA output, PS2 keyboard input, game logic, obstacles, and debugging outputs.
It manages global clock/reset, player state, and connects all submodules.
It also implements our logic for movements, instead of having a separate movement module.

*/
////////////////////////////////////////////////////////////////////////////////////////////////////


module crossy_road(
    input        CLOCK_50, 
    input  [9:0] SW,
    input  [3:0] KEY,
    // bi-Directionals 
    inout        PS2_CLK, 
    inout        PS2_DAT, 
    // VGA
    output [7:0] VGA_R, 
    output [7:0] VGA_G, 
    output [7:0] VGA_B, 
    output       VGA_HS, 
    output       VGA_VS, 
    output       VGA_BLANK_N, 
    output       VGA_SYNC_N,
    output       VGA_CLK,
    // Debug LEDs
    output [9:0] LEDR,
	 // NEW
    output [6:0] HEX0,
    output [6:0] HEX1,
    output [6:0] HEX2,
    output [6:0] HEX3
);

    ////////////////////////////  CLOCK & RESET  //////////////////////////////////////////////

    wire clk; 
    assign clk = CLOCK_50; 

	 // Global reset / power: SW[0] = 1 => game on, SW[0] = 0 => reset
    wire rst;
    assign rst = SW[0];             // reset button for everything !!! 

    // game_enable: turn display/game on
    wire game_enable;
    assign game_enable = rst;

    // start/play control switch
    wire start_play_switch; 
    assign start_play_switch = SW[1];   
	 
	 ////////////////////////////  PS/2 keyboard wires  //////////////////////////////////////////////
	wire [7:0] scan_code;
	wire       scan_ready;

	wire move_up_p1;
	wire move_down_p1;
	wire move_left_p1;
	wire move_right_p1;

	wire move_up_p2;
	wire move_down_p2;
	wire move_left_p2;
	wire move_right_p2;
	
	// Latched commands (stay 1 until consumed at player_tick)
	reg move_up_p1_cmd, move_down_p1_cmd, move_left_p1_cmd, move_right_p1_cmd;
	reg move_up_p2_cmd, move_down_p2_cmd, move_left_p2_cmd, move_right_p2_cmd;
	
	
    ////////////////////////////  LATCH & STRECHES  ///////////////////////////////////

	always @(posedge CLOCK_50 or negedge rst) begin
		 if (rst == 1'b0) begin
			  move_up_p1_cmd    <= 0;
			  move_down_p1_cmd  <= 0;
			  move_left_p1_cmd  <= 0;
			  move_right_p1_cmd <= 0;
			  move_up_p2_cmd    <= 0;
			  move_down_p2_cmd  <= 0;
			  move_left_p2_cmd  <= 0;
			  move_right_p2_cmd <= 0;
		 end else begin
			  // Latch any pulses from keyboard_decoder
			  if (move_up_p1)    move_up_p1_cmd    <= 1;
			  if (move_down_p1)  move_down_p1_cmd  <= 1;
			  if (move_left_p1)  move_left_p1_cmd  <= 1;
			  if (move_right_p1) move_right_p1_cmd <= 1;

			  if (move_up_p2)    move_up_p2_cmd    <= 1;
			  if (move_down_p2)  move_down_p2_cmd  <= 1;
			  if (move_left_p2)  move_left_p2_cmd  <= 1;
			  if (move_right_p2) move_right_p2_cmd <= 1;

			  // After a movement step happened, clear them
			  if (player_tick) begin
					move_up_p1_cmd    <= 0;
					move_down_p1_cmd  <= 0;
					move_left_p1_cmd  <= 0;
					move_right_p1_cmd <= 0;
					move_up_p2_cmd    <= 0;
					move_down_p2_cmd  <= 0;
					move_left_p2_cmd  <= 0;
					move_right_p2_cmd <= 0;
			  end
		 end
	end


    ////////////////////////////  PLAYER SELECTION SWITCHES  ///////////////////////////////////

    wire select_p1; 
    assign select_p1 = SW[2]; 

    wire select_p2; 
    assign select_p2 = SW[3]; 


    ////////////////////////////  PLAYER COORDINATES & NEXT POSITIONS  /////////////////////////

    reg [3:0] player_x;
    reg [3:0] player_y; 
    reg [3:0] player_2x; 	
    reg [3:0] player_2y; 

    // next positions computed from KEY presses
    reg [3:0] nextp1_x;  // next x position of player 1
    reg [3:0] nextp1_y;  // next y position of player 1
    reg [3:0] nextp2_x; 
    reg [3:0] nextp2_y; 

    // from FSM movement.v this is the initial position of both sprites 
    localparam P1_START_X = 4'd7;									
    localparam P1_START_Y = 4'd11; 
    localparam P2_START_X = 4'd8; 
    localparam P2_START_Y = 4'd11; 
	 
	 ////////////////////////////  ***************NEW PS2 stuff************ /////////////////////////
	 
	 wire [15:0] kb_hex;  // from ps2 core
	 
	wire [7:0] kb_low  = kb_hex[7:0];
	wire [7:0] kb_high = kb_hex[15:8];

	hex hex0_inst(.in(kb_low[3:0]),  .out(HEX0));
	hex hex1_inst(.in(kb_low[7:4]),  .out(HEX1));
	hex hex2_inst(.in(kb_high[3:0]), .out(HEX2));
	hex hex3_inst(.in(kb_high[7:4]), .out(HEX3));
	


    ////////////////////////////  HEART SYSTEM (FUTURE)  ///////////////////////////////////////
    // NOTE: not implemented yet — just reserved for later.
    // Each player will start with 2 hearts, extra hearts can be picked up.
    reg [2:0] hearts_p1;
    reg [2:0] hearts_p2;
    reg       p1_alive;
    reg       p2_alive;
    
	 // Extra heart system: at most one extra heart visible at a time,
	// two total per game (first, then second).
	// You can tweak these coordinates to exactly where you want them.
	localparam [3:0] EXTRA1_X = 4'd0,  EXTRA1_Y = 4'd6;   // first extra heart
	localparam [3:0] EXTRA2_X = 4'd14, EXTRA2_Y = 4'd1;   // second extra heart

	localparam [1:0] EXTRA_STAGE_NONE = 2'd0;
	localparam [1:0] EXTRA_STAGE_ONE  = 2'd1;  // first heart on board
	localparam [1:0] EXTRA_STAGE_TWO  = 2'd2;  // second heart on board

	reg [1:0] extra_stage;        // which extra heart we’re on
	reg       extra_heart_active; // 1 = draw it, 0 = none visible
	reg [3:0] extra_heart_x;
	reg [3:0] extra_heart_y;
	 
	 


    ////////////////////////////  RANDOMNESS / LFSR (FUTURE)  //////////////////////////////////
    // NOTE: instantiation of your LFSR module can go here later.
     wire [7:0] rand_bits;
    
     lfsr rng_inst (
         .clk(CLOCK_50),
         .rst(rst),
         .rnd(rand_bits)
     );
	  
	  // -------- LFSRs for car lanes (random speed + start positions) --------
		wire [7:0] rnd_lane10;
		wire [7:0] rnd_lane9;
		wire [7:0] rnd_lane3;
		wire [7:0] rnd_lane2;

		lfsr lfsr_lane10 (.clk(clk), .rst(rst), .rnd(rnd_lane10));
		lfsr lfsr_lane9  (.clk(clk), .rst(rst), .rnd(rnd_lane9));
		lfsr lfsr_lane3  (.clk(clk), .rst(rst), .rnd(rnd_lane3));
		lfsr lfsr_lane2  (.clk(clk), .rst(rst), .rnd(rnd_lane2));
		
		// Randomize lane speeds and start positions (sampled at RESET / START)
	always @(posedge CLOCK_50 or negedge rst) begin
		 if (rst == 1'b0) begin
			  // default safe values
			  car10_div <= 18_000_000;
			  car9_div  <= 16_000_000;
			  car3_div  <= 5_000_000;
			  car2_div  <= 3_000_000;

			  // row 10: 2 cars, segments [0..3] and [8..11]
			  car10_1_start_x <= 4'd0;
			  car10_2_start_x <= 4'd8;

			  // row 9: 3 cars, segments [1..4], [6..9], [11..14]
			  car9_1_start_x <= 4'd1;
			  car9_2_start_x <= 4'd6;
			  car9_3_start_x <= 4'd11;

			  // row 3: 2 cars, segment [2..3], [10..11]
			  car3_1_start_x <= 4'd2;
			  car3_2_start_x <= 4'd10;

			  // row 2: 2 cars, segments [2..5] and [10..13]
			  car2_1_start_x <= 4'd2;
			  car2_2_start_x <= 4'd10;
		 end
		 else if (S == START) begin
			  // ---------- lane speeds ----------
			  // BASE + (0..7)*STEP -> pick values you like
			  car10_div <= 18_000_000 + (rnd_lane10[2:0] * 1_000_000);
			  car9_div  <= 16_000_000 + (rnd_lane9[2:0]  * 1_000_000);
			  car3_div  <= 5_000_000 + (rnd_lane3[2:0]  * 1_000_000);
			  car2_div  <= 3_000_000 + (rnd_lane2[2:0]  * 1_000_000);

			  // ---------- row 10 start positions ----------
			  // keep them in non-overlapping segments:
			  // car10_1 in [0..1], car10_2 in [8..9]
			  car10_1_start_x <= 4'd0 + {3'b000, rnd_lane10[3]}; // 0 or 1
			  car10_2_start_x <= 4'd8 + {3'b000, rnd_lane10[4]}; // 8 or 9

			  // ---------- row 9 start positions ----------
			  // [1..2], [6..7], [11..12] to avoid overlap
			  car9_1_start_x <= 4'd1 + {3'b000, rnd_lane9[3]};   // 1 or 2
			  car9_2_start_x <= 4'd6 + {3'b000, rnd_lane9[4]};   // 6 or 7
			  car9_3_start_x <= 4'd11 + {3'b000, rnd_lane9[5]};  // 11 or 12

			  // ---------- row 3 start position ----------
			  // [5..7]
			  // First car: positions [2..4]
			  // Second car: positions [10..12]
			  car3_1_start_x <= 4'd2  + rnd_lane3[1:0];          // 2..5 (CAR_LENGTH=2)
			  car3_2_start_x <= 4'd10 + rnd_lane3[3:2];          // 10..13

			  // ---------- row 2 start positions ----------
			  // [2..4] and [10..12]
			  car2_1_start_x <= 4'd2  + rnd_lane2[1:0];          // 2..5 (but CAR_LENGTH=2 so ends by 6)
			  car2_2_start_x <= 4'd10 + rnd_lane2[3:2];          // 10..13
		 end
	end
	  


    ////////////////////////////  FSM STATE  ///////////////////////////////////////////////////

    parameter START = 3'd0,
              PLAY  = 3'd1,
              END   = 3'd2,
              ERROR = 3'd7;
			  
    reg [2:0] S;
    reg [2:0] NS; 
	 
	 wire start_screen  = (S == START);
	 wire end_screen    = (S == END);


    ////////////////////////////  COLLISION FLAGS (PLAYERS & OBSTACLES)  ///////////////////////

    // Player-to-player collision (next positions vs current positions)
    wire p1_hits_p2_next;
    wire p2_hits_p1_next;

    assign p1_hits_p2_next = p2_alive && (nextp1_x == player_2x) && (nextp1_y == player_2y);
    assign p2_hits_p1_next = p1_alive && (nextp2_x == player_x)  && (nextp2_y == player_y);

    wire is_blocked_1;   // from still_obstacles
    wire is_blocked_2;   // from still_obstacles

    wire is_train_block_1;  // from moving_obstacles (currently used as blocking; will later be lethal only)
    wire is_train_block_2;

    wire [3:0] train_head_for_vga; // if you want to draw it later


    // total blocking flags (for next movement)
    // NOTE: In future, remove is_train_block_1/2 to make trains lethal instead of blocking.
    wire blocked_total_1;
    wire blocked_total_2;

    // Trains should NOT block movement. They are lethal instead.
	// Only still obstacles + player–player collisions block.
	assign blocked_total_1 = is_blocked_1 | p1_hits_p2_next;
	assign blocked_total_2 = is_blocked_2 | p2_hits_p1_next;
	
	
	// Extra heart pickup detection (uses next positions so pickup happens
	// when they actually move onto the tile)
	wire p1_picks_extra =
		 extra_heart_active && p1_alive &&
		 (nextp1_x == extra_heart_x) &&
		 (nextp1_y == extra_heart_y);

	wire p2_picks_extra =
		 extra_heart_active && p2_alive &&
		 (nextp2_x == extra_heart_x) &&
		 (nextp2_y == extra_heart_y);

	wire any_extra_pickup = p1_picks_extra | p2_picks_extra;



    // train row/length constants (matching moving_obstacles)
    localparam [3:0] TRAIN_ROW_CONST    = 4'd6;  // same row as your track
    localparam [3:0] TRAIN_LENGTH_CONST = 4'd3;  // must match moving_obstacles
	 
	 // ----- Car lanes -----
	 localparam [3:0] CAR10_ROW_CONST    = 4'd10;
 	 localparam [3:0] CAR9_ROW_CONST     = 4'd9;
	 localparam [3:0] CAR3_ROW_CONST     = 4'd3;
	 localparam [3:0] CAR2_ROW_CONST     = 4'd2;
	 localparam [3:0] CAR_LENGTH_CONST   = 4'd2;
	 
	 wire [3:0] car10_1_head_x, car10_2_head_x;
	 wire [3:0] car9_1_head_x,  car9_2_head_x, car9_3_head_x;
	 wire [3:0] car3_1_head_x, car3_2_head_x;
	 wire [3:0] car2_1_head_x,  car2_2_head_x;
	 	 
		 
	// NEW: random speeds & start positions (per lane)
	reg [31:0] car10_div;
	reg [31:0] car9_div;
	reg [31:0] car3_div;
	reg [31:0] car2_div;

	reg [3:0] car10_1_start_x, car10_2_start_x;
	reg [3:0] car9_1_start_x,  car9_2_start_x, car9_3_start_x;
	reg [3:0] car3_1_start_x, car3_2_start_x;
	reg [3:0] car2_1_start_x,  car2_2_start_x;
	 
	 


    // --- Train hit detection (current positions, not "next") ---
    wire p1_hit_by_train_now;
    wire p2_hit_by_train_now;
	 
	 wire p1_hit_by_car10_now;
	 wire p2_hit_by_car10_now;

	 wire p1_hit_by_car9_now,  p2_hit_by_car9_now;
	wire p1_hit_by_car3_now,  p2_hit_by_car3_now;
	wire p1_hit_by_car2_now,  p2_hit_by_car2_now;
	 // assign the wires below
	 
	 
    assign p1_hit_by_train_now =
           (player_y == TRAIN_ROW_CONST) &&
           (player_x >= train_head_for_vga) &&
           (player_x <  train_head_for_vga + TRAIN_LENGTH_CONST);

    assign p2_hit_by_train_now =
           (player_2y == TRAIN_ROW_CONST) &&
           (player_2x >= train_head_for_vga) &&
           (player_2x <  train_head_for_vga + TRAIN_LENGTH_CONST);
			  
	  assign p1_hit_by_car10_now =
				 (player_y == CAR10_ROW_CONST) && (
					 // car 1 body
					 (player_x >= car10_1_head_x &&
					  player_x <  car10_1_head_x + CAR_LENGTH_CONST) ||
					 // car 2 body
					 (player_x >= car10_2_head_x &&
					  player_x <  car10_2_head_x + CAR_LENGTH_CONST)
				 );

		assign p2_hit_by_car10_now =
				 (player_2y == CAR10_ROW_CONST) && (
					 (player_2x >= car10_1_head_x &&
					  player_2x <  car10_1_head_x + CAR_LENGTH_CONST) ||
					 (player_2x >= car10_2_head_x &&
					  player_2x <  car10_2_head_x + CAR_LENGTH_CONST)
				 );
				 
		assign p1_hit_by_car9_now =
				 (player_y == CAR9_ROW_CONST) && (
					 (player_x >= car9_1_head_x &&
					  player_x <  car9_1_head_x + CAR_LENGTH_CONST) ||
					 (player_x >= car9_2_head_x &&
					  player_x <  car9_2_head_x + CAR_LENGTH_CONST) ||
					 (player_x >= car9_3_head_x &&
					  player_x <  car9_3_head_x + CAR_LENGTH_CONST)
				 );

		assign p2_hit_by_car9_now =
				 (player_2y == CAR9_ROW_CONST) && (
					 (player_2x >= car9_1_head_x &&
					  player_2x <  car9_1_head_x + CAR_LENGTH_CONST) ||
					 (player_2x >= car9_2_head_x &&
					  player_2x <  car9_2_head_x + CAR_LENGTH_CONST) ||
					 (player_2x >= car9_3_head_x &&
					  player_2x <  car9_3_head_x + CAR_LENGTH_CONST)
				 );
				 
		assign p1_hit_by_car3_now =
					(player_y == CAR3_ROW_CONST) && (
						 (player_x >= car3_1_head_x &&
						  player_x <  car3_1_head_x + CAR_LENGTH_CONST) ||
						 (player_x >= car3_2_head_x &&
						  player_x <  car3_2_head_x + CAR_LENGTH_CONST)
					);

		assign p2_hit_by_car3_now =
					(player_2y == CAR3_ROW_CONST) && (
						 (player_2x >= car3_1_head_x &&
						  player_2x <  car3_1_head_x + CAR_LENGTH_CONST) ||
						 (player_2x >= car3_2_head_x &&
						  player_2x <  car3_2_head_x + CAR_LENGTH_CONST)
					);
				  
		assign p1_hit_by_car2_now =
				 (player_y == CAR2_ROW_CONST) && (
					 (player_x >= car2_1_head_x &&
					  player_x <  car2_1_head_x + CAR_LENGTH_CONST) ||
					 (player_x >= car2_2_head_x &&
					  player_x <  car2_2_head_x + CAR_LENGTH_CONST)
				 );

		assign p2_hit_by_car2_now =
				 (player_2y == CAR2_ROW_CONST) && (
					 (player_2x >= car2_1_head_x &&
					  player_2x <  car2_1_head_x + CAR_LENGTH_CONST) ||
					 (player_2x >= car2_2_head_x &&
					  player_2x <  car2_2_head_x + CAR_LENGTH_CONST)
				 );

				 
				 
		// here are the combine hits
		
		wire p1_hit_any_moving_now;
		wire p2_hit_any_moving_now;

		assign p1_hit_any_moving_now = p1_hit_by_train_now |
												 p1_hit_by_car10_now |
												 p1_hit_by_car9_now  |
												 p1_hit_by_car3_now  |
												 p1_hit_by_car2_now;
												 
		assign p2_hit_any_moving_now = p2_hit_by_train_now |
												 p2_hit_by_car10_now |
												 p2_hit_by_car9_now  |
												 p2_hit_by_car3_now  |
												 p2_hit_by_car2_now;


    ////////////////////////////  MOVEMENT CLOCK DIVIDER  //////////////////////////////////////

    parameter integer MOVE_DIV = 10_000_000;  // ideal speed!!! 

    reg [31:0] move_counter;
    reg        move_tick; 

    wire player_tick;
    assign player_tick = move_tick;

    always @(posedge CLOCK_50 or negedge rst) begin
        if (rst == 1'b0) begin
            move_counter <= 32'd0;
            move_tick    <= 1'b0;
        end
        else begin
            if (move_counter == MOVE_DIV - 1) begin
                move_counter <= 32'd0;
                move_tick    <= 1'b1;
            end
            else begin
                move_counter <= move_counter + 32'b1;
                move_tick    <= 1'b0;
            end
        end
    end


    ////////////////////////////  NEXT POSITION LOGIC (KEY INPUTS)  /////////////////////////////

    always @(*) begin
        // default: stay in place
        nextp1_x = player_x;
        nextp1_y = player_y;
        nextp2_x = player_2x;
        nextp2_y = player_2y;

		  
		  if (select_p1) begin
				 if (move_up_p1_cmd && player_y > 0)
					  nextp1_y = player_y - 1;
				 else if (move_down_p1_cmd && player_y < 11)
					  nextp1_y = player_y + 1;
				 else if (move_left_p1_cmd && player_x > 0)
					  nextp1_x = player_x - 1;
				 else if (move_right_p1_cmd && player_x < 15)
					  nextp1_x = player_x + 1;
			end

			if (select_p2) begin
				 if (move_up_p2_cmd && player_2y > 0)
					  nextp2_y = player_2y - 1;
				 else if (move_down_p2_cmd && player_2y < 11)
					  nextp2_y = player_2y + 1;
				 else if (move_left_p2_cmd && player_2x > 0)
					  nextp2_x = player_2x - 1;
				 else if (move_right_p2_cmd && player_2x < 15)
					  nextp2_x = player_2x + 1;
			end
		

	/*		  // -------- Player 1 next position (WASD) --------
		 if (player_tick) begin
        if (select_p1) begin
            if (p1_up_held   && player_y > 0)  nextp1_y = player_y - 1;
            else if (p1_dn_held && player_y < 11) nextp1_y = player_y + 1;
            else if (p1_lt_held && player_x > 0)  nextp1_x = player_x - 1;
            else if (p1_rt_held && player_x < 15) nextp1_x = player_x + 1;
        end

        if (select_p2) begin
            if (p2_up_held   && player_2y > 0)  nextp2_y = player_2y - 1;
            else if (p2_dn_held && player_2y < 11) nextp2_y = player_2y + 1;
            else if (p2_lt_held && player_2x > 0)  nextp2_x = player_2x - 1;
            else if (p2_rt_held && player_2x < 15) nextp2_x = player_2x + 1;
        end
    end
		 */
		 /*
		 if (select_p1) begin
			  if (KEY[2] == 1'b0 && player_y > 0)
					nextp1_y = player_y - 1;          // UP
			  else if (KEY[1] == 1'b0 && player_y < 11)
					nextp1_y = player_y + 1;          // DOWN
			  else if (KEY[3] == 1'b0 && player_x > 0)
					nextp1_x = player_x - 1;          // LEFT
			  else if (KEY[0] == 1'b0 && player_x < 15)
					nextp1_x = player_x + 1;          // RIGHT
		 end

		 //--------------------------------------------
		 // Player 2 movement
		 // KEY[] is ACTIVE-LOW
		 //--------------------------------------------
		 if (select_p2) begin
			  if (KEY[2] == 1'b0 && player_2y > 0)
					nextp2_y = player_2y - 1;         // UP
			  else if (KEY[1] == 1'b0 && player_2y < 11)
					nextp2_y = player_2y + 1;         // DOWN
			  else if (KEY[3] == 1'b0 && player_2x > 0)
					nextp2_x = player_2x - 1;         // LEFT
			  else if (KEY[0] == 1'b0 && player_2x < 15)
					nextp2_x = player_2x + 1;         // RIGHT
		 end
		 */
		 
    end


    ////////////////////////////  FSM: STATE REGISTER  //////////////////////////////////////////

    always @(posedge CLOCK_50 or negedge rst) begin
        if (rst == 1'b0)
            S <= START;
        else
            S <= NS;
    end


    ////////////////////////////  FSM: NEXT STATE LOGIC  ////////////////////////////////////////

    always @(*) begin
        case (S)
            START: begin 
                if (start_play_switch == 1)
                    NS = PLAY; 
                else
                    NS = START; 
            end 

            PLAY: begin 
                if (player_y == 0 && player_2y == 0)
                    NS = END;
                else 
                    NS = PLAY; 
            end 

            END: begin 
					if (start_play_switch == 1'b0) // SW[1] == 0
						NS = START; 
					else
						NS = END;
            end 

            ERROR: begin 
                NS = START; 
            end

            default: NS = START;
        endcase
    end 


    ////////////////////////////  FSM: OUTPUT / POSITION UPDATE  ////////////////////////////////

    // 3rd always block: positions, hearts, and death logic
		always @ (posedge CLOCK_50 or negedge rst)
		begin 
			 if (rst == 1'b0) begin 
				  // RESET: positions + hearts + alive flags
				  player_x  <= P1_START_X;
				  player_y  <= P1_START_Y; 
				  player_2x <= P2_START_X;
				  player_2y <= P2_START_Y;

				  hearts_p1 <= 3'd2;   // each player starts with 2 hearts
				  hearts_p2 <= 3'd2;
				  p1_alive  <= 1'b1;
				  p2_alive  <= 1'b1;
				  
				  // extra hearts: start with first heart visible
				  extra_stage        <= EXTRA_STAGE_ONE;
				  extra_heart_active <= 1'b1;
				  extra_heart_x      <= EXTRA1_X;
				  extra_heart_y      <= EXTRA1_Y;
			 end
			 else begin 
				  case (S)
						START: begin 
							 // On START: reset positions and hearts
							 player_x  <= P1_START_X;
							 player_y  <= P1_START_Y; 
							 player_2x <= P2_START_X;
							 player_2y <= P2_START_Y;

							 hearts_p1 <= 3'd2;
							 hearts_p2 <= 3'd2;
							 p1_alive  <= 1'b1;
							 p2_alive  <= 1'b1;
							 
							 // reset extra hearts for a new game
							 extra_stage        <= EXTRA_STAGE_ONE;
							 extra_heart_active <= 1'b1;
							 extra_heart_x      <= EXTRA1_X;
							 extra_heart_y      <= EXTRA1_Y;
						end

						PLAY: begin 
							 if (player_tick) begin
								  // -------- Player 1 movement + train death --------
								  if (select_p1 == 1'b1 && p1_alive == 1'b1) begin
										if (p1_hit_any_moving_now) begin
											 // lose a heart if any left
											 if (hearts_p1 != 3'd0) begin
												  hearts_p1 <= hearts_p1 - 3'd1;

												  // if we just went from 1 -> 0, mark dead
												  if (hearts_p1 == 3'd1)
														p1_alive <= 1'b0;
											 end

											 // respawn at start
											 player_x <= P1_START_X;
											 player_y <= P1_START_Y;
										end
										else if (blocked_total_1 == 1'b0) begin
											 // normal movement if not blocked
											 player_x <= nextp1_x;
											 player_y <= nextp1_y;
											 
											 // extra heart pickup for P1
											 if (p1_picks_extra && (hearts_p1 < 3'd4)) begin
												  hearts_p1 <= hearts_p1 + 3'd1;
											 end
										end
										// else: stay in place
								  end

								  // -------- Player 2 movement + train death --------
								  if (select_p2 == 1'b1 && p2_alive == 1'b1) begin
										if (p2_hit_any_moving_now) begin
											 // lose a heart if any left
											 if (hearts_p2 != 3'd0) begin
												  hearts_p2 <= hearts_p2 - 3'd1;

												  // if we just went from 1 -> 0, mark dead
												  if (hearts_p2 == 3'd1)
														p2_alive <= 1'b0;
											 end

											 // respawn at start
											 player_2x <= P2_START_X;
											 player_2y <= P2_START_Y;
										end
										else if (blocked_total_2 == 1'b0) begin
											 // normal movement if not blocked
											 player_2x <= nextp2_x;
											 player_2y <= nextp2_y;
											 
											 // extra heart pickup for P2
											 if (p2_picks_extra && (hearts_p2 < 3'd4)) begin
												  hearts_p2 <= hearts_p2 + 3'd1;
											 end
										end
								  end
								  
								  // -------- Advance extra-heart stage if someone picked it up --------
								  if (any_extra_pickup) begin
										if (extra_stage == EXTRA_STAGE_ONE) begin
											 // Move to second location
											 extra_stage        <= EXTRA_STAGE_TWO;
											 extra_heart_x      <= EXTRA2_X;
											 extra_heart_y      <= EXTRA2_Y;
											 extra_heart_active <= 1'b1;
										end
										else if (extra_stage == EXTRA_STAGE_TWO) begin
											 // No more extra hearts for this game
											 extra_stage        <= EXTRA_STAGE_NONE;
											 extra_heart_active <= 1'b0;
										end
								  end
								  
							 end
						end

						END: begin 
							 // could add "win" logic here if you want
						end 	
				  endcase
			 end
		end


    ////////////////////////////  DEBUG LED ASSIGNMENTS  ////////////////////////////////////////
	

			 // Visible version of scan_ready (toggle on each new code)
		assign LEDR[0] = move_up_p1;
		assign LEDR[1] = move_down_p1;
		assign LEDR[2] = move_left_p1;
		assign LEDR[3] = move_right_p1;

		assign LEDR[4] = move_up_p2;
		assign LEDR[5] = move_down_p2;
		assign LEDR[6] = move_left_p2;
		assign LEDR[7] = move_right_p2;

		assign LEDR[8] = scan_ready;   // or scan_ready_vis from core
		assign LEDR[9] = 1'b0;

	
	

	 
	 /*
	 // DEBUG: show raw PS/2 pins and scan_ready
	 // DEBUG: show raw PS/2 pins and scan_ready
		assign LEDR[0] = PS2_CLK;     // raw clock from connector
		assign LEDR[1] = PS2_DAT;     // raw data from connector
		assign LEDR[7:2] = 6'b0;
		assign LEDR[8] = scan_ready;  // from ps2_controller
		assign LEDR[9] = rst;         // just to see reset
	 */
	//---------------------------



    ////////////////////////////  VGA / RENDER MODULE INSTANTIATION  ////////////////////////////

    vga_driver_memory vga_mem(
    .CLOCK_50(CLOCK_50), 
    .rst(rst),
    .SW(SW), 

    .player_x(player_x), 
    .player_y(player_y), 
    .player_2x(player_2x), 
    .player_2y(player_2y), 
    .done(1'b0),

    .hearts_p1(hearts_p1),
    .hearts_p2(hearts_p2),
    .p1_alive(p1_alive),
    .p2_alive(p2_alive),
	 
	 .extra_heart_x(extra_heart_x),
    .extra_heart_y(extra_heart_y),
    .extra_heart_active(extra_heart_active),
	 
	 .start_screen(start_screen),
    .end_screen(end_screen),

    .VGA_R(VGA_R), 
    .VGA_G(VGA_G), 
    .VGA_B(VGA_B), 
    .VGA_HS(VGA_HS), 
    .VGA_VS(VGA_VS),
    .VGA_BLANK_N(VGA_BLANK_N),
    .VGA_SYNC_N(VGA_SYNC_N),
    .VGA_CLK(VGA_CLK),

    .train_head_x(train_head_for_vga),
    .train_row(4'd6),

    // THESE MUST MATCH EXACTLY:
    .car10_1_head_x(car10_1_head_x),
    .car10_2_head_x(car10_2_head_x),
    .car9_1_head_x(car9_1_head_x),
    .car9_2_head_x(car9_2_head_x),
    .car9_3_head_x(car9_3_head_x),
    .car3_1_head_x(car3_1_head_x),
	 .car3_2_head_x(car3_2_head_x),
    .car2_1_head_x(car2_1_head_x),
    .car2_2_head_x(car2_2_head_x)
);


    ////////////////////////////  OBSTACLES MODULES  ////////////////////////////////////////////

    // still obstacles (trees, posts, etc.)
    still_obstacles stay1(
        .clk(clk), 
        .rst(rst), 
        .blocked_x(nextp1_x), 
        .blocked_y(nextp1_y), 
        .is_obstacles(is_blocked_1)
    ); 
							
    still_obstacles stay2(
        .clk(clk), 
        .rst(rst), 
        .blocked_x(nextp2_x), 
        .blocked_y(nextp2_y), 
        .is_obstacles(is_blocked_2)
    ); 	


    // moving obstacles: train lane for both players
    moving_obstacles #(
        .GRID_WIDTH(16),
        .GRID_HEIGHT(12),
        .TRAIN_ROW(4'd6),          // choose your train row
        .TRAIN_LENGTH(4'd3),
        .TRAIN_DIV(25_000_000)     // adjust speed if you want
    ) mov1 (
        .clk(clk),
        .rst(rst),
        .blocked_x(nextp1_x),
        .blocked_y(nextp1_y),
        .is_moving_obstacle(is_train_block_1),
        .train_head_x_out(train_head_for_vga) // optional: for VGA
    );

    moving_obstacles #(
        .GRID_WIDTH(16),
        .GRID_HEIGHT(12),
        .TRAIN_ROW(4'd6),          // same row so both see same train
        .TRAIN_LENGTH(4'd3),
        .TRAIN_DIV(25_000_000)
    ) mov2 (
        .clk(clk),
        .rst(rst),
        .blocked_x(nextp2_x),
        .blocked_y(nextp2_y),
        .is_moving_obstacle(is_train_block_2),
        .train_head_x_out()        // ignore this output here
    );
	 
	 // Row 10 cars: 2 cars, length 2, moving RIGHT
	moving_car_lane #(
		 .GRID_WIDTH(16),
		 .CAR_LENGTH(CAR_LENGTH_CONST),
		 .DIR_RIGHT(1)
	) car10_1 (
		 .clk(clk),
		 .rst(rst),
		 .start_x(car10_1_start_x),
		 .car_div(car10_div),
		 .car_head_x(car10_1_head_x)
	);

	moving_car_lane #(
		 .GRID_WIDTH(16),
		 .CAR_LENGTH(CAR_LENGTH_CONST),
		 .DIR_RIGHT(1)
	) car10_2 (
		 .clk(clk),
		 .rst(rst),
		 .start_x(car10_2_start_x),
		 .car_div(car10_div),
		 .car_head_x(car10_2_head_x)
	);
		
		
				// Row 9 cars: 3 cars, moving LEFT
		moving_car_lane #(
			 .GRID_WIDTH(16),
			 .CAR_LENGTH(CAR_LENGTH_CONST),
			 .DIR_RIGHT(0)
		) car9_1 (
			 .clk(clk),
			 .rst(rst),
			 .start_x(car9_1_start_x),
			 .car_div(car9_div),
			 .car_head_x(car9_1_head_x)
		);

		moving_car_lane #(
			 .GRID_WIDTH(16),
			 .CAR_LENGTH(CAR_LENGTH_CONST),
			 .DIR_RIGHT(0)
		) car9_2 (
			 .clk(clk),
			 .rst(rst),
			 .start_x(car9_2_start_x),
			 .car_div(car9_div),
			 .car_head_x(car9_2_head_x)
		);

		moving_car_lane #(
			 .GRID_WIDTH(16),
			 .CAR_LENGTH(CAR_LENGTH_CONST),
			 .DIR_RIGHT(0)
		) car9_3 (
			 .clk(clk),
			 .rst(rst),
			 .start_x(car9_3_start_x),
			 .car_div(car9_div),
			 .car_head_x(car9_3_head_x)
		);


		// Row 3: 2 cars, moving RIGHT (left -> right)
		moving_car_lane #(
			  .GRID_WIDTH(16),
			  .CAR_LENGTH(CAR_LENGTH_CONST),
			  .DIR_RIGHT(1)
		) car3_1 (
			  .clk(clk),
			  .rst(rst),
			  .start_x(car3_1_start_x),
			  .car_div(car3_div),
			  .car_head_x(car3_1_head_x)
		);

		moving_car_lane #(
			  .GRID_WIDTH(16),
			  .CAR_LENGTH(CAR_LENGTH_CONST),
			  .DIR_RIGHT(1)
		) car3_2 (
			  .clk(clk),
			  .rst(rst),
			  .start_x(car3_2_start_x),
			  .car_div(car3_div),
			  .car_head_x(car3_2_head_x)
		);

		// Row 2: 2 cars, moving LEFT
		moving_car_lane #(
			 .GRID_WIDTH(16),
			 .CAR_LENGTH(CAR_LENGTH_CONST),
			 .DIR_RIGHT(0)
		) car2_1 (
			 .clk(clk),
			 .rst(rst),
			 .start_x(car2_1_start_x),
			 .car_div(car2_div),
			 .car_head_x(car2_1_head_x)
		);

		moving_car_lane #(
			 .GRID_WIDTH(16),
			 .CAR_LENGTH(CAR_LENGTH_CONST),
			 .DIR_RIGHT(0)
		) car2_2 (
			 .clk(clk),
			 .rst(rst),
			 .start_x(car2_2_start_x),
			 .car_div(car2_div),
			 .car_head_x(car2_2_head_x)
		);
		
		
		
		
		
		ps2 ps2_inst (
    .PS2_KBCLK(PS2_CLK),
    .PS2_KBDAT(PS2_DAT),
    .computerClk(CLOCK_50),
    .rst_n(KEY[0]),      // KEY[0] is active-low, ps2 resets when KEY[0] = 0
    .hexo(kb_hex)
);

ps2_wrapper ps2_wrap_inst (
    .clk(CLOCK_50),
    .rst_n(KEY[0]),
    .hexo(kb_hex),
    .scan_code(scan_code),
    .scan_ready(scan_ready)
); 

keyboard_decoder kb (
    .clk(CLOCK_50),
    .rst_n(KEY[0]),          // active-low (KEY0 pressed = 0)
    .scan_code(scan_code),
    .scan_ready(scan_ready),

    .move_up_p1(move_up_p1),
    .move_down_p1(move_down_p1),
    .move_left_p1(move_left_p1),
    .move_right_p1(move_right_p1),

    .move_up_p2(move_up_p2),
    .move_down_p2(move_down_p2),
    .move_left_p2(move_left_p2),
    .move_right_p2(move_right_p2)
);




		



endmodule

