module STI_DAC(clk ,reset, load, pi_data, pi_length, pi_fill, pi_msb, pi_low, pi_end,
	       so_data, so_valid,
	       oem_finish, oem_dataout, oem_addr,
	       odd1_wr, odd2_wr, odd3_wr, odd4_wr, even1_wr, even2_wr, even3_wr, even4_wr);

input		clk;
input		reset;
input		load;
input		pi_msb;
input		pi_low;
input		pi_end;
input	[15:0]	pi_data;
input	[1:0]	pi_length;
input		pi_fill;

output	reg		so_data;
output	reg		so_valid;
output	reg	 	oem_finish;
output	reg		odd1_wr;
output	reg		odd2_wr;
output	reg		odd3_wr;
output	reg		odd4_wr;
output	reg		even1_wr;
output	reg		even2_wr;
output	reg		even3_wr;
output	reg		even4_wr;
output	reg	[4:0]	oem_addr;
output	reg	[7:0]	oem_dataout;

reg		[31:0]	data;

reg	[2:0]	CurrentState;
reg	[2:0]	NextState;

reg	[4:0]	counter;
reg		switch_odd_even;
reg	[3:0]	odd_full;
reg	[3:0]	even_full;

reg		fill;

reg	[15:0] 	pi_data_reverse;

reg	[4:0]	i;

always@(*)begin 
	for(i = 0; i < 16; i = i + 1)
		pi_data_reverse[i] = pi_data[15 - i];
end

always@(posedge clk or posedge reset)begin
	if(reset)
		data[31:0] <= 32'h0;
	else if(load)begin
		case(pi_length)
			2'h0:begin
				data[31:8] <= 24'h0;
				if(pi_low)begin
					if(pi_msb)
						data[7:0] <= pi_data[15:8];
					else
						data[7:0] <= pi_data_reverse[7:0];
				end
				else begin
					if(pi_msb)
						data[7:0] <= pi_data[7:0];
					else
						data[7:0] <= pi_data_reverse[15:8];
				end
			end
			2'h1:begin
				data[31:16] <= 16'h0;
				if(pi_msb)
					data[15:0] <= pi_data[15:0];
				else
					data[15:0] <= pi_data_reverse[15:0];
			end
			2'h2:begin
				if(pi_fill)begin
					if(pi_msb)begin
						data[23:8] <= pi_data[15:0];
						data[7:0] <= 8'h0;
					end
					else begin
						data[23:16] <= 8'h0;
						data[15:0] <= pi_data_reverse[15:0];
					end
				end
				else begin
					if(pi_msb)begin
						data[23:16] <= 8'h0;
						data[15:0] <= pi_data[15:0];
					end
					else begin
						data[23:8] <= pi_data_reverse[15:0];
						data[7:0] <= 8'h0;
					end
				end
			end
			2'h3:begin
				if(pi_fill)begin
					if(pi_msb)begin
						data[31:16] <= pi_data[15:0];
						data[15:0] <= 16'h0;
					end
					else begin
						data[31:16] <= 16'h0;
						data[15:0] <= pi_data_reverse[15:0];
					end
				end
				else begin
					if(pi_msb)begin
						data[31:16] <= 16'h0;
						data[15:0] <= pi_data[15:0];
					end
					else begin
						data[31:16] <= pi_data_reverse[15:0];
						data[15:0] <= 16'h0;
					end
				end
			end
		endcase
	end
end

always@(*)begin
	if(so_valid)begin
		case(pi_length)
			2'h0:
				so_data = data[7 - counter];
			2'h1:
				so_data = data[15 - counter];
			2'h2:
				so_data = data[23 - counter];
			2'h3:
				so_data = data[31 - counter];
		endcase
	end
	else
		so_data = 1'h0;
end

