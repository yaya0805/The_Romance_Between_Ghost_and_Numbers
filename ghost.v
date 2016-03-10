module ghost(LCD_CLK, RESETN, score, delay, wrong_eat, game_over, directions, six_num, six_pos, LCD_DATA, LCD_ENABLE,
       LCD_RW, LCD_RSTN, LCD_CS1, LCD_CS2, LCD_DI, nowCoord);

	input  LCD_CLK;
	input  RESETN;
	input [11:0] score;
	input [14:0] delay;
	input wrong_eat;
	input game_over;
	input [2:0]  directions;
	
	input [23:0] six_num;
	input [41:0] six_pos;
	
	output reg [7:0]  LCD_DATA;
	output LCD_ENABLE; 
	output reg LCD_RW;
	output LCD_RSTN;
	output LCD_CS1;
	output LCD_CS2;
	output reg LCD_DI;
	
	output reg [6:0] nowCoord;
	reg [6:0] nowCoord_next;
	
	reg [0:1] LCD_SEL;
	reg [0:1] LCD_SEL_NEXT;
	reg yzero, yzero_next;
	
	reg [7:0]  LCD_DATA_NEXT;
	reg LCD_RW_NEXT;
	reg LCD_DI_NEXT;
	
	reg [3:0]  STATE, STATE_NEXT;
	reg [2:0]  X_PAGE, X_PAGE_NEXT;
	reg [6:0]  Y, Y_NEXT;
	
	reg [2:0] ghost_X, ghost_X_next;
	reg [6:0] ghost_Y, ghost_Y_next;
	reg [2:0] num_X, num_X_next;
	reg [6:0] num_Y, num_Y_next;
	reg [2:0] numCnt, numCnt_next;
	reg [1:0] scoreCnt, scoreCnt_next;
	
	reg [5:0]  Z, Z_NEXT;
	reg [1:0]  IMAGE, IMAGE_NEXT;
	reg [3:0] NUMBER, NUMBER_NEXT;
	reg [3:0] SCORE, SCORE_NEXT;
	
	reg [7:0] PATTERN;
	reg [7:0] NUM_PATTERN;
	reg [7:0] SCORE_PATTERN;
	reg [7:0] BORDER_PATTERN;
	reg [7:0] OVER_0, OVER_1, OVER_2, OVER_3, OVER_4, OVER_5, OVER_6, OVER_7;
	
	reg [7:0]  INDEX, INDEX_NEXT, offset, offset_next;
	reg [14:0] PAUSE_TIME, PAUSE_TIME_NEXT;
	
	reg START, START_NEXT;	
	reg NEW_PAGE, NEW_PAGE_NEXT;
	reg NEW_COL, NEW_COL_NEXT;
	reg [2:0] PAGE_COUNTER, PAGE_COUNTER_NEXT;
	reg [6:0] COL_COUNTER, COL_COUNTER_NEXT;
	reg ENABLE, ENABLE_NEXT;
	
	wire [2:0] X0, X1, X2, X3, X4, X5;
	wire [6:0] Y0, Y1, Y2, Y3, Y4, Y5;
	wire [3:0] N0, N1, N2, N3, N4, N5;
	wire [3:0] score0, score1, score2;
	
	parameter Init          = 4'd0, 
			  Set_StartLine = 4'd1,
			  Clear_Screen  = 4'd2,
			  Copy_Image    = 4'd3,
			  Pause         = 4'd4,
			  Clear_pre     = 4'd5, 
			  Draw_Num      = 4'd6,/**畫數字用*/
			  Draw_Score    = 4'd7,
			  Game_Over     = 4'd8,
			  Draw_Border   = 4'd9;
			  
	//parameter Delay = 15'b111_0000_0000_0000;
	
	parameter move_left = 3'd1;
	parameter move_right = 3'd6;
	parameter move_up = 3'd4;
	parameter move_down = 3'd3;
	parameter move_SW = 3'd0;
	parameter move_NW = 3'd2;
	parameter move_NE = 3'd7;
	parameter move_SE = 3'd5;
	
	
	assign LCD_ENABLE = LCD_CLK & ENABLE; // when ENABLE=1, LCD write can occur at falling edge of clock 
	assign LCD_RSTN = RESETN;
	assign PAUSED_TO_THE_END = (PAUSE_TIME == 0) ? 1 : 0;	
	
	assign LCD_CS1 = LCD_SEL[0];
	assign LCD_CS2 = LCD_SEL[1];
	
	assign score0 = score[11:8],
		   score1 = score[7:4],
		   score2 = score[3:0];

	assign X0 =   six_pos[41:39],
		   X1 =   six_pos[34:32],		  
		   X2 =   six_pos[27:25],		   
		   X3 =   six_pos[20:18],		   
		   X4 =   six_pos[13:11],		   
		   X5 =   six_pos[6:4];		  
	
	assign Y0 = { six_pos[38:35], 3'b000 },
		   Y1 = { six_pos[31:28], 3'b000 },
		   Y2 = { six_pos[24:21], 3'b000 },
		   Y3 = { six_pos[17:14], 3'b000 },
		   Y4 = { six_pos[10:7], 3'b000 },
		   Y5 = { six_pos[3:0], 3'b000 };
		   
	assign N0 = six_num[23:20],
		   N1 = six_num[19:16],
		   N2 = six_num[15:12],
		   N3 = six_num[11:8],
		   N4 = six_num[7:4],
		   N5 = six_num[3:0];
	initial begin
		PAUSE_TIME <= delay;
	end
	always@(posedge LCD_CLK or negedge RESETN) begin
		if (!RESETN) begin
			STATE    <= Init;
			PAUSE_TIME    <= delay;
			X_PAGE   <= 0;
			Y  <= 0;
			Z <= 0;
			INDEX 	<=  0;
			LCD_SEL <= 2'b11;
			yzero <= 0;
			offset <=0;
			nowCoord <=0;
			
			ghost_X <= 0; ghost_Y <= 0;
			num_X <= 0; num_Y <= 0;
			numCnt <= 0; scoreCnt <= 0;
			
			LCD_DI   <= 0;
			LCD_RW   <= 0;
			IMAGE    <= 0;
			NUMBER   <= 0;
			SCORE    <= 0;
			
			START <= 0;
			NEW_PAGE <= 1'b0;
			NEW_COL <= 1'b0;
			COL_COUNTER <= 0;
			PAGE_COUNTER <= 0;
			ENABLE <= 1'b0;
		end else begin
			STATE    <= STATE_NEXT;
			PAUSE_TIME    <= PAUSE_TIME_NEXT;
			X_PAGE   <= X_PAGE_NEXT;
			Y  <= Y_NEXT;
			Z <= Z_NEXT;
			INDEX<= INDEX_NEXT;
			LCD_DI   <= LCD_DI_NEXT;
			LCD_RW   <= LCD_RW_NEXT;
			
			LCD_SEL <= LCD_SEL_NEXT;
			yzero <= yzero_next;
			offset <= offset_next;
			nowCoord <= nowCoord_next;
			
			ghost_X <= ghost_X_next;
			ghost_Y <= ghost_Y_next;
			num_X <= num_X_next;
			num_Y <= num_Y_next;
			numCnt <= numCnt_next;
			scoreCnt <= scoreCnt_next;
			
			LCD_DATA <= LCD_DATA_NEXT;
			IMAGE <= IMAGE_NEXT;
			NUMBER <= NUMBER_NEXT;
			SCORE <= SCORE_NEXT;
			
			START <= START_NEXT;	
			NEW_PAGE <= NEW_PAGE_NEXT;
			NEW_COL <= NEW_COL_NEXT;
			COL_COUNTER <= COL_COUNTER_NEXT;
			PAGE_COUNTER <= PAGE_COUNTER_NEXT;
			ENABLE <= ENABLE_NEXT;
		end
	end

	always @(*) begin
		// default assignments
		STATE_NEXT  = STATE;
		PAUSE_TIME_NEXT = PAUSE_TIME;
		X_PAGE_NEXT = X_PAGE;
		Y_NEXT = Y;
		Z_NEXT = Z;
		INDEX_NEXT = INDEX;
		LCD_DI_NEXT = LCD_DI;
		LCD_RW_NEXT = LCD_RW;
		
		LCD_SEL_NEXT = 2'b11;
		yzero_next = yzero;
		offset_next = offset;
		
		nowCoord_next = nowCoord;
		ghost_X_next = ghost_X;
		ghost_Y_next = ghost_Y;
		num_X_next = num_X;
		num_Y_next = num_Y;
		numCnt_next = numCnt;
		scoreCnt_next = scoreCnt;
		
		LCD_DATA_NEXT = LCD_DATA;	
		IMAGE_NEXT = IMAGE;
		NUMBER_NEXT = NUMBER;
		SCORE_NEXT = SCORE;
		
		COL_COUNTER_NEXT = COL_COUNTER; 
		PAGE_COUNTER_NEXT = PAGE_COUNTER;
		START_NEXT =	1'b0;	
		NEW_PAGE_NEXT = 1'b0;
		NEW_COL_NEXT = 1'b0;	
		ENABLE_NEXT = 1'b0;
		case(STATE)
			Init: begin  //initial state
				STATE_NEXT =  Set_StartLine;
				// prepare LCD instruction to turn display on
				LCD_DI_NEXT = 1'b0;
				LCD_RW_NEXT = 1'b0;
				LCD_DATA_NEXT = 8'b0011111_1;
				ENABLE_NEXT = 1'b1;

			end
			Set_StartLine: begin //set start line
				STATE_NEXT = Clear_Screen;
				// prepare LCD instruction to set start line
				LCD_DI_NEXT = 1'b0;
				LCD_RW_NEXT = 1'b0;
				LCD_DATA_NEXT = 8'b11_000000; // start line = 0
				ENABLE_NEXT = 1'b1;
				START_NEXT = 1'b1;
			end
			Clear_Screen: begin
				if (START) begin
					NEW_PAGE_NEXT = 1'b1;
					PAGE_COUNTER_NEXT = 0;
					COL_COUNTER_NEXT = 0;
					X_PAGE_NEXT = 0; // set initial X address
					Y_NEXT = 0; // set initial Y address
					//LCD_SEL_NEXT = 2'b11;
				end else	
				if (NEW_PAGE) begin
					// prepare LCD instruction to move to new page
					LCD_DI_NEXT = 1'b0;
					LCD_RW_NEXT = 1'd0;
					LCD_DATA_NEXT = {5'b10111, X_PAGE};
					ENABLE_NEXT = 1'b1;
					NEW_COL_NEXT = 1'b1;
				end else if (NEW_COL) begin 
					// prepare LCD instruction to move to column 0 
					LCD_DI_NEXT    = 1'b0;
					LCD_RW_NEXT    = 1'd0;
					LCD_DATA_NEXT  = 8'b01_000000; // to move to column 0
					ENABLE_NEXT = 1'b1;
				end else if (COL_COUNTER < 64) begin
					// prepare LCD instruction to write 00000000 into display RAM
					LCD_DI_NEXT    = 1'b1;
					LCD_RW_NEXT    = 1'd0;
					LCD_DATA_NEXT  = 8'b00000000;
					ENABLE_NEXT = 1'b1;
					COL_COUNTER_NEXT = COL_COUNTER + 1;
				end else begin
					if (PAGE_COUNTER == 7) begin // last page of screen
						STATE_NEXT = game_over ? Game_Over : Draw_Border;
						START_NEXT = 1'b1;
						//LCD_SEL_NEXT = 2'b10;
					end else begin
						// prepare to change page
						X_PAGE_NEXT  = X_PAGE + 1;
						NEW_PAGE_NEXT = 1'b1;
						PAGE_COUNTER_NEXT = PAGE_COUNTER + 1;
						COL_COUNTER_NEXT = 0;
					end
				end
			end
			Draw_Border: begin
				if(START) begin
					NEW_PAGE_NEXT = 1'b1;
					COL_COUNTER_NEXT = 0;
					INDEX_NEXT = 0;
				end else if (NEW_PAGE) begin
					// prepare LCD instruction to move to new page 
					LCD_DI_NEXT = 1'b0;
					LCD_RW_NEXT = 1'b0;
					LCD_DATA_NEXT = {5'b10111, 3'b000}; 
					ENABLE_NEXT = 1'b1;
					NEW_COL_NEXT = 1'b1;
				end else if (NEW_COL) begin
					// prepare LCD instruction to move to new column
					LCD_DI_NEXT = 1'b0;
					LCD_RW_NEXT = 1'b0;
					LCD_DATA_NEXT = {2'b01, 6'b101000};
					ENABLE_NEXT = 1'b1;
				end else if (COL_COUNTER < 24) begin
					LCD_SEL_NEXT = 2'b01;
					LCD_DI_NEXT = 1'b1;
					LCD_RW_NEXT = 1'b0;
					LCD_DATA_NEXT = BORDER_PATTERN;
					ENABLE_NEXT = 1'b1;
					INDEX_NEXT = INDEX + 1;
					COL_COUNTER_NEXT = COL_COUNTER + 1;
				end else begin
					STATE_NEXT = Draw_Score;
					START_NEXT = 1'b1;
				end
			end
			Draw_Score: begin
				if(START) begin
					NEW_PAGE_NEXT = 1'b1;
					COL_COUNTER_NEXT = 0;
					INDEX_NEXT = 0;
					case(scoreCnt)
						0: SCORE_NEXT = score0;
						1: SCORE_NEXT = score1;
						2: SCORE_NEXT = score2;
					endcase
				end else if (NEW_PAGE) begin
					// prepare LCD instruction to move to new page 
					LCD_DI_NEXT = 1'b0;
					LCD_RW_NEXT = 1'b0;
					LCD_DATA_NEXT = {5'b10111, 3'b000}; 
					ENABLE_NEXT = 1'b1;
					NEW_COL_NEXT = 1'b1;
				end else if (NEW_COL) begin
					// prepare LCD instruction to move to new column
					LCD_DI_NEXT = 1'b0;
					LCD_RW_NEXT = 1'b0;
					case(scoreCnt)
						0: LCD_DATA_NEXT = {2'b01, 6'b101010};
						1: LCD_DATA_NEXT = {2'b01, 6'b110010};
						2: LCD_DATA_NEXT = {2'b01, 6'b111010};
					endcase
					ENABLE_NEXT = 1'b1;
				end else if (COL_COUNTER < 6) begin
				
					LCD_SEL_NEXT = 2'b01;

					LCD_DI_NEXT = 1'b1;
					LCD_RW_NEXT = 1'b0;
					LCD_DATA_NEXT = SCORE_PATTERN;
					ENABLE_NEXT = 1'b1;
					INDEX_NEXT = INDEX + 1;
					COL_COUNTER_NEXT = COL_COUNTER + 1;
					
				end else begin
					if (scoreCnt == 2) begin
						STATE_NEXT = Draw_Num;
						START_NEXT = 1'b1;
						scoreCnt_next = 0;
						
					end else begin
						scoreCnt_next = scoreCnt + 1;
						START_NEXT = 1'b1;
					end
				end
			end
			Draw_Num: begin
				if(START) begin
					NEW_PAGE_NEXT = 1'b1;
					COL_COUNTER_NEXT = 0;
					INDEX_NEXT = 0;
					case(numCnt)
						0: num_X_next = X0; 
						1: num_X_next = X1; 
						2: num_X_next = X2; 
						3: num_X_next = X3; 
						4: num_X_next = X4; 
						5: num_X_next = X5; 
					endcase
					case(numCnt)
						0: num_Y_next = Y0;
						1: num_Y_next = Y1;
						2: num_Y_next = Y2;
						3: num_Y_next = Y3;
						4: num_Y_next = Y4;
						5: num_Y_next = Y5;
					endcase
					case(numCnt)
						0: NUMBER_NEXT = N0;
						1: NUMBER_NEXT = N1;
						2: NUMBER_NEXT = N2;
						3: NUMBER_NEXT = N3;
						4: NUMBER_NEXT = N4;
						5: NUMBER_NEXT = N5;
					endcase
					
				end else if (NEW_PAGE) begin
					// prepare LCD instruction to move to new page 
					LCD_DI_NEXT = 1'b0;
					LCD_RW_NEXT = 1'b0;
					LCD_DATA_NEXT = {5'b10111, num_X}; 
					ENABLE_NEXT = 1'b1;
					NEW_COL_NEXT = 1'b1;
				end else if (NEW_COL) begin
					// prepare LCD instruction to move to new column
					LCD_DI_NEXT = 1'b0;
					LCD_RW_NEXT = 1'b0;
					LCD_DATA_NEXT = {2'b01, num_Y[5:0]};
					ENABLE_NEXT = 1'b1;
				end else if (COL_COUNTER < 8) begin
				
					if(num_Y < 64 )
						LCD_SEL_NEXT = 2'b10;
					else
						LCD_SEL_NEXT = 2'b01;

					LCD_DI_NEXT = 1'b1;
					LCD_RW_NEXT = 1'b0;
					LCD_DATA_NEXT = NUM_PATTERN;
					ENABLE_NEXT = 1'b1;
					INDEX_NEXT = INDEX + 1;
					COL_COUNTER_NEXT = COL_COUNTER + 1;
					
				end else begin
					if (numCnt == 5) begin
						STATE_NEXT = Copy_Image;
						START_NEXT = 1'b1;
						numCnt_next = 0;
						
					end else begin
						numCnt_next = numCnt + 1; //DRAW下一個數字
						START_NEXT = 1'b1;
					end
				end
			
			end
			Copy_Image: begin // write image pattern into LCD RAM
				if (START) begin
					NEW_PAGE_NEXT = 1'b1;
					PAGE_COUNTER_NEXT = 0;
					COL_COUNTER_NEXT = 0;
					INDEX_NEXT = 0;
					case(directions)
							move_left:  ghost_Y_next = ghost_Y - 8;
							move_right: ghost_Y_next = ghost_Y + 8;
							move_up:    ghost_X_next = ghost_X - 1;
							move_down:  ghost_X_next = ghost_X + 1;
					endcase
					
					
				end else if (NEW_PAGE) begin
					// prepare LCD instruction to move to new page 
				
					LCD_DI_NEXT = 1'b0;
					LCD_RW_NEXT = 1'b0;
					LCD_DATA_NEXT = {5'b10111, ghost_X}; 

					ENABLE_NEXT = 1'b1;
					NEW_COL_NEXT = 1'b1;
				end else if (NEW_COL) begin
					// prepare LCD instruction to move to new column
					LCD_DI_NEXT = 1'b0;
					LCD_RW_NEXT = 1'b0;
					LCD_DATA_NEXT = {2'b01, ghost_Y[5:0]};
					ENABLE_NEXT = 1'b1;
					
				end else if (COL_COUNTER < 8) begin //load image 1 byte at a time, 16 is the width of image
					// prepare LCD instruction to write image data into display RAM
				
					if(ghost_Y < 64 )
						LCD_SEL_NEXT = 2'b10;
					else
						LCD_SEL_NEXT = 2'b01;
					
					
					LCD_DI_NEXT = 1'b1;
					LCD_RW_NEXT = 1'b0;
					LCD_DATA_NEXT = PATTERN;
					ENABLE_NEXT = 1'b1;
					INDEX_NEXT = INDEX + 1;
					COL_COUNTER_NEXT = COL_COUNTER + 1;
					
				end else begin
					//LCD_SEL_NEXT = 2'b11;
					//if (PAGE_COUNTER == 1) begin // last page of image
						if(wrong_eat || game_over)
							IMAGE_NEXT = 2'b10;
						else begin
							IMAGE_NEXT = IMAGE==2'b00 ? 2'b01 : 2'b00;
						end
						//NUMBER_NEXT = NUMBER==9? 0: NUMBER + 1;
						//IMAGE_NEXT = 2'b01;
						STATE_NEXT = Pause;
						COL_COUNTER_NEXT = 0;
						INDEX_NEXT = 0;
					//end else begin
						// prepare to change page
						//X_PAGE_NEXT = X_PAGE + 1;		
					//	NEW_PAGE_NEXT = 1'b1;
						//PAGE_COUNTER_NEXT = PAGE_COUNTER + 1;
						//COL_COUNTER_NEXT = 0;
						//Yoffset_next = 0;
					//end
				end
			end
			Pause: begin
				if (PAUSE_TIME==0) begin //(PAUSED_TO_THE_END) begin
					STATE_NEXT = Clear_Screen;
					START_NEXT = 1'b1;
					PAUSE_TIME_NEXT = delay;
				end else begin 
					STATE_NEXT = Pause;
					PAUSE_TIME_NEXT = PAUSE_TIME - 1; 
				end
				nowCoord_next =  {ghost_X, 4'b0000} + {3'b000, ghost_Y[6:3]};
			end
			Game_Over: begin
				if (START) begin
					NEW_PAGE_NEXT = 1'b1;
					PAGE_COUNTER_NEXT = 0;
					//COL_COUNTER_NEXT = 0;
					X_PAGE_NEXT = 0; // set initial X address
					INDEX_NEXT = 0;
					//LCD_SEL_NEXT = 2'b11;
				end else	
				if (NEW_PAGE) begin
					// prepare LCD instruction to move to new page
					LCD_DI_NEXT = 1'b0;
					LCD_RW_NEXT = 1'd0;
					LCD_DATA_NEXT = {5'b10111, X_PAGE};
					ENABLE_NEXT = 1'b1;
					NEW_COL_NEXT = 1'b1;
				end else if (NEW_COL) begin 
					// prepare LCD instruction to move to column 0 
					LCD_DI_NEXT    = 1'b0;
					LCD_RW_NEXT    = 1'd0;
					LCD_DATA_NEXT  = 8'b01_000000; // to move to column 0
					ENABLE_NEXT = 1'b1;
				end else if (INDEX < 128) begin
					// prepare LCD instruction to write 00000000 into display RAM
					LCD_DI_NEXT    = 1'b1;
					LCD_RW_NEXT    = 1'd0;
					if(INDEX < 64) LCD_SEL_NEXT = 2'b10;
					else           LCD_SEL_NEXT = 2'b01;
					case(X_PAGE)
						0: LCD_DATA_NEXT = OVER_0;
						1: LCD_DATA_NEXT = OVER_1;
						2: LCD_DATA_NEXT = OVER_2;
						3: LCD_DATA_NEXT = OVER_3;
						4: LCD_DATA_NEXT = OVER_4;
						5: LCD_DATA_NEXT = OVER_5;
						6: LCD_DATA_NEXT = OVER_6;
						7: LCD_DATA_NEXT = OVER_7;
					endcase
					ENABLE_NEXT = 1'b1;
					INDEX_NEXT = INDEX + 1;
				end else begin
					if (PAGE_COUNTER == 7) begin // last page of screen
						STATE_NEXT = Game_Over;
						START_NEXT = 1'b1;
					end else begin
						X_PAGE_NEXT  = X_PAGE + 1;
						INDEX_NEXT = 0;
						NEW_PAGE_NEXT = 1'b1;
						PAGE_COUNTER_NEXT = PAGE_COUNTER + 1;
					end
				end
			end
			
			default: STATE_NEXT = Init;
		endcase
    end
	
/*******************************
 * Set PAC_MAN image patterns  *
 *******************************/
 always @(*)begin
	case (IMAGE)
		2'b00:	// all black	
			case (INDEX)
			 // 4'h0  :  PATTERN = 8'b00000000;
			  4'h0  :  PATTERN = 8'b11111000;
			  4'h1  :  PATTERN = 8'b11111110;
			  4'h2  :  PATTERN = 8'b01111111;
			  4'h3  :  PATTERN = 8'b11111111;
			  4'h4  :  PATTERN = 8'b11111111;
			  4'h5  :  PATTERN = 8'b01111111;
			  4'h6  :  PATTERN = 8'b11111110;
			  4'h7  :  PATTERN = 8'b11111000; 
			  //4'h9  :  PATTERN = 8'b00000000;
			  //default:   
			endcase
		2'b01:	// black
			case (INDEX)
			//  4'h0  :  PATTERN = 8'b00000000;
			  4'h0  :  PATTERN = 8'b11111000;
			  4'h1  :  PATTERN = 8'b11100110;
			  4'h2  :  PATTERN = 8'b01100111;
			  4'h3  :  PATTERN = 8'b11111111;
			  4'h4  :  PATTERN = 8'b11111111;
			  4'h5  :  PATTERN = 8'b01100111;
			  4'h6  :  PATTERN = 8'b11100110;
			  4'h7  :  PATTERN = 8'b11111000;
			  
			  
			//  4'h9  :  PATTERN = 8'b00000000;	  
			endcase
		2'b10:	// white
			case (INDEX)
			  //4'h0  :  PATTERN = 8'b00000000;
			  4'h0  :  PATTERN = 8'b11111000;
			  4'h1  :  PATTERN = 8'b10000110;
			  4'h2  :  PATTERN = 8'b01001001;
			  4'h3  :  PATTERN = 8'b10000001;
			  4'h4  :  PATTERN = 8'b10000001;
			  4'h5  :  PATTERN = 8'b01001001;
			  4'h6  :  PATTERN = 8'b10000110;
			  4'h7  :  PATTERN = 8'b11111000;
			  //4'h9  :  PATTERN = 8'b00000000;	
			 			  
			endcase 
	endcase	
  end

 always @(*)begin
	case (NUMBER)
		0:	// all black	
			case (INDEX)
			 // 4'h0  :  PATTERN = 8'b00000000;
			  4'h0  :  NUM_PATTERN = 8'b00000000;
			  4'h1  :  NUM_PATTERN = 8'b00000000;
			  4'h2  :  NUM_PATTERN = 8'b01111100;
			  4'h3  :  NUM_PATTERN = 8'b10000110;
			  4'h4  :  NUM_PATTERN = 8'b10111010;
			  4'h5  :  NUM_PATTERN = 8'b11000010;
			  4'h6  :  NUM_PATTERN = 8'b01111100;
			  4'h7  :  NUM_PATTERN = 8'b00000000;
			  //4'h9  :  PATTERN = 8'b00000000;
			  //default:   
			endcase
		1:	// black
			case (INDEX)
			//  4'h0  :  PATTERN = 8'b00000000;
			  4'h0  :  NUM_PATTERN = 8'b00000000;
			  4'h1  :  NUM_PATTERN = 8'b00000000;
			  4'h2  :  NUM_PATTERN = 8'b10001000;
			  4'h3  :  NUM_PATTERN = 8'b10000100;
			  4'h4  :  NUM_PATTERN = 8'b11111110;
			  4'h5  :  NUM_PATTERN = 8'b10000000;
			  4'h6  :  NUM_PATTERN = 8'b10000000;
			  4'h7  :  NUM_PATTERN = 8'b00000000;
			  
			  
			//  4'h9  :  PATTERN = 8'b00000000;	  
			endcase
		2:	// white
			case (INDEX)
			  //4'h0  :  PATTERN = 8'b00000000;
			  4'h0  :  NUM_PATTERN = 8'b00000000;
			  4'h1  :  NUM_PATTERN = 8'b00000000;
			  4'h2  :  NUM_PATTERN = 8'b00000000;
			  4'h3  :  NUM_PATTERN = 8'b11000100;
			  4'h4  :  NUM_PATTERN = 8'b10100010;
			  4'h5  :  NUM_PATTERN = 8'b10010010;
			  4'h6  :  NUM_PATTERN = 8'b10001100;
			  4'h7  :  NUM_PATTERN = 8'b00000000;
			  //4'h9  :  PATTERN = 8'b00000000;	
			 			  
			endcase 
		3:	// white
			case (INDEX)
			  //4'h0  :  PATTERN = 8'b00000000;
			  4'h0  : NUM_PATTERN = 8'b00000000;
			  4'h1  : NUM_PATTERN = 8'b00000000;
			  4'h2  : NUM_PATTERN = 8'b01000100;
			  4'h3  : NUM_PATTERN = 8'b10000010;
			  4'h4  : NUM_PATTERN = 8'b10010010;
			  4'h5  : NUM_PATTERN = 8'b10010010;
			  4'h6  : NUM_PATTERN = 8'b01101100;
			  4'h7  : NUM_PATTERN = 8'b00000000;
			  //4'h9  :  PATTERN = 8'b00000000;	
			 			  
			endcase
		4:	// white
			case (INDEX)
			  //4'h0  :  PATTERN = 8'b00000000;
			  4'h0  : NUM_PATTERN = 8'b00000000;
			  4'h1  : NUM_PATTERN = 8'b00000000;
			  4'h2  : NUM_PATTERN = 8'b00110000;
			  4'h3  : NUM_PATTERN = 8'b00101000;
			  4'h4  : NUM_PATTERN = 8'b00100100;
			  4'h5  : NUM_PATTERN = 8'b11111110;
			  4'h6  : NUM_PATTERN = 8'b00100000;
			  4'h7  : NUM_PATTERN = 8'b00100000;
			  //4'h9  :  PATTERN = 8'b00000000;	
			 			  
			endcase 
		5:	// white
			case (INDEX)
			  //4'h0  :  PATTERN = 8'b00000000;
			  4'h0  :  NUM_PATTERN = 8'b00000000;
			  4'h1  :  NUM_PATTERN = 8'b00000000;
			  4'h2  :  NUM_PATTERN = 8'b00000000;
			  4'h3  :  NUM_PATTERN = 8'b01001110;
			  4'h4  :  NUM_PATTERN = 8'b10001010;
			  4'h5  :  NUM_PATTERN = 8'b10001010;
			  4'h6  :  NUM_PATTERN = 8'b01110010;
			  4'h7  :  NUM_PATTERN = 8'b00000000;
			  //4'h9  :  PATTERN = 8'b00000000;	
			 			  
			endcase 
		6:	// white
			case (INDEX)
			  //4'h0  :  PATTERN = 8'b00000000;
			  4'h0  :  NUM_PATTERN = 8'b00000000;
			  4'h1  :  NUM_PATTERN = 8'b00000000;
			  4'h2  :  NUM_PATTERN = 8'b01111000;
			  4'h3  :  NUM_PATTERN = 8'b10010100;
			  4'h4  :  NUM_PATTERN = 8'b10010010;
			  4'h5  :  NUM_PATTERN = 8'b10010000;
			  4'h6  :  NUM_PATTERN = 8'b01100000;
			  4'h7  :  NUM_PATTERN = 8'b00000000;
			  //4'h9  :  PATTERN = 8'b00000000;	
			 			  
			endcase 
		7:	// white
			case (INDEX)
			  //4'h0  :  PATTERN = 8'b00000000;
			  4'h0  :  NUM_PATTERN = 8'b00000000;
			  4'h1  :  NUM_PATTERN = 8'b00000000;
			  4'h2  :  NUM_PATTERN = 8'b00000010;
			  4'h3  :  NUM_PATTERN = 8'b00000010;
			  4'h4  :  NUM_PATTERN = 8'b11000010;
			  4'h5  :  NUM_PATTERN = 8'b00110010;
			  4'h6  :  NUM_PATTERN = 8'b00001110;
			  4'h7  :  NUM_PATTERN = 8'b00000000;
			  //4'h9  :  PATTERN = 8'b00000000;	
			 			  
			endcase 
		8:	// white
			case (INDEX)
			  //4'h0  :  PATTERN = 8'b00000000;
			  4'h0  :  NUM_PATTERN = 8'b00000000;
			  4'h1  :  NUM_PATTERN = 8'b00000000;
			  4'h2  :  NUM_PATTERN = 8'b01101100;
			  4'h3  :  NUM_PATTERN = 8'b10010010;
			  4'h4  :  NUM_PATTERN = 8'b10010010;
			  4'h5  :  NUM_PATTERN = 8'b10010010;
			  4'h6  :  NUM_PATTERN = 8'b01101100;
			  4'h7  :  NUM_PATTERN = 8'b00000000;
			  //4'h9  :  PATTERN = 8'b00000000;	
			 			  
			endcase 
		9:	// white
			case (INDEX)
			  //4'h0  :  PATTERN = 8'b00000000;
			  4'h0  :  NUM_PATTERN = 8'b00000000;
			  4'h1  :  NUM_PATTERN = 8'b00000000;
			  4'h2  :  NUM_PATTERN = 8'b00001100;
			  4'h3  :  NUM_PATTERN = 8'b00010010;
			  4'h4  :  NUM_PATTERN = 8'b10010010;
			  4'h5  :  NUM_PATTERN = 8'b01010010;
			  4'h6  :  NUM_PATTERN = 8'b00111100;
			  4'h7  :  NUM_PATTERN = 8'b00000000;
			  //4'h9  :  PATTERN = 8'b00000000;	
			 			  
			endcase 
	endcase	
end

 always @(*)begin
	case (SCORE)
		0: case (INDEX)
			  4'h0  :  SCORE_PATTERN = 8'b10000000;
			  4'h1  :  SCORE_PATTERN = 8'b10011110;
			  4'h2  :  SCORE_PATTERN = 8'b00100011;
			  4'h3  :  SCORE_PATTERN = 8'b00101101;
			  4'h4  :  SCORE_PATTERN = 8'b10110001;
			  4'h5  :  SCORE_PATTERN = 8'b10011110; 
			endcase
		1:	case (INDEX)
			  4'h0  :  SCORE_PATTERN = 8'b10000000;
			  4'h1  :  SCORE_PATTERN = 8'b10000000;
			  4'h2  :  SCORE_PATTERN = 8'b00100010;
			  4'h3  :  SCORE_PATTERN = 8'b00111111;
			  4'h4  :  SCORE_PATTERN = 8'b10100000;
			  4'h5  :  SCORE_PATTERN = 8'b10000000;  
			endcase
		2:  case (INDEX)
			  4'h0  :  SCORE_PATTERN = 8'b10000000;
			  4'h1  :  SCORE_PATTERN = 8'b10100010;
			  4'h2  :  SCORE_PATTERN = 8'b00110001;
			  4'h3  :  SCORE_PATTERN = 8'b00101001;
			  4'h4  :  SCORE_PATTERN = 8'b10100110;
			  4'h5  :  SCORE_PATTERN = 8'b10000000; 			  
			endcase 
		3:	case (INDEX)
			  4'h0  : SCORE_PATTERN = 8'b10000000;
			  4'h1  : SCORE_PATTERN = 8'b10010010;
			  4'h2  : SCORE_PATTERN = 8'b00100001;
			  4'h3  : SCORE_PATTERN = 8'b00100101;
			  4'h4  : SCORE_PATTERN = 8'b10100101;
			  4'h5  : SCORE_PATTERN = 8'b10011010;  
			endcase
		4:	case (INDEX)
			  4'h0  : SCORE_PATTERN = 8'b10000000;
			  4'h1  : SCORE_PATTERN = 8'b10011000;
			  4'h2  : SCORE_PATTERN = 8'b00010100;
			  4'h3  : SCORE_PATTERN = 8'b00010010;
			  4'h4  : SCORE_PATTERN = 8'b10111111;
			  4'h5  : SCORE_PATTERN = 8'b10010000;  
			endcase 
		5:	case (INDEX)
			  4'h0  :  SCORE_PATTERN = 8'b10000000;
			  4'h1  :  SCORE_PATTERN = 8'b10010111;
			  4'h2  :  SCORE_PATTERN = 8'b00100101;
			  4'h3  :  SCORE_PATTERN = 8'b00100101;
			  4'h4  :  SCORE_PATTERN = 8'b10011001;
			  4'h5  :  SCORE_PATTERN = 8'b10000000; 
			endcase 
		6:	case (INDEX)
			  4'h0  :  SCORE_PATTERN = 8'b10000000;
			  4'h1  :  SCORE_PATTERN = 8'b10011100;
			  4'h2  :  SCORE_PATTERN = 8'b00101010;
			  4'h3  :  SCORE_PATTERN = 8'b00101001;
			  4'h4  :  SCORE_PATTERN = 8'b10010000;
			  4'h5  :  SCORE_PATTERN = 8'b10000000;	  
			endcase 
		7:	case (INDEX)
			  4'h0  :  SCORE_PATTERN = 8'b10000000;
			  4'h1  :  SCORE_PATTERN = 8'b10000001;
			  4'h2  :  SCORE_PATTERN = 8'b00100001;
			  4'h3  :  SCORE_PATTERN = 8'b00011001;
			  4'h4  :  SCORE_PATTERN = 8'b10000111;
			  4'h5  :  SCORE_PATTERN = 8'b10000000;
			endcase 
		8:	case (INDEX)
			  4'h0  :  SCORE_PATTERN = 8'b10000000;
			  4'h1  :  SCORE_PATTERN = 8'b10011010;
			  4'h2  :  SCORE_PATTERN = 8'b00100101;
			  4'h3  :  SCORE_PATTERN = 8'b00100101;
			  4'h4  :  SCORE_PATTERN = 8'b10011010;
			  4'h5  :  SCORE_PATTERN = 8'b10000000; 
			endcase 
		9:	case (INDEX)
			  4'h0  :  SCORE_PATTERN = 8'b10000000;
			  4'h1  :  SCORE_PATTERN = 8'b10000110;
			  4'h2  :  SCORE_PATTERN = 8'b00101001;
			  4'h3  :  SCORE_PATTERN = 8'b00011001;
			  4'h4  :  SCORE_PATTERN = 8'b10001110;
			  4'h5  :  SCORE_PATTERN = 8'b10000000;
			endcase 
	endcase	
end
always@(*) begin
	case(INDEX)
	8'h00 : BORDER_PATTERN = 8'b01010101;
	8'h01 : BORDER_PATTERN = 8'b01010101;
	8'h02 : BORDER_PATTERN = 8'b00000000;
	8'h03 : BORDER_PATTERN = 8'b00000000;
	8'h04 : BORDER_PATTERN = 8'b00000000;
	8'h05 : BORDER_PATTERN = 8'b00000000;
	8'h06 : BORDER_PATTERN = 8'b00000000;
	8'h07 : BORDER_PATTERN = 8'b00000000;
	8'h08 : BORDER_PATTERN = 8'b00000000;
	8'h09 : BORDER_PATTERN = 8'b00000000;
	8'h0A : BORDER_PATTERN = 8'b00000000;
	8'h0B : BORDER_PATTERN = 8'b00000000;
	8'h0C : BORDER_PATTERN = 8'b00000000;
	8'h0D : BORDER_PATTERN = 8'b00000000;
	8'h0E : BORDER_PATTERN = 8'b00000000;
	8'h0F : BORDER_PATTERN = 8'b00000000;
	8'h10 : BORDER_PATTERN = 8'b00000000;
	8'h11 : BORDER_PATTERN = 8'b00000000;
	8'h12 : BORDER_PATTERN = 8'b00000000;
	8'h13 : BORDER_PATTERN = 8'b00000000;
	8'h14 : BORDER_PATTERN = 8'b00000000;
	8'h15 : BORDER_PATTERN = 8'b00000000;
	8'h16 : BORDER_PATTERN = 8'b00000000;
	8'h17 : BORDER_PATTERN = 8'b00000000;
	endcase
end
always@(INDEX) begin
case(INDEX)
	8'h00 : OVER_0 = 8'h00; 8'h01 : OVER_0 = 8'h00; 8'h02 : OVER_0 = 8'h00;	8'h03 : OVER_0 = 8'h00;
	8'h04 : OVER_0 = 8'h00; 8'h05 : OVER_0 = 8'h00;	8'h06 : OVER_0 = 8'h00;	8'h07 : OVER_0 = 8'h00;
	8'h08 : OVER_0 = 8'h00; 8'h09 : OVER_0 = 8'h80;	8'h0A : OVER_0 = 8'hC0;	8'h0B : OVER_0 = 8'hE0;
	8'h0C : OVER_0 = 8'hE0;	8'h0D : OVER_0 = 8'hE0;	8'h0E : OVER_0 = 8'hE0;	8'h0F : OVER_0 = 8'hE0;
	8'h10 : OVER_0 = 8'hE0; 8'h11 : OVER_0 = 8'hE0;	8'h12 : OVER_0 = 8'hE0;	8'h13 : OVER_0 = 8'hE0;
	8'h14 : OVER_0 = 8'hE0; 8'h15 : OVER_0 = 8'hE0;	8'h16 : OVER_0 = 8'hE0;	8'h17 : OVER_0 = 8'hE0;
	8'h18 : OVER_0 = 8'hE0; 8'h19 : OVER_0 = 8'hC0;	8'h1A : OVER_0 = 8'h80;	8'h1B : OVER_0 = 8'h00;
	8'h1C : OVER_0 = 8'h00;	8'h1D : OVER_0 = 8'h00;	8'h1E : OVER_0 = 8'h00;	8'h1F : OVER_0 = 8'h00;
	8'h20 : OVER_0 = 8'h00;	8'h21 : OVER_0 = 8'h00;	8'h22 : OVER_0 = 8'h00;	8'h23 : OVER_0 = 8'h00;
	8'h24 : OVER_0 = 8'h00;	8'h25 : OVER_0 = 8'h00;	8'h26 : OVER_0 = 8'h00;	8'h27 : OVER_0 = 8'h00;
	8'h28 : OVER_0 = 8'h00; 8'h29 : OVER_0 = 8'h00;	8'h2A : OVER_0 = 8'h00;	8'h2B : OVER_0 = 8'h00;
	8'h2C : OVER_0 = 8'h00;	8'h2D : OVER_0 = 8'h00;	8'h2E : OVER_0 = 8'h00;	8'h2F : OVER_0 = 8'h00;
	8'h30 : OVER_0 = 8'h00;	8'h31 : OVER_0 = 8'h00;	8'h32 : OVER_0 = 8'h00;	8'h33 : OVER_0 = 8'h00;
	8'h34 : OVER_0 = 8'h00;	8'h35 : OVER_0 = 8'h00;	8'h36 : OVER_0 = 8'h00;	8'h37 : OVER_0 = 8'h00;
	8'h38 : OVER_0 = 8'h00; 8'h39 : OVER_0 = 8'h00;	8'h3A : OVER_0 = 8'h00;	8'h3B : OVER_0 = 8'h00;
	8'h3C : OVER_0 = 8'h00;	8'h3D : OVER_0 = 8'h00;	8'h3E : OVER_0 = 8'h00;	8'h3F : OVER_0 = 8'h00;
	8'h40 : OVER_0 = 8'h00;	8'h41 : OVER_0 = 8'h00;	8'h42 : OVER_0 = 8'h00;	8'h43 : OVER_0 = 8'h00;
	8'h44 : OVER_0 = 8'h00;	8'h45 : OVER_0 = 8'h00;	8'h46 : OVER_0 = 8'h00;	8'h47 : OVER_0 = 8'h00;
	8'h48 : OVER_0 = 8'h00; 8'h49 : OVER_0 = 8'h00;	8'h4A : OVER_0 = 8'h00;	8'h4B : OVER_0 = 8'h00;
	8'h4C : OVER_0 = 8'h00;	8'h4D : OVER_0 = 8'h00;	8'h4E : OVER_0 = 8'h00;	8'h4F : OVER_0 = 8'h00;
	8'h50 : OVER_0 = 8'h00;	8'h51 : OVER_0 = 8'h00;	8'h52 : OVER_0 = 8'h00;	8'h53 : OVER_0 = 8'h00;
	8'h54 : OVER_0 = 8'h00;	8'h55 : OVER_0 = 8'h00;	8'h56 : OVER_0 = 8'h00;	8'h57 : OVER_0 = 8'h00;
	8'h58 : OVER_0 = 8'h00; 8'h59 : OVER_0 = 8'h00;	8'h5A : OVER_0 = 8'h00;	8'h5B : OVER_0 = 8'h00;
	8'h5C : OVER_0 = 8'h00;	8'h5D : OVER_0 = 8'h00;	8'h5E : OVER_0 = 8'h00;	8'h5F : OVER_0 = 8'h00;	
	8'h60 : OVER_0 = 8'h00;	8'h61 : OVER_0 = 8'h00;	8'h62 : OVER_0 = 8'h00;	8'h63 : OVER_0 = 8'h00;
	8'h64 : OVER_0 = 8'h00;	8'h65 : OVER_0 = 8'h00;	8'h66 : OVER_0 = 8'h00;	8'h67 : OVER_0 = 8'h00;
	8'h68 : OVER_0 = 8'h00; 8'h69 : OVER_0 = 8'h00;	8'h6A : OVER_0 = 8'h00;	8'h6B : OVER_0 = 8'h00;
	8'h6C : OVER_0 = 8'h00;	8'h6D : OVER_0 = 8'h00;	8'h6E : OVER_0 = 8'h00;	8'h6F : OVER_0 = 8'h00;	
	8'h70 : OVER_0 = 8'h00;	8'h71 : OVER_0 = 8'h00;	8'h72 : OVER_0 = 8'h00;	8'h73 : OVER_0 = 8'h00;
	8'h74 : OVER_0 = 8'h00;	8'h75 : OVER_0 = 8'h00;	8'h76 : OVER_0 = 8'h00;	8'h77 : OVER_0 = 8'h00;
	8'h78 : OVER_0 = 8'h00; 8'h79 : OVER_0 = 8'h00;	8'h7A : OVER_0 = 8'h00;	8'h7B : OVER_0 = 8'h00;
	8'h7C : OVER_0 = 8'h00;	8'h7D : OVER_0 = 8'h00;	8'h7E : OVER_0 = 8'h00;	8'h7F : OVER_0 = 8'h00;
endcase
end

always@(INDEX) begin
	case(INDEX)
	8'h00 : OVER_1 = 8'h00; 8'h01 : OVER_1 = 8'h00;	8'h02 : OVER_1 = 8'h00;	8'h03 : OVER_1 = 8'h00;
	8'h04 : OVER_1 = 8'h00;	8'h05 : OVER_1 = 8'h00;	8'h06 : OVER_1 = 8'h00;	8'h07 : OVER_1 = 8'h00;
	8'h08 : OVER_1 = 8'hFF; 8'h09 : OVER_1 = 8'hFF;	8'h0A : OVER_1 = 8'hFF;	8'h0B : OVER_1 = 8'hFF;
	8'h0C : OVER_1 = 8'h01;	8'h0D : OVER_1 = 8'h01;	8'h0E : OVER_1 = 8'h01;	8'h0F : OVER_1 = 8'h01;
	8'h10 : OVER_1 = 8'h01; 8'h11 : OVER_1 = 8'h01;	8'h12 : OVER_1 = 8'h01;	8'h13 : OVER_1 = 8'h01;
	8'h14 : OVER_1 = 8'h01;	8'h15 : OVER_1 = 8'h01;	8'h16 : OVER_1 = 8'h01;	8'h17 : OVER_1 = 8'h01;
	8'h18 : OVER_1 = 8'h1F; 8'h19 : OVER_1 = 8'h1F;	8'h1A : OVER_1 = 8'h1F;	8'h1B : OVER_1 = 8'h1F;
	8'h1C : OVER_1 = 8'h00;	8'h1D : OVER_1 = 8'h00;	8'h1E : OVER_1 = 8'h00;	8'h1F : OVER_1 = 8'h00;
	8'h20 : OVER_1 = 8'h00;	8'h21 : OVER_1 = 8'h80;	8'h22 : OVER_1 = 8'hC0;	8'h23 : OVER_1 = 8'hE0;
	8'h24 : OVER_1 = 8'hE0;	8'h25 : OVER_1 = 8'hE0;	8'h26 : OVER_1 = 8'hE0;	8'h27 : OVER_1 = 8'hE0;
	8'h28 : OVER_1 = 8'hE0; 8'h29 : OVER_1 = 8'hE0;	8'h2A : OVER_1 = 8'hE0;	8'h2B : OVER_1 = 8'hE0;
	8'h2C : OVER_1 = 8'hE0;	8'h2D : OVER_1 = 8'hC0;	8'h2E : OVER_1 = 8'h80;	8'h2F : OVER_1 = 8'h00;
	8'h30 : OVER_1 = 8'h00;	8'h31 : OVER_1 = 8'h00;	8'h32 : OVER_1 = 8'h00;	8'h33 : OVER_1 = 8'h00;
	8'h34 : OVER_1 = 8'hE0;	8'h35 : OVER_1 = 8'hE0;	8'h36 : OVER_1 = 8'hE0;	8'h37 : OVER_1 = 8'hE0;
	8'h38 : OVER_1 = 8'h00; 8'h39 : OVER_1 = 8'h00;	8'h3A : OVER_1 = 8'h00;	8'h3B : OVER_1 = 8'h00;
	8'h3C : OVER_1 = 8'h00;	8'h3D : OVER_1 = 8'h00;	8'h3E : OVER_1 = 8'h00;	8'h3F : OVER_1 = 8'h00;
	8'h40 : OVER_1 = 8'h00;	8'h41 : OVER_1 = 8'h00;	8'h42 : OVER_1 = 8'h00;	8'h43 : OVER_1 = 8'h00;
	8'h44 : OVER_1 = 8'h00;	8'h45 : OVER_1 = 8'h00;	8'h46 : OVER_1 = 8'h00;	8'h47 : OVER_1 = 8'h00;
	8'h48 : OVER_1 = 8'h00; 8'h49 : OVER_1 = 8'h00;	8'h4A : OVER_1 = 8'h00;	8'h4B : OVER_1 = 8'h00;
	8'h4C : OVER_1 = 8'h00;	8'h4D : OVER_1 = 8'h80;	8'h4E : OVER_1 = 8'hC0;	8'h4F : OVER_1 = 8'hE0;
	8'h50 : OVER_1 = 8'hE0;	8'h51 : OVER_1 = 8'hE0;	8'h52 : OVER_1 = 8'hE0;	8'h53 : OVER_1 = 8'hE0;
	8'h54 : OVER_1 = 8'hE0;	8'h55 : OVER_1 = 8'hE0;	8'h56 : OVER_1 = 8'hE0;	8'h57 : OVER_1 = 8'hE0;
	8'h58 : OVER_1 = 8'hE0; 8'h59 : OVER_1 = 8'hC0;	8'h5A : OVER_1 = 8'h80;	8'h5B : OVER_1 = 8'h00;
	8'h5C : OVER_1 = 8'h00;	8'h5D : OVER_1 = 8'h00;	8'h5E : OVER_1 = 8'h00;	8'h5F : OVER_1 = 8'h00;	
	8'h60 : OVER_1 = 8'h00;	8'h61 : OVER_1 = 8'h00;	8'h62 : OVER_1 = 8'h00;	8'h63 : OVER_1 = 8'h00;
	8'h64 : OVER_1 = 8'h20;	8'h65 : OVER_1 = 8'h50;	8'h66 : OVER_1 = 8'h50;	8'h67 : OVER_1 = 8'h88;
	8'h68 : OVER_1 = 8'h88; 8'h69 : OVER_1 = 8'h88;	8'h6A : OVER_1 = 8'h88;	8'h6B : OVER_1 = 8'h88;
	8'h6C : OVER_1 = 8'h88;	8'h6D : OVER_1 = 8'h88;	8'h6E : OVER_1 = 8'h88;	8'h6F : OVER_1 = 8'h88;	
	8'h70 : OVER_1 = 8'h88;	8'h71 : OVER_1 = 8'h50;	8'h72 : OVER_1 = 8'h50;	8'h73 : OVER_1 = 8'h20;
	8'h74 : OVER_1 = 8'h00;	8'h75 : OVER_1 = 8'h00;	8'h76 : OVER_1 = 8'h00;	8'h77 : OVER_1 = 8'h00;
	8'h78 : OVER_1 = 8'h00; 8'h79 : OVER_1 = 8'h00;	8'h7A : OVER_1 = 8'h00;	8'h7B : OVER_1 = 8'h00;
	8'h7C : OVER_1 = 8'h00;	8'h7D : OVER_1 = 8'h00;	8'h7E : OVER_1 = 8'h00;	8'h7F : OVER_1 = 8'h00;
	endcase
end
always@(INDEX) begin
	case(INDEX)
	8'h00 : OVER_2 = 8'h00; 8'h01 : OVER_2 = 8'h00;	8'h02 : OVER_2 = 8'h00;	8'h03 : OVER_2 = 8'h00;
	8'h04 : OVER_2 = 8'h00;	8'h05 : OVER_2 = 8'h00;	8'h06 : OVER_2 = 8'h00;	8'h07 : OVER_2 = 8'h00;
	8'h08 : OVER_2 = 8'hFF; 8'h09 : OVER_2 = 8'hFF;	8'h0A : OVER_2 = 8'hFF;	8'h0B : OVER_2 = 8'hFF;
	8'h0C : OVER_2 = 8'h00;	8'h0D : OVER_2 = 8'h00;	8'h0E : OVER_2 = 8'h00;	8'h0F : OVER_2 = 8'h00;
	8'h10 : OVER_2 = 8'h00;	8'h11 : OVER_2 = 8'h00;	8'h12 : OVER_2 = 8'h00;	8'h13 : OVER_2 = 8'h00;
	8'h14 : OVER_2 = 8'h1E;	8'h15 : OVER_2 = 8'h1E;	8'h16 : OVER_2 = 8'h1E;	8'h17 : OVER_2 = 8'h1E;
	8'h18 : OVER_2 = 8'hFE; 8'h19 : OVER_2 = 8'hFE;	8'h1A : OVER_2 = 8'hFE;	8'h1B : OVER_2 = 8'hFE;
	8'h1C : OVER_2 = 8'h00;	8'h1D : OVER_2 = 8'h00;	8'h1E : OVER_2 = 8'h00;	8'h1F : OVER_2 = 8'h00;
	8'h20 : OVER_2 = 8'h01;	8'h21 : OVER_2 = 8'h81;	8'h22 : OVER_2 = 8'hC1;	8'h23 : OVER_2 = 8'hE1;
	8'h24 : OVER_2 = 8'hE1;	8'h25 : OVER_2 = 8'hE1;	8'h26 : OVER_2 = 8'hE1;	8'h27 : OVER_2 = 8'hE1;
	8'h28 : OVER_2 = 8'hE1; 8'h29 : OVER_2 = 8'hE1;	8'h2A : OVER_2 = 8'hE1;	8'h2B : OVER_2 = 8'hE1;
	8'h2C : OVER_2 = 8'hFF;	8'h2D : OVER_2 = 8'hFF;	8'h2E : OVER_2 = 8'hFF;	8'h2F : OVER_2 = 8'hFF;
	8'h30 : OVER_2 = 8'h00;	8'h31 : OVER_2 = 8'h00;	8'h32 : OVER_2 = 8'h00;	8'h33 : OVER_2 = 8'h00;
	8'h34 : OVER_2 = 8'hFF;	8'h35 : OVER_2 = 8'hFF;	8'h36 : OVER_2 = 8'hFF;	8'h37 : OVER_2 = 8'hFF;
	8'h38 : OVER_2 = 8'h1E;	8'h39 : OVER_2 = 8'h1E;	8'h3A : OVER_2 = 8'h1E;	8'h3B : OVER_2 = 8'h1E;
	8'h3C : OVER_2 = 8'hFE;	8'h3D : OVER_2 = 8'hFC;	8'h3E : OVER_2 = 8'hFC;	8'h3F : OVER_2 = 8'hFE;
	8'h40 : OVER_2 = 8'h1E;	8'h41 : OVER_2 = 8'h1E;	8'h42 : OVER_2 = 8'h1E;	8'h43 : OVER_2 = 8'h1E;
	8'h44 : OVER_2 = 8'hFE;	8'h45 : OVER_2 = 8'hFE;	8'h46 : OVER_2 = 8'hFC;	8'h47 : OVER_2 = 8'hF8;
	8'h48 : OVER_2 = 8'h00; 8'h49 : OVER_2 = 8'h00;	8'h4A : OVER_2 = 8'h00;	8'h4B : OVER_2 = 8'h00;
	8'h4C : OVER_2 = 8'hFF;	8'h4D : OVER_2 = 8'hFF;	8'h4E : OVER_2 = 8'hFF;	8'h4F : OVER_2 = 8'hFF;
	8'h50 : OVER_2 = 8'hE1;	8'h51 : OVER_2 = 8'hE1;	8'h52 : OVER_2 = 8'hE1;	8'h53 : OVER_2 = 8'hE1;
	8'h54 : OVER_2 = 8'hE1;	8'h55 : OVER_2 = 8'hE1;	8'h56 : OVER_2 = 8'hE1;	8'h57 : OVER_2 = 8'hE1;
	8'h58 : OVER_2 = 8'hFF; 8'h59 : OVER_2 = 8'hFF;	8'h5A : OVER_2 = 8'hFF;	8'h5B : OVER_2 = 8'hFF;
	8'h5C : OVER_2 = 8'h00;	8'h5D : OVER_2 = 8'h00;	8'h5E : OVER_2 = 8'h00;	8'h5F : OVER_2 = 8'h00;	
	8'h60 : OVER_2 = 8'h00;	8'h61 : OVER_2 = 8'h00;	8'h62 : OVER_2 = 8'h00;	8'h63 : OVER_2 = 8'h00;
	8'h64 : OVER_2 = 8'h80;	8'h65 : OVER_2 = 8'h80;	8'h66 : OVER_2 = 8'hF8;	8'h67 : OVER_2 = 8'h08;
	8'h68 : OVER_2 = 8'h0E; 8'h69 : OVER_2 = 8'h02;	8'h6A : OVER_2 = 8'h02;	8'h6B : OVER_2 = 8'h02;
	8'h6C : OVER_2 = 8'h02;	8'h6D : OVER_2 = 8'h02;	8'h6E : OVER_2 = 8'h02;	8'h6F : OVER_2 = 8'h0E;	
	8'h70 : OVER_2 = 8'hF8;	8'h71 : OVER_2 = 8'h80;	8'h72 : OVER_2 = 8'h80;	8'h73 : OVER_2 = 8'h00;
	8'h74 : OVER_2 = 8'h00;	8'h75 : OVER_2 = 8'h00;	8'h76 : OVER_2 = 8'h00;	8'h77 : OVER_2 = 8'h00;
	8'h78 : OVER_2 = 8'h00; 8'h79 : OVER_2 = 8'h00;	8'h7A : OVER_2 = 8'h00;	8'h7B : OVER_2 = 8'h00;
	8'h7C : OVER_2 = 8'h00;	8'h7D : OVER_2 = 8'h00;	8'h7E : OVER_2 = 8'h00;	8'h7F : OVER_2 = 8'h00;
	endcase
end
always@(INDEX) begin
	case(INDEX)
	8'h00 : OVER_3 = 8'h00; 8'h01 : OVER_3 = 8'h00;	8'h02 : OVER_3 = 8'h00;	8'h03 : OVER_3 = 8'h00;
	8'h04 : OVER_3 = 8'h00;	8'h05 : OVER_3 = 8'h00;	8'h06 : OVER_3 = 8'h00;	8'h07 : OVER_3 = 8'h00;
	8'h08 : OVER_3 = 8'h3F; 8'h09 : OVER_3 = 8'h7F;	8'h0A : OVER_3 = 8'hFF;	8'h0B : OVER_3 = 8'hFF;
	8'h0C : OVER_3 = 8'hE0;	8'h0D : OVER_3 = 8'hE0;	8'h0E : OVER_3 = 8'hE0;	8'h0F : OVER_3 = 8'hE0;
	8'h10 : OVER_3 = 8'hE0; 8'h11 : OVER_3 = 8'hE0;	8'h12 : OVER_3 = 8'hE0;	8'h13 : OVER_3 = 8'hE0;
	8'h14 : OVER_3 = 8'hE0;	8'h15 : OVER_3 = 8'hE0;	8'h16 : OVER_3 = 8'hE0;	8'h17 : OVER_3 = 8'hE0;
	8'h18 : OVER_3 = 8'hFF;	8'h19 : OVER_3 = 8'hFF;	8'h1A : OVER_3 = 8'h7F;	8'h1B : OVER_3 = 8'h3F;
	8'h1C : OVER_3 = 8'h00;	8'h1D : OVER_3 = 8'h00;	8'h1E : OVER_3 = 8'h00;	8'h1F : OVER_3 = 8'h00;
	8'h20 : OVER_3 = 8'h3F;	8'h21 : OVER_3 = 8'h7F;	8'h22 : OVER_3 = 8'hFF;	8'h23 : OVER_3 = 8'hFF;
	8'h24 : OVER_3 = 8'hE1;	8'h25 : OVER_3 = 8'hE1;	8'h26 : OVER_3 = 8'hE1;	8'h27 : OVER_3 = 8'hE1;
	8'h28 : OVER_3 = 8'hE1; 8'h29 : OVER_3 = 8'hE1;	8'h2A : OVER_3 = 8'hE1;	8'h2B : OVER_3 = 8'hE1;
	8'h2C : OVER_3 = 8'hFF;	8'h2D : OVER_3 = 8'hFF;	8'h2E : OVER_3 = 8'hFF;	8'h2F : OVER_3 = 8'hFF;
	8'h30 : OVER_3 = 8'h00;	8'h31 : OVER_3 = 8'h00;	8'h32 : OVER_3 = 8'h00;	8'h33 : OVER_3 = 8'h00;
	8'h34 : OVER_3 = 8'hFF;	8'h35 : OVER_3 = 8'hFF;	8'h36 : OVER_3 = 8'hFF;	8'h37 : OVER_3 = 8'hFF;
	8'h38 : OVER_3 = 8'h00; 8'h39 : OVER_3 = 8'h00;	8'h3A : OVER_3 = 8'h00;	8'h3B : OVER_3 = 8'h00;
	8'h3C : OVER_3 = 8'hFF;	8'h3D : OVER_3 = 8'hFF;	8'h3E : OVER_3 = 8'hFF;	8'h3F : OVER_3 = 8'hFF;
	8'h40 : OVER_3 = 8'h00;	8'h41 : OVER_3 = 8'h00;	8'h42 : OVER_3 = 8'h00;	8'h43 : OVER_3 = 8'h00;
	8'h44 : OVER_3 = 8'hFF;	8'h45 : OVER_3 = 8'hFF;	8'h46 : OVER_3 = 8'hFF;	8'h47 : OVER_3 = 8'hFF;
	8'h48 : OVER_3 = 8'h00; 8'h49 : OVER_3 = 8'h00;	8'h4A : OVER_3 = 8'h00;	8'h4B : OVER_3 = 8'h00;
	8'h4C : OVER_3 = 8'h3F;	8'h4D : OVER_3 = 8'h7F;	8'h4E : OVER_3 = 8'hFF;	8'h4F : OVER_3 = 8'hFF;
	8'h50 : OVER_3 = 8'hE1;	8'h51 : OVER_3 = 8'hE1;	8'h52 : OVER_3 = 8'hE1;	8'h53 : OVER_3 = 8'hE1;
	8'h54 : OVER_3 = 8'hE1;	8'h55 : OVER_3 = 8'hE1;	8'h56 : OVER_3 = 8'hE1;	8'h57 : OVER_3 = 8'hE1;
	8'h58 : OVER_3 = 8'hE1; 8'h59 : OVER_3 = 8'hE1;	8'h5A : OVER_3 = 8'h01;	8'h5B : OVER_3 = 8'h01;
	8'h5C : OVER_3 = 8'h00;	8'h5D : OVER_3 = 8'h00;	8'h5E : OVER_3 = 8'h00;	8'h5F : OVER_3 = 8'h00;	
	8'h60 : OVER_3 = 8'h00;	8'h61 : OVER_3 = 8'h00;	8'h62 : OVER_3 = 8'h00;	8'h63 : OVER_3 = 8'h00;
	8'h64 : OVER_3 = 8'hFF;	8'h65 : OVER_3 = 8'h00;	8'h66 : OVER_3 = 8'h00;	8'h67 : OVER_3 = 8'hC9;
	8'h68 : OVER_3 = 8'h46; 8'h69 : OVER_3 = 8'h46;	8'h6A : OVER_3 = 8'hC9;	8'h6B : OVER_3 = 8'h00;
	8'h6C : OVER_3 = 8'h00;	8'h6D : OVER_3 = 8'hC9;	8'h6E : OVER_3 = 8'h46;	8'h6F : OVER_3 = 8'h46;	
	8'h70 : OVER_3 = 8'hC9; 8'h71 : OVER_3 = 8'h00;	8'h72 : OVER_3 = 8'h00;	8'h73 : OVER_3 = 8'hFF;
	8'h74 : OVER_3 = 8'h00;	8'h75 : OVER_3 = 8'h00;	8'h76 : OVER_3 = 8'h00;	8'h77 : OVER_3 = 8'h00;
	8'h78 : OVER_3 = 8'h00; 8'h79 : OVER_3 = 8'h00;	8'h7A : OVER_3 = 8'h00;	8'h7B : OVER_3 = 8'h00;
	8'h7C : OVER_3 = 8'h00;	8'h7D : OVER_3 = 8'h00;	8'h7E : OVER_3 = 8'h00; 8'h7F : OVER_3 = 8'h00;
	endcase
end
always@(INDEX) begin
	case(INDEX)
	8'h00 : OVER_4 = 8'h00; 8'h01 : OVER_4 = 8'h00;	8'h02 : OVER_4 = 8'h00;	8'h03 : OVER_4 = 8'h00;
	8'h04 : OVER_4 = 8'h80;	8'h05 : OVER_4 = 8'h00;	8'h06 : OVER_4 = 8'h80;	8'h07 : OVER_4 = 8'h00;
	8'h08 : OVER_4 = 8'h00; 8'h09 : OVER_4 = 8'h80;	8'h0A : OVER_4 = 8'h00;	8'h0B : OVER_4 = 8'h01;
	8'h0C : OVER_4 = 8'h81;	8'h0D : OVER_4 = 8'h01;	8'h0E : OVER_4 = 8'h81;	8'h0F : OVER_4 = 8'h01;
	8'h10 : OVER_4 = 8'h01; 8'h11 : OVER_4 = 8'h81;	8'h12 : OVER_4 = 8'h01;	8'h13 : OVER_4 = 8'h01;
	8'h14 : OVER_4 = 8'h81;	8'h15 : OVER_4 = 8'h01;	8'h16 : OVER_4 = 8'h81;	8'h17 : OVER_4 = 8'h01;
	8'h18 : OVER_4 = 8'h01; 8'h19 : OVER_4 = 8'h80;	8'h1A : OVER_4 = 8'h00;	8'h1B : OVER_4 = 8'h00;
	8'h1C : OVER_4 = 8'h00;	8'h1D : OVER_4 = 8'h00;	8'h1E : OVER_4 = 8'h00;	8'h1F : OVER_4 = 8'h00;
	8'h20 : OVER_4 = 8'h00;	8'h21 : OVER_4 = 8'h00;	8'h22 : OVER_4 = 8'h00;	8'h23 : OVER_4 = 8'h01;
	8'h24 : OVER_4 = 8'h01;	8'h25 : OVER_4 = 8'h01;	8'h26 : OVER_4 = 8'h01;	8'h27 : OVER_4 = 8'h01;
	8'h28 : OVER_4 = 8'h01; 8'h29 : OVER_4 = 8'h81;	8'h2A : OVER_4 = 8'hC1;	8'h2B : OVER_4 = 8'hE1;
	8'h2C : OVER_4 = 8'hE1;	8'h2D : OVER_4 = 8'hE1;	8'h2E : OVER_4 = 8'hE1;	8'h2F : OVER_4 = 8'hE1;
	8'h30 : OVER_4 = 8'hE0;	8'h31 : OVER_4 = 8'hE0;	8'h32 : OVER_4 = 8'hE0;	8'h33 : OVER_4 = 8'hE0;
	8'h34 : OVER_4 = 8'hE1;	8'h35 : OVER_4 = 8'hE1;	8'h36 : OVER_4 = 8'hE1;	8'h37 : OVER_4 = 8'hE1;
	8'h38 : OVER_4 = 8'hE0; 8'h39 : OVER_4 = 8'hC0;	8'h3A : OVER_4 = 8'h80;	8'h3B : OVER_4 = 8'h00;
	8'h3C : OVER_4 = 8'h01;	8'h3D : OVER_4 = 8'h01;	8'h3E : OVER_4 = 8'h01;	8'h3F : OVER_4 = 8'h01;
	8'h40 : OVER_4 = 8'h00;	8'h41 : OVER_4 = 8'h00;	8'h42 : OVER_4 = 8'h00;	8'h43 : OVER_4 = 8'h00;
	8'h44 : OVER_4 = 8'h01;	8'h45 : OVER_4 = 8'h01;	8'h46 : OVER_4 = 8'h01;	8'h47 : OVER_4 = 8'h01;
	8'h48 : OVER_4 = 8'h00; 8'h49 : OVER_4 = 8'h00;	8'h4A : OVER_4 = 8'h00;	8'h4B : OVER_4 = 8'h00;
	8'h4C : OVER_4 = 8'h00;	8'h4D : OVER_4 = 8'h00;	8'h4E : OVER_4 = 8'h00;	8'h4F : OVER_4 = 8'h01;
	8'h50 : OVER_4 = 8'h01;	8'h51 : OVER_4 = 8'h01;	8'h52 : OVER_4 = 8'h01;	8'h53 : OVER_4 = 8'h01;
	8'h54 : OVER_4 = 8'h01;	8'h55 : OVER_4 = 8'h01;	8'h56 : OVER_4 = 8'h01;	8'h57 : OVER_4 = 8'h01;
	8'h58 : OVER_4 = 8'h01; 8'h59 : OVER_4 = 8'h01;	8'h5A : OVER_4 = 8'h00;	8'h5B : OVER_4 = 8'h00;
	8'h5C : OVER_4 = 8'h00;	8'h5D : OVER_4 = 8'h00;	8'h5E : OVER_4 = 8'h00;	8'h5F : OVER_4 = 8'h00;	
	8'h60 : OVER_4 = 8'h00;	8'h61 : OVER_4 = 8'h00;	8'h62 : OVER_4 = 8'h00;	8'h63 : OVER_4 = 8'h00;
	8'h64 : OVER_4 = 8'h01;	8'h65 : OVER_4 = 8'h01;	8'h66 : OVER_4 = 8'h01;	8'h67 : OVER_4 = 8'h01;
	8'h68 : OVER_4 = 8'h00; 8'h69 : OVER_4 = 8'h00;	8'h6A : OVER_4 = 8'h01;	8'h6B : OVER_4 = 8'h01;
	8'h6C : OVER_4 = 8'h01;	8'h6D : OVER_4 = 8'h01;	8'h6E : OVER_4 = 8'h00;	8'h6F : OVER_4 = 8'h00;	
	8'h70 : OVER_4 = 8'h01;	8'h71 : OVER_4 = 8'h01;	8'h72 : OVER_4 = 8'h01;	8'h73 : OVER_4 = 8'h01;
	8'h74 : OVER_4 = 8'h00;	8'h75 : OVER_4 = 8'h00;	8'h76 : OVER_4 = 8'h00;	8'h77 : OVER_4 = 8'h00;
	8'h78 : OVER_4 = 8'h00; 8'h79 : OVER_4 = 8'h00;	8'h7A : OVER_4 = 8'h00;	8'h7B : OVER_4 = 8'h00;
	8'h7C : OVER_4 = 8'h00;	8'h7D : OVER_4 = 8'h00;	8'h7E : OVER_4 = 8'h00;	8'h7F : OVER_4 = 8'h00;
	endcase
end
always@(INDEX) begin
	case(INDEX)
		8'h00 : OVER_5 = 8'h00; 
	8'h01 : OVER_5 = 8'h00;
	8'h02 : OVER_5 = 8'h00;
	8'h03 : OVER_5 = 8'h00;
	8'h04 : OVER_5 = 8'h07;
	8'h05 : OVER_5 = 8'h01;
	8'h06 : OVER_5 = 8'h07;
	8'h07 : OVER_5 = 8'h00;
	8'h08 : OVER_5 = 8'h07; 
	8'h09 : OVER_5 = 8'h02;
	8'h0A : OVER_5 = 8'h07;
	8'h0B : OVER_5 = 8'h80;
	8'h0C : OVER_5 = 8'h47;
	8'h0D : OVER_5 = 8'h41;
	8'h0E : OVER_5 = 8'h27;
	8'h0F : OVER_5 = 8'h20;
	8'h10 : OVER_5 = 8'h27; 
	8'h11 : OVER_5 = 8'h22;
	8'h12 : OVER_5 = 8'h47;
	8'h13 : OVER_5 = 8'h40;
	8'h14 : OVER_5 = 8'h87;
	8'h15 : OVER_5 = 8'h01;
	8'h16 : OVER_5 = 8'h07;
	8'h17 : OVER_5 = 8'h00;
	8'h18 : OVER_5 = 8'h07; 
	8'h19 : OVER_5 = 8'h02;
	8'h1A : OVER_5 = 8'h07;
	8'h1B : OVER_5 = 8'h00;
	8'h1C : OVER_5 = 8'h00;
	8'h1D : OVER_5 = 8'h00;
	8'h1E : OVER_5 = 8'h00;
	8'h1F : OVER_5 = 8'h00;
	8'h20 : OVER_5 = 8'h00;
	8'h21 : OVER_5 = 8'h00;
	8'h22 : OVER_5 = 8'h00;
	8'h23 : OVER_5 = 8'h00;
	8'h24 : OVER_5 = 8'h00;
	8'h25 : OVER_5 = 8'h00;
	8'h26 : OVER_5 = 8'h00;
	8'h27 : OVER_5 = 8'h00;
	8'h28 : OVER_5 = 8'hFF; 
	8'h29 : OVER_5 = 8'hFF;
	8'h2A : OVER_5 = 8'hFF;
	8'h2B : OVER_5 = 8'hFF;
	8'h2C : OVER_5 = 8'h01;
	8'h2D : OVER_5 = 8'h01;
	8'h2E : OVER_5 = 8'h01;
	8'h2F : OVER_5 = 8'h01;
	8'h30 : OVER_5 = 8'h01;
	8'h31 : OVER_5 = 8'h01;
	8'h32 : OVER_5 = 8'h01;
	8'h33 : OVER_5 = 8'h01;
	8'h34 : OVER_5 = 8'h01;
	8'h35 : OVER_5 = 8'h01;
	8'h36 : OVER_5 = 8'h01;
	8'h37 : OVER_5 = 8'h01;
	8'h38 : OVER_5 = 8'hFF; 
	8'h39 : OVER_5 = 8'hFF;
	8'h3A : OVER_5 = 8'hFF;
	8'h3B : OVER_5 = 8'hFF;
	8'h3C : OVER_5 = 8'h00;
	8'h3D : OVER_5 = 8'h00;
	8'h3E : OVER_5 = 8'h00;
	8'h3F : OVER_5 = 8'h00;
	8'h40 : OVER_5 = 8'hE0;
	8'h41 : OVER_5 = 8'hE0;
	8'h42 : OVER_5 = 8'hE0;
	8'h43 : OVER_5 = 8'hE0;
	8'h44 : OVER_5 = 8'h00;
	8'h45 : OVER_5 = 8'h00;
	8'h46 : OVER_5 = 8'h00;
	8'h47 : OVER_5 = 8'h00;
	8'h48 : OVER_5 = 8'h00; 
	8'h49 : OVER_5 = 8'h00;
	8'h4A : OVER_5 = 8'h00;
	8'h4B : OVER_5 = 8'h00;
	8'h4C : OVER_5 = 8'hE0;
	8'h4D : OVER_5 = 8'hE0;
	8'h4E : OVER_5 = 8'hE0;
	8'h4F : OVER_5 = 8'hE0;
	8'h50 : OVER_5 = 8'h00;
	8'h51 : OVER_5 = 8'h00;
	8'h52 : OVER_5 = 8'h00;
	8'h53 : OVER_5 = 8'h00;
	8'h54 : OVER_5 = 8'h00;
	8'h55 : OVER_5 = 8'h80;
	8'h56 : OVER_5 = 8'hC0;
	8'h57 : OVER_5 = 8'hE0;
	8'h58 : OVER_5 = 8'hE0; 
	8'h59 : OVER_5 = 8'hE0;
	8'h5A : OVER_5 = 8'hE0;
	8'h5B : OVER_5 = 8'hE0;
	8'h5C : OVER_5 = 8'hE0;
	8'h5D : OVER_5 = 8'hE0;
	8'h5E : OVER_5 = 8'hE0;
	8'h5F : OVER_5 = 8'hE0;	
	8'h60 : OVER_5 = 8'hE0;
	8'h61 : OVER_5 = 8'hC0;
	8'h62 : OVER_5 = 8'h80;
	8'h63 : OVER_5 = 8'h00;
	8'h64 : OVER_5 = 8'h00;
	8'h65 : OVER_5 = 8'h00;
	8'h66 : OVER_5 = 8'h00;
	8'h67 : OVER_5 = 8'h00;
	8'h68 : OVER_5 = 8'hE0; 
	8'h69 : OVER_5 = 8'hE0;
	8'h6A : OVER_5 = 8'hE0;
	8'h6B : OVER_5 = 8'hE0;
	8'h6C : OVER_5 = 8'h00;
	8'h6D : OVER_5 = 8'h80;
	8'h6E : OVER_5 = 8'hC0;
	8'h6F : OVER_5 = 8'hE0;	
	8'h70 : OVER_5 = 8'hE0;
	8'h71 : OVER_5 = 8'hE0;
	8'h72 : OVER_5 = 8'hE0;
	8'h73 : OVER_5 = 8'hE0;
	8'h74 : OVER_5 = 8'hE0;
	8'h75 : OVER_5 = 8'hC0;
	8'h76 : OVER_5 = 8'h80;
	8'h77 : OVER_5 = 8'h00;
	8'h78 : OVER_5 = 8'h00; 
	8'h79 : OVER_5 = 8'h00;
	8'h7A : OVER_5 = 8'h00;
	8'h7B : OVER_5 = 8'h00;
	8'h7C : OVER_5 = 8'h00;
	8'h7D : OVER_5 = 8'h00;
	8'h7E : OVER_5 = 8'h00;
	8'h7F : OVER_5 = 8'h00;
	endcase
end
always@(INDEX) begin
	case(INDEX)
		8'h00 : OVER_6 = 8'h00; 
	8'h01 : OVER_6 = 8'h00;
	8'h02 : OVER_6 = 8'h00;
	8'h03 : OVER_6 = 8'h00;
	8'h04 : OVER_6 = 8'h00;
	8'h05 : OVER_6 = 8'h00;
	8'h06 : OVER_6 = 8'h00;
	8'h07 : OVER_6 = 8'h00;
	8'h08 : OVER_6 = 8'h78; 
	8'h09 : OVER_6 = 8'hC6;
	8'h0A : OVER_6 = 8'h01;
	8'h0B : OVER_6 = 8'h01;
	8'h0C : OVER_6 = 8'h20;
	8'h0D : OVER_6 = 8'h60;
	8'h0E : OVER_6 = 8'hA0;
	8'h0F : OVER_6 = 8'hA5;
	8'h10 : OVER_6 = 8'h25; 
	8'h11 : OVER_6 = 8'h22;
	8'h12 : OVER_6 = 8'h22;
	8'h13 : OVER_6 = 8'h20;
	8'h14 : OVER_6 = 8'h21;
	8'h15 : OVER_6 = 8'h21;
	8'h16 : OVER_6 = 8'h26;
	8'h17 : OVER_6 = 8'h38;
	8'h18 : OVER_6 = 8'h00; 
	8'h19 : OVER_6 = 8'h00;
	8'h1A : OVER_6 = 8'h00;
	8'h1B : OVER_6 = 8'h00;
	8'h1C : OVER_6 = 8'h00;
	8'h1D : OVER_6 = 8'h00;
	8'h1E : OVER_6 = 8'h00;
	8'h1F : OVER_6 = 8'h00;
	8'h20 : OVER_6 = 8'h00;
	8'h21 : OVER_6 = 8'h00;
	8'h22 : OVER_6 = 8'h00;
	8'h23 : OVER_6 = 8'h00;
	8'h24 : OVER_6 = 8'h00;
	8'h25 : OVER_6 = 8'h00;
	8'h26 : OVER_6 = 8'h00;
	8'h27 : OVER_6 = 8'h00;
	8'h28 : OVER_6 = 8'hFF; 
	8'h29 : OVER_6 = 8'hFF;
	8'h2A : OVER_6 = 8'hFF;
	8'h2B : OVER_6 = 8'hFF;
	8'h2C : OVER_6 = 8'h00;
	8'h2D : OVER_6 = 8'h00;
	8'h2E : OVER_6 = 8'h00;
	8'h2F : OVER_6 = 8'h00;
	8'h30 : OVER_6 = 8'h00;
	8'h31 : OVER_6 = 8'h00;
	8'h32 : OVER_6 = 8'h00;
	8'h33 : OVER_6 = 8'h00;
	8'h34 : OVER_6 = 8'h00;
	8'h35 : OVER_6 = 8'h00;
	8'h36 : OVER_6 = 8'h00;
	8'h37 : OVER_6 = 8'h00;
	8'h38 : OVER_6 = 8'hFF; 
	8'h39 : OVER_6 = 8'hFF;
	8'h3A : OVER_6 = 8'hFF;
	8'h3B : OVER_6 = 8'hFF;
	8'h3C : OVER_6 = 8'h00;
	8'h3D : OVER_6 = 8'h00;
	8'h3E : OVER_6 = 8'h00;
	8'h3F : OVER_6 = 8'h00;
	8'h40 : OVER_6 = 8'hFF;
	8'h41 : OVER_6 = 8'hFF;
	8'h42 : OVER_6 = 8'hFF;
	8'h43 : OVER_6 = 8'hFF;
	8'h44 : OVER_6 = 8'h00;
	8'h45 : OVER_6 = 8'h00;
	8'h46 : OVER_6 = 8'h00;
	8'h47 : OVER_6 = 8'h00;
	8'h48 : OVER_6 = 8'h00; 
	8'h49 : OVER_6 = 8'h00;
	8'h4A : OVER_6 = 8'h00;
	8'h4B : OVER_6 = 8'h00;
	8'h4C : OVER_6 = 8'hFF;
	8'h4D : OVER_6 = 8'hFF;
	8'h4E : OVER_6 = 8'hFF;
	8'h4F : OVER_6 = 8'hFF;
	8'h50 : OVER_6 = 8'h00;
	8'h51 : OVER_6 = 8'h00;
	8'h52 : OVER_6 = 8'h00;
	8'h53 : OVER_6 = 8'h00;
	8'h54 : OVER_6 = 8'hFF;
	8'h55 : OVER_6 = 8'hFF;
	8'h56 : OVER_6 = 8'hFF;
	8'h57 : OVER_6 = 8'hFF;
	8'h58 : OVER_6 = 8'hE1; 
	8'h59 : OVER_6 = 8'hE1;
	8'h5A : OVER_6 = 8'hE1;
	8'h5B : OVER_6 = 8'hE1;
	8'h5C : OVER_6 = 8'hE1;
	8'h5D : OVER_6 = 8'hE1;
	8'h5E : OVER_6 = 8'hE1;
	8'h5F : OVER_6 = 8'hE1;	
	8'h60 : OVER_6 = 8'hFF;
	8'h61 : OVER_6 = 8'hFF;
	8'h62 : OVER_6 = 8'hFF;
	8'h63 : OVER_6 = 8'hFF;
	8'h64 : OVER_6 = 8'h00;
	8'h65 : OVER_6 = 8'h00;
	8'h66 : OVER_6 = 8'h00;
	8'h67 : OVER_6 = 8'h00;
	8'h68 : OVER_6 = 8'hFF; 
	8'h69 : OVER_6 = 8'hFF;
	8'h6A : OVER_6 = 8'hFF;
	8'h6B : OVER_6 = 8'hFF;
	8'h6C : OVER_6 = 8'h1F;
	8'h6D : OVER_6 = 8'h0F;
	8'h6E : OVER_6 = 8'h07;
	8'h6F : OVER_6 = 8'h03;	
	8'h70 : OVER_6 = 8'h01;
	8'h71 : OVER_6 = 8'h01;
	8'h72 : OVER_6 = 8'h01;
	8'h73 : OVER_6 = 8'h01;
	8'h74 : OVER_6 = 8'h03;
	8'h75 : OVER_6 = 8'h07;
	8'h76 : OVER_6 = 8'h0F;
	8'h77 : OVER_6 = 8'h1F;
	8'h78 : OVER_6 = 8'h00; 
	8'h79 : OVER_6 = 8'h00;
	8'h7A : OVER_6 = 8'h00;
	8'h7B : OVER_6 = 8'h00;
	8'h7C : OVER_6 = 8'h00;
	8'h7D : OVER_6 = 8'h00;
	8'h7E : OVER_6 = 8'h00;
	8'h7F : OVER_6 = 8'h00;
	endcase
end
always@(INDEX) begin
	case(INDEX)
		8'h00 : OVER_7 = 8'h00; 
	8'h01 : OVER_7 = 8'h00;
	8'h02 : OVER_7 = 8'h00;
	8'h03 : OVER_7 = 8'h00;
	8'h04 : OVER_7 = 8'h00;
	8'h05 : OVER_7 = 8'h00;
	8'h06 : OVER_7 = 8'h00;
	8'h07 : OVER_7 = 8'h00;
	8'h08 : OVER_7 = 8'h00; 
	8'h09 : OVER_7 = 8'h01;
	8'h0A : OVER_7 = 8'h02;
	8'h0B : OVER_7 = 8'h06;
	8'h0C : OVER_7 = 8'h08;
	8'h0D : OVER_7 = 8'h08;
	8'h0E : OVER_7 = 8'h10;
	8'h0F : OVER_7 = 8'h10;
	8'h10 : OVER_7 = 8'h11; 
	8'h11 : OVER_7 = 8'h11;
	8'h12 : OVER_7 = 8'h0A;
	8'h13 : OVER_7 = 8'h0A;
	8'h14 : OVER_7 = 8'h06;
	8'h15 : OVER_7 = 8'h00;
	8'h16 : OVER_7 = 8'h00;
	8'h17 : OVER_7 = 8'h00;
	8'h18 : OVER_7 = 8'h00; 
	8'h19 : OVER_7 = 8'h00;
	8'h1A : OVER_7 = 8'h00;
	8'h1B : OVER_7 = 8'h00;
	8'h1C : OVER_7 = 8'h00;
	8'h1D : OVER_7 = 8'h00;
	8'h1E : OVER_7 = 8'h00;
	8'h1F : OVER_7 = 8'h00;
	8'h20 : OVER_7 = 8'h00;
	8'h21 : OVER_7 = 8'h00;
	8'h22 : OVER_7 = 8'h00;
	8'h23 : OVER_7 = 8'h00;
	8'h24 : OVER_7 = 8'h00;
	8'h25 : OVER_7 = 8'h00;
	8'h26 : OVER_7 = 8'h00;
	8'h27 : OVER_7 = 8'h00;
	8'h28 : OVER_7 = 8'h3F; 
	8'h29 : OVER_7 = 8'h7F;
	8'h2A : OVER_7 = 8'hFF;
	8'h2B : OVER_7 = 8'hFF;
	8'h2C : OVER_7 = 8'hE0;
	8'h2D : OVER_7 = 8'hE0;
	8'h2E : OVER_7 = 8'hE0;
	8'h2F : OVER_7 = 8'hE0;
	8'h30 : OVER_7 = 8'hE0;
	8'h31 : OVER_7 = 8'hE0;
	8'h32 : OVER_7 = 8'hE0;
	8'h33 : OVER_7 = 8'hE0;
	8'h34 : OVER_7 = 8'hE0;
	8'h35 : OVER_7 = 8'hE0;
	8'h36 : OVER_7 = 8'hE0;
	8'h37 : OVER_7 = 8'hE0;
	8'h38 : OVER_7 = 8'hFF; 
	8'h39 : OVER_7 = 8'hFF;
	8'h3A : OVER_7 = 8'h7F;
	8'h3B : OVER_7 = 8'h3F;
	8'h3C : OVER_7 = 8'h00;
	8'h3D : OVER_7 = 8'h00;
	8'h3E : OVER_7 = 8'h00;
	8'h3F : OVER_7 = 8'h00;
	8'h40 : OVER_7 = 8'h03;
	8'h41 : OVER_7 = 8'h07;
	8'h42 : OVER_7 = 8'h0F;
	8'h43 : OVER_7 = 8'h1F;
	8'h44 : OVER_7 = 8'h3E;
	8'h45 : OVER_7 = 8'h7C;
	8'h46 : OVER_7 = 8'hF8;
	8'h47 : OVER_7 = 8'hF0;
	8'h48 : OVER_7 = 8'hF0; 
	8'h49 : OVER_7 = 8'hF8;
	8'h4A : OVER_7 = 8'h7C;
	8'h4B : OVER_7 = 8'h3E;
	8'h4C : OVER_7 = 8'h1F;
	8'h4D : OVER_7 = 8'h0F;
	8'h4E : OVER_7 = 8'h07;
	8'h4F : OVER_7 = 8'h03;
	8'h50 : OVER_7 = 8'h00;
	8'h51 : OVER_7 = 8'h00;
	8'h52 : OVER_7 = 8'h00;
	8'h53 : OVER_7 = 8'h00;
	8'h54 : OVER_7 = 8'h3F;
	8'h55 : OVER_7 = 8'h7F;
	8'h56 : OVER_7 = 8'hFF;
	8'h57 : OVER_7 = 8'hFF;
	8'h58 : OVER_7 = 8'hE1; 
	8'h59 : OVER_7 = 8'hE1;
	8'h5A : OVER_7 = 8'hE1;
	8'h5B : OVER_7 = 8'hE1;
	8'h5C : OVER_7 = 8'hE1;
	8'h5D : OVER_7 = 8'hE1;
	8'h5E : OVER_7 = 8'hE1;
	8'h5F : OVER_7 = 8'hE1;	
	8'h60 : OVER_7 = 8'hE1;
	8'h61 : OVER_7 = 8'hE1;
	8'h62 : OVER_7 = 8'h01;
	8'h63 : OVER_7 = 8'h01;
	8'h64 : OVER_7 = 8'h00;
	8'h65 : OVER_7 = 8'h00;
	8'h66 : OVER_7 = 8'h00;
	8'h67 : OVER_7 = 8'h00;
	8'h68 : OVER_7 = 8'hFF; 
	8'h69 : OVER_7 = 8'hFF;
	8'h6A : OVER_7 = 8'hFF;
	8'h6B : OVER_7 = 8'hFF;
	8'h6C : OVER_7 = 8'h00;
	8'h6D : OVER_7 = 8'h00;
	8'h6E : OVER_7 = 8'h00;
	8'h6F : OVER_7 = 8'h00;	
	8'h70 : OVER_7 = 8'h00;
	8'h71 : OVER_7 = 8'h00;
	8'h72 : OVER_7 = 8'h00;
	8'h73 : OVER_7 = 8'h00;
	8'h74 : OVER_7 = 8'h00;
	8'h75 : OVER_7 = 8'h00;
	8'h76 : OVER_7 = 8'h00;
	8'h77 : OVER_7 = 8'h00;
	8'h78 : OVER_7 = 8'h00; 
	8'h79 : OVER_7 = 8'h00;
	8'h7A : OVER_7 = 8'h00;
	8'h7B : OVER_7 = 8'h00;
	8'h7C : OVER_7 = 8'h00;
	8'h7D : OVER_7 = 8'h00;
	8'h7E : OVER_7 = 8'h00;
	8'h7F : OVER_7 = 8'h00;
	endcase
end

endmodule 