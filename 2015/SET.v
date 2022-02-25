module SET ( clk , rst, en, central, radius, mode, busy, valid, candidate );

input		clk;
input		rst;
input		en;
input	[23:0]	central;
input	[11:0]	radius;
input	[1:0]	mode;
output		busy;
output		valid;
output	[7:0]	candidate;

reg		busy;
reg		valid;
reg	[7:0]	candidate;

reg	[2:0]	CurrentState;
reg	[2:0]	NextState;

reg	[2:0]	coordinate_x;
reg	[2:0]	coordinate_y;
reg	[4:0]	counter;

reg	[5:0]	A;
reg	[5:0]	B;
reg	[5:0]	A_and_B;
reg	[5:0]	A_and_C;
reg	[5:0]	B_and_C;
reg	[5:0]	A_and_B_and_C;

reg	signed	[3:0]	multiplier;
reg	[7:0]	Result_A;
reg	[7:0]	Result_B;
reg	[7:0]	Result_C;

reg		calculate;

wire	[7:0]	Square;

assign	Square = multiplier * multiplier;

always@(posedge clk or posedge rst)begin
	if(rst)
		Result_A <= 8'h0;
	else if(calculate && counter == 5'h1)
		Result_A <= Square;
	else if(calculate && counter == 5'h3)
		Result_A <= Result_A - Square;
	else if(calculate && counter == 5'h5)
		Result_A <= Result_A - Square;
end

always@(posedge clk or posedge rst)begin
	if(rst)
		Result_B <= 8'h0;
	else if(calculate && counter == 5'h7)
		Result_B <= Square;
	else if(calculate && counter == 5'h9)
		Result_B <= Result_B - Square;
	else if(calculate && counter == 5'hb)
		Result_B <= Result_B - Square;
end

always@(posedge clk or posedge rst)begin
	if(rst)
		Result_C <= 8'h0;
	else if(calculate && counter == 5'hd)
		Result_C <= Square;
	else if(calculate && counter == 5'hf)
		Result_C <= Result_C - Square;
	else if(calculate && counter == 5'h11)
		Result_C <= Result_C - Square;
end

always@(posedge clk or posedge rst)begin
	if(rst)
		multiplier <= 4'h0;
	else if(calculate)begin
		case(counter)
			5'h0:
				multiplier <= radius[11:8];
			5'h2:
				multiplier <= central[23:20] - coordinate_x - 1;
			5'h4:
				multiplier <= central[19:16] - coordinate_y - 1;
			5'h6:
				multiplier <= radius[7:4];
			5'h8:
				multiplier <= central[15:12] - coordinate_x - 1;
			5'ha:
				multiplier <= central[11:8] - coordinate_y - 1;
			5'hc:
				multiplier <= radius[3:0];
			5'he:
				multiplier <= central[7:4] - coordinate_x - 1;
			5'h10:
				multiplier <= central[3:0] - coordinate_y - 1;
		endcase
	end
end

always@(posedge clk or posedge rst)begin
	if(rst)
		A_and_B_and_C <= 8'h0;
	else if(valid)
		A_and_B_and_C <= 8'h0;
	else if(calculate && counter == 5'h12)begin
		if(Result_A[7] == 1'h0 && Result_B[7] == 1'h0 && Result_C[7] == 1'h0)
			A_and_B_and_C <= A_and_B_and_C + 1'h1;
	end
end

always@(posedge clk or posedge rst)begin
	if(rst)
		A_and_C <= 8'h0;
	else if(valid)
		A_and_C <= 8'h0;
	else if(calculate && counter == 5'h12)begin
		if(Result_A[7] == 1'h0 && Result_C[7] == 1'h0)
			A_and_C <= A_and_C + 1'h1;
	end
end

always@(posedge clk or posedge rst)begin
	if(rst)
		B_and_C <= 8'h0;
	else if(valid)
		B_and_C <= 8'h0;
	else if(calculate && counter == 5'h12)begin
		if(Result_B[7] == 1'h0 && Result_C[7] == 1'h0)
			B_and_C <= B_and_C + 1'h1;
	end
end

always@(posedge clk or posedge rst)begin
	if(rst)
		A_and_B <= 8'h0;
	else if(valid)
		A_and_B <= 8'h0;
	else if(calculate && counter == 5'h12)begin
		if(Result_A[7] == 1'h0 && Result_B[7] == 1'h0)
			A_and_B <= A_and_B + 1'h1;
	end
end

always@(posedge clk or posedge rst)begin
	if(rst)
		B <= 8'h0;
	else if(valid)
		B <= 8'h0;
	else if(calculate && counter == 5'h12)begin
		if(Result_B[7] == 1'h0)
			B <= B + 1'h1;
	end
end

always@(posedge clk or posedge rst)begin
	if(rst)
		A <= 8'h0;
	else if(valid)
		A <= 8'h0;
	else if(calculate && counter == 5'h12)begin
		if(Result_A[7] == 1'h0)
			A <= A + 1'h1;
	end	
end

always@(posedge clk or posedge rst)begin
	if(rst)
		coordinate_y <= 3'h0;
	else if(calculate && counter == 5'h12 && coordinate_x == 3'h7 && coordinate_y == 3'h7) 
		coordinate_y <= 3'h0;
	else if(calculate && counter == 5'h12 && coordinate_x == 3'h7)
		coordinate_y <= coordinate_y + 1'h1;
end

always@(posedge clk or posedge rst)begin
	if(rst)
		coordinate_x <= 3'h0;
	else if(calculate && counter == 5'h12 && coordinate_x == 3'h7)
		coordinate_x <= 3'h0;
	else if(calculate && counter == 5'h12)
		coordinate_x <= coordinate_x + 1'h1;
end

always@(posedge clk or posedge rst)begin
	if(rst)
		counter <= 5'h0;
	else if(calculate && counter == 5'h12)
		counter <= 5'h0;
	else if(calculate)
		counter <= counter + 1'h1;
end

always@(posedge clk or posedge rst)begin
	if(rst)
		candidate <= 8'h0;
	else if(mode == 2'h0) 
		candidate <= A;
	else if(mode == 2'h1)
		candidate <= A_and_B;
	else if(mode == 2'h2)
		candidate <= A + B - A_and_B - A_and_B;
	else if(mode == 2'h3)
		candidate <= A_and_B + B_and_C + A_and_C - A_and_B_and_C - A_and_B_and_C - A_and_B_and_C;
end

always@(posedge clk or posedge rst)begin
	if(rst)
		CurrentState <= 3'h0;
	else
		CurrentState <= NextState;
end

always@(*)begin
	case(CurrentState)
		3'h0://reset
			NextState = 3'h1;
		3'h1://read data
			NextState = 3'h2;
		3'h2:begin//calculate
			if(coordinate_x == 3'h7 && coordinate_y == 3'h7 && counter == 5'h12)
				NextState = 3'h3;
			else
				NextState = 3'h2;
		end
		3'h3://write data
			NextState = 3'h4;
		3'h4://output
			NextState = 3'h0;
		default:
			NextState = 3'h0;
	endcase
end

always@(*)begin
	case(CurrentState)
		3'h0:begin
			busy = 0;
			valid = 0;
			calculate = 0;
		end
		3'h1:begin
			busy = 0;
			valid = 0;
			calculate = 0;
		end
		3'h2:begin
			busy = 1;
			valid = 0;
			calculate = 1;
		end
		3'h3:begin
			busy = 1;
			valid = 0;
			calculate = 0;
		end
		3'h4:begin
			busy = 1;
			valid = 1;
			calculate = 0;
		end
		default:begin
			busy = 0;
			valid = 0;
			calculate = 0;
		end
	endcase
end

endmodule


