////////////////////////////////////////////////////////////////////////////////////////////////////
/*
This module is for all still objects / obstacles (i.e. train tracks, streets, trees, railroad crossing end posts, etc) 
Defines static obstacles and non-moving map elements.
This module provides fixed obstacle locations used for collision checks and rendering, and using parameterized grid 
*/
////////////////////////////////////////////////////////////////////////////////////////////////////


module still_obstacles #(
									parameter GRID_WIDTH = 16,			// 16 columns 
									parameter GRID_HEIGHT = 12)		// 12 rows 
									(input clk, 
									input rst, 
									// obstacle  logic 
									input [3:0] blocked_x, 				// x coordinate for a blocked grid square (obstacles) 
									input [3:0] blocked_y,  			// y coordinate for a blocked grid square (obstacles) 
									output reg is_obstacles); 					// 1 bit (1/0 = y/n) is obstacles is present in said grid square 
											
									
reg obstacles_grid[0:GRID_WIDTH - 1][0:GRID_HEIGHT - 1];		// sets total grid x & y as a matrix
		
		
always @ (*)
begin 
	if(obstacles_grid[blocked_x][blocked_y] == 1'b1)	
		is_obstacles = 1'b1; 
	else 
		is_obstacles = 1'b0;
end 
/*
//out of bounds safety precaution 	
always @ (*)
begin 
	 if (blocked_x < GRID_WIDTH && blocked_y < GRID_HEIGHT)
        is_obstacles = obstacles_grid[blocked_x][blocked_y];
    else
        is_obstacles = 1'b0;
end 
*/


// obstacle grid placemnt; intializaiton + hardcoding 
always @ (posedge clk or negedge rst) 
begin 
	if(rst == 1'b0)
	begin 
		obstacles_grid[0][0] <= 1'b0;
		obstacles_grid[0][1] <= 1'b0;
		obstacles_grid[0][2] <= 1'b0;
		obstacles_grid[0][3] <= 1'b0;
		obstacles_grid[0][4] <= 1'b0;
		obstacles_grid[0][5] <= 1'b0;
		obstacles_grid[0][6] <= 1'b0;
		obstacles_grid[0][7] <= 1'b0;
		obstacles_grid[0][8] <= 1'b0;
		obstacles_grid[0][9] <= 1'b0;
		obstacles_grid[0][10] <= 1'b0;
		obstacles_grid[0][11] <= 1'b0;

		obstacles_grid[1][0] <= 1'b0;
		obstacles_grid[1][1] <= 1'b0;
		obstacles_grid[1][2] <= 1'b0;
		obstacles_grid[1][3] <= 1'b0;
		obstacles_grid[1][4] <= 1'b0;
		obstacles_grid[1][5] <= 1'b0;
		obstacles_grid[1][6] <= 1'b0;
		obstacles_grid[1][7] <= 1'b0;
		obstacles_grid[1][8] <= 1'b0;
		obstacles_grid[1][9] <= 1'b0;
		obstacles_grid[1][10] <= 1'b0;
		obstacles_grid[1][11] <= 1'b0;

		obstacles_grid[2][0] <= 1'b0;
		obstacles_grid[2][1] <= 1'b0;
		obstacles_grid[2][2] <= 1'b0;
		obstacles_grid[2][3] <= 1'b0;
		obstacles_grid[2][4] <= 1'b0;
		obstacles_grid[2][5] <= 1'b0;
		obstacles_grid[2][6] <= 1'b0;
		obstacles_grid[2][7] <= 1'b0;
		obstacles_grid[2][8] <= 1'b0;
		obstacles_grid[2][9] <= 1'b0;
		obstacles_grid[2][10] <= 1'b0;
		obstacles_grid[2][11] <= 1'b0;

		obstacles_grid[3][0] <= 1'b0;
		obstacles_grid[3][1] <= 1'b0;
		obstacles_grid[3][2] <= 1'b0;
		obstacles_grid[3][3] <= 1'b0;
		obstacles_grid[3][4] <= 1'b0;
		obstacles_grid[3][5] <= 1'b0;
		obstacles_grid[3][6] <= 1'b0;
		obstacles_grid[3][7] <= 1'b0;
		obstacles_grid[3][8] <= 1'b0;
		obstacles_grid[3][9] <= 1'b0;
		obstacles_grid[3][10] <= 1'b0;
		obstacles_grid[3][11] <= 1'b0;

		obstacles_grid[4][0] <= 1'b0;
		obstacles_grid[4][1] <= 1'b0;
		obstacles_grid[4][2] <= 1'b0;
		obstacles_grid[4][3] <= 1'b0;
		obstacles_grid[4][4] <= 1'b0;
		obstacles_grid[4][5] <= 1'b0;
		obstacles_grid[4][6] <= 1'b0;
		obstacles_grid[4][7] <= 1'b0;
		obstacles_grid[4][8] <= 1'b0;
		obstacles_grid[4][9] <= 1'b0;
		obstacles_grid[4][10] <= 1'b0;
		obstacles_grid[4][11] <= 1'b0;

		obstacles_grid[5][0] <= 1'b0;
		obstacles_grid[5][1] <= 1'b0;
		obstacles_grid[5][2] <= 1'b0;
		obstacles_grid[5][3] <= 1'b0;
		obstacles_grid[5][4] <= 1'b0;
		obstacles_grid[5][5] <= 1'b0;
		obstacles_grid[5][6] <= 1'b0;
		obstacles_grid[5][7] <= 1'b0;
		obstacles_grid[5][8] <= 1'b0;
		obstacles_grid[5][9] <= 1'b0;
		obstacles_grid[5][10] <= 1'b0;
		obstacles_grid[5][11] <= 1'b0;

		obstacles_grid[6][0] <= 1'b0;
		obstacles_grid[6][1] <= 1'b0;
		obstacles_grid[6][2] <= 1'b0;
		obstacles_grid[6][3] <= 1'b0;
		obstacles_grid[6][4] <= 1'b0;
		obstacles_grid[6][5] <= 1'b0;
		obstacles_grid[6][6] <= 1'b0;
		obstacles_grid[6][7] <= 1'b0;
		obstacles_grid[6][8] <= 1'b0;
		obstacles_grid[6][9] <= 1'b0;
		obstacles_grid[6][10] <= 1'b0;
		obstacles_grid[6][11] <= 1'b0;

		obstacles_grid[7][0] <= 1'b0;
		obstacles_grid[7][1] <= 1'b0;
		obstacles_grid[7][2] <= 1'b0;
		obstacles_grid[7][3] <= 1'b0;
		obstacles_grid[7][4] <= 1'b0;
		obstacles_grid[7][5] <= 1'b0;
		obstacles_grid[7][6] <= 1'b0;
		obstacles_grid[7][7] <= 1'b0;
		obstacles_grid[7][8] <= 1'b0;
		obstacles_grid[7][9] <= 1'b0;
		obstacles_grid[7][10] <= 1'b0;
		obstacles_grid[7][11] <= 1'b0;

		obstacles_grid[8][0] <= 1'b0;
		obstacles_grid[8][1] <= 1'b0;
		obstacles_grid[8][2] <= 1'b0;
		obstacles_grid[8][3] <= 1'b0;
		obstacles_grid[8][4] <= 1'b0;
		obstacles_grid[8][5] <= 1'b0;
		obstacles_grid[8][6] <= 1'b0;
		obstacles_grid[8][7] <= 1'b0;
		obstacles_grid[8][8] <= 1'b0;
		obstacles_grid[8][9] <= 1'b0;
		obstacles_grid[8][10] <= 1'b0;
		obstacles_grid[8][11] <= 1'b0;

		obstacles_grid[9][0] <= 1'b0;
		obstacles_grid[9][1] <= 1'b0;
		obstacles_grid[9][2] <= 1'b0;
		obstacles_grid[9][3] <= 1'b0;
		obstacles_grid[9][4] <= 1'b0;
		obstacles_grid[9][5] <= 1'b0;
		obstacles_grid[9][6] <= 1'b0;
		obstacles_grid[9][7] <= 1'b0;
		obstacles_grid[9][8] <= 1'b0;
		obstacles_grid[9][9] <= 1'b0;
		obstacles_grid[9][10] <= 1'b0;
		obstacles_grid[9][11] <= 1'b0;

		obstacles_grid[10][0] <= 1'b0;
		obstacles_grid[10][1] <= 1'b0;
		obstacles_grid[10][2] <= 1'b0;
		obstacles_grid[10][3] <= 1'b0;
		obstacles_grid[10][4] <= 1'b0;
		obstacles_grid[10][5] <= 1'b0;
		obstacles_grid[10][6] <= 1'b0;
		obstacles_grid[10][7] <= 1'b0;
		obstacles_grid[10][8] <= 1'b0;
		obstacles_grid[10][9] <= 1'b0;
		obstacles_grid[10][10] <= 1'b0;
		obstacles_grid[10][11] <= 1'b0;

		obstacles_grid[11][0] <= 1'b0;
		obstacles_grid[11][1] <= 1'b0;
		obstacles_grid[11][2] <= 1'b0;
		obstacles_grid[11][3] <= 1'b0;
		obstacles_grid[11][4] <= 1'b0;
		obstacles_grid[11][5] <= 1'b0;
		obstacles_grid[11][6] <= 1'b0;
		obstacles_grid[11][7] <= 1'b0;
		obstacles_grid[11][8] <= 1'b0;
		obstacles_grid[11][9] <= 1'b0;
		obstacles_grid[11][10] <= 1'b0;
		obstacles_grid[11][11] <= 1'b0;

		obstacles_grid[12][0] <= 1'b0;
		obstacles_grid[12][1] <= 1'b0;
		obstacles_grid[12][2] <= 1'b0;
		obstacles_grid[12][3] <= 1'b0;
		obstacles_grid[12][4] <= 1'b0;
		obstacles_grid[12][5] <= 1'b0;
		obstacles_grid[12][6] <= 1'b0;
		obstacles_grid[12][7] <= 1'b0;
		obstacles_grid[12][8] <= 1'b0;
		obstacles_grid[12][9] <= 1'b0;
		obstacles_grid[12][10] <= 1'b0;
		obstacles_grid[12][11] <= 1'b0;

		obstacles_grid[13][0] <= 1'b0;
		obstacles_grid[13][1] <= 1'b0;
		obstacles_grid[13][2] <= 1'b0;
		obstacles_grid[13][3] <= 1'b0;
		obstacles_grid[13][4] <= 1'b0;
		obstacles_grid[13][5] <= 1'b0;
		obstacles_grid[13][6] <= 1'b0;
		obstacles_grid[13][7] <= 1'b0;
		obstacles_grid[13][8] <= 1'b0;
		obstacles_grid[13][9] <= 1'b0;
		obstacles_grid[13][10] <= 1'b0;
		obstacles_grid[13][11] <= 1'b0;

		obstacles_grid[14][0] <= 1'b0;
		obstacles_grid[14][1] <= 1'b0;
		obstacles_grid[14][2] <= 1'b0;
		obstacles_grid[14][3] <= 1'b0;
		obstacles_grid[14][4] <= 1'b0;
		obstacles_grid[14][5] <= 1'b0;
		obstacles_grid[14][6] <= 1'b0;
		obstacles_grid[14][7] <= 1'b0;
		obstacles_grid[14][8] <= 1'b0;
		obstacles_grid[14][9] <= 1'b0;
		obstacles_grid[14][10] <= 1'b0;
		obstacles_grid[14][11] <= 1'b0;

		obstacles_grid[15][0] <= 1'b0;
		obstacles_grid[15][1] <= 1'b0;
		obstacles_grid[15][2] <= 1'b0;
		obstacles_grid[15][3] <= 1'b0;
		obstacles_grid[15][4] <= 1'b0;
		obstacles_grid[15][5] <= 1'b0;
		obstacles_grid[15][6] <= 1'b0;
		obstacles_grid[15][7] <= 1'b0;
		obstacles_grid[15][8] <= 1'b0;
		obstacles_grid[15][9] <= 1'b0;
		obstacles_grid[15][10] <= 1'b0;
		obstacles_grid[15][11] <= 1'b0;
	end
	
	
	// Hard coding static obstacle placement: 
	// trees 
	else begin 
		obstacles_grid[0][1] <= 1'b1; 
		obstacles_grid[1][1] <= 1'b1; 
		obstacles_grid[3][1] <= 1'b1; 
		obstacles_grid[4][1] <= 1'b1; 
		obstacles_grid[6][1] <= 1'b1; 
		obstacles_grid[8][1] <= 1'b1; 
		obstacles_grid[10][1] <= 1'b1; 
		obstacles_grid[12][1] <= 1'b1; 
		obstacles_grid[13][1] <= 1'b1;
		obstacles_grid[15][1] <= 1'b1; 
		
		//
		obstacles_grid[1][5] <= 1'b1; 
		obstacles_grid[2][5] <= 1'b1; 
		obstacles_grid[3][5] <= 1'b1;
		obstacles_grid[4][5] <= 1'b1; 
		
		obstacles_grid[1][7] <= 1'b1; 
		obstacles_grid[2][7] <= 1'b1; 
		obstacles_grid[3][7] <= 1'b1;
		obstacles_grid[4][7] <= 1'b1; 
		
		obstacles_grid[11][5] <= 1'b1; 
		obstacles_grid[12][5] <= 1'b1;
		obstacles_grid[13][5] <= 1'b1; 
		obstacles_grid[14][5] <= 1'b1; 
		
		obstacles_grid[11][7] <= 1'b1; 
		obstacles_grid[12][7] <= 1'b1; 
		obstacles_grid[13][7] <= 1'b1;
		obstacles_grid[14][7] <= 1'b1; 
		
		// rail road crossing end posts row 5 
		obstacles_grid[0][5] <= 1'b1; 
		obstacles_grid[15][5] <= 1'b1;
		
		// rail road crossing end posts row 7
		obstacles_grid[0][7] <= 1'b1; 
		obstacles_grid[15][7] <= 1'b1; 
	end  
end 



					
endmodule 									
									
					
									
									

									
