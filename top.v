module top (clock_40MHz, rstn, col, row, LCD_DATA, LCD_ENABLE,
       LCD_RW, LCD_RSTN, LCD_CS1, LCD_CS2, LCD_DI, dig, seg);
	   
input clock_40MHz;
input rstn;
input [0:3] col;
output [0:3] row;
output [7:0]  LCD_DATA;
output LCD_ENABLE; 
output LCD_RW;
output LCD_RSTN;
output LCD_CS1;
output LCD_CS2;
output LCD_DI;
output [0:3] dig;
output [0:14] seg;

wire clock_1MHz,clock_100KHz,clock_10KHz,clock_1KHz,clock_100Hz,clock_10Hz,clock_1Hz;
wire [2:0] directions;
wire[15:0] buffer;
wire[3:0] valid;
wire [6:0] nowCoord;
wire [23:0] six_num;
wire [41:0] six_pos;
wire [11:0] score;
wire wrong_eat;
wire game_over;
wire [14:0] delay;
	

	clk_div clock(clock_40MHz, clock_1MHz, clock_100KHz, clock_10KHz, clock_1KHz, clock_100Hz, clock_10Hz, clock_1Hz);
	
	keypad_scanner key_scan(clock_100Hz, rstn, col, row, directions);
	
	
	ghost ghost(clock_100KHz, rstn, score, delay, wrong_eat, game_over, directions, six_num, six_pos, LCD_DATA, LCD_ENABLE, LCD_RW, LCD_RSTN, LCD_CS1, LCD_CS2, LCD_DI, nowCoord);

	random rnd_num(clock_100KHz, rstn, nowCoord, six_num, six_pos, buffer, valid, score, delay, wrong_eat, game_over);
	
	display_ct display(clock_1KHz, buffer, valid, dig, seg);
	
	
endmodule
