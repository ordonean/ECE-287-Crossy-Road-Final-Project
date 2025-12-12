module vga_driver_memory (

    //////////// ADC //////////
    //output           ADC_CONVST,
    //output           ADC_DIN,
    //input            ADC_DOUT,
    //output           ADC_SCLK,

    //////////// Audio //////////
    //input            AUD_ADCDAT,
    //inout            AUD_ADCLRCK,
    //inout            AUD_BCLK,
    //output           AUD_DACDAT,
    //inout            AUD_DACLRCK,
    //output           AUD_XCK,

    //////////// CLOCK //////////
    input            CLOCK_50,

    //////////// SEG7 //////////
    output     [6:0] HEX0,
    output     [6:0] HEX1,
    output     [6:0] HEX2,
    output     [6:0] HEX3,

    //////////// KEY //////////
    //input      [3:0] KEY,

    //////////// LED //////////
    output     [9:0] LEDR,

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
    input [3:0] player_x,
    input [3:0] player_y,
    input [3:0] player_2x,
    input [3:0] player_2y,
	 input rst
);


reg [3:0] grid_x; 
reg [3:0] grid_y;
 
wire [9:0]x; 																	// current x (0 to 799)
wire [9:0]y; 																	// current y (0 to 524)

// car position
reg [3:0] car_x; 																// this is the grid version of the car x axis 
reg [3:0] car_y; 																// this is the grid version of the car y axis 

//more obstacles added here???? or wihtin still obstacles??? 
// train track inputs 
//reg [3:0] ttrack_x; 															// this is the grid version of the train track x axis 
//reg [3:0] ttrack_y;															// this is the grid version of the train track y axis 

wire clk;
assign clk = CLOCK_50;

wire active_pixels; 															// = 1 when in drawing space  | = 0 when not in drawing space meaning: active high
assign LEDR[0] = active_pixels;     									// this means that LEDR[0] will be on if within screen display area / "drawing space"            

wire vga_pix_clk;
assign VGA_CLK = vga_pix_clk;												// 11/30 KC said delete clk divider cuz we double dividing: 50 MHz -> 25 MHz -> 12.5 MHz


// Turn off all 7 seg displays.
assign HEX0 = 7'h00;
assign HEX1 = 7'h00;
assign HEX2 = 7'h00;
assign HEX3 = 7'h00;


// Tile size (grid -> pixel translation)
localparam TILE = 10'd40; 												// 40 pixels per grid cell 

// grid * TILE = spite pixel origins 
wire [9:0] player_x_px = player_x * TILE; 
wire [9:0] player_y_px = player_y * TILE; 
wire [9:0] player_2x_px = player_2x * TILE; 
wire [9:0] player_2y_px = player_2y * TILE; 

// grid * Tile = car position translation 
wire [9:0] car_x_px = car_x * TILE; 								// this is the pixel version of the car x axis 
wire [9:0] car_y_px = car_y * TILE; 								//this is the pixel version of the car y axis 


always @ (*) 																// this always block conditions the grid to show only when we are currently in the drawing space
begin 																		// this prevents from miscalculations occuring by dividing including the pixels from the front / back porch
	if(active_pixels == 1)
	begin 
		grid_x = x / TILE; 													// 16 columns 
		grid_y = y / TILE; 													// 12 rows 
	end else begin
		grid_x = 0;
		grid_y = 0; 
	end
end 



//this whole instantiation right here is correlated witht the vga_driver. This means that this module that were are currently
//in only cares about the actualy visuals (rgb) rather than any of the sync pulses and porches.
vga_driver the_vga( 
.clk(CLOCK_50),    // 11/30 - KC told me to change from VGA_CLK -> CLOCK_50
.rst(rst),

.vga_clk(vga_pix_clk),  // get the 25 MHz pixel clock out

.hsync(VGA_HS),
.vsync(VGA_VS),

.active_pixels(active_pixels),

.xPixel(x),
.yPixel(y),

.VGA_BLANK_N(VGA_BLANK_N),
.VGA_SYNC_N(VGA_SYNC_N));



//this is taking pixel color and sending it to VGA DAC pins
// Note: vga_color = our orginal color output so all vairbales are now accounted for here
	always @(*)
	begin
		{VGA_R, VGA_G, VGA_B} = vga_color; // concatenation: [23:16] = red, [15:8] = green, [7:0] = blue ...... 8 bits each
	end


reg [23:0] vga_color;



// this is game_display.
always @ (*)
begin
	vga_color = 24'hFFFFFF; 											// the deault is white when not in display area
	
	if(rst == 1'b0) begin															
		vga_color = 24'hAACCFF; 										// this sets the background = pastel blue no matter what's showing up (obstacle wise)
	end
	else begin
	
		if(active_pixels == 1'b1) begin								// if within visible area:
			vga_color = 24'hAACCFF; 									// pastel blue is the default background color 
			
			// train tracks 
			if(grid_y == 6) begin 
				vga_color = 24'hA9A9A9;									// dark grey for the train track  
			end 
			
			//streets 
			else if(grid_y == 2 || grid_y == 3 || grid_y == 9 || grid_y == 10) begin 
				vga_color = 24'hA9A9A9; 
			end
			
			// railroad crossing end posts 
			else if(grid_y == 5 && (grid_x == 0 || grid_x == 15)) begin 
				vga_color = 24'hFFFFFF; 
			end 
			else if(grid_y == 7 && (grid_x == 0 || grid_x == 15)) begin 
				vga_color = 24'hFFFFFF; 	
			end 
			
			// trees 
			else if(grid_y == 1) begin 
				case(grid_x) 
					0: vga_color = 24'h228B22;
					1: vga_color = 24'h228B22;
					3: vga_color = 24'h228B22;
					4: vga_color = 24'h228B22;
					6: vga_color = 24'h228B22;
					8: vga_color = 24'h228B22;
					10: vga_color = 24'h228B22;
					12: vga_color = 24'h228B22;
					13: vga_color = 24'h228B22;
					15: vga_color = 24'h228B22;
					default: vga_color = 24'hAACCFF;
				endcase 
			end
			
			// Sprite 1
			else if(grid_x == player_x && grid_y == player_y) begin
				vga_color = 24'hF5F5DC; 								// beige
			end
			// Sprite 2 
			else if(grid_x == player_2x && grid_y == player_2y) begin
				vga_color = 24'h964B00; 								//medium brown 
			end 
			end
			else begin 														// when not active pixels,
				vga_color = 24'hFFFFFF;					 				//keep default (white)
			
			end
	end
end 


endmodule