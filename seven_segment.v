module seven_segment (
input [3:0]i,
output reg [6:0]o
);


// HEX out - rewire DE2
//  ---a---
// |       |
// f       b
// |       |
//  ---g---
// |       |
// e       c
// |       |
//  ---d---

always @(*)
begin
	case (i)

7'd0: o = 7'b0000001;

7'd1: o = 7'b1001111;

7'd2: o = 7'b0010010;

7'd3: o = 7'b0000110;

7'd4: o = 7'b1001100;

7'd5: o = 7'b0100100;

7'd6: o = 7'b0100000;

7'd7: o = 7'b0001111;

7'd8: o = 7'b0000000;

7'd9: o = 7'b0000100;

7'd10: o = 7'b0001000;

7'd11: o = 7'b1100000;

7'd12: o = 7'b0110001;

7'd13: o = 7'b1000010;

7'd14: o = 7'b0110000;

7'd15: o = 7'b0111000;

default: o = 7'b1111111;
endcase
end

endmodule