always@(posedge clk or posedge reset)begin
	if(reset)
		switch_odd_even <= 1'h0;
	else if(counter[2:0] == 3'h7)
		switch_odd_even <= switch_odd_even + 1'h1;
end

always@(posedge clk or posedge reset)begin
	if(reset)begin
		odd_full <= 4'h0;
		even_full <= 4'h0;
	end
	else begin
		if(counter[2:0] == 3'h7 && oem_addr == 5'h1f && switch_odd_even == 1'h0 && even_full == 4'h0)
			even_full <= 4'h1;
		else if(counter[2:0] == 3'h7 && oem_addr == 5'h1f && switch_odd_even == 1'h0 && even_full == 4'h1)
			even_full <= 4'h3;
		else if(counter[2:0] == 3'h7 && oem_addr == 5'h1f && switch_odd_even == 1'h0 && even_full == 4'h3)
			even_full <= 4'h7;
		else if(counter[2:0] == 3'h7 && oem_addr == 5'h1f && switch_odd_even == 1'h0 && even_full == 4'h7)
			even_full <= 4'hf;
		if(counter[2:0] == 3'h7 && oem_addr == 5'h1f && switch_odd_even == 1'h1 && odd_full == 4'h0)
			odd_full <= 4'h1;
		else if(counter[2:0] == 3'h7 && oem_addr == 5'h1f && switch_odd_even == 1'h1 && odd_full == 4'h1)
			odd_full <= 4'h3;
		else if(counter[2:0] == 3'h7 && oem_addr == 5'h1f && switch_odd_even == 1'h1 && odd_full == 4'h3)
			odd_full <= 4'h7;
		else if(counter[2:0] == 3'h7 && oem_addr == 5'h1f && switch_odd_even == 1'h1 && odd_full == 4'h7)
			odd_full <= 4'hf;
	end
end

always@(posedge clk or posedge reset)begin
	if(reset)begin
		odd1_wr <= 1'h0;
		odd2_wr <= 1'h0;
		odd3_wr <= 1'h0;
		odd4_wr <= 1'h0;
		even1_wr <= 1'h0;
		even2_wr <= 1'h0;
		even3_wr <= 1'h0;
		even4_wr <= 1'h0;
	end
	else if(counter[2:0] == 3'h1)begin
		if(oem_addr[2])begin
			if(switch_odd_even)begin
				case(odd_full)
					4'h0:odd1_wr <= 1'h1;
					4'h1:odd2_wr <= 1'h1;
					4'h3:odd3_wr <= 1'h1;
					4'h7:odd4_wr <= 1'h1;
				endcase
			end
			else begin
				case(even_full)
					4'h0:even1_wr <= 1'h1;
					4'h1:even2_wr <= 1'h1;
					4'h3:even3_wr <= 1'h1;
					4'h7:even4_wr <= 1'h1;
				endcase
			end
		end
		else begin
			if(switch_odd_even)begin
				case(even_full)
					4'h0:even1_wr <= 1'h1;
					4'h1:even2_wr <= 1'h1;
					4'h3:even3_wr <= 1'h1;
					4'h7:even4_wr <= 1'h1;
				endcase
			end
			else begin
				case(odd_full)
					4'h0:odd1_wr <= 1'h1;
					4'h1:odd2_wr <= 1'h1;
					4'h3:odd3_wr <= 1'h1;
					4'h7:odd4_wr <= 1'h1;
				endcase
			end
		end
	end
	else if(counter[2:0] == 3'h2)begin
		odd1_wr <= 1'h0;
		odd2_wr <= 1'h0;
		odd3_wr <= 1'h0;
		odd4_wr <= 1'h0;
		even1_wr <= 1'h0;
		even2_wr <= 1'h0;
		even3_wr <= 1'h0;
		even4_wr <= 1'h0;
	end
end

always@(posedge clk or posedge reset)begin
	if(reset)
		oem_addr <= 5'h0;
	else if(counter[2:0] == 3'h7 && switch_odd_even)
		oem_addr <= oem_addr + 1'h1;
end

always@(posedge clk or posedge reset)begin
	if(reset)
		oem_dataout <= 8'h0;
	else if(fill == 1'h0 && counter[2:0] == 3'h1)begin
		case(pi_length)
			2'h0:begin
				oem_dataout <= data[7:0];
			end
			2'h1:begin
				case(counter)
					5'h1:
						oem_dataout <= data[15:8];
					5'h9:
						oem_dataout <= data[7:0];
				endcase
			end
			2'h2:begin
				case(counter)
					5'h1:
						oem_dataout <= data[23:16];
					5'h9:
						oem_dataout <= data[15:8];
					5'h11:
						oem_dataout <= data[7:0];
				endcase
			end
			2'h3:begin
				case(counter)
					5'h1:
						oem_dataout <= data[31:24];
					5'h9:
						oem_dataout <= data[23:16];
					5'h11:
						oem_dataout <= data[15:8];
					5'h19:
						oem_dataout <= data[7:0];
				endcase
			end
		endcase
	end
	else if(fill)
		oem_dataout <= 8'h0;
end

always@(posedge clk or posedge reset)begin
	if(reset)
		counter <= 5'h0;
	else if(so_valid && pi_length == 2'h0 && counter == 5'h7)
		counter <= 5'h0;
	else if(so_valid && pi_length == 2'h1 && counter == 5'hf)
		counter <= 5'h0;
	else if(so_valid && pi_length == 2'h2 && counter == 5'h17)
		counter <= 5'h0;
	else if(so_valid && pi_length == 2'h3 && counter == 5'h1f)
		counter <= 5'h0;
	else if(so_valid)
		counter <= counter + 1'h1;
	else if(fill && counter == 5'h7)
		counter <= 5'h0;
	else if(fill)
		counter <= counter + 1'h1;
end

always@(posedge clk or posedge reset)begin
	if(reset)
		CurrentState <= 3'h0;
	else if(load)
		CurrentState <= 3'h1;
	else
		CurrentState <= NextState;
end

always@(*)begin
	case(CurrentState)
		3'h0:begin
			NextState = 3'h1;
		end
		3'h1:begin
			NextState = 3'h2;
		end
		3'h2:begin
			if(pi_end)begin
				if(pi_length == 2'h0 && counter == 5'h7)
					NextState = 3'h3;
				else if(pi_length == 2'h1 && counter == 5'hf)
					NextState = 3'h3;
				else if(pi_length == 2'h2 && counter == 5'h17)
					NextState = 3'h3;
				else if(pi_length == 2'h3 && counter == 5'h1f)
					NextState = 3'h3;
				else
					NextState = 3'h2;
			end
			else begin
				if(pi_length == 2'h0 && counter == 5'h7)
					NextState = 3'h0;
				else if(pi_length == 2'h1 && counter == 5'hf)
					NextState = 3'h0;
				else if(pi_length == 2'h2 && counter == 5'h17)
					NextState = 3'h0;
				else if(pi_length == 2'h3 && counter == 5'h1f)
					NextState = 3'h0;
				else
					NextState = 3'h2;
			end
		end
		3'h3:begin
			if(oem_addr == 5'h1f && counter == 5'h7 && switch_odd_even && odd_full == 4'h7)
				NextState = 3'h4;
			else
				NextState = 3'h3;
		end
		3'h4:begin
			NextState = 3'h4;
		end
		default:begin
			NextState = 3'h0;
		end
	endcase
end

always@(*)begin
	case(CurrentState)
		3'h0:begin
			so_valid = 0;
			oem_finish = 0;
			fill = 0;
		end
		3'h1:begin
			so_valid = 0;
			oem_finish = 0;
			fill = 0;
		end
		3'h2:begin
			so_valid = 1;
			oem_finish = 0;
			fill = 0;
		end
		3'h3:begin
			so_valid = 0;
			oem_finish = 0;
			fill = 1;
		end
		3'h4:begin
			so_valid = 0;
			oem_finish = 1;
			fill = 0;
		end
		default:begin
			so_valid = 0;
			oem_finish = 0;
			fill = 0;
		end
	endcase
end

endmodule
