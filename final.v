module final(clk, rst, button,button2, led, VGA_CLK, VGA_VS, VGA_HS, VGA_BLANK_N, VGA_SYNC_N, VGA_R, VGA_G, VGA_B, HEX0, HEX2);

output [6:0] HEX0, HEX2;
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
reg [5:0] NS;
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

reg [3:0] left_score;
reg [3:0] right_score;

assign led[5:0] = S; //displaying what state we are in

seven_segment left(left_score, HEX0);
seven_segment right(right_score, HEX2);
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
	WAIT_FOR_PLAYERS	= 6'd17,
	WIN_LEFT			= 6'd18,
	WIN_RIGHT		= 6'd19,
	SCORE_LEFT		= 6'd20,
	SCORE_RIGHT		= 6'd21,
	ERROR 			= 6'hF;

always @(posedge clk)
begin

	if ( rst == 1'b0 )
		S <= START;
	else
		S <= NS;
end

always @(*) 
begin
		case (S)
			START:
			begin
				if (draw < 17'b10000000000000000)
					NS = START;
				else
					NS =  INIT_PADDLE;
			end
			INIT_PADDLE:
			begin
				if (draw < 6'b10000)
					NS = INIT_PADDLE;
				else
					NS = INIT_PADDLE_2;
			end
			INIT_PADDLE_2:
			begin
				if (draw < 6'b10000)
					NS = INIT_PADDLE_2;
				else
					NS = INIT_BALL;
			end
			INIT_BALL: NS = WAIT_FOR_PLAYERS;
			WAIT_FOR_PLAYERS:
			begin
			if ( (~button[1] || ~button[2] )|| (~button2[2] || ~button2[1]) )
				NS = IDLE;
			else
				NS = WAIT_FOR_PLAYERS;
			end
			IDLE:
			begin
				if (frame)
					NS = ERASE_PADDLE;
				else 
					NS = IDLE;
			end
			ERASE_PADDLE:
			begin
				if (draw < 6'b100000)
					NS = ERASE_PADDLE;
				else
					NS = UPDATE_PADDLE;
			end
			UPDATE_PADDLE: NS = DRAW_PADDLE;
			DRAW_PADDLE: 
			begin
				if (draw < 6'b100000 )
					NS = DRAW_PADDLE;
				else 
					NS = ERASE_PADDLE_2;
			end
			ERASE_PADDLE_2:
			begin
				if (draw < 6'b100000)
					NS = ERASE_PADDLE_2;
				else
					NS = UPDATE_PADDLE_2;
			end
			UPDATE_PADDLE_2: NS = DRAW_PADDLE_2;
			DRAW_PADDLE_2: 
			begin
				if (draw < 6'b100000 )
					NS = DRAW_PADDLE_2;
				else 
					NS = ERASE_BALL;
			end
			ERASE_BALL: NS = UPDATE_BALL;
			UPDATE_BALL:
			begin
				if (ball_x <= 8'd0) 
					NS = SCORE_LEFT;
				else if (ball_x >= 8'd160) 
					NS = SCORE_RIGHT;
				else
					NS = DRAW_BALL;
			end
			DRAW_BALL: NS = IDLE;
			SCORE_LEFT: 
			begin
				if ( left_score < 3)
					NS = START;
				else
					NS = GAME_OVER;
			end
			SCORE_RIGHT: 
			begin
				if ( right_score < 3)
					NS = START;
				else
					NS = GAME_OVER;
			end
			GAME_OVER: NS = GAME_OVER;
	endcase
end
	
	// Calling clock to display
	clock(.clock(clk), .clk(frame));
	
	// ===================================== FSM
	
always @(posedge clk) 
begin
	border_init <= 1'b0;
	paddle_init <= 1'b0;
	ball_init <= 1'b0;
	brick_init <= 1'b0;
	colour <= 3'b000; // Background color
	x <= 8'b00000000;
	y <= 8'b00000000;
	if (~rst) begin
		left_score <= 4'd0;
		right_score <= 4'd0;
	end
	case (S)
	
		START: 
		begin
			if (draw < 17'b10000000000000000)
			begin
				x <= draw[7:0];
				y <= draw[16:8];
				draw <= draw + 1'b1;
			end 
			else 
			begin
				draw <= 8'b00000000;
			end
		end
		
		INIT_PADDLE: 
		begin
			if (draw < 6'b10000)
			begin
				pad_x <= 8'd10;		//Placement of paddle
				pad_y <= 8'd52; 	// Placement of paddle
				x <= pad_x;		//size of paddle (x)
				y <= pad_y + draw[3:0];	//size of paddle (y)
				draw <= draw + 1'b1;
				colour <= 3'b000;
			end 
			else 
			begin
				draw <= 8'b00000000;
			end
		end
		INIT_PADDLE_2: 
		begin
			if (draw < 6'b10000)
			begin
				pad2_x <= 8'd150;		//Placement of paddle
				pad2_y <= 8'd52; 	// Placement of paddle
				x <= pad2_x;		//size of paddle (x)
				y <= pad2_y + draw[3:0];	//size of paddle (y)
				draw <= draw + 1'b1;
				colour <= 3'b000;
			end 
			else 
			begin
				draw <= 8'b00000000;
			end
		end
		
		INIT_BALL: 
		begin
			ball_x <= 8'd80;	// Placement of ball
			ball_y <= 8'd60; 	// Placement of ball
			x <= ball_x;
			y <= ball_y;
			colour <= 3'b000;
		end	
	
		ERASE_PADDLE:
		begin
			if (draw < 6'b100000) 
			begin
				x <= pad_x + draw[7]; // Same as init_paddle
				y <= pad_y + draw[3:0];
				draw <= draw + 1'b1;
			end 
			else 
			begin
				draw <= 8'b00000000;
			end
		end

		UPDATE_PADDLE: 
		begin
			if (~button[1] && pad_y < -8'd152) pad_y = pad_y + 2'd2; // Moves paddle up (Chnages lower bound)
			if (~button[2] && pad_y > 8'd0) pad_y = pad_y - 2'd2; // Moves paddle down (Changes upper bound)							
		end
		
		DRAW_PADDLE: 
		begin
			if (draw < 6'b100000) 
			begin
				x <= pad_x;
				y <= pad_y + draw[3:0];
				draw <= draw + 1'b1;
				colour <= 3'b111;
			end 
			else 
			begin
				draw <= 8'b00000000;
			end
		end
		
			
		ERASE_PADDLE_2:
		begin
			if (draw < 6'b100000) 
			begin
				x <= pad2_x + draw[7]; // Same as init_paddle
				y <= pad2_y + draw[3:0];
				draw <= draw + 1'b1;
			end 
			else 
			begin
				draw <= 8'b00000000;
			end
		end

		UPDATE_PADDLE_2: 
		begin
			if (~button2[1] && pad2_y < -8'd152) 
				pad2_y <= pad2_y + 2'd2; // Moves paddle up (Chnages lower bound)
			if (~button2[2] && pad2_y > 8'd0) 
				pad2_y <= pad2_y - 2'd2; // Moves paddle down (Changes upper bound)							
		end
		
		DRAW_PADDLE_2: 
		begin
			if (draw < 6'b100000) 
			begin
				x <= pad2_x;
				y <= pad2_y + draw[3:0];
				draw <= draw + 1'b1;
				colour <= 3'b111;
			end 
			else 
			begin
				draw <= 8'b00000000;
			end
		end
		
		ERASE_BALL: 
		begin
			x <= ball_x;
			y <= ball_y;
		end
		
		UPDATE_BALL: 
		begin
			if ((ball_y == 8'd0) || (ball_y == -8'd136))
				ball_ydir = ~ball_ydir;
			if (~ball_xdir)
				ball_x <= ball_x + 2'd2; // moves ball right
			else
				ball_x <= ball_x - 2'd2; // moves ball left
				
			if (ball_ydir) 
				ball_y <= ball_y + 2'd2; // moves ball up
			else 
				ball_y <= ball_y - 2'd2; // moves ball down
				
			if ((ball_x == 8'd0) || (ball_x == 8'd160) || ((ball_xdir) && (ball_x > pad_x - 8'd1) && 
			   (ball_x < pad_x + 8'd3) && (ball_y >= pad_y) && (ball_y <= pad_y + 8'd15))) 
				ball_xdir <= ~ball_xdir;
			
			else if (((~ball_xdir) && (ball_x < pad2_x + 8'd1) && 
			   (ball_x > pad2_x - 8'd3) && (ball_y >= pad2_y) && (ball_y <= pad2_y + 8'd15)))
				ball_xdir <= ~ball_xdir;

			

			end
		SCORE_LEFT: left_score <= left_score + 4'd1;


		SCORE_RIGHT: right_score <= right_score + 4'd1;
		DRAW_BALL:
		begin
			x <= ball_x;
			y <= ball_y;
			colour <= 3'b100;
		end
		
		// when ball contacts the brick changes x direction same for update brick 1-5
		
		GAME_OVER: 
		begin
			if (draw < 17'b10000000000000000)
			begin
				x <= draw[7:0];
				y <= draw[16:8];
				draw <= draw + 1'b1;
				colour <= 3'b100;
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
