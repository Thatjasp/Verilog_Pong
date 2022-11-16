module final(clk, rst, button,button2, led, VGA_CLK, VGA_VS, VGA_HS, VGA_BLANK_N, VGA_SYNC_N, VGA_R, VGA_G, VGA_B);

input clk;
input rst;
input [2:0] button;
input [2:0] button2;
output [17:0] led;


output VGA_CLK;
output VGA_HS;
output VGA_VS;
output VGA_BLANK_N;
output VGA_SYNC_N;
output [9:0] VGA_R;
output [9:0] VGA_G;
output [9:0] VGA_B;

// Found VGA on the internet (Credited in citation)
vga_adapter VGA(
  .resetn(1'b1),
  .clock(clk),
  .colour(colour),
  .x(x),
  .y(y),
  .plot(1'b1),
  .VGA_R(VGA_R),
  .VGA_G(VGA_G),
  .VGA_B(VGA_B),
  .VGA_HS(VGA_HS),
  .VGA_VS(VGA_VS),
  .VGA_BLANK(VGA_BLANK_N),
  .VGA_SYNC(VGA_SYNC_N),
  .VGA_CLK(VGA_CLK));
defparam VGA.RESOLUTION = "160x120";
defparam VGA.MONOCHROME = "FALSE";
defparam VGA.BITS_PER_COLOUR_CHANNEL = 1;
defparam VGA.BACKGROUND_IMAGE = "black.mif";

reg [5:0] S;
reg border_init;
reg paddle_init;
reg ball_init;
reg brick_init;
reg [7:0]x;
reg [7:0]y;
reg [7:0]pad_x, pad_y, pad2_x, pad2_y;
reg [7:0]ball_x, ball_y;
reg [2:0]colour;
reg ball_xdir, ball_ydir;
reg [17:0]draw;
wire frame;

assign led[5:0] = S; //displaying what state we are in


parameter
	START			   = 6'd0,
   INIT_PADDLE    = 6'd1,
	INIT_PADDLE_2	= 6'd2,
   INIT_BALL   	= 6'd3,
   IDLE           = 6'd4,
   ERASE_PADDLE   = 6'd5,
   UPDATE_PADDLE  = 6'd6,
   DRAW_PADDLE    = 6'd7,
	ERASE_PADDLE_2   = 6'd8,
   UPDATE_PADDLE_2  = 6'd9,
   DRAW_PADDLE_2    = 6'd10,
   ERASE_BALL     = 6'd11,
   UPDATE_BALL    = 6'd12,
   DRAW_BALL      = 6'd13,
   GAME_WON       = 6'd14,
	GAME_OVER		= 6'd15,
	ERROR 			= 6'hF;

	
	
	// Calling clock to display
	clock(.clock(clk), .clk(frame));

	assign led[7] = ((ball_ydir) && (ball_y > pad_y - 8'd1) && 
	(ball_y < pad_y + 8'd2) && (ball_x >= pad_x) && (ball_x <= pad_x + 8'd8));
	
	// ===================================== FSM
	
	always @(posedge clk) 
	begin
		border_init = 1'b0;
		paddle_init = 1'b0;
		ball_init = 1'b0;
		brick_init = 1'b0;
		colour = 3'b000; // Background color
		x = 8'b00000000;
		y = 8'b00000000;

	if (~rst)
		S = START;
	case (S)
	
		START: 
		begin
			if (draw < 17'b10000000000000000)
			begin
				x = draw[7:0];
				y = draw[16:8];
				draw = draw + 1'b1;
			end 
			else 
			begin
				draw = 8'b00000000;
				S = INIT_PADDLE;
			end
		end
		
		INIT_PADDLE: 
		begin
			if (draw < 6'b10000)
			begin
				pad_x = 8'd10;		//Placement of paddle
				pad_y = 8'd52; 	// Placement of paddle
				x = pad_x + draw[7];		//size of paddle (x)
				y = pad_y + draw[3:0];	//size of paddle (y)
				draw = draw + 1'b1;
				colour = 3'b000;
			end 
			else 
			begin
				draw = 8'b00000000;
				S = INIT_PADDLE_2;
			end
		end
		INIT_PADDLE_2: 
		begin
			if (draw < 6'b10000)
			begin
				pad2_x = 8'd150;		//Placement of paddle
				pad2_y = 8'd52; 	// Placement of paddle
				x = pad2_x + draw[7];		//size of paddle (x)
				y = pad2_y + draw[3:0];	//size of paddle (y)
				draw = draw + 1'b1;
				colour = 3'b000;
			end 
			else 
			begin
				draw = 8'b00000000;
				S = INIT_BALL;
			end
		end
		
		INIT_BALL: 
		begin
			ball_x = 8'd40;	// Placement of ball
			ball_y = 8'd40; 	// Placement of ball
			x = ball_x;
			y = ball_y;
			colour = 3'b000;
			S = IDLE;
		end
		IDLE:
			if (frame)
			S = ERASE_PADDLE;	//Should be Erase_paddle
	
	
		ERASE_PADDLE:
		begin
			if (draw < 6'b100000) 
			begin
				x = pad_x + draw[7]; // Same as init_paddle
				y = pad_y + draw[3:0];
				draw = draw + 1'b1;
			end 
			else 
			begin
				draw = 8'b00000000;
				S = UPDATE_PADDLE;
			end
		end

		UPDATE_PADDLE: 
		begin
			if (~button[1] && pad_y < -8'd152) pad_y = pad_y + 1'b1; // Moves paddle up (Chnages lower bound)
			if (~button[2] && pad_y > 8'd0) pad_y = pad_y - 1'b1; // Moves paddle down (Changes upper bound)							
			S = DRAW_PADDLE;
		end
		
		DRAW_PADDLE: 
		begin
			if (draw < 6'b100000) 
			begin
				x = pad_x + draw[7];
				y = pad_y + draw[3:0];
				draw = draw + 1'b1;
				colour = 3'b111;
			end 
			else 
			begin
				draw = 8'b00000000;
				S = ERASE_PADDLE_2;
			end
		end
		
			
		ERASE_PADDLE_2:
		begin
			if (draw < 6'b100000) 
			begin
				x = pad2_x + draw[7]; // Same as init_paddle
				y = pad2_y + draw[3:0];
				draw = draw + 1'b1;
			end 
			else 
			begin
				draw = 8'b00000000;
				S = UPDATE_PADDLE_2;
			end
		end

		UPDATE_PADDLE_2: 
		begin
			if (~button2[1] && pad2_y < -8'd152) 
				pad2_y = pad2_y + 1'b1; // Moves paddle up (Chnages lower bound)
			if (~button2[2] && pad2_y > 8'd0) 
				pad2_y = pad2_y - 1'b1; // Moves paddle down (Changes upper bound)							
			S = DRAW_PADDLE_2;
		end
		
		DRAW_PADDLE_2: 
		begin
			if (draw < 6'b100000) 
			begin
				x = pad2_x + draw[7];
				y = pad2_y + draw[3:0];
				draw = draw + 1'b1;
				colour = 3'b111;
			end 
			else 
			begin
				draw = 8'b00000000;
				S = ERASE_BALL;
			end
		end
		
		ERASE_BALL: 
		begin
			x = ball_x;
			y = ball_y;
			S = UPDATE_BALL;
		end
		
		UPDATE_BALL: 
		begin
			if (~ball_xdir)
				ball_x = ball_x + 1'b1; // moves ball right
			else
				ball_x = ball_x - 1'b1; // moves ball left
				
			if (ball_ydir) 
				ball_y = ball_y + 1'b1; // moves ball up
			else 
				ball_y = ball_y - 1'b1; // moves ball down
				
			if ((ball_x == 8'd0) || (ball_x == 8'd160) || ((ball_xdir) && (ball_x > pad_x - 8'd1) && 
			   (ball_x < pad_x + 8'd3) && (ball_y >= pad_y) && (ball_y <= pad_y + 8'd15))) // Ball boundary x direction with paddle
				ball_xdir = ~ball_xdir;
			
			else if (((~ball_xdir) && (ball_x < pad2_x + 8'd1) && 
			   (ball_x > pad2_x - 8'd3) && (ball_y >= pad2_y) && (ball_y <= pad2_y + 8'd15))) // Ball boundary x direction with paddle
				ball_xdir = ~ball_xdir;

			if ((ball_y == 8'd0) || (ball_y == -8'd136))
				ball_ydir = ~ball_ydir;

			if (ball_x <= 8'd0) // y boundary below paddle = GAME OVER!!!!!
				S = GAME_OVER;
			else if (ball_x >= 8'd160) 
				S = GAME_OVER;
			else
				S = DRAW_BALL;
		end
		
		DRAW_BALL:
		begin
			x = ball_x;
			y = ball_y;
			colour = 3'b100;
			S = IDLE;
		end
		
		// when ball contacts the brick changes x direction same for update brick 1-5
		
		GAME_OVER: 
		begin
			if (draw < 17'b10000000000000000)
			begin
				x = draw[7:0];
				y = draw[16:8];
				draw = draw + 1'b1;
				colour = 3'b100;
			end
		end
	endcase
	end

endmodule
	
// ======================================== Display to screen (part of the VGA)

module clock (
  input clock,
  output clk
);

reg [19:0] frame_counter;
reg frame;

always@(posedge clock)
  begin
    if (frame_counter == 20'b0) begin
      frame_counter = 20'd833332;  // This divisor gives us ~60 frames per second
      frame = 1'b1;
    end 
	 
	 else 
	 begin
      frame_counter = frame_counter - 1'b1;
      frame = 1'b0;
    end
  end

assign clk = frame;
endmodule
