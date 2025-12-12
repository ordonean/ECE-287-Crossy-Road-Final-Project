
/*
///////////////////////////////
//  The most current one 12/9/25
////////////////////////////////


// Simple PS/2 receiver:
// Reads scan codes from PS2 keyboard and outputs:
//   scan_code  = 8-bit code
//   scan_ready = 1 for 1 clock when a new code is ready

module ps2_controller (
    input  clk,          // 50 MHz system clock
    input  rst,          // ACTIVE-LOW reset (0 = reset)
    input  ps2_clk,      // PS/2 clock line from board
    input  ps2_data,     // PS/2 data line from board

    output reg [7:0] scan_code,
    output reg       scan_ready
);

    // Synchronizers for PS2 clock and data
    reg [2:0] ps2_clk_sync;
    reg [2:0] ps2_data_sync;

    always @(posedge clk or negedge rst) begin
        if (rst == 1'b0)
            ps2_clk_sync <= 3'b000;
        else
            ps2_clk_sync <= {ps2_clk_sync[1:0], ps2_clk};
    end

    always @(posedge clk or negedge rst) begin
        if (rst == 1'b0)
            ps2_data_sync <= 3'b000;
        else
            ps2_data_sync <= {ps2_data_sync[1:0], ps2_data};
    end

    wire ps2_clk_synced  = ps2_clk_sync[2];
    wire ps2_data_synced = ps2_data_sync[2];

    // Detect falling edge of PS2 clock
    wire ps2_clk_fall;
    assign ps2_clk_fall = (ps2_clk_sync[2:1] == 2'b10);

    // Bit capture registers
    reg [3:0]  bit_count;   // 0..10
    reg [10:0] shift_reg;   // start + 8 data + parity + stop

    always @(posedge clk or negedge rst) begin
        if (rst == 1'b0) begin
            bit_count  <= 4'd0;
            shift_reg  <= 11'd0;
            scan_code  <= 8'd0;
            scan_ready <= 1'b0;
        end
        else begin
            // default: no new code this cycle
            scan_ready <= 1'b0;

            if (ps2_clk_fall) begin
                // shift in a new bit at each falling edge
                shift_reg <= {ps2_data_synced, shift_reg[10:1]};
                bit_count <= bit_count + 4'd1;

                if (bit_count == 4'd10) begin
                    // all 11 bits captured
                    bit_count <= 4'd0;
	

							
                    // Check: start bit = 0, stop bit = 1, parity OK
                    if (shift_reg[0]  == 1'b0 &&          // start
                        shift_reg[10] == 1'b1 &&          // stop
                        (^shift_reg[9:1] == 1'b1)) begin  // odd parity
                        scan_code  <= shift_reg[8:1];     // 8 data bits
                        scan_ready <= 1'b1;               // pulse 1 clock
                    end
						  
						  // TEMP: accept any 11-bit frame so we can at least see activity
							scan_code  <= shift_reg[8:1];
							scan_ready <= 1'b1;
                end
            end
        end
    end

endmodule



*/




































// Purpose: this module communicates with the PS2 core / controller 
// Flow: ps2_data_in --> ps2_controller 


// must detect falling edges of ps2_clk, shift in 11 bits,track bit_count, extract only data bits, output scan code + scan ready

