module DT(
	input 			clk, 
	input			reset,
	output	reg		done ,
	output	reg		sti_rd ,
	output	reg 	[9:0]	sti_addr ,
	input		[15:0]	sti_di,
	output	reg		res_wr ,
	output	reg		res_rd ,
	output	reg 	[13:0]	res_addr ,
	output	reg 	[7:0]	res_do,
	input		[7:0]	res_di
	);

reg	[3:0] CurrentState;
reg	[3:0] NextState;

reg	[4:0] counter;
reg	[3:0] load_counter;

reg	[15:0] data;
reg	[7:0] predata[4:0];

reg	forward_load;
reg	backward_load;
reg	forward_store;
reg     backward_store;
reg	forward_calculate;
reg	backward_calculate;

always@(posedge clk or negedge reset)begin
	if(!reset)
		res_do <= 8'hff;
	else if(forward_load && load_counter == 3'h0)
		res_do <= 8'hff;
	else if(forward_calculate)begin
		if(data[counter] == 0)
			res_do <= 8'h0;
		else begin
			if(predata[load_counter] < res_do)
				res_do <= predata[load_counter] + 1;
		end
	end
	else if(backward_load && load_counter == 3'h0)
		res_do <= 8'hff;
	else if(backward_calculate)begin
		if(load_counter == 3'h4)begin
			if(predata[0] < res_do)
				res_do <= predata[0];
		end
		else begin
			if(predata[load_counter + 1] < res_do)
				res_do <= predata[load_counter + 1] + 1;
		end
	end
end

always@(posedge clk or negedge reset)begin
	if(!reset)
		res_addr <= 14'h3f7f;
	else if(forward_load && load_counter == 3'h2)
		res_addr <= res_addr + 8'h7e;
	else if(forward_load)
		res_addr <= res_addr + 1;
	else if(forward_store && res_addr != 14'h3fff)
		res_addr <= res_addr - 8'h80;
	else if(backward_load && load_counter == 3'h1)
		res_addr <= res_addr + 8'h7e;
	else if(backward_load && load_counter == 3'h4)
		res_addr <= res_addr - 8'h81;
	else if(backward_load)
		res_addr <= res_addr + 1;
	else if(backward_store)
		res_addr <= res_addr - 1;
end

always@(posedge clk or negedge reset)begin
	if(!reset)begin
		predata[0] <= 8'hf;
		predata[1] <= 8'hf;
		predata[2] <= 8'hf;
		predata[3] <= 8'hf;
		predata[4] <= 8'hff;
	end
	else if(forward_load)
		predata[load_counter] <= res_di;
	else if(backward_load)
		predata[load_counter] <= res_di;
end

always@(posedge clk or negedge reset)begin
	if(!reset)
		sti_addr <= 10'h0;
	else if(sti_rd)
		sti_addr <= sti_addr + 1;
end

always@(posedge clk or negedge reset)begin
	if(!reset)
		data <= 16'h0;
	else if(sti_rd)
		data <=  sti_di;
end

always@(posedge clk or negedge reset)begin
	if(!reset)
		counter <= 4'hf;
	else if(res_wr && counter == 4'h0)
		counter <= 4'hf;
	else if(res_wr)
		counter <= counter - 1;
end

always@(posedge clk or negedge reset)begin
	if(!reset)
		load_counter <= 3'h0;
	else if(forward_load && load_counter == 3'h3)
		load_counter <= 3'h0;
	else if(forward_load)
		load_counter <= load_counter + 1;
	else if(forward_calculate && load_counter == 3'h3)
		load_counter <= 3'h0;
	else if(forward_calculate)
		load_counter <= load_counter + 1;
	else if(backward_load && load_counter == 3'h4)
		load_counter <= 3'h0;
	else if(backward_load)
		load_counter <= load_counter + 1;
	else if(backward_calculate && load_counter == 3'h4)
		load_counter <= 3'h0;
	else if(backward_calculate)
		load_counter <= load_counter + 1;
end

always@(posedge clk or negedge reset)begin
	if(!reset)
		CurrentState <= 4'b0;
	else
		CurrentState <= NextState;
end

always@(*)begin
	case(CurrentState)
		4'h0:begin//reset
			NextState = 4'h1;
		end
		4'h1:begin//forward load1
			NextState = 4'h2;
		end
		4'h2:begin//forward load2
			if(load_counter == 3'h3)
				NextState = 4'h3;
			else
				NextState = 4'h2;
		end
		4'h3:begin//forward calculate
			if(load_counter == 3'h3)
				NextState = 4'h4;
			else
				NextState = 4'h3;
		end
		4'h4:begin//forward store
			if(sti_addr == 10'h0 && counter == 4'h0)
				NextState = 4'h5;
			else if(counter == 4'h0)
				NextState = 4'h1;
			else
				NextState = 4'h2;
		end
		4'h5:begin//backward load
			if(load_counter == 3'h4)
				NextState = 4'h6;
			else
				NextState = 4'h5;
		end
		4'h6:begin//backward calculate
			if(load_counter == 3'h4)
				NextState = 4'h7;
			else
				NextState = 4'h6;
		end
		4'h7:begin//backward store
			if(res_addr == 14'h0)
				NextState = 4'h8;
			else
				NextState = 4'h5;
		end
		4'h8:begin//finish
			NextState = 4'h8;
		end
		default:begin
			NextState = 4'h0;
		end
	endcase
end

always@(*)begin
	case(CurrentState)
		4'h0:begin//reset
			done = 0;
			sti_rd = 0;
			res_rd = 0;
			res_wr = 0;
			forward_load = 0;
			backward_load = 0;
			forward_store = 0;
			backward_store = 0;
			forward_calculate = 0;
			backward_calculate = 0;
		end
		4'h1:begin//forward load1
			done = 0;
			sti_rd = 1;
			res_rd = 0;
			res_wr = 0;
			forward_load = 0;
			backward_load = 0;
			forward_store = 0;
			backward_store = 0;
			forward_calculate = 0;
			backward_calculate = 0;
		end
		4'h2:begin//forward load2
			done = 0;
			sti_rd = 0;
			res_rd = 1;
			res_wr = 0;
			forward_load = 1;
			backward_load = 0;
			forward_store = 0;
			backward_store = 0;
			forward_calculate = 0;
			backward_calculate = 0;
		end
		4'h3:begin//forward calculate
			done = 0;
			sti_rd = 0;
			res_rd = 0;
			res_wr = 0;
			forward_load = 0;
			backward_load = 0;
			forward_store = 0;
			backward_store = 0;
			forward_calculate = 1;
			backward_calculate = 0;
		end
		4'h4:begin//forward store
			done = 0;
			sti_rd = 0;
			res_rd = 0;
			res_wr = 1;
			forward_load = 0;
			backward_load = 0;
			forward_store = 1;
			backward_store = 0;
			forward_calculate = 0;
			backward_calculate = 0;
		end
		4'h5:begin//backward load
			done = 0;
			sti_rd = 0;
			res_rd = 1;
			res_wr = 0;
			forward_load = 0;
			backward_load = 1;
			forward_store = 0;
			backward_store = 0;
			forward_calculate = 0;
			backward_calculate = 0;
		end
		4'h6:begin//backward calculate
			done = 0;
			sti_rd = 0;
			res_rd = 0;
			res_wr = 0;
			forward_load = 0;
			backward_load = 0;
			forward_store = 0;
			backward_store = 0;
			forward_calculate = 0;
			backward_calculate = 1;
		end
		4'h7:begin//backward store
			done = 0;
			sti_rd = 0;
			res_rd = 0;
			res_wr = 1;
			forward_load = 0;
			backward_load = 0;
			forward_store = 0;
			backward_store = 1;
			forward_calculate = 0;
			backward_calculate = 0;
		end
		4'h8:begin//finish
			done = 1;
			sti_rd = 0;
			res_rd = 0;
			res_wr = 0;
			forward_load = 0;
			backward_load = 0;
			forward_store = 0;
			backward_store = 0;
			forward_calculate = 0;
			backward_calculate = 0;
		end
		default:begin
			done = 0;
			sti_rd = 0;
			res_rd = 0;
			res_wr = 0;
			forward_load = 0;
			backward_load = 0;
			forward_store = 0;
			backward_store = 0;
			forward_calculate = 0;
			backward_calculate = 0;
		end
	endcase
end

endmodule
