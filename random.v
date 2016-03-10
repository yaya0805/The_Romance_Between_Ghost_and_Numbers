module random(clk, rstn, nowCoord, six_num, six_pos, buffer, valid, score, delay, wrong_eat, game_over);
	input clk;
	input rstn;
	//input [1:0] state;
	input [6:0] nowCoord;
	/*coord: {X, 4'b0000} + {3'b000, Y[6:3]}*/
	output reg [23:0] six_num;
	output reg [41:0] six_pos;
	output reg [15:0] buffer;
	output reg [3:0] valid;
	output reg [11:0] score;
	output reg [14:0] delay;
	output reg wrong_eat;
	output reg game_over;
	
	reg [14:0] delay_next;
	reg update, update_next;
	reg wrong_eat_next,game_over_next;
	reg [11:0] score_next;
	reg [23:0] six_num_next;
	reg [41:0] six_pos_next;
	reg [3:0] valid_next;
	reg [15:0] buffer_next;
	reg [3:0] randNum, randNum_next, newNum, newNum_next;
	reg [7:0] randPos, randPos_next;
	reg [6:0] newPos, newPos_next;
	reg [6:0] preCoord, preCoord_next;
	
	reg [6:0] arr [0:124];
	reg [3:0] s0, s1, s2;
	reg [3:0] s0_next, s1_next, s2_next;
	reg [3:0] curNum, curNum_next;
	
	//reg [17:0] data_next;
	reg [6:0] pos1, pos2, pos3, pos4, pos5, pos6;
	reg [6:0] pos1_next, pos2_next, pos3_next, pos4_next, pos5_next, pos6_next;
	reg [3:0] num1, num2, num3, num4, num5, num6;
	reg [3:0] num1_next, num2_next, num3_next, num4_next, num5_next, num6_next;
	initial begin
		pos1 <= {3'b000, 4'b0111};
	    pos2 <= {3'b001, 4'b0011};
	    pos3 <= {3'b010, 4'b1100};
	    pos4 <= {3'b011, 4'b0110};
	    pos5 <= {3'b110, 4'b1001};
	    pos6 <= {3'b111, 4'b0001};
		num1 <= 4'h1;
	    num2 <= 4'h2;
	    num3 <= 4'h3;
	    num4 <= 4'h4;
	    num5 <= 4'h3;
	    num6 <= 4'h2;
		delay <= 15'b111_0000_0000_0000;
		for (reg[7:0] i=0,j=0; i<=127; i=i+1) begin
			if(i!=13 && i!=14 && i!=15) begin //score board
				arr[j] = i[6:0];
				j=j+1;
			end
		end
	end
	
	always @(posedge clk or negedge rstn) begin
	  if (rstn == 1'b0) begin
		 six_num <= 24'h000000;
		 six_pos <= 0;
		 buffer <= 16'h0000;
		 valid <= 4'b0000;
		 randNum <= 4'b0000;
		 preCoord <= 7'b000000;
		 newNum <= 4'b0000;
		 randPos <= 0;
		 newPos <= 0;
		 score <= 12'h000;
		 s0 <= 0; s1 <= 0; s2 <= 0;
		 game_over <= 0;
		 wrong_eat <= 0;
		 delay <= 15'b111_0000_0000_0000;
		//coord formula: {X, Y[6:3]}
		 pos1 <= {3'b000, 4'b0111}; num1 <= 4'h1;
		 pos2 <= {3'b001, 4'b0011}; num2 <= 4'h2;
		 pos3 <= {3'b010, 4'b1100}; num3 <= 4'h3;
		 pos4 <= {3'b011, 4'b0110}; num4 <= 4'h4;
		 pos5 <= {3'b110, 4'b1001}; num5 <= 4'h3;
		 pos6 <= {3'b111, 4'b0001}; num6 <= 4'h2;
		 update <= 0;
	  end else begin
		 six_num <= six_num_next;
		 six_pos <= six_pos_next;
		 buffer <= buffer_next;
		 valid <= valid_next;
		 score <= score_next;
		 randNum <= randNum_next;
		 preCoord <= preCoord_next;
		 newNum <= newNum_next;
		 randPos <= randPos_next;
		 newPos <= newPos_next;
		 update <= update_next;
		 pos1 <= pos1_next; num1 <= num1_next;
		 pos2 <= pos2_next; num2 <= num2_next;
		 pos3 <= pos3_next; num3 <= num3_next;
		 pos4 <= pos4_next; num4 <= num4_next;
		 pos5 <= pos5_next; num5 <= num5_next;
		 pos6 <= pos6_next; num6 <= num6_next;
		 s0 <= s0_next; s1 <= s1_next; s2 <= s2_next;
		 game_over <= game_over_next;
		 wrong_eat <= wrong_eat_next;
		 delay <= delay_next;
	  end
	end
	
	always @(*) begin
		randNum_next = randNum;
		if(randNum == 4'b0000)
				randNum_next = 4'b0001;
		else begin
				randNum_next = {randNum[1]^randNum[0],  randNum[3:1]};
		end
	end
	
	always @(*) begin
		randPos_next = randPos;
		if(randPos == 8'b0000_0000) begin
			randPos_next = 8'b1000_0000;
		end else begin
			randPos_next = {randPos[6:4], randPos[7]^randPos[3], randPos[7]^randPos[2], randPos[7]^randPos[1], randPos[0], randPos[7]};
		end
	end
	
	always @(*) begin
		newPos_next = newPos;
		
		if(randPos[6:0]!=7'b000_1101 && randPos[6:0]!=7'b000_1110 && randPos[6:0]!=7'b000_1111 && randPos[6:0]!=pos1 && randPos[6:0]!=pos2 && randPos[6:0]!=pos3 && randPos[6:0]!=pos4 && randPos[6:0]!=pos5 && randPos[6:0]!=pos6) begin
			newPos_next = randPos[6:0];
		end
	/*	case(randPos[6:0]) // avoid the scoreboard
			7'b000_1101: newPos_next = 7'b001_1101;
			7'b000_1110: newPos_next = 7'b010_1110;
			7'b000_1111: newPos_next = 7'b100_1111;
			pos1: newPos_next = 7'b000_0000;
			pos2: newPos_next = 7'b001_0000;
			pos3: newPos_next = 7'b010_0000;
			pos4: newPos_next = 7'b011_0000;
			pos5: newPos_next = 7'b100_0000;
			pos6: newPos_next = 7'b101_0000;
		endcase*/
	end

	always @(*) begin//計算分數
		game_over_next = game_over;
		s0_next = s0; s1_next = s1; s2_next = s2;
		preCoord_next = preCoord;
		
		//邊界判斷
		if(nowCoord[6:4]==3'b000 && preCoord[6:4]==3'b111)
			game_over_next = 1'b1;
		else if(nowCoord[6:4]==3'b111 && preCoord[6:4]==3'b000)
			game_over_next = 1'b1;
		
		if(nowCoord[3:0]==4'b1111 && preCoord[3:0]==4'b0000)
			game_over_next = 1'b1;
		else if(nowCoord[3:0]==4'b0000 && preCoord[3:0]==4'b1111)
			game_over_next = 1'b1;
		
		case(nowCoord)
			7'b000_1101: game_over_next = 1'b1;//scoreboard's coord
			7'b000_1110: game_over_next = 1'b1;
			7'b000_1111: game_over_next = 1'b1;
			pos1: s0_next = s0 + num1;
			pos2: begin
				if(num1==num2)
					s0_next = s0 + num2;
				else begin
					if(s0 >= num2)
						s0_next = s0 - num2;
					else if(s1 > 0) begin
						s1_next = s1 - 1;
						s0_next = s0 + 10 - num2;
					end else if(s2 > 0) begin
						s2_next = s2 - 1;
						s1_next = 9;
						s0_next = s0 + 10 - num2;
					end else begin
						game_over_next = 1'b1;
					end
				end
			end
			pos3:  begin
				if(num1==num3)
					s0_next = s0 + num3;
				else begin
					if(s0 >= num3)
						s0_next = s0 - num3;
					else if(s1 > 0) begin
						s1_next = s1 - 1;
						s0_next = s0 + 10 - num3;
					end else if(s2 > 0) begin
						s2_next = s2 - 1;
						s1_next = 9;
						s0_next = s0 + 10 - num3;
					end else begin
						game_over_next = 1'b1;
					end
				end
			end
			pos4:  begin
				if(num1==num4)
					s0_next = s0 + num4;
				else begin
					if(s0 >= num4)
						s0_next = s0 - num4;
					else if(s1 > 0) begin
						s1_next = s1 - 1;
						s0_next = s0 + 10 - num4;
					end else if(s2 > 0) begin
						s2_next = s2 - 1;
						s1_next = 9;
						s0_next = s0 + 10 - num4;
					end else begin
						game_over_next = 1'b1;
					end
				end
			end
			pos5:  begin
				if(num1==num5)
					s0_next = s0 + num5;
				else begin
					if(s0 >= num5)
						s0_next = s0 - num5;
					else if(s1 > 0) begin
						s1_next = s1 - 1;
						s0_next = s0 + 10 - num5;
					end else if(s2 > 0) begin
						s2_next = s2 - 1;
						s1_next = 9;
						s0_next = s0 + 10 - num5;
					end else begin
						game_over_next = 1'b1;
					end
				end
			end
			pos6:  begin
				if(num1==num6)
					s0_next = s0 + num6;
				else begin
					if(s0 >= num6)
						s0_next = s0 - num6;
					else if(s1 > 0) begin
						s1_next = s1 - 1;
						s0_next = s0 + 10 - num6;
					end else if(s2 > 0) begin
						s2_next = s2 - 1;
						s1_next = 9;
						s0_next = s0 + 10 - num6;
					end else begin
						game_over_next = 1'b1;
					end
				end
			end

		endcase
		if(s0_next > 9) begin
			s0_next = s0_next - 10;
			s1_next = s1 + 1;
			if(s1_next > 9) begin
				s1_next = s1_next - 10;
				s2_next = s2 + 1;
			end
		end
		if(preCoord!=nowCoord) begin
			preCoord_next = nowCoord;
		end
	end
	
	always @(*) begin
		wrong_eat_next = wrong_eat;
		update_next = update;
		pos1_next = pos1; num1_next = num1;
		pos2_next = pos2; num2_next = num2;
		pos3_next = pos3; num3_next = num3;
		pos4_next = pos4; num4_next = num4;
		pos5_next = pos5; num5_next = num5;
		pos6_next = pos6; num6_next = num6;

		case(nowCoord)
			pos1: begin
				pos1_next = pos2;
				pos2_next = pos3;
				pos3_next = pos4;
				pos4_next = pos5;
				pos5_next = pos6;
				pos6_next = newPos; //暫定
				
				num1_next = num2;
				num2_next = num3;
				num3_next = num4;
				num4_next = num5;
				num5_next = num6;
				num6_next = newNum;
				wrong_eat_next = 1'b0;
		    end
			pos2: begin
				if(num2==num1) begin
					pos1_next = pos1;
					num1_next = num2;
					wrong_eat_next = 1'b0;
				end 
				else begin
					wrong_eat_next = 1'b1;
				end
				pos2_next = pos3;
				pos3_next = pos4;
				pos4_next = pos5;
				pos5_next = pos6;
				pos6_next = newPos; //暫定
				
				num2_next = num3;
				num3_next = num4;
				num4_next = num5;
				num5_next = num6;
				num6_next = newNum;
					
			end
			pos3: begin
				if(num3==num1) begin
					pos1_next = pos2;
					pos2_next = pos1;
					
					num1_next = num2;
					num2_next = num3;
					wrong_eat_next = 1'b0;
				end 
				else begin
					wrong_eat_next = 1'b1;
				end
				pos3_next = pos4;
				pos4_next = pos5;
				pos5_next = pos6;
				pos6_next = newPos; //暫定
				
				num3_next = num4;
				num4_next = num5;
				num5_next = num6;
				num6_next = newNum;

	        end
			pos4: begin
				if(num4==num1) begin
					pos1_next = pos2;
					pos2_next = pos3;
					pos3_next = pos1;
					
					num1_next = num2;
					num2_next = num3;
					num3_next = num4;
					wrong_eat_next = 1'b0;
				end
				else begin
					wrong_eat_next = 1'b1;
				end
				pos4_next = pos5;
				pos5_next = pos6;
				pos6_next = newPos; //暫定
				
				num4_next = num5;
				num5_next = num6;
				num6_next = newNum;
			end
			pos5: begin
				if(num5==num1) begin
					pos1_next = pos2;
					pos2_next = pos3;
					pos3_next = pos4;
					pos4_next = pos1;
					
					num1_next = num2;
					num2_next = num3;
					num3_next = num4;
					num4_next = num5;
					wrong_eat_next = 1'b0;
				end
				else begin
					wrong_eat_next = 1'b1;
				end
				pos5_next = pos6;
				pos6_next = newPos; //暫定
				
				num5_next = num6;
				num6_next = newNum;
			end
			pos6: begin
				if(num6==num1) begin
					pos1_next = pos2;
					pos2_next = pos3;
					pos3_next = pos4;
					pos4_next = pos5;
					pos5_next = pos1;
					
					num1_next = num2;
					num2_next = num3;
					num3_next = num4;
					num4_next = num5;
					num5_next = num6;
					wrong_eat_next = 1'b0;
				end
				else begin
					wrong_eat_next = 1'b1;
				end
				pos6_next = newPos; //暫定
				num6_next = newNum;
			end
		//	default: wrong_eat_next = 1'b0;
		endcase
	end
	
	always @(*) begin
		six_pos_next = {pos1, pos2, pos3, pos4, pos5, pos6};
		six_num_next = {num1, num2, num3, num4, num5, num6};
		valid_next = game_over? 4'b0000 : 4'b1111;
		buffer_next = six_num[23:8];
		score_next = {s2, s1, s0};
		//buffer_next = {six_pos[38:35], six_pos[31:28], six_pos[24:21], six_pos[17:14] };
	end
	always @(*) begin //調整速度
		delay_next = delay;
		case(s2)
			4'h0: begin 
				if(s1<4'h5)
					delay_next = 15'b111_0000_0000_0000;
				else
					delay_next = 15'b110_1000_0000_0000;
					
			end
			4'h1: begin
				if(s1<4'h5)
					delay_next = 15'b110_0000_0000_0000;
				else
					delay_next = 15'b101_1000_0000_0000;
			end
			4'h2: begin
				if(s1<4'h5)
					delay_next = 15'b101_0000_0000_0000;
				else
					delay_next = 15'b100_1000_0000_0000;
			end
			4'h3: begin 
				if(s1<4'h5)
					delay_next = 15'b100_0000_0000_0000;
				else
					delay_next = 15'b011_1000_0000_0000;
			end
			4'h4: begin 
				if(s1<4'h5)
					delay_next = 15'b011_0000_0000_0000;
				else
					delay_next = 15'b010_1000_0000_0000;
			end
			4'h5: begin
				if(s1<4'h5)
					delay_next = 15'b010_0000_0000_0000;
				else
					delay_next = 15'b001_1000_0000_0000;
			end
			4'h6: delay_next = 15'b001_0000_0000_0000;
			4'h7: delay_next = 15'b001_0000_0000_0000;
			4'h8: delay_next = 15'b001_0000_0000_0000;
			4'h9: delay_next = 15'b001_0000_0000_0000;
		endcase
	end
	always @(*) begin
		newNum_next = newNum;
		case(randNum)
			4'b0000: newNum_next = 4'b0001;
			4'b0001: newNum_next = 4'b0001;
			4'b0010: newNum_next = 4'b0001;
			4'b0011: newNum_next = 4'b0001;
			4'b0100: newNum_next = 4'b0010;
			4'b0101: newNum_next = 4'b0010;
			4'b0110: newNum_next = 4'b0010;
			4'b0111: newNum_next = 4'b0010;
			4'b1000: newNum_next = 4'b0011;
			4'b1001: newNum_next = 4'b0011;
			4'b1010: newNum_next = 4'b0011;
			4'b1011: newNum_next = 4'b0011;
			4'b1100: newNum_next = 4'b0100;
			4'b1101: newNum_next = 4'b0100;
			4'b1110: newNum_next = 4'b0100;
			4'b1111: newNum_next = 4'b0100;
		endcase
	end
	
endmodule
