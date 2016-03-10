//	Display 4 HEX digits on 14-segment displays

module display_ct (
	input clk,
	input [15:0] four_hex,
	input [3:0] valid,		//for each digit, indicate if it should be displayed
	output reg [0:3] dig,	//4 pins to control four digits
	output reg [0:14] seg	//15 pins to control 14 segments plus decimal point
);	
	
	reg [1:0] state, state_next;

	//assign the encodings of the hexadecimals for 14-segment display
	parameter 	BCD0 = 15'b0000_0011_1100111,
					BCD1 = 15'b1001_1111_1111111,
					BCD2 = 15'b0010_0100_1111111,
					BCD3 = 15'b0000_1100_1111111,
					BCD4 = 15'b1001_1000_1111111,
					BCD5 = 15'b0100_1000_1111111,
					BCD6 = 15'b0100_0000_1111111,
					BCD7 = 15'b0001_1111_1111111,
					BCD8 = 15'b0000_0000_1111111,
					BCD9 = 15'b0000_1000_1111111,
					BCDA = 15'b0001_0000_1111111,
					BCDB = 15'b0000_1110_1011011,
					BCDC = 15'b0110_0011_1111111,
					BCDD = 15'b0000_1111_1011011,
					BCDE = 15'b0110_0000_1111111,
					BCDF = 15'b0111_0000_1111111,	
					DARK = 15'b1111_1111_1111111;
	
	// assign state encoding
	parameter	STATE_DIGIT0 = 2'd0,
					STATE_DIGIT1 = 2'd1,
					STATE_DIGIT2 = 2'd2,
					STATE_DIGIT3 = 2'd3;

	// state transition
	always @ (posedge clk) begin
		state <= state_next;
	end

	// compute next state
	always@(*) begin
		case(state)
			STATE_DIGIT0:	state_next = STATE_DIGIT1;
			STATE_DIGIT1:	state_next = STATE_DIGIT2;					
			STATE_DIGIT2: 	state_next = STATE_DIGIT3;				
			STATE_DIGIT3: 	state_next = STATE_DIGIT0;							
			default: 		state_next = STATE_DIGIT0;
		endcase
	end
	
	// select one digit to display by state
	always@(*) begin
		case(state)
			STATE_DIGIT0:	dig = 4'b1110;
			STATE_DIGIT1:	dig = 4'b1101;		
			STATE_DIGIT2: 	dig = 4'b1011;		
			STATE_DIGIT3: 	dig = 4'b0111;					
			default: 		dig = 4'b1111;	
		endcase
	end

	// select segments to display
	always@(*) begin
		if (valid[state] == 1'b1) begin
			case (four_hex[(state*4)+:4])
				4'h0: seg = BCD0;
				4'h1: seg = BCD1;
				4'h2: seg = BCD2;
				4'h3: seg = BCD3;
				4'h4: seg = BCD4;
				4'h5: seg = BCD5;
				4'h6: seg = BCD6;
				4'h7: seg = BCD7;
				4'h8: seg = BCD8;
				4'h9: seg = BCD9;
				4'hA: seg = BCDA;
				4'hB: seg = BCDB;
				4'hC: seg = BCDC;
				4'hD: seg = BCDD;
				4'hE: seg = BCDE;
				4'hF: seg = BCDF;
				default:	seg = DARK;
			endcase
		end else begin
			seg = DARK;
		end
	end

endmodule

	// --> four_hex[(state*4)+:4] can be replaced with the following
	// traditional code:
	// case (state)
	//   2'd0: var = four_hex[3:0];
	//   2'd1: var = four_hex[7:4];
	//   2'd2: var = four_hex[11:5];
	//   2'd3: var = four_hex[15:12];
	// endcase
	// case (var)
	//   4'h0: seg = BCD0;
	//	  4'h1: seg = BCD1;
	//   ...