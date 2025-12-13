////////////////////////////////////////////////////////////////////////////////////////////////////
/*
Generates VGA timing and the full game scene.
Determines pixel color based on current screen coordinates and game state such as players, obstacles, and other elements.
ROM instantiations are found at bottom, and IP Core ROM logic found before game_display always block 
Note: drawing priority means displaying the pixels/grid(s) first to be updated in the always block
*/
////////////////////////////////////////////////////////////////////////////////////////////////////


module vga_driver_memory (

    //////////// CLOCK //////////
    input            CLOCK_50,

    //////////// SEG7 //////////
    output     [6:0] HEX0,
    output     [6:0] HEX1,
    output     [6:0] HEX2,
    output     [6:0] HEX3,

    //////////// SW //////////
    input      [9:0] SW,

    //////////// VGA //////////
    output           VGA_BLANK_N,
    output reg [7:0] VGA_B,
    output           VGA_CLK,
    output reg [7:0] VGA_G,
    output           VGA_HS,
    output reg [7:0] VGA_R,
    output           VGA_SYNC_N,
    output           VGA_VS,

    //////////// SPRITE INPUTS //////////
    input  [3:0] player_x,
    input  [3:0] player_y,
    input  [3:0] player_2x,
    input  [3:0] player_2y,
    input        rst,
    input        done,     // (unused for now, kept for compatibility)

    // NEW: hearts + alive flags
    input  [2:0] hearts_p1,
    input  [2:0] hearts_p2,
    input        p1_alive,
    input        p2_alive,
	 
	 // NEW: extra heart to draw on the grid
    input [3:0]  extra_heart_x,
    input [3:0]  extra_heart_y,
    input        extra_heart_active,
	 
	 // screen: start + end
	 input        start_screen,   // S == START
    input        end_screen,     // S == END

    // Train position from moving_obstacles / crossy_road
    input  [3:0] train_head_x,
    input  [3:0] train_row,
	 
	 // NEW: car heads for lanes
    input  [3:0] car10_1_head_x,
    input  [3:0] car10_2_head_x,
    input  [3:0] car9_1_head_x,
    input  [3:0] car9_2_head_x,
    input  [3:0] car9_3_head_x,
    input  [3:0] car3_1_head_x,
	 input  [3:0] car3_2_head_x,
    input  [3:0] car2_1_head_x,
    input  [3:0] car2_2_head_x
);

    reg  [3:0] grid_x; 
    reg  [3:0] grid_y;

    wire [9:0] xPixel_internal;   // current x (0 to 639)
    wire [9:0] yPixel_internal;   // current y (0 to 479)

    // Tile size (grid -> pixel translation)
    localparam TILE         = 10'd40; // 40 pixels per grid cell 
    localparam TRAIN_LENGTH = 4'd3;   // train is 3 tiles long
	 
	 localparam [3:0] CAR10_ROW_CONST  = 4'd10;
	 localparam [3:0] CAR9_ROW_CONST   = 4'd9;
	 localparam [3:0] CAR3_ROW_CONST   = 4'd3;
	 localparam [3:0] CAR2_ROW_CONST   = 4'd2;
	 localparam [3:0] CAR_LENGTH_CONST = 4'd2;

    wire clk;
    assign clk = CLOCK_50;

    wire active_pixels;             
    wire vga_pix_clk;

    assign VGA_CLK = vga_pix_clk;

    // Display enable from SW[0]
    wire game_enable;
    assign game_enable = SW[0];

    // Turn off all 7 seg displays.
    assign HEX0 = 7'h00;
    assign HEX1 = 7'h00;
    assign HEX2 = 7'h00;
    assign HEX3 = 7'h00;

    // grid * TILE = pixel origins (not strictly needed now but fine to keep)
    wire [9:0] player_x_px  = player_x  * TILE; 
    wire [9:0] player_y_px  = player_y  * TILE; 
    wire [9:0] player_2x_px = player_2x * TILE; 
    wire [9:0] player_2y_px = player_2y * TILE; 
	 
	 //hearts
	 wire extra_heart_here =
    extra_heart_active &&
    (grid_x == extra_heart_x) &&
    (grid_y == extra_heart_y);

    // compute grid coordinates only in visible area
    always @(*) begin
        if (active_pixels == 1'b1) begin 
            grid_x = xPixel_internal / TILE; // 16 columns 
            grid_y = yPixel_internal / TILE; // 12 rows 
        end
        else begin
            grid_x = 4'd0;
            grid_y = 4'd0; 
        end
    end

    reg [23:0] vga_color;

    // send RGB to pins
    always @(*) begin
        {VGA_R, VGA_G, VGA_B} = vga_color; // [23:16]=R, [15:8]=G, [7:0]=B
    end

	 
	 
/*
///////////////////////////////// ROM INSTANTIATION LOGIC FOR SPRITE HEARTS //////////////////////////////////////////////
	// Heart Live count: (0,11):
	wire [9:0] heart_011x_px = 4'd0 * TILE; 	// Grid position x = 0 
	wire [9:0] heart_011y_px = 4'd11 * TILE; 	// Grid position y = 11
	
	wire [23:0] heart_011_color; 
	wire [6:0] heart_011x = xPixel_internal - heart_011x_px; 	
	wire [6:0] heart_011y = yPixel_internal - heart_011y_px; 	
	wire [10:0] heart_011_address = (heart_011y * TILE) + heart_011x; 
	
	wire within_heart_011 = ((xPixel_internal >= heart_011x_px) && (xPixel_internal < heart_011x_px + 6'd40) && 
									(yPixel_internal >= heart_011y_px) && (yPixel_internal < heart_011y_px + 6'd40)); 
	
	reg within_heart_011_delayed; 
	// accounting for memory reading clk delay
	always @ (posedge vga_pix_clk) begin 
		within_heart_011_delayed <= within_heart_011; 
	end 
	
	wire heart_011_transparent = ((heart_011_color[23:16] < 8'h10) && (heart_011_color[15:8] < 8'h10) && (heart_011_color[7:0] < 8'h10) || 
									(heart_011_color[23:16] < 8'h10) && (heart_011_color[15:8] < 8'h10) && (heart_011_color[7:0] < 8'h10) );  
	wire show_heart_011 = within_heart_011_delayed && !heart_011_transparent; 
	
	
	// Heart Live count: (1,11):
	wire [9:0] heart_0111x_px = 4'd1 * TILE; 	
	wire [9:0] heart_0111y_px = 4'd11 * TILE; 	
	
	wire [23:0] heart_0111_color; 
	wire [6:0] heart_0111x = xPixel_internal - heart_0111x_px; 	
	wire [6:0] heart_0111y = yPixel_internal - heart_0111y_px; 	
	wire [10:0] heart_0111_address = (heart_0111y * TILE) + heart_0111x; 
	
	wire within_heart_0111 = ((xPixel_internal >= heart_0111x_px) && (xPixel_internal < heart_0111x_px + 6'd40) && 
									(yPixel_internal >= heart_0111y_px) && (yPixel_internal < heart_0111y_px + 6'd40)); 
	
	reg within_heart_0111_delayed; 
	// accounting for memory reading clk delay
	always @ (posedge vga_pix_clk) begin 
		within_heart_0111_delayed <= within_heart_0111; 
	end 
	
	wire heart_0111_transparent = ((heart_0111_color[23:16] < 8'h10) && (heart_0111_color[15:8] < 8'h10) && (heart_0111_color[7:0] < 8'h10)); 
	wire show_heart_0111 = within_heart_0111_delayed && !heart_0111_transparent; 
	 
	 
	// Heart Live count: (12,11):  ORIGINALLY: 14, 11
	wire [9:0] heart_1411x_px = 4'd12 * TILE; 	
	wire [9:0] heart_1411y_px = 4'd11 * TILE; 	
	
	wire [23:0] heart_1411_color; 
	wire [6:0] heart_1411x = xPixel_internal - heart_1411x_px; 	
	wire [6:0] heart_1411y = yPixel_internal - heart_1411y_px; 
	wire [10:0] heart_1411_address = (heart_1411y * TILE) + heart_1411x; 
	
	wire within_heart_1411 = ((xPixel_internal >= heart_1411x_px) && (xPixel_internal < heart_1411x_px + 6'd40) && 
									(yPixel_internal >= heart_1411y_px) && (yPixel_internal < heart_1411y_px + 6'd40)); 
	
	reg within_heart_1411_delayed; 
	// accounting for memory reading clk delay
	always @ (posedge vga_pix_clk) begin 
		within_heart_1411_delayed <= within_heart_1411; 
	end 
	
	wire heart_1411_transparent = ((heart_1411_color[23:16] < 8'h10) && (heart_1411_color[15:8] < 8'h10) && (heart_1411_color[7:0] < 8'h10) || 
									(heart_1411_color[23:16] < 8'h10) && (heart_1411_color[15:8] < 8'h10) && (heart_1411_color[7:0] < 8'h10) );  
	wire show_heart_1411 = within_heart_1411_delayed && !heart_1411_transparent; 
	 
	 
	// Heart Live count: (13,11):   ORIGINALLY: 15, 11
	wire [9:0] heart_1511x_px = 4'd13 * TILE; 	
	wire [9:0] heart_1511y_px = 4'd11 * TILE; 	
	
	wire [23:0] heart_1511_color; 
	wire [6:0] heart_1511x = xPixel_internal - heart_1511x_px; 
	wire [6:0] heart_1511y = yPixel_internal - heart_1511y_px; 	
	wire [10:0] heart_1511_address = (heart_1511y * TILE) + heart_1511x; 
	
	wire within_heart_1511 = ((xPixel_internal >= heart_1511x_px) && (xPixel_internal < heart_1511x_px + 6'd40) && 
									(yPixel_internal >= heart_1511y_px) && (yPixel_internal < heart_1511y_px + 6'd40)); 
	
	reg within_heart_1511_delayed; 
	// accounting for memory reading clk delay
	always @ (posedge vga_pix_clk) begin 
		within_heart_1511_delayed <= within_heart_1511; 
	end 
	
	wire heart_1511_transparent = ((heart_1511_color[23:16] < 8'h10) && (heart_1511_color[15:8] < 8'h10) && (heart_1511_color[7:0] < 8'h10));  
	wire show_heart_1511 = within_heart_1511_delayed && !heart_1511_transparent; 
*/	 	
	
//////////////////////////////////////////////////// ROM INSTANTIATION LOGIC FOR SPRITES ///////////////////////////////////////////	
	// sprite 1 
	wire [23:0] sprite1_color; 											
	wire [5:0] sprite1_x = xPixel_internal - player_x_px; 					
	wire [5:0] sprite1_y = yPixel_internal - player_y_px; 					
	//based on ROM adress formula:   adress = (row * width) + column 
	wire [10:0] sprite1_address = (sprite1_y * TILE) + sprite1_x; 			

	// checking if within sprite bounds 
	wire within_sprite1 = (xPixel_internal >= player_x_px) && (xPixel_internal < player_x_px + 6'd40) && (yPixel_internal >= player_y_px) && (yPixel_internal < player_y_px + 6'd40); 
	reg within_sprite1_delayed; 
	// transparent background 
	wire sprite1_transparent = ((sprite1_color[23:16] < 8'h10) && (sprite1_color[15:8] < 8'h10) && (sprite1_color[7:0] < 8'h10)); // black background 
	
	
	wire show_sprite1 = within_sprite1_delayed && !sprite1_transparent; 
	// accounting for memory reading clk delay 
	always @ (posedge vga_pix_clk) begin 
		within_sprite1_delayed <= within_sprite1; 
	end 
	
	
	// sprite 2 
	wire [23:0] sprite2_color; 											// 24 bits because ROM will output 12 bits 
	wire [5:0] sprite2_x = xPixel_internal - player_2x_px; 					// relative x position: current Horizontal pixel - sprite's horizontal position... 6 bits holds all 40 pixels 
	wire [5:0] sprite2_y = yPixel_internal - player_2y_px; 					// relative y position: current Vertical pixel - sprite's vertical position ... 6 bits holds all 40 pixels 
	//based on ROM adress formula:   adress = (row * width) + column 
	wire [10:0] sprite2_address = (sprite2_y * TILE) + sprite2_x; 			// 11 bits to fit 1600 pixels 

	// checking if within sprite bounds 
	wire within_sprite2 = (xPixel_internal >= player_2x_px) && (xPixel_internal < player_2x_px + 6'd40) && (yPixel_internal >= player_2y_px) && (yPixel_internal < player_2y_px + 6'd40); 
	reg within_sprite2_delayed; 
	// transparent background 
	wire sprite2_transparent = ((sprite2_color[23:16] < 8'h10) && (sprite2_color[15:8] < 8'h10) && (sprite2_color[7:0] < 8'h10) || // black background 
									(sprite2_color[23:16] < 8'h10) && (sprite2_color[15:8] < 8'h10) && (sprite2_color[7:0] < 8'h10) );  // white background 
	wire show_sprite2 = within_sprite2_delayed && !sprite2_transparent; 
	// accounting for memory reading clk delay 
	always @ (posedge vga_pix_clk) begin 
		within_sprite2_delayed <= within_sprite2; 
	end 	
	
//////////////////////////////////////////////////// ROM INSTANTIATION LOGIC FOR TOP MOVING CARS ///////////////////////////////////////////
	// Green Car: All Nighter (L -> R) 
	 wire [9:0] allnight_car_x = car3_1_head_x; 
	 wire [9:0] allnight_car_y = CAR3_ROW_CONST;
	 
	 wire [9:0] allnight_carx_px  = allnight_car_x  * TILE; 
    wire [9:0] allnight_cary_px  = allnight_car_y  * TILE; 
	 
	wire [23:0] allnight_car_color; 											
	wire [11:0] allnight_car_offset_x = xPixel_internal - allnight_carx_px; 			// changed to 12 bits for multi-block length (32000 pxs)		
	wire [11:0] allnight_car_offset_y = yPixel_internal - allnight_cary_px; 			// changed to 12 bits for multi-block length  (3200 pxs)
	//based on ROM adress formula....   width: account for multiple grid blocks wide 
	wire [12:0] allnight_car_address = (allnight_car_offset_y * (CAR_LENGTH_CONST * TILE)) + allnight_car_offset_x; 	// 13 bits to fit 4800 pixels			

	// checking if within sprite bounds 
	wire within_allnight_car = (xPixel_internal >= allnight_carx_px) && (xPixel_internal < allnight_carx_px + (CAR_LENGTH_CONST * TILE)) && 
									(yPixel_internal >= allnight_cary_px) && (yPixel_internal < allnight_cary_px + TILE); 
	
	reg within_allnight_car_delayed; 
	// transparent background 
	wire allnight_car_transparent = ((allnight_car_color[23:16] < 8'h10) && (allnight_car_color[15:8] < 8'h10) && (allnight_car_color[7:0] < 8'h10));  
	wire show_allnight_car = within_allnight_car_delayed && !allnight_car_transparent; 
	// accounting for memory reading clk delay 
	always @ (posedge vga_pix_clk) begin 
		within_allnight_car_delayed <= within_allnight_car; 
	end 
	
	// Red Car: "Is That All?" (L -> R) 
	 wire [9:0] isthatall_car_x = car3_2_head_x; 
	 wire [9:0] isthatall_car_y = CAR3_ROW_CONST;
	 
	 wire [9:0] isthatall_carx_px  = isthatall_car_x  * TILE; 
    wire [9:0] isthatall_cary_px  = isthatall_car_y  * TILE; 
	 
	wire [23:0] isthatall_car_color; 											
	wire [11:0] isthatall_car_offset_x = xPixel_internal - isthatall_carx_px; 			// changed to 12 bits for multi-block length (32000 pxs)		
	wire [11:0] isthatall_car_offset_y = yPixel_internal - isthatall_cary_px; 			// changed to 12 bits for multi-block length  (3200 pxs)
	//based on ROM adress formula....   width: account for multiple grid blocks wide 
	wire [12:0] isthatall_car_address = (isthatall_car_offset_y * (CAR_LENGTH_CONST * TILE)) + isthatall_car_offset_x; 	// 13 bits to fit 4800 pixels			

	// checking if within sprite bounds 
	wire within_isthatall_car = (xPixel_internal >= isthatall_carx_px) && (xPixel_internal < isthatall_carx_px + (CAR_LENGTH_CONST * TILE)) && 
									(yPixel_internal >= isthatall_cary_px) && (yPixel_internal < isthatall_cary_px + TILE); 
	
	reg within_isthatall_car_delayed; 
	// transparent background 
	wire isthatall_car_transparent = ((isthatall_car_color[23:16] < 8'h10) && (isthatall_car_color[15:8] < 8'h10) && (isthatall_car_color[7:0] < 8'h10));  
	wire show_isthatall_car = within_isthatall_car_delayed && !isthatall_car_transparent; 
	// accounting for memory reading clk delay 
	always @ (posedge vga_pix_clk) begin 
		within_isthatall_car_delayed <= within_isthatall_car; 
	end 

	// Blue Car: Exam 3 (R -> L) 
	 wire [9:0] exam3_car_x = car2_1_head_x; 
	 wire [9:0] exam3_car_y = CAR2_ROW_CONST;
	 
	 wire [9:0] exam3_carx_px  = exam3_car_x  * TILE; 
    wire [9:0] exam3_cary_px  = exam3_car_y  * TILE; 
	 
	wire [23:0] exam3_car_color; 											
	wire [11:0] exam3_car_offset_x = xPixel_internal - exam3_carx_px; 			// changed to 12 bits for multi-block length (32000 pxs)		
	wire [11:0] exam3_car_offset_y = yPixel_internal - exam3_cary_px; 			// changed to 12 bits for multi-block length  (3200 pxs)
	//based on ROM adress formula....   width: account for multiple grid blocks wide 
	wire [12:0] exam3_car_address = (exam3_car_offset_y * (CAR_LENGTH_CONST * TILE)) + exam3_car_offset_x; 	// 13 bits to fit 4800 pixels			

	// checking if within sprite bounds 
	wire within_exam3_car = (xPixel_internal >= exam3_carx_px) && (xPixel_internal < exam3_carx_px + (CAR_LENGTH_CONST * TILE)) && 
									(yPixel_internal >= exam3_cary_px) && (yPixel_internal < exam3_cary_px + TILE); 
	
	reg within_exam3_car_delayed; 
	// transparent background 
	wire exam3_car_transparent = ((exam3_car_color[23:16] < 8'h10) && (exam3_car_color[15:8] < 8'h10) && (exam3_car_color[7:0] < 8'h10));  
	wire show_exam3_car = within_exam3_car_delayed && !exam3_car_transparent; 
	// accounting for memory reading clk delay 
	always @ (posedge vga_pix_clk) begin 
		within_exam3_car_delayed <= within_exam3_car; 
	end 
	
	// Brown Car: Lab Full (R -> L) 
	 wire [9:0] labfull_car_x = car2_2_head_x; 
	 wire [9:0] labfull_car_y = CAR2_ROW_CONST;
	 
	 wire [9:0] labfull_carx_px  = labfull_car_x  * TILE; 
    wire [9:0] labfull_cary_px  = labfull_car_y  * TILE; 
	 
	// Moving Orange Homework Car 
	wire [23:0] labfull_car_color; 											
	wire [11:0] labfull_car_offset_x = xPixel_internal - labfull_carx_px; 			// changed to 12 bits for multi-block length (32000 pxs)		
	wire [11:0] labfull_car_offset_y = yPixel_internal - labfull_cary_px; 			// changed to 12 bits for multi-block length  (3200 pxs)
	//based on ROM adress formula....   width: account for multiple grid blocks wide 
	wire [12:0] labfull_car_address = (labfull_car_offset_y * (CAR_LENGTH_CONST * TILE)) + labfull_car_offset_x; 	// 13 bits to fit 4800 pixels			

	// checking if within sprite bounds 
	wire within_labfull_car = (xPixel_internal >= labfull_carx_px) && (xPixel_internal < labfull_carx_px + (CAR_LENGTH_CONST * TILE)) && 
									(yPixel_internal >= labfull_cary_px) && (yPixel_internal < labfull_cary_px + TILE); 
	
	reg within_labfull_car_delayed; 
	// transparent background 
	wire labfull_car_transparent = ((labfull_car_color[23:16] < 8'h10) && (labfull_car_color[15:8] < 8'h10) && (labfull_car_color[7:0] < 8'h10));  
	wire show_labfull_car = within_labfull_car_delayed && !labfull_car_transparent; 
	// accounting for memory reading clk delay 
	always @ (posedge vga_pix_clk) begin 
		within_labfull_car_delayed <= within_labfull_car; 
	end 

///////////////////////////////// ROM INSTANTIATION MODULE FOR BOTTOM CARS /////////////////////////////////////////////////////////////////////
   // Orange Car: Homeworks
	 wire [9:0] homework_car_x = car10_1_head_x; 
	 wire [9:0] homework_car_y = CAR10_ROW_CONST;
	 
	 wire [9:0] homework_carx_px  = homework_car_x  * TILE; 
    wire [9:0] homework_cary_px  = homework_car_y  * TILE; 
	 
	wire [23:0] homework_car_color; 											
	wire [11:0] homework_car_offset_x = xPixel_internal - homework_carx_px; 			// changed to 12 bits for multi-block length (32000 pxs)		
	wire [11:0] homework_car_offset_y = yPixel_internal - homework_cary_px; 			// changed to 12 bits for multi-block length  (3200 pxs)
	//based on ROM adress formula....   width: account for multiple grid blocks wide 
	wire [12:0] homework_car_address = (homework_car_offset_y * (CAR_LENGTH_CONST * TILE)) + homework_car_offset_x; 	// 13 bits to fit 4800 pixels			

	// checking if within sprite bounds 
	wire within_homework_car = (xPixel_internal >= homework_carx_px) && (xPixel_internal < homework_carx_px + (CAR_LENGTH_CONST * TILE)) && 
									(yPixel_internal >= homework_cary_px) && (yPixel_internal < homework_cary_px + TILE); 
	
	reg within_homework_car_delayed; 
	// transparent background 
	wire homework_car_transparent = ((homework_car_color[23:16] < 8'h10) && (homework_car_color[15:8] < 8'h10) && (homework_car_color[7:0] < 8'h10));  
	wire show_homework_car = within_homework_car_delayed && !homework_car_transparent; 
	// accounting for memory reading clk delay 
	always @ (posedge vga_pix_clk) begin 
		within_homework_car_delayed <= within_homework_car; 
	end 
	
	
	// Purple Car: Lab 9 
	 wire [9:0] lab9_car_x = car10_2_head_x; 
	 wire [9:0] lab9_car_y = CAR10_ROW_CONST;
	 
	 wire [9:0] lab9_carx_px  = lab9_car_x  * TILE; 
    wire [9:0] lab9_cary_px  = lab9_car_y  * TILE; 
	 
	wire [23:0] lab9_car_color; 											
	wire [11:0] lab9_car_offset_x = xPixel_internal - lab9_carx_px; 					
	wire [11:0] lab9_car_offset_y = yPixel_internal - lab9_cary_px; 			
	//based on ROM adress formula....   width: account for multiple grid blocks wide 
	wire [12:0] lab9_car_address = (lab9_car_offset_y * (CAR_LENGTH_CONST * TILE)) + lab9_car_offset_x;

	// checking if within sprite bounds 
	wire within_lab9_car = (xPixel_internal >= lab9_carx_px) && (xPixel_internal < lab9_carx_px + (CAR_LENGTH_CONST * TILE)) && 
									(yPixel_internal >= lab9_cary_px) && (yPixel_internal < lab9_cary_px + TILE); 
	
	reg within_lab9_car_delayed; 
	// transparent background 
	wire lab9_car_transparent = ((lab9_car_color[23:16] < 8'h10) && (lab9_car_color[15:8] < 8'h10) && (lab9_car_color[7:0] < 8'h10));  
	wire show_lab9_car = within_lab9_car_delayed && !lab9_car_transparent; 
	// accounting for memory reading clk delay 
	always @ (posedge vga_pix_clk) begin 
		within_lab9_car_delayed <= within_lab9_car; 
	end 

	
	 // R->L Blue Lab 12 Car 
	 wire [9:0] lab12_car_x = car9_1_head_x; 
	 wire [9:0] lab12_car_y = CAR9_ROW_CONST;
	 
	 wire [9:0] lab12_carx_px  = lab12_car_x  * TILE; 
    wire [9:0] lab12_cary_px  = lab12_car_y  * TILE; 
	  
	wire [23:0] lab12_car_color; 											
	wire [11:0] lab12_car_offset_x = xPixel_internal - lab12_carx_px; 			// changed to 12 bits for multi-block length (32000 pxs)		
	wire [11:0] lab12_car_offset_y = yPixel_internal - lab12_cary_px; 			// changed to 12 bits for multi-block length  (3200 pxs)
	wire [12:0] lab12_car_address = (lab12_car_offset_y * (CAR_LENGTH_CONST * TILE)) + lab12_car_offset_x; 	// 13 bits to fit 4800 pixels			

	// checking if within sprite bounds 
	wire within_lab12_car = (xPixel_internal >= lab12_carx_px) && (xPixel_internal < lab12_carx_px + (CAR_LENGTH_CONST * TILE)) && 
									(yPixel_internal >= lab12_cary_px) && (yPixel_internal < lab12_cary_px + TILE); 
	
	reg within_lab12_car_delayed; 
	// transparent background 
	wire lab12_car_transparent = ((lab12_car_color[23:16] < 8'h10) && (lab12_car_color[15:8] < 8'h10) && (lab12_car_color[7:0] < 8'h10));  
	wire show_lab12_car = within_lab12_car_delayed && !lab12_car_transparent; 
	// accounting for memory reading clk delay 
	always @ (posedge vga_pix_clk) begin 
		within_lab12_car_delayed <= within_lab12_car; 
	end 
	
	
	// R->L Green Handwriting
	 wire [9:0] handwriting_car_x = car9_2_head_x; 
	 wire [9:0] handwriting_car_y = CAR9_ROW_CONST;
	 
	 wire [9:0] handwriting_carx_px  = handwriting_car_x  * TILE; 
    wire [9:0] handwriting_cary_px  = handwriting_car_y  * TILE; 
	 
	wire [23:0] handwriting_car_color; 											
	wire [11:0] handwriting_car_offset_x = xPixel_internal - handwriting_carx_px; 					
	wire [11:0] handwriting_car_offset_y = yPixel_internal - handwriting_cary_px; 			
	wire [12:0] handwriting_car_address = (handwriting_car_offset_y * (CAR_LENGTH_CONST * TILE)) + handwriting_car_offset_x;

	// checking if within sprite bounds 
	wire within_handwriting_car = (xPixel_internal >= handwriting_carx_px) && (xPixel_internal < handwriting_carx_px + (CAR_LENGTH_CONST * TILE)) && 
									(yPixel_internal >= handwriting_cary_px) && (yPixel_internal < handwriting_cary_px + TILE); 
									
	reg within_handwriting_car_delayed; 
	// transparent background 
	wire handwriting_car_transparent = ((handwriting_car_color[23:16] < 8'h10) && (handwriting_car_color[15:8] < 8'h10) && (handwriting_car_color[7:0] < 8'h10));  
	wire show_handwriting_car = within_handwriting_car_delayed && !handwriting_car_transparent; 
	// accounting for memory reading clk delay 
	always @ (posedge vga_pix_clk) begin 
		within_handwriting_car_delayed <= within_handwriting_car; 
	end 
	
	
	// R->L Red 8:30 AM
	 wire [9:0] am0830_car_x = car9_3_head_x; 
	 wire [9:0] am0830_car_y = CAR9_ROW_CONST;
	 
	 wire [9:0] am0830_carx_px  = am0830_car_x  * TILE; 
    wire [9:0] am0830_cary_px  = am0830_car_y  * TILE; 
	 
	wire [23:0] am0830_car_color; 											
	wire [11:0] am0830_car_offset_x = xPixel_internal - am0830_carx_px; 					
	wire [11:0] am0830_car_offset_y = yPixel_internal - am0830_cary_px; 			
	wire [12:0] am0830_car_address = (am0830_car_offset_y * (CAR_LENGTH_CONST * TILE)) + am0830_car_offset_x;

	// checking if within sprite bounds 
	wire within_am0830_car = (xPixel_internal >= am0830_carx_px) && (xPixel_internal < am0830_carx_px + (CAR_LENGTH_CONST * TILE)) && 
									(yPixel_internal >= am0830_cary_px) && (yPixel_internal < am0830_cary_px + TILE); 
									
	reg within_am0830_car_delayed; 
	// transparent background 
	wire am0830_car_transparent = ((am0830_car_color[23:16] < 8'h10) && (am0830_car_color[15:8] < 8'h10) && (am0830_car_color[7:0] < 8'h10));  
	wire show_am0830_car = within_am0830_car_delayed && !am0830_car_transparent; 
	// accounting for memory reading clk delay 
	always @ (posedge vga_pix_clk) begin 
		within_am0830_car_delayed <= within_am0830_car; 
	end 
	
////////////////////////////////////////// ROM MODULE INSTATIATION FOR TRAIN  //////////////////////////////////////////////////////////////////////////////////	 
    wire [9:0] train_006_x = train_head_x; 
	 wire [9:0] train_006_y = train_row;
	 wire [9:0] train_006x_px  = train_006_x  * TILE; 
    wire [9:0] train_006y_px  = train_006_y  * TILE; 
	 
	// Moving train
	wire [23:0] train_006_color; 											
	wire [9:0] train_006_offset_x = xPixel_internal - train_006x_px; 			// changed to 10 bits for multi-block length				
	wire [9:0] train_006_offset_y = yPixel_internal - train_006y_px; 			// changed to 10 bits for multi-block length		
	wire [12:0] train_006_address = (train_006_offset_y * (TRAIN_LENGTH * TILE)) + train_006_offset_x; 	// 13 bits to fit 4800 pixels			

	// checking if within sprite bounds 
	wire within_train_006 = (xPixel_internal >= train_006x_px) && (xPixel_internal < train_006x_px + (TRAIN_LENGTH * TILE)) && 
									(yPixel_internal >= train_006y_px) && (yPixel_internal < train_006y_px + TILE); 
	reg within_train_006_delayed; 
	// transparent background 
	wire train_006_transparent = ((train_006_color[23:16] < 8'h10) && (train_006_color[15:8] < 8'h10) && (train_006_color[7:0] < 8'h10));  
	wire show_train_006 = within_train_006_delayed && !train_006_transparent; 
	// accounting for memory reading clk delay 
	always @ (posedge vga_pix_clk) begin 
		within_train_006_delayed <= within_train_006; 
	end 

	
////////////////////////////////////////// ROM MODULE INSTATIATION FOR RAILROAD CROSSING POSTS //////////////////////////////////////////////////////////////////////////////////	 
	// RRxing post: (0,5):
	wire [9:0] rrxing_05x_px = 4'd0 * TILE; 	// Grid position x = 0 
	wire [9:0] rrxing_05y_px = 4'd5 * TILE; 	// Grid position y = 5 
	
	wire [23:0] rrxing_05_color; 
	wire [6:0] rrxing_05x = xPixel_internal - rrxing_05x_px; 	
	wire [6:0] rrxing_05y = yPixel_internal - rrxing_05y_px; 	
	wire [10:0] rrxing_05_address = (rrxing_05y * TILE) + rrxing_05x; 
	
	wire within_rrxing_05 = ((xPixel_internal >= rrxing_05x_px) && (xPixel_internal < rrxing_05x_px + 6'd40) && 
									(yPixel_internal >= rrxing_05y_px) && (yPixel_internal < rrxing_05y_px + 6'd40)); 
	
	reg within_rrxing_05_delayed; 
	// accounting for memory reading clk delay
	always @ (posedge vga_pix_clk) begin 
		within_rrxing_05_delayed <= within_rrxing_05; 
	end 
	
	wire rrxing_05_transparent = ((rrxing_05_color[23:16] < 8'h10) && (rrxing_05_color[15:8] < 8'h10) && (rrxing_05_color[7:0] < 8'h10) );  
	wire show_rrxing_05 = within_rrxing_05_delayed && !rrxing_05_transparent; 
	
	
	
	// RRxing post: (15,5):
	wire [9:0] rrxing_1505x_px = 4'd15 * TILE; 	
	wire [9:0] rrxing_1505y_px = 4'd5 * TILE; 	
	
	wire [23:0] rrxing_1505_color; 
	wire [6:0] rrxing_1505x = xPixel_internal - rrxing_1505x_px; 	
	wire [6:0] rrxing_1505y = yPixel_internal - rrxing_1505y_px; 	
	wire [10:0] rrxing_1505_address = (rrxing_1505y * TILE) + rrxing_1505x; 
	
	wire within_rrxing_1505 = ((xPixel_internal >= rrxing_1505x_px) && (xPixel_internal < rrxing_1505x_px + 6'd40) && 
									(yPixel_internal >= rrxing_1505y_px) && (yPixel_internal < rrxing_1505y_px + 6'd40)); 
	
	reg within_rrxing_1505_delayed; 
	// accounting for memory reading clk delay
	always @ (posedge vga_pix_clk) begin 
		within_rrxing_1505_delayed <= within_rrxing_1505; 
	end 
	
	wire rrxing_1505_transparent = ((rrxing_1505_color[23:16] < 8'h10) && (rrxing_1505_color[15:8] < 8'h10) && (rrxing_1505_color[7:0] < 8'h10));  
	wire show_rrxing_1505 = within_rrxing_1505_delayed && !rrxing_1505_transparent; 
	
	 
	// RRxing post: (0,7):
	wire [9:0] rrxing_07x_px = 4'd0 * TILE; 
	wire [9:0] rrxing_07y_px = 4'd7 * TILE; 	
	
	wire [23:0] rrxing_07_color; 
	wire [6:0] rrxing_07x = xPixel_internal - rrxing_07x_px; 	
	wire [6:0] rrxing_07y = yPixel_internal - rrxing_07y_px; 	
	wire [10:0] rrxing_07_address = (rrxing_07y * TILE) + rrxing_07x; 
	
	wire within_rrxing_07 = ((xPixel_internal >= rrxing_07x_px) && (xPixel_internal < rrxing_07x_px + 6'd40) && 
									(yPixel_internal >= rrxing_07y_px) && (yPixel_internal < rrxing_07y_px + 6'd40)); 
	
	reg within_rrxing_07_delayed; 
	// accounting for memory reading clk delay
	always @ (posedge vga_pix_clk) begin 
		within_rrxing_07_delayed <= within_rrxing_07; 
	end 
	wire rrxing_07_transparent = ((rrxing_07_color[23:16] < 8'h10) && (rrxing_07_color[15:8] < 8'h10) && (rrxing_07_color[7:0] < 8'h10));  
	wire show_rrxing_07 = within_rrxing_07_delayed && !rrxing_07_transparent;  
	 
	 
	// RRxing post: (15,7):
	wire [9:0] rrxing_1507x_px = 4'd15 * TILE; 	// Grid position x = 0 
	wire [9:0] rrxing_1507y_px = 4'd7 * TILE; 	// Grid position y = 5 
	
	wire [23:0] rrxing_1507_color; 
	wire [6:0] rrxing_1507x = xPixel_internal - rrxing_1507x_px; 	
	wire [6:0] rrxing_1507y = yPixel_internal - rrxing_1507y_px; 
	wire [10:0] rrxing_1507_address = (rrxing_1507y * TILE) + rrxing_1507x; 
	
	wire within_rrxing_1507 = ((xPixel_internal >= rrxing_1507x_px) && (xPixel_internal < rrxing_1507x_px + 6'd40) && 
									(yPixel_internal >= rrxing_1507y_px) && (yPixel_internal < rrxing_1507y_px + 6'd40)); 
	
	reg within_rrxing_1507_delayed; 
	// accounting for memory reading clk delay
	always @ (posedge vga_pix_clk) begin 
		within_rrxing_1507_delayed <= within_rrxing_1507; 
	end 
	wire rrxing_1507_transparent = ((rrxing_1507_color[23:16] < 8'h10) && (rrxing_1507_color[15:8] < 8'h10) && (rrxing_1507_color[7:0] < 8'h10) );  
	wire show_rrxing_1507 = within_rrxing_1507_delayed && !rrxing_1507_transparent;   
	 	
	
	
////////////////////////////////////////// ROM MODULE INSTATIATION FOR RAILROAD Gates //////////////////////////////////////////////////////////////////////////////////	 
	// Railroad Gate 1: (1,5) -> (4, 5):
	wire [9:0] gate1x_px = 4'd1 * TILE; 	// starting x position 
	wire [9:0] gate1y_px = 4'd5 * TILE; 	// starting y position 	
	
	wire [23:0] gate1_color; 
	wire [10:0] gate1x = xPixel_internal - gate1x_px; 	
	wire [5:0] gate1y = yPixel_internal - gate1y_px; 	
	wire [13:0] gate1_address = (gate1y * (4 * TILE)) + gate1x; 
	
	wire within_gate1 = ((xPixel_internal >= gate1x_px) && (xPixel_internal < gate1x_px + (4 * TILE)) && 
									(yPixel_internal >= gate1y_px) && (yPixel_internal < gate1y_px + TILE)); 
	
	reg within_gate1_delayed; 
	// accounting for memory reading clk delay
	always @ (posedge vga_pix_clk) begin 
		within_gate1_delayed <= within_gate1; 
	end 
	wire gate1_transparent = ((gate1_color[23:16] < 8'h10) && (gate1_color[15:8] < 8'h10) && (gate1_color[7:0] < 8'h10) );  
	wire show_gate1 = within_gate1_delayed && !gate1_transparent; 
	
	

	// Railroad Gate 2: (11,5) -> (14, 5):
	wire [9:0] gate2x_px = 4'd11 * TILE;  
	wire [9:0] gate2y_px = 4'd5 * TILE; 	
	
	wire [23:0] gate2_color; 
	wire [10:0] gate2x = xPixel_internal - gate2x_px; 	
	wire [5:0] gate2y = yPixel_internal - gate2y_px; 	
	wire [13:0] gate2_address = (gate2y * (4 * TILE)) + gate2x; 
	
	wire within_gate2 = ((xPixel_internal >= gate2x_px) && (xPixel_internal < gate2x_px + (4 * TILE)) && 
									(yPixel_internal >= gate2y_px) && (yPixel_internal < gate2y_px + TILE)); 
	
	reg within_gate2_delayed; 
	
	// accounting for memory reading clk delay
	always @ (posedge vga_pix_clk) begin 
		within_gate2_delayed <= within_gate2; 
	end 
	wire gate2_transparent = ((gate2_color[23:16] < 8'h10) && (gate2_color[15:8] < 8'h10) && (gate2_color[7:0] < 8'h10) );  
	wire show_gate2 = within_gate2_delayed && !gate2_transparent; 
	
	
	
	// Railroad Gate 3: (1,7) -> (4,7):
	wire [9:0] gate13x_px = 4'd1 * TILE; 	
	wire [9:0] gate13y_px = 4'd7 * TILE; 	 	
	
	wire [23:0] gate13_color; 
	wire [10:0] gate13x = xPixel_internal - gate13x_px; 	
	wire [5:0] gate13y = yPixel_internal - gate13y_px; 	
	wire [13:0] gate13_address = (gate13y * (4 * TILE)) + gate13x; 
	
	wire within_gate13 = ((xPixel_internal >= gate13x_px) && (xPixel_internal < gate13x_px + (4 * TILE)) && 
									(yPixel_internal >= gate13y_px) && (yPixel_internal < gate13y_px + TILE)); 
	
	reg within_gate13_delayed; 
	
	// accounting for memory reading clk delay
	always @ (posedge vga_pix_clk) begin 
		within_gate13_delayed <= within_gate13; 
	end 
	wire gate13_transparent = ((gate13_color[23:16] < 8'h10) && (gate13_color[15:8] < 8'h10) && (gate13_color[7:0] < 8'h10));  
	wire show_gate13 = within_gate13_delayed && !gate13_transparent; 
	

	// Railroad Gate 4: (11,7) -> (14,7):
	wire [9:0] gate14x_px = 4'd11 * TILE; 
	wire [9:0] gate14y_px = 4'd7 * TILE; 		
	
	wire [23:0] gate14_color; 
	wire [10:0] gate14x = xPixel_internal - gate14x_px; 	
	wire [5:0] gate14y = yPixel_internal - gate14y_px; 	
	wire [13:0] gate14_address = (gate14y * (4 * TILE)) + gate14x; 
	
	wire within_gate14 = ((xPixel_internal >= gate14x_px) && (xPixel_internal < gate14x_px + (4 * TILE)) && 
									(yPixel_internal >= gate14y_px) && (yPixel_internal < gate14y_px + TILE)); 
	
	reg within_gate14_delayed; 
	
	// accounting for memory reading clk delay
	always @ (posedge vga_pix_clk) begin 
		within_gate14_delayed <= within_gate14; 
	end 
	wire gate14_transparent = ((gate14_color[23:16] < 8'h10) && (gate14_color[15:8] < 8'h10) && (gate14_color[7:0] < 8'h10) );  
	wire show_gate14 = within_gate14_delayed && !gate14_transparent; 
	
	

////////////////////////////////// ROM Display Logic for "Stupid Questions?" Trees /////////////////////////////////////
	wire [23:0] sqtree_color; 
	wire [23:0] demtree_color; 
	wire [23:0] extree_color; 
	wire [10:0] sqtree_address; 

	// defining all positions
	// Tree @ (0,1)
	wire [9:0] sqtree1x_px = 4'd0 * TILE; 	// Grid position x = 0 
	wire [9:0] sqtree1y_px = 4'd1 * TILE; 	// Grid position y = 5 
	wire [6:0] sqtreex = xPixel_internal - sqtree1x_px; 	
	wire [6:0] sqtreey = yPixel_internal - sqtree1y_px; 

	wire within_sqtree1 = ((xPixel_internal >= sqtree1x_px) && (xPixel_internal < sqtree1x_px + TILE) && 
									(yPixel_internal >= sqtree1y_px) && (yPixel_internal < sqtree1y_px + TILE)); 
	
	// Tree @ (4, 1)
	wire [9:0] sqtree2x_px = 4'd4 * TILE; 	
	wire [9:0] sqtree2y_px = 4'd1 * TILE; 
	wire [6:0] sqtree2x = xPixel_internal - sqtree2x_px; 	
	wire [6:0] sqtree2y = yPixel_internal - sqtree2y_px; 

	wire within_sqtree2 = ((xPixel_internal >= sqtree2x_px) && (xPixel_internal < sqtree2x_px + TILE) && 
									(yPixel_internal >= sqtree2y_px) && (yPixel_internal < sqtree2y_px + TILE)); 
	
	// Tree @ (10, 1)
	wire [9:0] sqtree3x_px = 4'd10 * TILE; 	
	wire [9:0] sqtree3y_px = 4'd1 * TILE; 	
	wire [6:0] sqtree3x = xPixel_internal - sqtree3x_px; 	
	wire [6:0] sqtree3y = yPixel_internal - sqtree3y_px; 

	wire within_sqtree3 = ((xPixel_internal >= sqtree3x_px) && (xPixel_internal < sqtree3x_px + TILE) && 
									(yPixel_internal >= sqtree3y_px) && (yPixel_internal < sqtree3y_px + TILE)); 
	
	// Tree @ (13, 1)
	wire [9:0] sqtree4x_px = 4'd13 * TILE; 	
	wire [9:0] sqtree4y_px = 4'd1 * TILE; 	
	wire [6:0] sqtree4x = xPixel_internal - sqtree4x_px; 	
	wire [6:0] sqtree4y = yPixel_internal - sqtree4y_px; 

	wire within_sqtree4 = ((xPixel_internal >= sqtree4x_px) && (xPixel_internal < sqtree4x_px + TILE) && 
									(yPixel_internal >= sqtree4y_px) && (yPixel_internal < sqtree4y_px + TILE));
	
	
	// Tree @ (1,1)
	wire [9:0] extree1x_px = 4'd1 * TILE; 	
	wire [9:0] extree1y_px = 4'd1 * TILE; 	
	wire [6:0] extreex = xPixel_internal - extree1x_px; 	
	wire [6:0] extreey = yPixel_internal - extree1y_px; 
	
	wire within_extree1 = ((xPixel_internal >= sqtree4x_px) && (xPixel_internal < sqtree4x_px + TILE) && 
									(yPixel_internal >= sqtree4y_px) && (yPixel_internal < sqtree4y_px + TILE)); 
	
	// Tree @ (6, 1)
	wire [9:0] extree2x_px = 4'd6 * TILE; 	
	wire [9:0] extree2y_px = 4'd1 * TILE; 
	wire [6:0] extree2x = xPixel_internal - extree2x_px; 	
	wire [6:0] extree2y = yPixel_internal - extree2y_px; 

	wire within_extree2 = ((xPixel_internal >= extree2x_px) && (xPixel_internal < extree2x_px + TILE) && 
									(yPixel_internal >= extree2y_px) && (yPixel_internal < extree2y_px + TILE)); 
	
	// Tree @ (12, 1)
	wire [9:0] extree3x_px = 4'd12 * TILE; 	
	wire [9:0] extree3y_px = 4'd1 * TILE; 	
	wire [6:0] extree3x = xPixel_internal - extree3x_px; 	
	wire [6:0] extree3y = yPixel_internal - extree3y_px; 

	wire within_extree3 = ((xPixel_internal >= extree3x_px) && (xPixel_internal < extree3x_px + TILE) && 
									(yPixel_internal >= extree3y_px) && (yPixel_internal < extree3y_px + TILE)); 
									
									
	// Tree @ (3,1)
	wire [9:0] demtree1x_px = 4'd3 * TILE; 	
	wire [9:0] demtree1y_px = 4'd1 * TILE; 	
	wire [6:0] demtreex = xPixel_internal - demtree1x_px; 	
	wire [6:0] demtreey = yPixel_internal - demtree1y_px; 

	wire within_demtree1 = ((xPixel_internal >= demtree1x_px) && (xPixel_internal < demtree1x_px + TILE) && 
									(yPixel_internal >= demtree1y_px) && (yPixel_internal < demtree1y_px + TILE)); 
	
	// Tree @ (8, 1)
	wire [9:0] demtree2x_px = 4'd8 * TILE; 	
	wire [9:0] demtree2y_px = 4'd1 * TILE; 
	wire [6:0] demtree2x = xPixel_internal - demtree2x_px; 	
	wire [6:0] demtree2y = yPixel_internal - demtree2y_px; 

	wire within_demtree2 = ((xPixel_internal >= demtree2x_px) && (xPixel_internal < demtree2x_px + TILE) && 
									(yPixel_internal >= demtree2y_px) && (yPixel_internal < demtree2y_px + TILE)); 
	
	// Tree @ (15, 1)
	wire [9:0] demtree3x_px = 4'd15 * TILE; 	
	wire [9:0] demtree3y_px = 4'd1 * TILE; 	
	wire [6:0] demtree3x = xPixel_internal - demtree3x_px; 	
	wire [6:0] demtree3y = yPixel_internal - demtree3y_px; 

	wire within_demtree3 = ((xPixel_internal >= demtree3x_px) && (xPixel_internal < demtree3x_px + TILE) && 
									(yPixel_internal >= demtree3y_px) && (yPixel_internal < demtree3y_px + TILE)); 
									
									
									
	// Mux for ROM address 
	reg [10:0] sqtree_address_mux; 
	
	always @ (*) begin 
		if(within_sqtree1) begin
			sqtree_address_mux = (sqtreey * TILE) + sqtreex; 
		end 
		else if(within_sqtree2) begin
			sqtree_address_mux = (sqtree2y * TILE) + sqtree2x; 
		end 
		else if(within_sqtree3) begin
			sqtree_address_mux = (sqtree3y * TILE) + sqtree3x; 
		end 
		else if(within_sqtree4) begin
			sqtree_address_mux = (sqtree4y * TILE) + sqtree4x; 
		end 
		else if(within_extree1) begin 
				sqtree_address_mux = (extreey * TILE) + extreex; 
			end 
		else if(within_extree2) begin 
				sqtree_address_mux = (extree2y * TILE) + extree2x; 
			end
		else if(within_extree3) begin 
				sqtree_address_mux = (extree3y * TILE) + extree3x; 
		end
		else if(within_demtree1) begin 
				sqtree_address_mux = (demtreey * TILE) + demtreex; 
			end 
		else if(within_demtree2) begin 
				sqtree_address_mux = (demtree2y * TILE) + demtree2x; 
		end
		else if(within_demtree3) begin 
				sqtree_address_mux = (demtree3y * TILE) + demtree3x; 
			end	
		else 
			sqtree_address_mux = 11'd0; 
	end 
	
	
	assign sqtree_address = sqtree_address_mux; 
	
	// combined transpaarency check 
	wire within_any_sqtree = within_sqtree1 || within_sqtree2 || within_sqtree3 || within_sqtree4 || within_extree1 || within_extree2 || within_extree3 || within_demtree1 || within_demtree2 || within_demtree3; 
	reg within_any_sqtree_delayed; 
	
	always @ (posedge vga_pix_clk) begin 
		within_any_sqtree_delayed <= within_any_sqtree; 
	end 
	
	wire sqtree_transparent = ((sqtree_color[23:16] < 8'h10) && (sqtree_color[15:8] < 8'h10) && (sqtree_color[7:0] < 8'h10) &&
										(demtree_color[23:16] < 8'h10) && (demtree_color[15:8] < 8'h10) && (demtree_color[7:0] < 8'h10) && 
										(extree_color[23:16] < 8'h10) && (extree_color[15:8] < 8'h10) && (extree_color[7:0] < 8'h10));  
	wire show_sqtree = (within_any_sqtree_delayed && !sqtree_transparent); 

	  
	 
	
//////////////////////////////////////////////////////// GAME DISPLAY LOGIC ////////////////////////////////////////////////////////////////////	 	 
	 
	 
    // ------------ GAME RENDERING ------------
    //
    // Order (topmost first in the chain):
    //  1. Players (only if alive)
    //  2. Hearts HUD row (y == 0)
    //  3. Train body (moving)
    //  4. Train track (row 6)
    //  5. Streets (rows 2,3,9,10)
    //  6. Posts (white)
    //  7. Trees on row 1
    //  8. Fallback white

    always @(*) begin
        vga_color = 24'h000000;  // default black

        if (game_enable == 1'b1) begin
            if (active_pixels == 1'b1) begin
				
					 if (start_screen) begin
						  // START state: solid green screen
						  vga_color = 24'h00F350; // test: green
					 end
					 else if (end_screen) begin
						  vga_color = 24'h7209B7; 			// background: deep purple 
							// this inner logic is hardcoding the letters within the end screen
							if(	(((xPixel_internal > 119) && (xPixel_internal <= 131))	&& ((yPixel_internal > 39) && (yPixel_internal <= 61)) ||
									((xPixel_internal > 130) && (xPixel_internal <= 143)) && ((yPixel_internal > 56) && (yPixel_internal <= 79)) || 
									((xPixel_internal > 143) && (xPixel_internal <= 154)) && ((yPixel_internal > 39) && (yPixel_internal <= 61)))||	//Y
									
									(((xPixel_internal > 160) && (xPixel_internal <= 172)) && ((yPixel_internal > 39) && (yPixel_internal <= 79)) ||
									((xPixel_internal > 160) && (xPixel_internal <= 195)) && ((yPixel_internal > 69) && (yPixel_internal <= 79)) || 
									((xPixel_internal > 160) && (xPixel_internal <= 195)) && ((yPixel_internal > 39) && (yPixel_internal <= 49)) || 
									((xPixel_internal > 183) && (xPixel_internal <= 195)) && ((yPixel_internal > 39) && (yPixel_internal <= 79)))||		// O
									
									(((xPixel_internal > 201) && (xPixel_internal <= 213)) && ((yPixel_internal > 39) && (yPixel_internal <= 79)) || 
									((xPixel_internal > 201) && (xPixel_internal <= 236)) && ((yPixel_internal > 69) && (yPixel_internal <= 79)) ||
									((xPixel_internal > 224) && (xPixel_internal <= 236)) && ((yPixel_internal > 39) && (yPixel_internal <= 79)))||	 //U
									
									(((xPixel_internal > 340) && (xPixel_internal <= 352)) && ((yPixel_internal > 39) && (yPixel_internal <= 79)) ||
									((xPixel_internal > 340) && (xPixel_internal <= 375)) && ((yPixel_internal > 54) && (yPixel_internal <= 64)) || 
									((xPixel_internal > 363) && (xPixel_internal <= 375)) && ((yPixel_internal > 39) && (yPixel_internal <= 79)))|| 		// H
									
									(((xPixel_internal > 381) && (xPixel_internal <= 393)) && ((yPixel_internal > 39) && (yPixel_internal <= 79)) ||
									((xPixel_internal > 381) && (xPixel_internal <= 416)) && ((yPixel_internal > 39) && (yPixel_internal <= 49)) ||
									((xPixel_internal > 381) && (xPixel_internal <= 416)) && ((yPixel_internal > 59) && (yPixel_internal <= 69)) ||
									((xPixel_internal > 404) && (xPixel_internal <= 416)) && ((yPixel_internal > 39) && (yPixel_internal <= 79))) ||  // A
										
									(((xPixel_internal > 422) && (xPixel_internal <= 434)) && ((yPixel_internal > 39) && (yPixel_internal <= 59)) ||
									((xPixel_internal > 433) && (xPixel_internal <= 437)) && ((yPixel_internal > 58) && (yPixel_internal <= 65)) || 
									((xPixel_internal > 436) && (xPixel_internal <= 440)) && ((yPixel_internal > 64) && (yPixel_internal <= 71)) ||
									((xPixel_internal > 439) && (xPixel_internal <= 443)) && ((yPixel_internal > 70) && (yPixel_internal <= 79)) ||
									// finish V later...
									((xPixel_internal > 445) && (xPixel_internal <= 457)) && ((yPixel_internal > 39) && (xPixel_internal <= 59))) || 

									
									(((xPixel_internal > 463) && (xPixel_internal <= 498)) && ((yPixel_internal > 39) && (yPixel_internal <= 49)) ||	// E
									((xPixel_internal > 463) && (xPixel_internal <= 475)) && ((yPixel_internal > 39) && (yPixel_internal <= 79))  ||
									((xPixel_internal > 463) && (xPixel_internal <= 485)) && ((yPixel_internal > 58) && (yPixel_internal <= 65)) ||
									((xPixel_internal > 463) && (xPixel_internal <= 498)) && ((yPixel_internal > 69) && (yPixel_internal <= 79))) || 

									
									(((xPixel_internal > 59) && (xPixel_internal <= 94)) && ((yPixel_internal > 124) && (yPixel_internal <= 134)) ||	//S
									((xPixel_internal > 59) && (xPixel_internal <= 71)) && ((yPixel_internal > 124) && (yPixel_internal <= 144)) ||
									((xPixel_internal > 59) && (xPixel_internal <= 94)) && ((yPixel_internal > 139) && (yPixel_internal <= 149)) ||
									((xPixel_internal > 82) && (xPixel_internal <= 94)) && ((yPixel_internal > 149) && (yPixel_internal <= 154)) ||
									((xPixel_internal > 59) && (xPixel_internal <= 94)) && ((yPixel_internal > 154) && (yPixel_internal <= 164))) ||
									
									
									(((xPixel_internal > 100) && (xPixel_internal <= 112)) && ((yPixel_internal > 124) && (yPixel_internal <= 164)) ||  // U
									((xPixel_internal > 128) && (xPixel_internal <= 140)) && ((yPixel_internal > 124) && (yPixel_internal <= 164)) ||
									((xPixel_internal > 100) && (xPixel_internal <= 140)) && ((yPixel_internal > 154) && (yPixel_internal <= 164))) ||
									
									(((xPixel_internal > 146) && (xPixel_internal <=181)) && ((yPixel_internal > 124) && (yPixel_internal <= 134)) ||	//C
									((xPixel_internal > 146) && (xPixel_internal <= 158)) && ((yPixel_internal > 124) && (yPixel_internal <= 164)) ||
									((xPixel_internal > 146) && (xPixel_internal <= 181)) && ((yPixel_internal > 154) && (yPixel_internal <= 164)))||
									
									(((xPixel_internal > 187) && (xPixel_internal <= 222)) && ((yPixel_internal > 124) && (yPixel_internal <= 134)) ||	// C 
									((xPixel_internal > 187) && (xPixel_internal <= 199)) && ((yPixel_internal > 124) && (yPixel_internal <= 164)) ||
									((xPixel_internal > 187) && (xPixel_internal <= 222)) && ((yPixel_internal > 154) && (yPixel_internal <= 164)))|| 
									
									(((xPixel_internal > 228) && (xPixel_internal <= 263)) && ((yPixel_internal > 124) && (yPixel_internal <= 134)) ||	// E 
									((xPixel_internal > 228) && (xPixel_internal <= 241)) && ((yPixel_internal > 124) && (yPixel_internal <= 164))  ||
									((xPixel_internal > 228) && (xPixel_internal <= 251)) && ((yPixel_internal > 143) && (yPixel_internal <= 150)) ||
									((xPixel_internal > 228) && (xPixel_internal <= 263)) && ((yPixel_internal > 154) && (yPixel_internal <= 164))) ||
									
									(((xPixel_internal > 269) && (xPixel_internal <= 304)) && ((yPixel_internal > 124) && (yPixel_internal <= 134)) ||	//S
									((xPixel_internal > 269) && (xPixel_internal <= 281)) && ((yPixel_internal > 124) && (yPixel_internal <= 144)) ||
									((xPixel_internal > 269) && (xPixel_internal <= 304)) && ((yPixel_internal > 139) && (yPixel_internal <= 149)) ||
									((xPixel_internal > 292) && (xPixel_internal <= 304)) && ((yPixel_internal > 149) && (yPixel_internal <= 154)) ||
									((xPixel_internal > 269) && (xPixel_internal <= 304)) && ((yPixel_internal > 154) && (yPixel_internal <= 164))) ||
									
									(((xPixel_internal > 310) && (xPixel_internal <= 345)) && ((yPixel_internal > 124) && (yPixel_internal <= 134)) ||	//S
									((xPixel_internal > 310) && (xPixel_internal <= 322)) && ((yPixel_internal > 124) && (yPixel_internal <= 144)) ||
									((xPixel_internal > 310) && (xPixel_internal <= 345)) && ((yPixel_internal > 139) && (yPixel_internal <= 149)) ||
									((xPixel_internal > 333) && (xPixel_internal <= 345)) && ((yPixel_internal > 149) && (yPixel_internal <= 154)) ||
									((xPixel_internal > 310) && (xPixel_internal <= 345)) && ((yPixel_internal > 154) && (yPixel_internal <= 164))) ||
									
									(((xPixel_internal > 351) && (xPixel_internal <= 386)) && ((yPixel_internal > 124) && (yPixel_internal <= 134)) ||	// F 
									((xPixel_internal > 351) && (xPixel_internal <= 364)) && ((yPixel_internal > 124) && (yPixel_internal <= 164))  ||
									((xPixel_internal > 351) && (xPixel_internal <= 374)) && ((yPixel_internal > 145) && (yPixel_internal <= 152))) || 
									
									(((xPixel_internal > 392) && (xPixel_internal <= 404)) && ((yPixel_internal > 124) && (yPixel_internal <= 164)) ||  // U
									((xPixel_internal > 420) && (xPixel_internal <= 432)) && ((yPixel_internal > 124) && (yPixel_internal <= 164)) ||
									((xPixel_internal > 392) && (xPixel_internal <= 432)) && ((yPixel_internal > 154) && (yPixel_internal <= 164))) ||
									
									(((xPixel_internal > 433) && (xPixel_internal <= 446)) && ((yPixel_internal > 124) && (yPixel_internal <= 164))  ||  //L
									((xPixel_internal > 433) && (xPixel_internal <= 468)) && ((yPixel_internal > 154) && (yPixel_internal <= 164))) ||
									
									(((xPixel_internal > 474) && (xPixel_internal <= 486)) && ((yPixel_internal > 124) && (yPixel_internal <= 164))  ||  //L
									((xPixel_internal > 474) && (xPixel_internal <= 509)) && ((yPixel_internal > 154) && (yPixel_internal <= 164))) ||
									
									(((xPixel_internal > 515) && (xPixel_internal <= 527))	&& ((yPixel_internal > 124) && (yPixel_internal <= 146)) ||
									((xPixel_internal > 527) && (xPixel_internal <= 540)) && ((yPixel_internal > 141) && (yPixel_internal <= 164)) || 
									((xPixel_internal > 538) && (xPixel_internal <= 550)) && ((yPixel_internal > 124) && (yPixel_internal <= 146)))||	//Y
									
									(((xPixel_internal > 556) && (xPixel_internal <= 591)) && ((yPixel_internal > 124) && (yPixel_internal <= 134)) || //?
									((xPixel_internal > 579) && (xPixel_internal <= 591)) && ((yPixel_internal > 124) && (yPixel_internal <= 149)) ||
									((xPixel_internal > 574) && (xPixel_internal <= 591)) && ((yPixel_internal > 139) && (yPixel_internal <= 149)) || 
									((xPixel_internal > 570) && (xPixel_internal <= 576)) && ((yPixel_internal > 139) && (yPixel_internal <= 154)) ||
									((xPixel_internal > 570) && (xPixel_internal <= 576)) && ((yPixel_internal > 159) && (yPixel_internal <= 164)))||
									
									(((xPixel_internal > 19) && (xPixel_internal <= 54)) && ((yPixel_internal > 204) && (yPixel_internal <= 214)) ||	// C 
									((xPixel_internal > 19) && (xPixel_internal <= 31)) && ((yPixel_internal > 204) && (yPixel_internal <= 244)) ||
									((xPixel_internal > 19) && (xPixel_internal <= 54)) && ((yPixel_internal > 234) && (yPixel_internal <= 244)))|| 
									
									
									(((xPixel_internal > 60) && (xPixel_internal <= 72)) && ((yPixel_internal > 204) && (yPixel_internal <= 244)) ||
									((xPixel_internal > 60) && (xPixel_internal <= 95)) && ((yPixel_internal > 234) && (yPixel_internal <= 244)) || 
									((xPixel_internal > 60) && (xPixel_internal <= 95)) && ((yPixel_internal > 204) && (yPixel_internal <= 214)) || 
									((xPixel_internal > 83) && (xPixel_internal <= 95)) && ((yPixel_internal > 204) && (yPixel_internal <= 244)))||		// O
									

								   (((xPixel_internal > 101) && (xPixel_internal <= 113)) && ((yPixel_internal > 204) && (yPixel_internal <= 244)) ||   // left vertical
								   ((xPixel_internal > 124) && (xPixel_internal <= 136)) && ((yPixel_internal > 204) && (yPixel_internal <= 244)) ||   // right vertical

							    	 ((xPixel_internal > 113) && (xPixel_internal <= 118)) && ((yPixel_internal > 204) && (yPixel_internal <= 214)) ||
								   ((xPixel_internal > 118) && (xPixel_internal <= 122)) && ((yPixel_internal > 214) && (yPixel_internal <= 224)) ||
								   ((xPixel_internal > 122) && (xPixel_internal <= 126)) && ((yPixel_internal > 214) && (yPixel_internal <= 224)) ||
								   ((xPixel_internal > 126) && (xPixel_internal <= 131)) && ((yPixel_internal > 204) && (yPixel_internal <= 214)) ||
								   ((xPixel_internal > 118) && (xPixel_internal <= 126)) && ((yPixel_internal > 224) && (yPixel_internal <= 244))) ||   // M
									
									(((xPixel_internal > 142) && (xPixel_internal <= 154)) && ((yPixel_internal > 204) && (yPixel_internal <= 244)) ||	// P
									((xPixel_internal > 165) && (xPixel_internal <= 177)) && ((yPixel_internal > 204) && (yPixel_internal <= 229))  ||
									((xPixel_internal > 142) && (xPixel_internal <= 177)) && ((yPixel_internal > 219) && (yPixel_internal <= 229))  ||
									((xPixel_internal > 142) && (xPixel_internal <= 177)) && ((yPixel_internal > 204) && (yPixel_internal <= 214))) || 
									
									(((xPixel_internal > 183) && (xPixel_internal <= 195)) && ((yPixel_internal > 204) && (yPixel_internal <= 244))  ||  //L
									((xPixel_internal > 183) && (xPixel_internal <= 218)) && ((yPixel_internal > 234) && (yPixel_internal <= 244))) ||
									
									(((xPixel_internal > 224) && (xPixel_internal <= 259)) && ((yPixel_internal > 204) && (yPixel_internal <= 214)) ||	// E 
									((xPixel_internal > 224) && (xPixel_internal <= 237)) && ((yPixel_internal > 204) && (yPixel_internal <= 244))  ||
									((xPixel_internal > 224) && (xPixel_internal <= 247)) && ((yPixel_internal > 219) && (yPixel_internal <= 229)) ||
									((xPixel_internal > 224) && (xPixel_internal <= 259)) && ((yPixel_internal > 234) && (yPixel_internal <= 244))) ||
									
									(((xPixel_internal > 265) && (xPixel_internal <= 300)) && ((yPixel_internal > 204) && (yPixel_internal <= 214)) ||
									((xPixel_internal > 277) && (xPixel_internal <= 289)) && ((yPixel_internal > 204) && (yPixel_internal <= 244))) ||  // T

									
									(((xPixel_internal > 306) && (xPixel_internal <= 341)) && ((yPixel_internal > 204) && (yPixel_internal <= 214)) ||	// E 
									((xPixel_internal > 306) && (xPixel_internal <= 318)) && ((yPixel_internal > 204) && (yPixel_internal <= 244))  ||
									((xPixel_internal > 306) && (xPixel_internal <= 328)) && ((yPixel_internal > 219) && (yPixel_internal <= 229)) ||
									((xPixel_internal > 306) && (xPixel_internal <= 341)) && ((yPixel_internal > 234) && (yPixel_internal <= 244))) ||
									
									(((xPixel_internal > 347) && (xPixel_internal <= 359)) && ((yPixel_internal > 204) && (yPixel_internal <= 244)) || // D
									((xPixel_internal > 347) && (xPixel_internal <= 370)) && ((yPixel_internal > 204) && (yPixel_internal <= 214)) ||
									((xPixel_internal > 368) && (xPixel_internal <= 372)) && ((yPixel_internal > 214) && (yPixel_internal <= 219)) ||
									((xPixel_internal > 370) && (xPixel_internal <= 374)) && ((yPixel_internal > 219) && (yPixel_internal <= 229)) ||
									((xPixel_internal > 368) && (xPixel_internal <= 372)) && ((yPixel_internal > 229) && (yPixel_internal <= 234)) ||
									((xPixel_internal > 347) && (xPixel_internal <= 370)) && ((yPixel_internal > 234) && (yPixel_internal <= 244)))||
									
									(((xPixel_internal > 578) && (xPixel_internal <= 590)) && ((yPixel_internal > 364) && (yPixel_internal <= 390)) || // !
									((xPixel_internal > 578) && (xPixel_internal <= 590)) && ((yPixel_internal > 399) && (yPixel_internal <= 404))) ||
									
									// ------------------- "THE"  (y: 244 -> 284) -------------------

									 // T  (x: 441 -> 476)
									 (((xPixel_internal > 441) && (xPixel_internal <= 476)) && ((yPixel_internal > 244) && (yPixel_internal <= 254)) ||  // top bar
									  ((xPixel_internal > 453) && (xPixel_internal <= 465)) && ((yPixel_internal > 244) && (yPixel_internal <= 284)))   // stem
								 ||
									 // H  (x: 482 -> 517)
									 (((xPixel_internal > 482) && (xPixel_internal <= 494)) && ((yPixel_internal > 244) && (yPixel_internal <= 284)) ||  // left bar
									  ((xPixel_internal > 505) && (xPixel_internal <= 517)) && ((yPixel_internal > 244) && (yPixel_internal <= 284)) ||  // right bar
									  ((xPixel_internal > 482) && (xPixel_internal <= 517)) && ((yPixel_internal > 262) && (yPixel_internal <= 272)))    // middle bar
								 ||
									 // E  (x: 523 -> 558)
									 (((xPixel_internal > 523) && (xPixel_internal <= 535)) && ((yPixel_internal > 244) && (yPixel_internal <= 284)) ||  // left bar
									  ((xPixel_internal > 523) && (xPixel_internal <= 558)) && ((yPixel_internal > 244) && (yPixel_internal <= 254)) ||  // top bar
									  ((xPixel_internal > 523) && (xPixel_internal <= 552)) && ((yPixel_internal > 262) && (yPixel_internal <= 272)) ||  // mid bar
									  ((xPixel_internal > 523) && (xPixel_internal <= 558)) && ((yPixel_internal > 274) && (yPixel_internal <= 284))) ||    // bottom bar


								// ------------------- "FINAL"  (y: 304 -> 344) -------------------
								
									 // F  (x: 19 -> 54)
									 (((xPixel_internal > 19) && (xPixel_internal <= 31)) && ((yPixel_internal > 304) && (yPixel_internal <= 344)) ||    // left bar
									  ((xPixel_internal > 19) && (xPixel_internal <= 54)) && ((yPixel_internal > 304) && (yPixel_internal <= 314)) ||    // top bar
									  ((xPixel_internal > 19) && (xPixel_internal <= 49)) && ((yPixel_internal > 322) && (yPixel_internal <= 332))) ||     // mid bar

									 // I  (x: 60 -> 95)
									 (((xPixel_internal > 60) && (xPixel_internal <= 95)) && ((yPixel_internal > 304) && (yPixel_internal <= 314)) ||    // top bar
									  ((xPixel_internal > 71) && (xPixel_internal <= 83)) && ((yPixel_internal > 304) && (yPixel_internal <= 344)) ||    // stem
									  ((xPixel_internal > 60) && (xPixel_internal <= 95)) && ((yPixel_internal > 334) && (yPixel_internal <= 344))) ||     // bottom bar
							
									 // N  (x: 101 -> 136)
									 (((xPixel_internal > 101) && (xPixel_internal <= 113)) && ((yPixel_internal > 304) && (yPixel_internal <= 344)) ||  // left bar
									  ((xPixel_internal > 124) && (xPixel_internal <= 136)) && ((yPixel_internal > 304) && (yPixel_internal <= 344)) ||  // right bar
									  // diagonal (chunked)
									  ((xPixel_internal > 112) && (xPixel_internal <= 118)) && ((yPixel_internal > 310) && (yPixel_internal <= 320)) ||
									  ((xPixel_internal > 116) && (xPixel_internal <= 122)) && ((yPixel_internal > 320) && (yPixel_internal <= 330)) ||
									  ((xPixel_internal > 120) && (xPixel_internal <= 126)) && ((yPixel_internal > 330) && (yPixel_internal <= 340))) ||
					
									 // A  (x: 142 -> 177)
									 (((xPixel_internal > 142) && (xPixel_internal <= 154)) && ((yPixel_internal > 304) && (yPixel_internal <= 344)) ||  // left bar
									  ((xPixel_internal > 165) && (xPixel_internal <= 177)) && ((yPixel_internal > 304) && (yPixel_internal <= 344)) ||  // right bar
									  ((xPixel_internal > 142) && (xPixel_internal <= 177)) && ((yPixel_internal > 304) && (yPixel_internal <= 314)) ||  // top bar
									  ((xPixel_internal > 142) && (xPixel_internal <= 177)) && ((yPixel_internal > 324) && (yPixel_internal <= 334))) ||   // mid bar
								 
									 // L  (x: 183 -> 218)
									 (((xPixel_internal > 183) && (xPixel_internal <= 195)) && ((yPixel_internal > 304) && (yPixel_internal <= 344)) ||  // left bar
									  ((xPixel_internal > 183) && (xPixel_internal <= 218)) && ((yPixel_internal > 334) && (yPixel_internal <= 344))) ||    // bottom bar
								

								// ------------------- "PROJECT!"  (y: 364 -> 404) -------------------
								
									 // P  (x: 442 -> 457)
									 (((xPixel_internal > 442) && (xPixel_internal <= 446)) && ((yPixel_internal > 364) && (yPixel_internal <= 404)) ||  // left bar
									  ((xPixel_internal > 442) && (xPixel_internal <= 457)) && ((yPixel_internal > 364) && (yPixel_internal <= 370)) ||  // top
									  ((xPixel_internal > 442) && (xPixel_internal <= 457)) && ((yPixel_internal > 382) && (yPixel_internal <= 388)) ||  // mid
									  ((xPixel_internal > 453) && (xPixel_internal <= 457)) && ((yPixel_internal > 364) && (yPixel_internal <= 388))) ||   // right (top half)
								 
									 // R  (x: 457 -> 472)
									 (((xPixel_internal > 457) && (xPixel_internal <= 461)) && ((yPixel_internal > 364) && (yPixel_internal <= 404)) ||  // left bar
									  ((xPixel_internal > 457) && (xPixel_internal <= 472)) && ((yPixel_internal > 364) && (yPixel_internal <= 370)) ||  // top
									  ((xPixel_internal > 457) && (xPixel_internal <= 472)) && ((yPixel_internal > 382) && (yPixel_internal <= 388)) ||  // mid
									  ((xPixel_internal > 468) && (xPixel_internal <= 472)) && ((yPixel_internal > 364) && (yPixel_internal <= 388)) ||  // right (top half)
									  ((xPixel_internal > 465) && (xPixel_internal <= 472)) && ((yPixel_internal > 388) && (yPixel_internal <= 404))) ||   // leg
								 
									 // O  (x: 472 -> 486)
									 (((xPixel_internal > 472) && (xPixel_internal <= 476)) && ((yPixel_internal > 364) && (yPixel_internal <= 404)) ||  // left
									  ((xPixel_internal > 482) && (xPixel_internal <= 486)) && ((yPixel_internal > 364) && (yPixel_internal <= 404)) ||  // right
									  ((xPixel_internal > 472) && (xPixel_internal <= 486)) && ((yPixel_internal > 364) && (yPixel_internal <= 370)) ||  // top
									  ((xPixel_internal > 472) && (xPixel_internal <= 486)) && ((yPixel_internal > 398) && (yPixel_internal <= 404))) ||   // bottom

									 // J  (x: 486 -> 507)
									 (((xPixel_internal > 486) && (xPixel_internal <= 507)) && ((yPixel_internal > 364) && (yPixel_internal <= 370)) ||  // top
									  ((xPixel_internal > 501) && (xPixel_internal <= 507)) && ((yPixel_internal > 364) && (yPixel_internal <= 398)) ||  // right stem
									  ((xPixel_internal > 492) && (xPixel_internal <= 507)) && ((yPixel_internal > 398) && (yPixel_internal <= 404)) ||  // bottom
									  ((xPixel_internal > 486) && (xPixel_internal <= 492)) && ((yPixel_internal > 388) && (yPixel_internal <= 404))) ||   // hook

									 // E  (x: 507 -> 524)
									 (((xPixel_internal > 507) && (xPixel_internal <= 511)) && ((yPixel_internal > 364) && (yPixel_internal <= 404)) ||  // left
									  ((xPixel_internal > 507) && (xPixel_internal <= 524)) && ((yPixel_internal > 364) && (yPixel_internal <= 370)) ||  // top
									  ((xPixel_internal > 507) && (xPixel_internal <= 522)) && ((yPixel_internal > 382) && (yPixel_internal <= 388)) ||  // mid
									  ((xPixel_internal > 507) && (xPixel_internal <= 524)) && ((yPixel_internal > 398) && (yPixel_internal <= 404))) ||   // bottom

									 // C  (x: 524 -> 541)
									 (((xPixel_internal > 524) && (xPixel_internal <= 528)) && ((yPixel_internal > 364) && (yPixel_internal <= 404)) ||  // left
									  ((xPixel_internal > 524) && (xPixel_internal <= 541)) && ((yPixel_internal > 364) && (yPixel_internal <= 370)) ||  // top
									  ((xPixel_internal > 524) && (xPixel_internal <= 541)) && ((yPixel_internal > 398) && (yPixel_internal <= 404)))  ||  // bottom
								 
									 // T  (x: 541 -> 564)
									 (((xPixel_internal > 541) && (xPixel_internal <= 564)) && ((yPixel_internal > 364) && (yPixel_internal <= 370)) ||  // top
									  ((xPixel_internal > 551) && (xPixel_internal <= 554)) && ((yPixel_internal > 364) && (yPixel_internal <= 404))) ||   // stem
								 
									 // !  (x: ~584 -> 596)  (keep your style)
									 (((xPixel_internal > 584) && (xPixel_internal <= 596)) && ((yPixel_internal > 364) && (yPixel_internal <= 390)) ||
									  ((xPixel_internal > 584) && (xPixel_internal <= 596)) && ((yPixel_internal > 399) && (yPixel_internal <= 404)))
								

									
									
									
									) begin 
								vga_color = 24'hFFBF00; // amber yellow 
							
							
							end 
					 end
				 	 else begin
				
						 // base background inside visible area
						 vga_color = 24'hAACCFF; // pastel blue

						 // ---------- Players (only if alive) ----------
						 if (show_sprite1 && p1_alive) begin
							  vga_color = sprite1_color;  // beige
						 end
						 else if (p2_alive && show_sprite2) begin
							  vga_color = sprite2_color;  // medium brown 
						 end
						 
						 // ---------- Extra heart pickup on the board ----------
						else if (extra_heart_here) begin
							 // you can pick a different “special heart” color if you like
							 vga_color = 24'hFF1493;  // deep pink for pickup heart
						end


						 // ---------- Hearts HUD (bottom row y = 11) ----------
						else if (grid_y == 4'd11) begin
							 // Player 1 hearts: x = 0,1,2,3 (up to 4 hearts)
							 if ((grid_x == 4'd0 && hearts_p1 >= 3'd1) ||
								  (grid_x == 4'd1 && hearts_p1 >= 3'd2) ||
								  (grid_x == 4'd2 && hearts_p1 >= 3'd3) ||
								  (grid_x == 4'd3 && hearts_p1 >= 3'd4)) begin
								  vga_color = 24'hFF0000;  // red heart
							 end
							 // Player 2 hearts: x = 12,13,14,15 (up to 4 hearts)
							 else if ((grid_x == 4'd12 && hearts_p2 >= 3'd1) ||
										 (grid_x == 4'd13 && hearts_p2 >= 3'd2) ||
										 (grid_x == 4'd14 && hearts_p2 >= 3'd3) ||
										 (grid_x == 4'd15 && hearts_p2 >= 3'd4)) begin
								  vga_color = 24'hFF0000;  // red heart
							 end
							 else begin
								  // HUD row but no heart in this cell: keep sky color
								  vga_color = 24'hAACCFF;
							 end
						end
					
						 
						 // ---------- Row 10 cars (two cars, right) ----------
						else if (show_homework_car) begin 
							vga_color = homework_car_color; 
						end 
						else if (show_lab9_car) begin 
							vga_color = lab9_car_color; 
						end
						// ---------- Row 9 cars (three cars, left) ----------
						else if (show_lab12_car) begin 
							vga_color = lab12_car_color; 
						end 
						else if (show_handwriting_car) begin 
							vga_color = handwriting_car_color; 
						end
						else if (show_am0830_car) begin 
							vga_color = am0830_car_color; 
						end

						// ---------- Row 3 car (one car, left) ----------
						 else if (show_allnight_car) begin
							 vga_color = allnight_car_color;
						 end
						 else if (show_isthatall_car) begin 
								vga_color = isthatall_car_color; 
						 end 

						// ---------- Row 2 cars (two cars, left) ----------
						 else if (show_exam3_car) begin
							 vga_color = exam3_car_color;
						 end
						 else if (show_labfull_car) begin 
							 vga_color = labfull_car_color; 
						 end
						 // ---------- Moving train body ----------
						else if (show_train_006) begin
							vga_color = train_006_color;  // red train
						end
						 	
						 // ---------- Static environment ----------
						 // train tracks (static) at row 6
						 else if (grid_y == 4'd6) begin 
							  vga_color = 24'hA9A9A9;  // dark grey for the train track  
						 end 
				
						 // streets 
						 else if (grid_y == 4'd2 || grid_y == 4'd3 ||
									 grid_y == 4'd9 || grid_y == 4'd10) begin 
							  vga_color = 24'hA9A9A9; 
						 end

					// railroad crossing end fences
                   else if (show_gate1) begin 
							vga_color = gate1_color; 	
                  end 
					   else if (show_gate2) begin 
							vga_color = gate2_color;
					   end 
                  else if (show_gate13) begin 
							vga_color = gate13_color; 	
                  end 
					   else if (show_gate14) begin 
							vga_color = gate14_color;
					   end 
					 
                // railroad crossing end posts 
					 else if(show_rrxing_05) begin 
							vga_color = rrxing_05_color;
					 end 	
					 else if(show_rrxing_1505) begin 
							vga_color = rrxing_1505_color; 
					 end 
                else if (show_rrxing_07) begin 
							vga_color = rrxing_07_color; 
                end 
					 else if(show_rrxing_1507) begin 
							vga_color = rrxing_1507_color; 
					end  

                // trees on row 1
                else if (show_sqtree) begin 
						vga_color = sqtree_color; 
					 end 
					 else if (show_sqtree) begin 
						vga_color = sqtree_color; 
					 end 
					 else if (show_sqtree) begin 
						vga_color = sqtree_color; 
					 end 
					 
						 else begin
							  // fallback for any visible cell that isn't handled above
							  vga_color = 24'hAACCFF;
						 end
					end
            end
        end
    end
	 
	 // VGA timing / sync generator
    vga_driver the_vga( 
        .clk(CLOCK_50),
        .rst(rst),

        .vga_clk(vga_pix_clk),

        .hsync(VGA_HS),
        .vsync(VGA_VS),

        .active_pixels(active_pixels),

        .xPixel(xPixel_internal),
        .yPixel(yPixel_internal),

        .VGA_BLANK_N(VGA_BLANK_N),
        .VGA_SYNC_N(VGA_SYNC_N)
    );
	 
/*
// ROM module instantiation for regular heart count 									
	rom4heartcount heart_011_inst(.address(heart_011_address), 
											.clock(vga_pix_clk), 
											.data(24'd0), 
											.q(heart_011_color), 
											.wren(1'b0)); 
											
	rom4heartcount heart_0111_inst(.address(heart_0111_address), 
											.clock(vga_pix_clk), 
											.data(24'd0), 
											.q(heart_0111_color), 
											.wren(1'b0)); 
	
	rom4heartcount heart_1411_inst(.address(heart_1411_address), 
											.clock(vga_pix_clk), 
											.data(24'd0), 
											.q(heart_1411_color), 
											.wren(1'b0)); 
											
	rom4heartcount heart_1511_inst(.address(heart_1511_address), 
											.clock(vga_pix_clk), 
											.data(24'd0), 
											.q(heart_1511_color), 
											.wren(1'b0)); 											
	*/										
// ROM module instatiaion for sprite 1 
	rom4sprite1 sprite1_inst(.address(sprite1_address), 
									 .clock(vga_pix_clk), 
									 .data(24'd0),
									 .q(sprite1_color), 
									 .wren(1'b0)); 						

// ROM module instatiaion for sprite 2 
	rom4sprite2 sprite2_inst(.address(sprite2_address), 
									 .clock(vga_pix_clk), 
									 .data(24'd0),
									 .q(sprite2_color), 
									 .wren(1'b0)); 																
								
// ROM module instantiation for Top Car: Green All Nighter 									
	rom4allnight allnight_inst(.address(allnight_car_address), 
											.clock(vga_pix_clk), 
											.data(24'd0), 
											.q(allnight_car_color), 
											.wren(1'b0)); 	 
											
// ROM module instantiation for Top Car: Blue Exam 3  									
	rom4exam3 exam3_inst(.address(exam3_car_address), 
											.clock(vga_pix_clk), 
											.data(24'd0), 
											.q(exam3_car_color), 
											.wren(1'b0)); 	 
											
// ROM module instantiation for Top Car: Brown Lab Full 									
	rom4labfull labfull_inst(.address(labfull_car_address), 
											.clock(vga_pix_clk), 
											.data(24'd0), 
											.q(labfull_car_color), 
											.wren(1'b0));
											
// ROM module instantiation for Top Car: Red "Is That All?" 									
rom4isthatall isthatall_inst(.address(isthatall_car_address), 
											.clock(vga_pix_clk), 
											.data(24'd0), 
											.q(isthatall_car_color), 
											.wren(1'b0)); 										
						
// ROM module instantiation for Orange bottom Homework Car L -> R
	rom4homeworkcar homeworkcar_inst(.address(homework_car_address), 
												.clock(vga_pix_clk), 
												.data(24'd0),
												.q(homework_car_color), 
												.wren(1'b0)); 
												
// ROM module instantiation for Purple bottom Lab9 Car L -> R
	rom4lab9 lab9car_inst(.address(lab9_car_address), 
												.clock(vga_pix_clk), 
												.data(24'd0),
												.q(lab9_car_color), 
												.wren(1'b0));
	
// ROM module instantiation for Blue bottom Lab 12 Car R -> L
	rom4lab12 lab12car_inst(.address(lab12_car_address), 
												.clock(vga_pix_clk), 
												.data(24'd0),
												.q(lab12_car_color), 
												.wren(1'b0)); 
												
// ROM module instantiation for Green bottom Handwriting Car R -> L
	rom4handwritingcar handwritingcar_inst(.address(handwriting_car_address), 
												.clock(vga_pix_clk), 
												.data(24'd0),
												.q(handwriting_car_color), 
												.wren(1'b0));
	
// ROM module instantiation for Red bottom 8:30am Car R -> L
	rom4am0830car am0830car_inst(.address(am0830_car_address), 
												.clock(vga_pix_clk), 
												.data(24'd0),
												.q(am0830_car_color), 
												.wren(1'b0));		
	
// ROM module instatiation for train 
	rom4train train_inst(.address(train_006_address), 
								.clock(vga_pix_clk), 
								.data(24'd0), 
								.q(train_006_color),
								.wren(1'b0)); 	
	
// ROM module instantiation for RRXING End Posts  								 
	rom4RRXING rrxing_05post_inst(.address(rrxing_05_address), 
										 .clock(vga_pix_clk), 
										.data(24'd0),
										.q(rrxing_05_color), 
										.wren(1'b0)); 						
										
	rom4RRXING rrxing_1505post_inst(.address(rrxing_1505_address), 
										 .clock(vga_pix_clk), 
										.data(24'd0),
										.q(rrxing_1505_color), 
										.wren(1'b0)); 						
										
	rom4RRXING rrxing_07post_inst(.address(rrxing_07_address), 
										 .clock(vga_pix_clk), 
										.data(24'd0),
										.q(rrxing_07_color), 
										.wren(1'b0)); 					
	
	rom4RRXING rrxing_1507post_inst(.address(rrxing_1507_address), 
										 .clock(vga_pix_clk), 
										.data(24'd0),
										.q(rrxing_1507_color), 
										.wren(1'b0)); 						
							
// ROM module instantiation for RRXING crossing gates 
	rom4gate1 gate1(.address(gate1_address), 
						 .clock(vga_pix_clk), 
						 .data(24'd0), 
						 .q(gate1_color), 
						 .wren(1'b0)); 
	
	rom4gate2 gate2_inst(.address(gate2_address), 
						 .clock(vga_pix_clk), 
						 .data(24'd0), 
						 .q(gate2_color), 
						 .wren(1'b0)); 
						 
	rom4gate1 gate13_inst(.address(gate13_address), 
						 .clock(vga_pix_clk), 
						 .data(24'd0), 
						 .q(gate13_color), 
						 .wren(1'b0)); 
	
	rom4gate2 gate14_inst(.address(gate14_address), 
						 .clock(vga_pix_clk), 
						 .data(24'd0), 
						 .q(gate14_color), 
						 .wren(1'b0)); 
	
// ROM module instantiation for "Stupid Questions?" Trees 
	rom4sqtree sqtree_inst(.address(sqtree_address), 
								  .clock(vga_pix_clk), 
								  .data(24'd0), 
								  .q(sqtree_color), 
								  .wren(1'b0)); 
/*								  
// ROM module instantiation for "Extra Credit?" Trees 								  
	rom4sqtree extree_inst(.address(extree_address), 
								  .clock(vga_pix_clk), 
								  .data(24'd0), 
								  .q(extree_color), 
								  .wren(1'b0)); 
								  
// ROM module instantiation for "Project Demo Friday" Trees 								  								  
	rom4sqtree demtree_inst(.address(demtree_address), 
								  .clock(vga_pix_clk), 
								  .data(24'd0), 
								  .q(demtree_color), 
								  .wren(1'b0)); 

*/											
endmodule


