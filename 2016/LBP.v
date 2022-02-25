
`timescale 1ns/10ps
module LBP ( clk, reset, gray_addr, gray_req, gray_ready, gray_data, lbp_addr, lbp_valid, lbp_data, finish);
input   		clk;
input   		reset;
output	reg	[13:0]	gray_addr;
output	reg		gray_req;
input   		gray_ready;
input   	[7:0]	gray_data;
output	reg	[13:0]	lbp_addr;
output	reg		lbp_valid;
output	reg	[7:0]	lbp_data;
output	reg		finish;
//====================================================================

reg	[3:0]	CurrentState;
reg	[3:0]	NextState;

reg		read_data;
reg		compared1;
reg             compared2;
reg             compared3;
reg             compared4;
reg             compared5;
reg             compared6;
reg             compared7;
reg             compared8;
reg	[6:0]	write_counter;

reg	[7:0]	data;

always@(posedge clk or posedge reset)begin
	if(reset)
		lbp_data <= 8'h0;
	else if(compared1)begin
		if(gray_data < data)
			lbp_data[0] <= 1'h0;
		else
			lbp_data[0] <= 1'h1;
	end
        else if(compared2)begin
                if(gray_data < data)
                        lbp_data[1] <= 1'h0;
                else
                        lbp_data[1] <= 1'h1;
        end
        else if(compared3)begin
                if(gray_data < data)
                        lbp_data[2] <= 1'h0;
                else
                        lbp_data[2] <= 1'h1;
        end
        else if(compared4)begin
                if(gray_data < data)
                        lbp_data[3] <= 1'h0;
                else
                        lbp_data[3] <= 1'h1;
        end
        else if(compared5)begin
                if(gray_data < data)
                        lbp_data[4] <= 1'h0;
                else
                        lbp_data[4] <= 1'h1;
        end
        else if(compared6)begin
                if(gray_data < data)
                        lbp_data[5] <= 1'h0;
                else
                        lbp_data[5] <= 1'h1;
        end
        else if(compared7)begin
                if(gray_data < data)
                        lbp_data[6] <= 1'h0;
                else
                        lbp_data[6] <= 1'h1;
        end
        else if(compared8)begin
                if(gray_data < data)
                        lbp_data[7] <= 1'h0;
                else
                        lbp_data[7] <= 1'h1;
        end
end


always@(posedge clk or posedge reset)begin
	if(reset)
		data <= 8'h0;
	else if(read_data)
		data <= gray_data;
end

always@(posedge clk or posedge reset)begin
	if(reset)
		lbp_addr <= 14'h81;//addr = 129
	else if(lbp_valid && write_counter == 7'h7d)
		lbp_addr <= lbp_addr + 2'h3;
	else if(lbp_valid)
		lbp_addr <= lbp_addr + 1'h1;
end

always@(posedge clk or posedge reset)begin
	if(reset)
		write_counter <= 7'h0;
	else if(lbp_valid && write_counter == 7'h7d)
		write_counter <= 7'h0;
	else if(lbp_valid)
		write_counter <= write_counter + 1'h1;
end

always@(posedge clk or posedge reset)begin
	if(reset)
		gray_addr <= 14'h81;//addr = 129
	else if(read_data)
		gray_addr <= gray_addr - 8'h81;//addr = addr - 129
	else if(compared1)
		gray_addr <= gray_addr + 1'h1;
	else if(compared2)
		gray_addr <= gray_addr + 1'h1;
	else if(compared3)
		gray_addr <= gray_addr + 7'h7e;//addr = addr + 126
	else if(compared4)
		gray_addr <= gray_addr + 2'h2;
	else if(compared5)
		gray_addr <= gray_addr + 7'h7e;//addr = addr + 126
	else if(compared6)
		gray_addr <= gray_addr + 1'h1;
        else if(compared7)
                gray_addr <= gray_addr + 1'h1;
        else if(compared8 && write_counter == 7'h7d)//addr = addr - 126
                gray_addr <= gray_addr - 7'h7e;
	else if(compared8)
                gray_addr <= gray_addr - 8'h80;//addr = addr - 128
end

always@(posedge clk or posedge reset)begin
	if(reset)
		CurrentState <= 4'h0;
	else
		CurrentState <= NextState;
end

always@(*)begin
	case(CurrentState)
		4'h0:begin//reset
			if(gray_ready)
				NextState = 4'h1;
			else
				NextState = 4'h0;
		end
		4'h1:begin//load value
			NextState = 4'h2;
		end
		4'h2:begin//compared value
                        NextState = 4'h3;
                end
		4'h3:begin//compared value
                        NextState = 4'h4;
                end
                4'h4:begin//compared value
                        NextState = 4'h5;
                end
                4'h5:begin//compared value
                        NextState = 4'h6;
                end
                4'h6:begin//compared value
                        NextState = 4'h7;
                end
                4'h7:begin//compared value
                        NextState = 4'h8;
                end
                4'h8:begin//compared value
                        NextState = 4'h9;
                end
		4'h9:begin//compared value
			NextState = 4'ha;
		end
		4'ha:begin//write value
                        if(lbp_addr == 14'h3f7e)
                                NextState = 4'hb;
                        else
                                NextState = 4'h1;
                end
		4'hb:begin//finish
			NextState = 4'h0;
		end
		default:begin
			NextState = 4'h0;
		end
	endcase
end

always@(*)begin
	case(CurrentState)
		4'h0:begin//reset
			gray_req = 0;
			read_data = 0;
			compared1 = 0;
			compared2 = 0;
			compared3 = 0;
			compared4 = 0;
                        compared5 = 0;
                        compared6 = 0;
                        compared7 = 0;
                        compared8 = 0;
			lbp_valid = 0;
			finish = 0;
		end
		4'h1:begin//load value
			gray_req = 1;
			read_data = 1;
                        compared1 = 0;
                        compared2 = 0;
                        compared3 = 0;
                        compared4 = 0;
                        compared5 = 0;
                        compared6 = 0;
                        compared7 = 0;
                        compared8 = 0;
			lbp_valid = 0;
			finish = 0;
		end
                4'h2:begin//compared value 1
                        gray_req = 1;
			read_data = 0;
                        compared1 = 1;
                        compared2 = 0;
                        compared3 = 0;
                        compared4 = 0;
                        compared5 = 0;
                        compared6 = 0;
                        compared7 = 0;
                        compared8 = 0;
                        lbp_valid = 0;
                        finish = 0;
                end
                4'h3:begin//compared value 2
                        gray_req = 1;
			read_data = 0;
                        compared1 = 0;
                        compared2 = 1;
                        compared3 = 0;
                        compared4 = 0;
                        compared5 = 0;
                        compared6 = 0;
                        compared7 = 0;
                        compared8 = 0;
                        lbp_valid = 0;
                        finish = 0;
                end
                4'h4:begin//compared value 3
                        gray_req = 1;
			read_data = 0;
                        compared1 = 0;
                        compared2 = 0;
                        compared3 = 1;
                        compared4 = 0;
                        compared5 = 0;
                        compared6 = 0;
                        compared7 = 0;
                        compared8 = 0;
                        lbp_valid = 0;
                        finish = 0;
                end
                4'h5:begin//compared value 4
                        gray_req = 1;
                        read_data = 0;
                        compared1 = 0;
                        compared2 = 0;
                        compared3 = 0;
                        compared4 = 1;
                        compared5 = 0;
                        compared6 = 0;
                        compared7 = 0;
                        compared8 = 0;
                        lbp_valid = 0;
                        finish = 0;
                end
                4'h6:begin//compared value 5
                        gray_req = 1;
                        read_data = 0;
                        compared1 = 0;
                        compared2 = 0;
                        compared3 = 0;
                        compared4 = 0;
                        compared5 = 1;
                        compared6 = 0;
                        compared7 = 0;
                        compared8 = 0;
                        lbp_valid = 0;
                        finish = 0;
                end
                4'h7:begin//compared value 6
                        gray_req = 1;
                        read_data = 0;
                        compared1 = 0;
                        compared2 = 0;
                        compared3 = 0;
                        compared4 = 0;
                        compared5 = 0;
                        compared6 = 1;
                        compared7 = 0;
                        compared8 = 0;
                        lbp_valid = 0;
                        finish = 0;
                end
                4'h8:begin//compared value 7
                        gray_req = 1;
                        read_data = 0;
                        compared1 = 0;
                        compared2 = 0;
                        compared3 = 0;
                        compared4 = 0;
                        compared5 = 0;
                        compared6 = 0;
                        compared7 = 1;
                        compared8 = 0;
                        lbp_valid = 0;
                        finish = 0;
                end
                4'h9:begin//compared value 8
                        gray_req = 1;
                        read_data = 0;
                        compared1 = 0;
                        compared2 = 0;
                        compared3 = 0;
                        compared4 = 0;
                        compared5 = 0;
                        compared6 = 0;
                        compared7 = 0;
                        compared8 = 1;
                        lbp_valid = 0;
                        finish = 0;
                end
		4'ha:begin//write value
                        gray_req = 0;
                        read_data = 0;
                        compared1 = 0;
                        compared2 = 0;
                        compared3 = 0;
                        compared4 = 0;
                        compared5 = 0;
                        compared6 = 0;
                        compared7 = 0;
                        compared8 = 0;
                        lbp_valid = 1;
                        finish = 0;
                end
		4'hb:begin//finish
			gray_req = 0;
                        read_data = 0;
                        compared1 = 0;
                        compared2 = 0;
                        compared3 = 0;
                        compared4 = 0;
                        compared5 = 0;
                        compared6 = 0;
                        compared7 = 0;
                        compared8 = 0;
			lbp_valid = 0;
			finish = 1;
		end
		default:begin
			gray_req = 0;
                        read_data = 0;
                        compared1 = 0;
                        compared2 = 0;
                        compared3 = 0;
                        compared4 = 0;
                        compared5 = 0;
                        compared6 = 0;
                        compared7 = 0;
                        compared8 = 0;
			lbp_valid = 0;
			finish = 0;
		end
	endcase
end

//====================================================================
endmodule
