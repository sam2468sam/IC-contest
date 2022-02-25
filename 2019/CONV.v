
`timescale 1ns/10ps

module  CONV(
	/*input*/		clk,
	/*input*/		reset,
	/*output*/		busy,	
	/*input*/		ready,	
			
	/*output*/		iaddr,
	/*input*/		idata,	
	
	/*output*/	 	cwr,
	/*output*/	 	caddr_wr,
	/*output*/	 	cdata_wr,
	
	/*output*/	 	crd,
	/*output*/	 	caddr_rd,
	/*input*/	 	cdata_rd,
	
	/*output*/	 	csel
	);

input	clk;
input	reset;
input	ready;
input	[19:0]idata;
input	[19:0]cdata_rd;

output	busy;
output	crd;
output	cwr;
output	[2:0]csel;
output	[11:0]iaddr;
output	[11:0]caddr_rd;
output	[11:0]caddr_wr;
output	[19:0]cdata_wr;

wire	signed	[19:0]kernel1[8:0];
wire	signed	[19:0]bias1;

wire	signed	[19:0]kernel2[8:0];
wire	signed	[19:0]bias2;

reg	signed	[19:0]input_data[8:0];
reg     signed  [39:0]partial_sum1[8:0];
reg     signed  [39:0]partial_sum2[8:0];
reg	signed	[39:0]sum1;
reg     signed	[39:0]sum2;
reg	[19:0]rounding_sum1;
reg     [19:0]rounding_sum2;

reg	[3:0]CurrentState;
reg     [3:0]NextState;
reg	[3:0]counter;
reg	kernel_number;

//cls = convolution load input state
//ccs = convolution calculate state
//cws = convolution write state
//mls = maxpooling load input state
//mcs = maxpooling calculate state
//mws = maxpooling write state
//fls = flatten load input state
//fws = flatten write state
reg	cls, ccs, cws, mls, mcs, mws, fls, fws;

reg	busy;
reg	crd;
reg	cwr;
reg	[2:0]csel;
reg	[11:0]iaddr;
reg	[11:0]caddr_rd;
reg	[11:0]caddr_wr;

assign	kernel1[0] = 20'h0A89E;
assign	kernel1[1] = 20'h092D5;
assign	kernel1[2] = 20'h06D43;
assign	kernel1[3] = 20'h01004;
assign	kernel1[4] = 20'hF8F71;
assign	kernel1[5] = 20'hF6E54;
assign	kernel1[6] = 20'hFA6D7;
assign	kernel1[7] = 20'hFC834;
assign	kernel1[8] = 20'hFAC19;

assign	bias1 = 20'h01310;

assign  kernel2[0] = 20'hFDB55;
assign  kernel2[1] = 20'h02992;
assign  kernel2[2] = 20'hFC994;
assign  kernel2[3] = 20'h050FD;
assign  kernel2[4] = 20'h02F20;
assign  kernel2[5] = 20'h0202D;
assign  kernel2[6] = 20'h03BD7;
assign  kernel2[7] = 20'hFD369;
assign  kernel2[8] = 20'h05E68;

assign  bias2 = 20'hF7295;

assign	cdata_wr = (kernel_number) ? rounding_sum2 : rounding_sum1;

always@(posedge clk)begin //control which filter convolution
        if(!busy)
                kernel_number <= 0;
        else begin
                if(ccs && counter == 12)
                        kernel_number <= kernel_number + 1;
		else if(cws)
			kernel_number <= kernel_number + 1;
		else if(mls && counter == 3)
			kernel_number <= kernel_number + 1;
		else if(mws)
                        kernel_number <= kernel_number + 1;
		else if(fls)
			kernel_number <= kernel_number + 1;
		else if(fws)
                        kernel_number <= kernel_number + 1;
        end
end

always@(posedge clk)begin //control the number of cycle in every state
        if(!busy)
                counter <= 0;
        else begin
                if(cls && counter == 8)
                	counter <= 0;
		else if(ccs && counter == 12)
			counter <= 0;
		else if(cws)
			counter <= 0;
		else if(mls && counter == 3)
                        counter <= 0;
		else if(mcs && counter == 1)
                        counter <= 0;
		else if(mws)
                        counter <= 0;
		else if(fls)
                        counter <= 0;
		else if(fws)
                        counter <= 0;
		else
			counter <= counter + 1;
        end
end

always@(posedge clk)begin //control the address for load & write
	if(!busy)begin
                kernel_number <= 0;
                iaddr <= 12'b111110111111;
		caddr_rd <= 0;
		caddr_wr <= 0;
        end
        else begin
		if(cls)begin
			if(counter == 8)
				iaddr <= iaddr - 130;
			else if(counter == 2 || counter == 5)
				iaddr <= iaddr + 62;
			else
				iaddr <= iaddr + 1;
		end
		else if(cws && kernel_number)begin
			caddr_wr <= caddr_wr + 1;
			iaddr <= iaddr + 1;
		end
		else if(mls)begin
			if(counter == 3)
				caddr_rd <= caddr_rd - 65;
			else if(counter == 1)
				caddr_rd <= caddr_rd + 63;
			else
				caddr_rd <= caddr_rd + 1;
		end
		else if(mws && kernel_number)begin
			if(caddr_wr[4:0] == 5'b11111)
                		caddr_rd <= caddr_rd + 66;
			else
				caddr_rd <= caddr_rd + 2;
			if(caddr_wr == 1023 && kernel_number)
				caddr_wr <= 0;
			else
				caddr_wr <= caddr_wr + 1;
                end
		else if(fls && kernel_number)
			caddr_rd <= caddr_rd + 1;
		else if(fws)
			caddr_wr <= caddr_wr + 1;
	end
end

always@(posedge clk)begin //control the register for input data 
	if(cls)begin
		if(caddr_wr == 0)begin //top left
			if(counter < 3 || counter % 3 == 0)
                                input_data[counter] <= 0;
                        else
                                input_data[counter] <= idata;
		end
		else if(caddr_wr == 63)begin //top right
			if(counter < 3 || counter % 3 == 2)
                                input_data[counter] <= 0;
                        else
                                input_data[counter] <= idata;
		end
		else if(caddr_wr == 4032)begin //bottom left
			if(counter > 5 || counter % 3 == 0)
                                input_data[counter] <= 0;
                        else
                                input_data[counter] <= idata;
		end
		else if(caddr_wr == 4095)begin//bottm right
			if(counter > 5 || counter % 3 == 2)
                                input_data[counter] <= 0;
                        else
                                input_data[counter] <= idata;
		end
		else if(caddr_wr < 63)begin //first row
			if(counter < 3)
				input_data[counter] <= 0;
			else
				input_data[counter] <= idata;
		end
		else if(caddr_wr > 4032)begin //last row
			if(counter > 5)
                                input_data[counter] <= 0;
                        else
                                input_data[counter] <= idata;
		end
		else if(caddr_wr[5:0] == 0)begin //first column
			if(counter % 3 == 0)
                                input_data[counter] <= 0;
                        else
                                input_data[counter] <= idata;
		end
		else if(caddr_wr[5:0] == 6'b111111)begin //last column
			if(counter % 3 == 2)
                                input_data[counter] <= 0;
                        else
                                input_data[counter] <= idata;
		end
		else //others
			input_data[counter] <= idata;
	end
	else if(mls)begin
		if(!kernel_number)
			input_data[counter] <= cdata_rd;
		else
			input_data[counter + 4] <= cdata_rd;
	end
	else if(fls)begin
		if(!kernel_number)
			rounding_sum1 <= cdata_rd;
		else
			rounding_sum2 <= cdata_rd;
	end
end

always@(posedge clk)begin //control the calculation for every state 
	if(ccs)begin
		if(counter == 9)begin
			if(!kernel_number)begin
				sum1 <= partial_sum1[0] + partial_sum1[1] + partial_sum1[2] + partial_sum1[3] + partial_sum1[4] 
				      + partial_sum1[5] + partial_sum1[6] + partial_sum1[7] + partial_sum1[8];
			end
			else begin
				sum2 <= partial_sum2[0] + partial_sum2[1] + partial_sum2[2] + partial_sum2[3] + partial_sum2[4]
                                      + partial_sum2[5] + partial_sum2[6] + partial_sum2[7] + partial_sum2[8];
			end
		end
		else if(counter == 10)begin
			if(!kernel_number)
				rounding_sum1 <= sum1[35:16] + sum1[15];
			else
				rounding_sum2 <= sum2[35:16] + sum2[15];
		end
		else if(counter == 11)begin
			if(!kernel_number)
                                rounding_sum1 <= rounding_sum1 + bias1;
                        else
                                rounding_sum2 <= rounding_sum2 + bias2;
		end
		else if(counter == 12)begin
                        if(!kernel_number)
                                rounding_sum1 <= (rounding_sum1[19]) ? 0 : rounding_sum1;
                        else
                                rounding_sum2 <= (rounding_sum2[19]) ? 0 : rounding_sum2;
                end
		else begin
			if(!kernel_number)
				partial_sum1[counter] <= input_data[counter] * kernel1[counter];
			else
				partial_sum2[counter] <= input_data[counter] * kernel2[counter];
		end
	end
	else if(mcs)begin
		if(counter == 0)begin
			input_data[0] <= (input_data[0] > input_data[1]) ? input_data[0] : input_data[1];
			input_data[2] <= (input_data[2] > input_data[3]) ? input_data[2] : input_data[3];
			input_data[4] <= (input_data[4] > input_data[5]) ? input_data[4] : input_data[5];
			input_data[6] <= (input_data[6] > input_data[7]) ? input_data[6] : input_data[7];
		end
		else begin
			rounding_sum1 <= (input_data[0] > input_data[2]) ? input_data[0] : input_data[2];
			rounding_sum2 <= (input_data[4] > input_data[6]) ? input_data[4] : input_data[6];
		end
	end
end

always@(posedge clk)begin //control state change
	if(reset)
		CurrentState <= 0;
	else
		CurrentState <= NextState;
end

always@(*)begin //control state change
	case(CurrentState)
		4'b0000: begin //start state
			if(ready)
				NextState = 4'b0001;
			else
				NextState = 4'b0000;
		end
		4'b0001: begin //convolution load input state
			if(counter == 8)
				NextState = 4'b0010;
			else
				NextState = 4'b0001;
		end
		4'b0010: begin //convolution calculate state
			if(kernel_number && counter == 12)
                                NextState = 4'b0011;
                        else
                                NextState = 4'b0010;
		end
		4'b0011: begin //convolution write state
			if(kernel_number && caddr_wr == 4095)
				NextState = 4'b0100;
			else if(kernel_number)
                                NextState = 4'b0001;
                        else
                                NextState = 4'b0011;
		end
		4'b0100: begin //maxpooling load input state
			if(kernel_number && counter == 3)
                                NextState = 4'b0101;
                        else
                                NextState = 4'b0100;
		end
		4'b0101: begin //maxpooling calculate state
                        if(counter == 1)
                                NextState = 4'b0110;
                        else
                                NextState = 4'b0101;
                end
		4'b0110: begin //maxpooling write state
			if(kernel_number && caddr_wr == 1023)
                                NextState = 4'b0111;
			else if(kernel_number)
				NextState = 4'b0100;
                        else
                                NextState = 4'b0110;
		end
		4'b0111: begin //flatten load state
			if(kernel_number)
                		NextState = 4'b1000;
			else
				NextState = 4'b0111;
		end
		4'b1000: begin //flatten write state
			if(caddr_wr == 2047)
                        	NextState = 4'b1001;
			else if(kernel_number)
                                NextState = 4'b0111;
			else
				NextState = 4'b1000;
		end
		4'b1001: begin //finish state
                        NextState = 4'b1001;
                end
		default:
			NextState = 4'b0000;
	endcase
end

always@(*)begin //control the output
	case(CurrentState)
		4'b0000: begin //start state
			busy = 0;
			crd = 0;
			cwr = 0;
			csel = 3'b000;
			cls = 0;
			ccs = 0;
			cws = 0;
			mls = 0;
			mcs = 0;
			mws = 0;
			fls = 0;
                        fws = 0;
                end
                4'b0001: begin //convolution load input state
			busy = 1;
                        crd = 0;
                        cwr = 0;
                        csel = 3'b000;
			cls = 1;
			ccs = 0;
			cws = 0;
			mls = 0;
			mcs = 0;
			mws = 0;
			fls = 0;
                        fws = 0;
                end
                4'b0010: begin //convolution calculate state
			busy = 1;
                        crd = 0;
                        cwr = 0;
                        csel = 3'b000;
			cls = 0;
			ccs = 1;
			cws = 0;
			mls = 0;
			mcs = 0;
			mws = 0;
			fls = 0;
                        fws = 0;
                end
                4'b0011: begin //convolution write state
			busy = 1;
                        crd = 0;
                        cwr = 1;
			if(!kernel_number)
                        	csel = 3'b001;
			else
				csel = 3'b010;
			cls = 0;
			ccs = 0;
			cws = 1;
			mls = 0;
			mcs = 0;
			mws = 0;
			fls = 0;
                        fws = 0;
                end
                4'b0100: begin //maxpooling load input state
			busy = 1;
                        crd = 1;
                        cwr = 0;
			if(!kernel_number)
                        	csel = 3'b001;
			else
                                csel = 3'b010;
			cls = 0;
			ccs = 0;
			cws = 0;
			mls = 1;
			mcs = 0;
			mws = 0;
			fls = 0;
                        fws = 0;
                end
		4'b0101: begin //maxpooling calculate state
                        busy = 1;
                        crd = 0;
                        cwr = 0;
                        csel = 3'b000;
                        cls = 0;
                        ccs = 0;
                        cws = 0;
                        mls = 0;
			mcs = 1;
                        mws = 0;
			fls = 0;
                        fws = 0;
                end
                4'b0110: begin //maxpooling write state
			busy = 1;
                        crd = 0;
                        cwr = 1;
                        if(!kernel_number)
                                csel = 3'b011;
                        else
                                csel = 3'b100;
			cls = 0;
			ccs = 0;
			cws = 0;
			mls = 0;
			mcs = 0;
			mws = 1;
			fls = 0;
                        fws = 0;
                end
                4'b0111: begin //flatten load state
			busy = 1;
                        crd = 1;
                        cwr = 0;
                        if(!kernel_number)
                                csel = 3'b011;
                        else
                                csel = 3'b100;
			cls = 0;
			ccs = 0;
			cws = 0;
			mls = 0;
			mcs = 0;
			mws = 0;
			fls = 1;
			fws = 0;
                end
                4'b1000: begin //flatten write state
			busy = 1;
                        crd = 0;
                        cwr = 1;
                        csel = 3'b101;
			cls = 0;
			ccs = 0;
			cws = 0;
			mls = 0;
			mcs = 0;
			mws = 0;
			fls = 0;
                        fws = 1;
                end
		4'b1001: begin //finish state
                        busy = 0;
                        crd = 0;
                        cwr = 0;
                        csel = 3'b000;
			cls = 0;
			ccs = 0;
			cws = 0;
			mls = 0;
			mcs = 0;
			mws = 0;
			fls = 0;
                        fws = 0;
		end
		default: begin
			busy = 0;
                        crd = 0;
                        cwr = 0;
                        csel = 3'b000;
                        cls = 0;
                        ccs = 0;
                        cws = 0;
                        mls = 0;
			mcs = 0;
                        mws = 0;
			fls = 0;
                        fws = 0;
		end
	endcase
end

endmodule