/*
module ps2_controller #(parameter INTIALIZE_MOUSE = 0) (
							// inputs
							input CLOCK_50, 
							input rst, 
							input [7:0] scan_code, 
							input scan_ready, 
							
							// Bi directionals 
							input PS2_CLK,											// this is the official PS2 Clock  
							input PS2_DAT,											// this is the official ps2 data
							
							// Outputs 
							output command_sent, 
							output error_comm_timed_out, 
							
							output reg [7:0] recieved_data, 
							output reg recieved_data_en); 					// = 1 if new data recieved 
							

wire [7:0] command_w; 
wire send_command_w; 
wire command_sent_w; 
wire error_comm_timed_out_w; 
 


generate
	if(INITIALIZE_MOUSE == 1)
	begin 
		reg init_done;
	// init_done register 	
	always @ (posedge CLOCK_50 or negedge rst)
	begin 
		if(rst == 1'b0)
			init_done <= 1'b0; 
		else if(command_sent_w == 1)
			init_done <= 1'b1; 
	end 
	
	// output signaal selections 
	always @(*)
	begin
		if(init_done == 1)
		begin 
			command_w = command; 
			send_command_w = (command_sent_w == 1'b0 && error_comm_timed_out == 1'b0); 
			command_sent = 1'b0; 
			error_comm_timed_out = 1'b1; 
		end
	end 
end
else begin 
	always @ (*)
	begin 
		// no initalization mode - pass through 
		command_w =command; 
		send_command_w = send_command; 
		command_sent = command_sent_w; 
		error_comm_timed_out = error_comm_timed_out_w; 
	end
end 

endgenerate 


			 
wire ps2_clk_posedge; 
wire ps2_clk_negedge; 

wire start_recieving_data; 
wire wait_for_data; 

//internal registers 
reg [7:0] idle_counter; 
reg ps2_clk_reg; 
reg ps2_data_reg; 
reg last_ps2_clk; 

// FSM States & Registers 
reg [2:0]S; 
reg [2:0]NS; 

parameter START = 3'd0, 
			 IDLE = 3'd1, 
			 COMMAND_OUT = 3'd2, 
			 END_TRANSFER = 3'd3, 
			 END_DELAYED = 3'd4; 
			 

// 1st alwyas block 
always @ (posedge CLOCK_50 or negedge rst)
begin 
	if(rst == 1'b0)
	begin
		S <= START; 
	end 
	else begin 
		S <= NS; 
	end 
end 
	
	
// 2nd always block 
always @(*)
begin 
	case(S) 
		START: 
		begin
			NS <= IDLE; 
		end
		IDLE: 
		begin 
			if(idle_counter == 8'hFF && send_command == 1'b1)
				NS <= COMMAND_OUT; 
			else if(ps2_data_reg == 1'b0 && ps2_clk_posedge == 1'b1)
				NS <= DATA_IN; 
			else 
				NS <= IDLE; 
		end 
		DATA_IN: 
		begin 
			if(recieved_data_en == 1'b1)
				NS <= IDLE; 
			else 
				NS <= DATA_IN; 
		end 
		COMMAND_OUT: 
		begin 
			if(command_was_sent == 1'b1 || error_comm_timed_out == 1'b1)
				NS <= END_TRANSFER; 
			else 
				NS <= COMMAND_OUT; 
		end 
		END_TRANSFER: 
		begin
			if(send_command == 1'b0)
				NS <= IDLE; 
			else if(ps2_data_reg == 1'b0 && ps2_clk_posedge == 1'b1)
				NS <= END_DELAYED; 
			else 
				NS <= END_TRANSFER; 
		end 
		END_DELAYED: 
		begin 
			if(recieved_data_en == 1'b1)
			begin 
				if(send_command == 1'b0)
					NS <= IDLE; 
				else 
					NS <= END_TRANSFER; 
			end 
			else 
				NS <= END_DELAYED; 
		end 
		
		default: 
			NS <= IDLE; 
		endcase
	end 

	
	
					///////////// sequential logic ///////////////////////

always @ (posedge CLOCK_50 or negedge rst)
begin 
	if(rst == 1'b0) 
	begin 
		last_ps2_clk <= 1'b1; 
		ps2_clk_reg <= 1'b1; 
		ps2_data_reg <= 1'b1; 
	end 
	else begin 
		last_ps2_clk <= ps2_clk_reg; 
		ps2_clk_reg <= PS2_CLK; 
		ps2_data_reg <= PS2_DAT; 
	end 
end 
		
			
always @ (posedge CLOCK_50 or negedge rst)
begin 
	if(rst == 1'b0) 
	begin 
		idle_counter <= 6'h00; 
	end 
	else begin 
		if(S == IDLE && idle_counter != 6'h3F)
		begin
			idle_counter <= idle_counter + 6'h01; 
		end 
		else if(S != IDLE) 
		begin 
			idle_counter <= 6'h00; 
		end 
	end 
end 




					///////////// combinational logic ///////////////////////


always @(*) begin
    // Default values
    ps2_clk_posedge        = 1'b0;
    ps2_clk_negedge        = 1'b0;
    start_receiving_data   = 1'b0;
    wait_for_data = 1'b0;

    // Clock edges
    if (ps2_clk_reg == 1'b1 && last_ps2_clk == 1'b0)
        ps2_clk_posedge = 1'b1;

    if (ps2_clk_reg == 1'b0 && last_ps2_clk == 1'b1)
        ps2_clk_negedge = 1'b1;

    // State-based signals
    if (S == DATA_IN)
        start_receiving_data = 1'b1;

    if (S == END_TRANSFER)
        wait_for_data = 1'b1;
end


					/////////////  instantiations ///////////////////////

ps2_data_in data_inst(.clk(CLOCK_50), 
							.rst(rst), 
							.wait_for_data(wait_for_data), 
							.start_receiving_data(start_receiving_data), 
							.ps2_clk_posedge(ps2_clk_posedge), 
							.ps2_clk_negedge(ps2_clk_negedge), 
							.ps2_data(ps2_data_reg), 
							//outputs 
							.recieved_data(recieved_data), 
							.recieved_data_en(recieved_data_en)); 

ps2_command_out command_inst(.clk(CLOCK_50), 
							.rst(rst), 
							.scan_code(command_w),
							.scan_ready(send_command_w), 
							.ps2_clk_posedge(ps2_clk_posedge), 
							.ps2_clk_negedge(ps2_clk_negedge), 
							.PS2_CLK(PS2_CLK),
							.PS2_DAT(PS2_DAT),
							// outputs 
							.command_sent(command_sent_w), 
							.error_comm_timed_out(error_comm_timed_out_w)); 

endmodule 




*/