module huffman(clk, reset, gray_valid, gray_data, CNT_valid, CNT1, CNT2, CNT3, CNT4, CNT5, CNT6, code_valid, HC1, HC2, HC3, HC4, HC5, HC6, M1, M2, M3, M4, M5, M6);

input	clk;
input	reset;
input	gray_valid;
input	[7:0] gray_data;
output	CNT_valid;
output	[7:0] CNT1, CNT2, CNT3, CNT4, CNT5, CNT6;
output	code_valid;
output	[7:0] HC1, HC2, HC3, HC4, HC5, HC6;
output	[7:0] M1, M2, M3, M4, M5, M6;

reg	CNT_valid;
reg	code_valid;

reg	[7:0] CNT_num[5:0];
reg     [7:0] CNT_huffmancode[5:0];
reg     [2:0] CNT_huffmancode_count[5:0];
reg     [7:0] CNT_index[5:0];
reg	[2:0] CNT_order[5:0][5:0];
reg	[2:0] CNT_count[5:0];

reg	[2:0] CurrentState;
reg	[2:0] NextState;

reg	sort;
reg	sort_finish;
reg     calculate;
reg	[2:0] counter;
reg	[2:0] i;
reg	[2:0] round;

assign	CNT1 = (CNT_valid) ? CNT_num[0] : 8'b0;
assign  CNT2 = (CNT_valid) ? CNT_num[1] : 8'b0;
assign  CNT3 = (CNT_valid) ? CNT_num[2] : 8'b0;
assign  CNT4 = (CNT_valid) ? CNT_num[3] : 8'b0;
assign  CNT5 = (CNT_valid) ? CNT_num[4] : 8'b0;
assign  CNT6 = (CNT_valid) ? CNT_num[5] : 8'b0;

assign	HC1 = (code_valid) ? CNT_huffmancode[0] : 8'b0;
assign	HC2 = (code_valid) ? CNT_huffmancode[1] : 8'b0;
assign	HC3 = (code_valid) ? CNT_huffmancode[2] : 8'b0;
assign	HC4 = (code_valid) ? CNT_huffmancode[3] : 8'b0;
assign	HC5 = (code_valid) ? CNT_huffmancode[4] : 8'b0;
assign	HC6 = (code_valid) ? CNT_huffmancode[5] : 8'b0;

assign	M1 = (code_valid) ? CNT_index[0] : 8'b0;
assign	M2 = (code_valid) ? CNT_index[1] : 8'b0;
assign	M3 = (code_valid) ? CNT_index[2] : 8'b0;
assign	M4 = (code_valid) ? CNT_index[3] : 8'b0;
assign	M5 = (code_valid) ? CNT_index[4] : 8'b0;
assign	M6 = (code_valid) ? CNT_index[5] : 8'b0;

always@(posedge clk or posedge reset)begin
        if(reset)
                counter <= 3'b1;
	else if(calculate)
		counter <= 3'b1;
	else if(sort)
                counter <= counter + 1;
end

always@(posedge clk or posedge reset)begin
        if(reset)
                sort_finish <= 0;
        else if(sort && counter == round)
                sort_finish <= 1;
	else if (calculate)
		sort_finish <= 0;
end

always@(posedge clk or posedge reset)begin
        if(reset)
                round <= 3'b101;
        else if(calculate)
                round <= round - 1;
end

