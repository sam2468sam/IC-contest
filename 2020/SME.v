module SME(clk,reset,chardata,isstring,ispattern,valid,match,match_index);
input	clk;
input 	reset;
input 	[7:0]chardata;
input 	isstring;
input 	ispattern;
output 	match;
output 	[4:0]match_index;
output 	valid;

reg 	match;
reg 	valid;

reg	[2:0]CurrentState;
reg     [2:0]NextState;
reg	load_string;
reg	load_pattern;
reg	calculate;
reg	calculate_finish;

reg	[4:0]string_counter;
reg     [4:0]string_counter1;
reg	[7:0]strings[31:0];

reg     [3:0]pattern_counter;
reg	[7:0]patterns[7:0];

reg	hit;
reg	star;

reg	[5:0]i;
reg	[3:0]j;
reg	[5:0]index;
reg	[5:0]index_i;
reg	[3:0]index_j;

integer	k;

assign match_index = (star) ? index : index_i;

always@(*)begin
	if(calculate && (i > string_counter || (j > pattern_counter - 1)))
		calculate_finish = 1;
	else
		calculate_finish = 0;
end

always@(posedge clk or posedge reset)begin
	if(reset)begin
		i <= 6'b0;
		j <= 4'b0;
		index <= 6'b0;
		index_i <= 6'b0;
		index_j <= 4'b0;
		hit <= 0;
		star <= 0;
		match <= 0;
	end
	else if(valid)begin
		i <= 6'b0;
                j <= 4'b0;
                index <= 6'b0;
                index_i <= 6'b0;
                index_j <= 4'b0;
		hit <= 0;
                star <= 0;
		match <= 0;
	end
	else if(calculate)begin
		if(patterns[j] == 8'h2a)begin
			if(j == pattern_counter - 1)
				match <= 1;
			hit <= 1;
			star <= 1;
			index <= index_i;
			index_i <= i;
			index_j <= j + 1;
			j <= j + 1;
		end
		else if(patterns[j] == 8'h5e)begin
			if(i == 6'b0)begin
				hit <= 1;
				index_i <= i;
				j <= j + 1;
			end
			else if(strings[i] == 8'h20)begin
				hit <= 1;
				index_i <= i + 1;
				i <= i + 1;
				j <= j + 1;
			end
			else
				i <= i + 1;
		end
		else if((patterns[j] == 8'h2e) || (patterns[j] == strings[i]))begin
			if(j == pattern_counter - 1)begin
				if(hit == 0)
					index_i <= i;
                                match <= 1;
				i <= i + 1;
                                j <= j + 1;
			end
			else if((j == pattern_counter - 2) && (patterns[j + 1] == 8'h24))begin
				if((i == string_counter) || (strings[i + 1] == 8'h20))begin
					if(hit == 0)
                                        	index_i <= i;
					match <= 1;
					i <= i + 2;
                                	j <= j + 2;
				end
				else begin
					i <= index_i + 1;
                               		j <= index_j;
                               		hit <= 0;
				end
			end
			else if(hit == 0)begin
				hit <= 1;
				index_i <= i;
				i <= i + 1;
				j <= j + 1;
			end
			else begin
				i <= i + 1;
                                j <= j + 1;
			end
		end
		else if(patterns[j] != strings[i])begin
			if(hit)begin
				i <= index_i + 1;
				j <= index_j;
				hit <= 0;
			end
			else begin
				i <= i + 1;
				j <= index_j;
			end
		end
	end
end

always@(posedge clk or posedge reset)begin
	if(reset)
		string_counter <= 5'b0;
	else if(CurrentState == 3'b0 && isstring)
		string_counter <= 5'b0;
	else if(valid && isstring)
                string_counter <= 5'b0;
	else if(isstring)
		string_counter <= string_counter + 5'b1;
end

always@(posedge clk or posedge reset)begin
	if(reset)
		string_counter1 <= 5'b0;
	else if(ispattern)
		string_counter1 <= 5'b0;
	else if(isstring)
		string_counter1 <= string_counter1 + 5'b1;
end

always@(posedge clk or posedge reset)begin
	if(reset)begin
		for(k = 0; k < 32; k = k + 1)
			strings[k] <= 8'b0;
	end
	else if(isstring)
		strings[string_counter1] <= chardata;
end

always@(posedge clk or posedge reset)begin
	if(reset)
                pattern_counter <= 4'b0;
	else if(calculate_finish)
                pattern_counter <= 4'b0;
	else if(ispattern)
		pattern_counter <= pattern_counter + 4'b1;
end

always@(posedge clk or posedge reset)begin
	if(reset)begin
		for(k = 0; k < 8; k = k + 1)
                        patterns[k] <= 8'b0;
	end
	else begin
        	if(ispattern)
                	patterns[pattern_counter] <= chardata;
	end
end

always@(posedge clk or posedge reset)begin
	if(reset)
		CurrentState <= 3'b0;
	else
		CurrentState <= NextState;
end

always@(*)begin
	case(CurrentState)
		3'b0:begin
			if(isstring)
				NextState = 3'b001;
			else
				NextState = 3'b0;
		end
		3'b001:begin
			if(ispattern)
				NextState = 3'b010;
			else
				NextState = 3'b001;
                end
		3'b010:begin
			if(!ispattern)
				NextState = 3'b011;
			else
				NextState = 3'b010;
                end
		3'b011:begin
			if(calculate_finish)
				NextState = 3'b100;
			else
				NextState = 3'b011;
                end
		3'b100:begin
			if(isstring)
				NextState = 3'b001;
			else
				NextState = 3'b010;
		end
		default:
			NextState = 3'b0;
	endcase
end

always@(*)begin
	case(CurrentState)
		3'b0:begin
			valid = 0;
			load_string = 0;
			load_pattern = 0;
			calculate = 0;
                end
                3'b001:begin
			valid = 0;
			load_string = 1;
			load_pattern = 0;
			calculate = 0;
                end
                3'b010:begin
			valid = 0;
			load_string = 0;
			load_pattern = 1;
			calculate = 0;
                end
                3'b011:begin
			valid = 0;
			load_string = 0;
			load_pattern = 0;
			calculate = 1;
                end
                3'b100:begin
			valid = 1;
			load_string = 0;
			load_pattern = 0;
			calculate = 0;
		end
                default:begin
			valid = 0;
			load_string = 0;
			load_pattern = 0;
			calculate = 0;
		end
        endcase
end

endmodule