always@(posedge clk or posedge reset)begin
        if(reset)begin
		for(i = 0; i < 6; i = i + 1)begin
                	CNT_num[i] <= 8'b0;
			CNT_huffmancode[i] <= 8'b0;
			CNT_huffmancode_count[i] <= 3'b0;
			CNT_index[i] <= 8'b0;
			CNT_order[i][0] <= i;
			CNT_order[i][1] <= 3'b0;
			CNT_order[i][2] <= 3'b0;
			CNT_order[i][3] <= 3'b0;
			CNT_order[i][4] <= 3'b0;
			CNT_order[i][5] <= 3'b0;
			CNT_count[i] <= 3'b1;
		end
	end
        else if(gray_valid)begin
		case(gray_data)
			8'h01:
				CNT_num[0] <= CNT_num[0] + 1;
			8'h02:
                                CNT_num[1] <= CNT_num[1] + 1;
			8'h03:
                                CNT_num[2] <= CNT_num[2] + 1;
			8'h04:
                                CNT_num[3] <= CNT_num[3] + 1;
			8'h05:
                                CNT_num[4] <= CNT_num[4] + 1;
			8'h06:
                                CNT_num[5] <= CNT_num[5] + 1;
		endcase
	end
	else if(sort)begin
		if(counter[0])begin
			for(i = 0; i < 6; i = i + 2)begin
				if(CNT_num[i] < CNT_num[i + 1])begin
					CNT_num[i] <= CNT_num[i + 1];
					CNT_num[i + 1] <= CNT_num[i];
					CNT_order[i][0] <= CNT_order[i + 1][0];
					CNT_order[i][1] <= CNT_order[i + 1][1];
					CNT_order[i][2] <= CNT_order[i + 1][2];
					CNT_order[i][3] <= CNT_order[i + 1][3];
					CNT_order[i][4] <= CNT_order[i + 1][4];
					CNT_order[i][5] <= CNT_order[i + 1][5];
					CNT_order[i + 1][0] <= CNT_order[i][0];
					CNT_order[i + 1][1] <= CNT_order[i][1];
					CNT_order[i + 1][2] <= CNT_order[i][2];
					CNT_order[i + 1][3] <= CNT_order[i][3];
					CNT_order[i + 1][4] <= CNT_order[i][4];
					CNT_order[i + 1][5] <= CNT_order[i][5];
				end
			end
		end
		else begin
			for(i = 1; i < 5; i = i + 2)begin
                                if(CNT_num[i] < CNT_num[i + 1])begin
                                        CNT_num[i] <= CNT_num[i + 1];
                                        CNT_num[i + 1] <= CNT_num[i];
					CNT_order[i][0] <= CNT_order[i + 1][0];
					CNT_order[i][1] <= CNT_order[i + 1][1];
					CNT_order[i][2] <= CNT_order[i + 1][2];
					CNT_order[i][3] <= CNT_order[i + 1][3];
					CNT_order[i][4] <= CNT_order[i + 1][4];
					CNT_order[i][5] <= CNT_order[i + 1][5];
					CNT_order[i + 1][0] <= CNT_order[i][0];
					CNT_order[i + 1][1] <= CNT_order[i][1];
					CNT_order[i + 1][2] <= CNT_order[i][2];
					CNT_order[i + 1][3] <= CNT_order[i][3];
					CNT_order[i + 1][4] <= CNT_order[i][4];
					CNT_order[i + 1][5] <= CNT_order[i][5];
                                end
                        end
		end
	end
	else if(calculate)begin
		CNT_num[round - 1] <= CNT_num[round - 1] + CNT_num[round];
		case(CNT_count[CNT_order[round][0]])
			3'b001:begin
				CNT_order[round - 1][CNT_count[CNT_order[round - 1][0]]] <= CNT_order[round][0];
				CNT_huffmancode[CNT_order[round][0]][CNT_huffmancode_count[CNT_order[round][0]]] <= 1'b1;
				CNT_huffmancode_count[CNT_order[round][0]] <= CNT_huffmancode_count[CNT_order[round][0]] + 1;
				CNT_index[CNT_order[round][0]] <= (CNT_index[CNT_order[round][0]] << 1) + 1;
			end
			3'b010:begin
				CNT_order[round - 1][CNT_count[CNT_order[round - 1][0]]] <= CNT_order[round][0];
				CNT_order[round - 1][CNT_count[CNT_order[round - 1][0]] + 1] <= CNT_order[round][1];
				CNT_huffmancode[CNT_order[round][0]][CNT_huffmancode_count[CNT_order[round][0]]] <= 1'b1;
				CNT_huffmancode[CNT_order[round][1]][CNT_huffmancode_count[CNT_order[round][1]]] <= 1'b1;
				CNT_huffmancode_count[CNT_order[round][0]] <= CNT_huffmancode_count[CNT_order[round][0]] + 1;
				CNT_huffmancode_count[CNT_order[round][1]] <= CNT_huffmancode_count[CNT_order[round][1]] + 1;
				CNT_index[CNT_order[round][0]] <= (CNT_index[CNT_order[round][0]] << 1) + 1;
				CNT_index[CNT_order[round][1]] <= (CNT_index[CNT_order[round][1]] << 1) + 1;
			end
			3'b011:begin
				CNT_order[round - 1][CNT_count[CNT_order[round - 1][0]]] <= CNT_order[round][0];
				CNT_order[round - 1][CNT_count[CNT_order[round - 1][0]] + 1] <= CNT_order[round][1];
				CNT_order[round - 1][CNT_count[CNT_order[round - 1][0]] + 2] <= CNT_order[round][2];
				CNT_huffmancode[CNT_order[round][0]][CNT_huffmancode_count[CNT_order[round][0]]] <= 1'b1;
				CNT_huffmancode[CNT_order[round][1]][CNT_huffmancode_count[CNT_order[round][1]]] <= 1'b1;
				CNT_huffmancode[CNT_order[round][2]][CNT_huffmancode_count[CNT_order[round][2]]] <= 1'b1;
				CNT_huffmancode_count[CNT_order[round][0]] <= CNT_huffmancode_count[CNT_order[round][0]] + 1;
				CNT_huffmancode_count[CNT_order[round][1]] <= CNT_huffmancode_count[CNT_order[round][1]] + 1;
				CNT_huffmancode_count[CNT_order[round][2]] <= CNT_huffmancode_count[CNT_order[round][2]] + 1;
				CNT_index[CNT_order[round][0]] <= (CNT_index[CNT_order[round][0]] << 1) + 1;
				CNT_index[CNT_order[round][1]] <= (CNT_index[CNT_order[round][1]] << 1) + 1;
				CNT_index[CNT_order[round][2]] <= (CNT_index[CNT_order[round][2]] << 1) + 1;
			end
			3'b100:begin
				CNT_order[round - 1][CNT_count[CNT_order[round - 1][0]]] <= CNT_order[round][0];
				CNT_order[round - 1][CNT_count[CNT_order[round - 1][0]] + 1] <= CNT_order[round][1];
				CNT_order[round - 1][CNT_count[CNT_order[round - 1][0]] + 2] <= CNT_order[round][2];
				CNT_order[round - 1][CNT_count[CNT_order[round - 1][0]] + 3] <= CNT_order[round][3];
				CNT_huffmancode[CNT_order[round][0]][CNT_huffmancode_count[CNT_order[round][0]]] <= 1'b1;
				CNT_huffmancode[CNT_order[round][1]][CNT_huffmancode_count[CNT_order[round][1]]] <= 1'b1;
				CNT_huffmancode[CNT_order[round][2]][CNT_huffmancode_count[CNT_order[round][2]]] <= 1'b1;
				CNT_huffmancode[CNT_order[round][3]][CNT_huffmancode_count[CNT_order[round][3]]] <= 1'b1;
				CNT_huffmancode_count[CNT_order[round][0]] <= CNT_huffmancode_count[CNT_order[round][0]] + 1;
				CNT_huffmancode_count[CNT_order[round][1]] <= CNT_huffmancode_count[CNT_order[round][1]] + 1;
				CNT_huffmancode_count[CNT_order[round][2]] <= CNT_huffmancode_count[CNT_order[round][2]] + 1;
				CNT_huffmancode_count[CNT_order[round][3]] <= CNT_huffmancode_count[CNT_order[round][3]] + 1;
				CNT_index[CNT_order[round][0]] <= (CNT_index[CNT_order[round][0]] << 1) + 1;
				CNT_index[CNT_order[round][1]] <= (CNT_index[CNT_order[round][1]] << 1) + 1;
				CNT_index[CNT_order[round][2]] <= (CNT_index[CNT_order[round][2]] << 1) + 1;
				CNT_index[CNT_order[round][3]] <= (CNT_index[CNT_order[round][3]] << 1) + 1;
			end
			3'b101:begin
				CNT_order[round - 1][CNT_count[CNT_order[round - 1][0]]] <= CNT_order[round][0];
				CNT_order[round - 1][CNT_count[CNT_order[round - 1][0]] + 1] <= CNT_order[round][1];
				CNT_order[round - 1][CNT_count[CNT_order[round - 1][0]] + 2] <= CNT_order[round][2];
				CNT_order[round - 1][CNT_count[CNT_order[round - 1][0]] + 3] <= CNT_order[round][3];
				CNT_order[round - 1][CNT_count[CNT_order[round - 1][0]] + 4] <= CNT_order[round][4];
				CNT_huffmancode[CNT_order[round][0]][CNT_huffmancode_count[CNT_order[round][0]]] <= 1'b1;
				CNT_huffmancode[CNT_order[round][1]][CNT_huffmancode_count[CNT_order[round][1]]] <= 1'b1;
				CNT_huffmancode[CNT_order[round][2]][CNT_huffmancode_count[CNT_order[round][2]]] <= 1'b1;
				CNT_huffmancode[CNT_order[round][3]][CNT_huffmancode_count[CNT_order[round][3]]] <= 1'b1;
				CNT_huffmancode[CNT_order[round][4]][CNT_huffmancode_count[CNT_order[round][4]]] <= 1'b1;
				CNT_huffmancode_count[CNT_order[round][0]] <= CNT_huffmancode_count[CNT_order[round][0]] + 1;
				CNT_huffmancode_count[CNT_order[round][1]] <= CNT_huffmancode_count[CNT_order[round][1]] + 1;
				CNT_huffmancode_count[CNT_order[round][2]] <= CNT_huffmancode_count[CNT_order[round][2]] + 1;
				CNT_huffmancode_count[CNT_order[round][3]] <= CNT_huffmancode_count[CNT_order[round][3]] + 1;
				CNT_huffmancode_count[CNT_order[round][4]] <= CNT_huffmancode_count[CNT_order[round][4]] + 1;
				//CNT_huffmancode[CNT_order[round][4]] <= (CNT_huffmancode[CNT_order[round][4]] << 1) + 1;
				CNT_index[CNT_order[round][0]] <= (CNT_index[CNT_order[round][0]] << 1) + 1;
				CNT_index[CNT_order[round][1]] <= (CNT_index[CNT_order[round][1]] << 1) + 1;
				CNT_index[CNT_order[round][2]] <= (CNT_index[CNT_order[round][2]] << 1) + 1;
				CNT_index[CNT_order[round][3]] <= (CNT_index[CNT_order[round][3]] << 1) + 1;
				CNT_index[CNT_order[round][4]] <= (CNT_index[CNT_order[round][4]] << 1) + 1;
			end
		endcase
		case(CNT_count[CNT_order[round - 1][0]])
                        3'b001:begin
				CNT_huffmancode_count[CNT_order[round - 1][0]] <= CNT_huffmancode_count[CNT_order[round - 1][0]] + 1;
				CNT_index[CNT_order[round - 1][0]] <= (CNT_index[CNT_order[round - 1][0]] << 1) + 1;
                        end
                        3'b010:begin
				CNT_huffmancode_count[CNT_order[round - 1][0]] <= CNT_huffmancode_count[CNT_order[round - 1][0]] + 1;
				CNT_huffmancode_count[CNT_order[round - 1][1]] <= CNT_huffmancode_count[CNT_order[round - 1][1]] + 1;
				CNT_index[CNT_order[round - 1][0]] <= (CNT_index[CNT_order[round - 1][0]] << 1) + 1;
				CNT_index[CNT_order[round - 1][1]] <= (CNT_index[CNT_order[round - 1][1]] << 1) + 1;
                        end
                        3'b011:begin
				CNT_huffmancode_count[CNT_order[round - 1][0]] <= CNT_huffmancode_count[CNT_order[round - 1][0]] + 1;
				CNT_huffmancode_count[CNT_order[round - 1][1]] <= CNT_huffmancode_count[CNT_order[round - 1][1]] + 1;
				CNT_huffmancode_count[CNT_order[round - 1][2]] <= CNT_huffmancode_count[CNT_order[round - 1][2]] + 1;
				CNT_index[CNT_order[round - 1][0]] <= (CNT_index[CNT_order[round - 1][0]] << 1) + 1;
				CNT_index[CNT_order[round - 1][1]] <= (CNT_index[CNT_order[round - 1][1]] << 1) + 1;
				CNT_index[CNT_order[round - 1][2]] <= (CNT_index[CNT_order[round - 1][2]] << 1) + 1;
                        end
                        3'b100:begin
				CNT_huffmancode_count[CNT_order[round - 1][0]] <= CNT_huffmancode_count[CNT_order[round - 1][0]] + 1;
				CNT_huffmancode_count[CNT_order[round - 1][1]] <= CNT_huffmancode_count[CNT_order[round - 1][1]] + 1;
				CNT_huffmancode_count[CNT_order[round - 1][2]] <= CNT_huffmancode_count[CNT_order[round - 1][2]] + 1;
				CNT_huffmancode_count[CNT_order[round - 1][3]] <= CNT_huffmancode_count[CNT_order[round - 1][3]] + 1;
				CNT_index[CNT_order[round - 1][0]] <= (CNT_index[CNT_order[round - 1][0]] << 1) + 1;
				CNT_index[CNT_order[round - 1][1]] <= (CNT_index[CNT_order[round - 1][1]] << 1) + 1;
				CNT_index[CNT_order[round - 1][2]] <= (CNT_index[CNT_order[round - 1][2]] << 1) + 1;
				CNT_index[CNT_order[round - 1][3]] <= (CNT_index[CNT_order[round - 1][3]] << 1) + 1;
                        end
                        3'b101:begin
				CNT_huffmancode_count[CNT_order[round - 1][0]] <= CNT_huffmancode_count[CNT_order[round - 1][0]] + 1;
				CNT_huffmancode_count[CNT_order[round - 1][1]] <= CNT_huffmancode_count[CNT_order[round - 1][1]] + 1;
				CNT_huffmancode_count[CNT_order[round - 1][2]] <= CNT_huffmancode_count[CNT_order[round - 1][2]] + 1;
				CNT_huffmancode_count[CNT_order[round - 1][3]] <= CNT_huffmancode_count[CNT_order[round - 1][3]] + 1;
				CNT_huffmancode_count[CNT_order[round - 1][4]] <= CNT_huffmancode_count[CNT_order[round - 1][4]] + 1;
				CNT_index[CNT_order[round - 1][0]] <= (CNT_index[CNT_order[round - 1][0]] << 1) + 1;
				CNT_index[CNT_order[round - 1][1]] <= (CNT_index[CNT_order[round - 1][1]] << 1) + 1;
				CNT_index[CNT_order[round - 1][2]] <= (CNT_index[CNT_order[round - 1][2]] << 1) + 1;
				CNT_index[CNT_order[round - 1][3]] <= (CNT_index[CNT_order[round - 1][3]] << 1) + 1;
				CNT_index[CNT_order[round - 1][4]] <= (CNT_index[CNT_order[round - 1][4]] << 1) + 1;
                        end
                endcase
		CNT_count[CNT_order[round - 1][0]] <= CNT_count[CNT_order[round - 1][0]] + CNT_count[CNT_order[round][0]];
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
		3'b0: begin//reset state
			if(gray_valid)
				NextState = 3'b001;
			else
				NextState = 3'b000;
		end
		3'b001: begin//load state
			if(!gray_valid)
                                NextState = 3'b010;
                        else
                                NextState = 3'b001;
                end
		3'b010: //output CNT* state
			NextState = 3'b011;
		3'b011: begin//sort state
			if(sort_finish)
				NextState = 3'b100;
			else
				NextState = 3'b011;
                end
		3'b100: begin//calculate state
			if(round == 3'b001)
                                NextState = 3'b101;
                        else
                                NextState = 3'b011;
                end
		3'b101: //output HC*, M* state
			NextState = 3'b0;
		/*3'b110: //finish state
                        NextState = 3'b110;*/
		default:
			NextState = 3'b0;
	endcase
end

always@(*)begin
        case(CurrentState)
                3'b0: begin//reset state
			CNT_valid = 0;
                        code_valid = 0;
			sort = 0;
			calculate = 0;
                end
                3'b001: begin//load state
			CNT_valid = 0;
                        code_valid = 0;
			sort = 0;
			calculate = 0;
                end
                3'b010: begin//output CNT* state
			CNT_valid = 1;
			code_valid = 0;
			sort = 0;
			calculate = 0;
                end
                3'b011: begin//sort state
			CNT_valid = 0;
                        code_valid = 0;
			sort = 1;
			calculate = 0;
                end
                3'b100: begin//calculate state
			CNT_valid = 0;
                        code_valid = 0;
			sort = 0;
			calculate = 1;
                end
                3'b101: begin//output HC*, M* state
			CNT_valid = 0;
                        code_valid = 1;
			sort = 0;
			calculate = 0;
                end
		/*3'b110: begin//finish state
                        CNT_valid = 0;
                        code_valid = 0;
			sort = 0;
                        calculate = 0;
                end*/
                default: begin
			CNT_valid = 0;
                        code_valid = 0;
			sort = 0;
			calculate = 0;
		end
        endcase
end
  
endmodule

