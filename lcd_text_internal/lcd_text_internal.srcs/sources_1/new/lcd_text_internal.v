module text_lcd_internal(clk, rst, LCD_E, LCD_RS, LCD_RW, LCD_DATA, LED_out, number_btn, control_btn, line);
input clk, rst;
input [9:0] number_btn;
input [1:0] control_btn;
input line; // line1, line2 change
reg [4:0] internal; // Counter upto 22

output reg LCD_RS, LCD_RW;
output LCD_E;
output reg [7:0] LCD_DATA, LED_out;

wire line_posi, line_nega; // line변화 확인용

wire [9:0] btn_number;
wire [1:0] btn_control;
reg [2:0] state;
reg [7:0] cnt;
parameter  DELAY = 3'b000,
			FUNCTION_SET = 3'b001,
			DISP_ONOFF = 3'b010,
			ENTRY_MODE = 3'b011,
			SET_ADDRESS = 3'b100,
			DELAY_T = 3'b101,
			WRITE = 3'b110,
			CURSOR = 3'b111;
//button oneshot

oneshot_universal #(.WIDTH(14)) U1(clk, rst, {number_btn[9:0], control_btn[1:0], line, ~line}, {btn_number[9:0], btn_control[1:0], line_posi, line_nega});

always @(posedge clk or negedge rst) begin
	if(!rst) begin
		state <= DELAY;
		LED_out <= 8'b0000_0000;
	end
	else begin
		case(state)
			DELAY : begin
				LED_out <= 8'b1000_0000;
				if(cnt == 70) state <= FUNCTION_SET;
			end
			FUNCTION_SET : begin
				LED_out <= 8'b0100_0000;
				if(cnt == 30) state <= DISP_ONOFF;
			end
			DISP_ONOFF : begin
				LED_out <= 8'b0010_0000;
				if(cnt == 30) state <= ENTRY_MODE;
			end
			ENTRY_MODE : begin
				LED_out <= 8'b0001_0000;
				if(cnt == 30) state <= SET_ADDRESS;
			end
			SET_ADDRESS : begin
				LED_out <= 8'b0000_1000;
				if(cnt == 100) state <= DELAY_T;
			end
			DELAY_T : begin
				LED_out <= 8'b0000_0100;
				state <= |btn_number ? WRITE : (|btn_control ? CURSOR : DELAY_T);
			end
			WRITE : begin
				LED_out <= 8'b0000_0010;
				if(cnt == 30) state <= DELAY_T;
			end
			CURSOR : begin
				LED_out <= 8'b0000_0001;
				if(cnt == 30) state <= DELAY_T;
			end
		endcase
	end
end
always @(posedge clk or negedge rst) begin
	if(!rst)
		cnt <= 0;
	else begin	
		case(state)
			DELAY :
				if(cnt >= 70) cnt <= 0;
				else cnt <= cnt + 1;
			FUNCTION_SET :
				if(cnt >= 30) cnt <= 0;
				else cnt <= cnt + 1;
			DISP_ONOFF :
				if(cnt >= 30) cnt <= 0;
				else cnt <= cnt + 1;
			ENTRY_MODE :
				if(cnt >= 30) cnt <= 0;
				else cnt <= cnt + 1;
			SET_ADDRESS :
				if(cnt >= 100) cnt <= 0;
				else cnt <= cnt + 1;
			DELAY_T :
				cnt <= 0;
			WRITE :
				if(cnt >= 30) cnt <= 0;
				else cnt <= cnt + 1;
			CURSOR :
				if(cnt >= 30) cnt <= 0;
				else cnt <= cnt + 1;
		endcase
	end
end
always @(posedge clk or negedge rst) begin
	if(!rst)
		{LCD_RS, LCD_RW, LCD_DATA} = 10'b0_0_0000_0000;
	else begin
		case(state)
			FUNCTION_SET : // 
				{LCD_RS, LCD_RW, LCD_DATA} = 10'b0_0_0011_1000;
			DISP_ONOFF : //
				{LCD_RS, LCD_RW, LCD_DATA} = 10'b0_0_0000_1111; // C=1, B=1
			ENTRY_MODE :
				{LCD_RS, LCD_RW, LCD_DATA} = 10'b0_0_0000_0110;
			SET_ADDRESS : begin // LINE 1과 LINE2를 나누어 줌
				if(line == 0) // LINE1
					{LCD_RS, LCD_RW, LCD_DATA} = 10'b0_0_1000_0000;
				else // LINE2
					{LCD_RS, LCD_RW, LCD_DATA} = 10'b0_0_1100_0000;
			end
			DELAY_T : // 
				{LCD_RS, LCD_RW, LCD_DATA} = 10'b0_0_0000_1111;
			WRITE : begin //
				if(cnt == 20) begin // 
					case(number_btn) // 토글
						10'b1000_0000_00 : {LCD_RS, LCD_RW, LCD_DATA} = 10'b1_0_0011_0001; // 1
						10'b0100_0000_00 : {LCD_RS, LCD_RW, LCD_DATA} = 10'b1_0_0011_0010; // 2
						10'b0010_0000_00 : {LCD_RS, LCD_RW, LCD_DATA} = 10'b1_0_0011_0011; // 3
						10'b0001_0000_00 : {LCD_RS, LCD_RW, LCD_DATA} = 10'b1_0_0011_0100; // 4
						10'b0000_1000_00 : {LCD_RS, LCD_RW, LCD_DATA} = 10'b1_0_0011_0101; // 5
						10'b0000_0100_00 : {LCD_RS, LCD_RW, LCD_DATA} = 10'b1_0_0011_0110; // 6
						10'b0000_0010_00 : {LCD_RS, LCD_RW, LCD_DATA} = 10'b1_0_0011_0111; // 7
						10'b0000_0001_00 : {LCD_RS, LCD_RW, LCD_DATA} = 10'b1_0_0011_1000; // 8
						10'b0000_0000_10 : {LCD_RS, LCD_RW, LCD_DATA} = 10'b1_0_0011_1001; // 9
						10'b0000_0000_01 : {LCD_RS, LCD_RW, LCD_DATA} = 10'b1_0_0011_1010; // 0
					endcase
				end
				else if(cnt == 21) begin
				    if(internal == 0 & ~line) // LINE1 처음상태로
					   {LCD_RS, LCD_RW, LCD_DATA} = 10'b0010000000;
					else if(internal == 0 & line) // LINE2 처음상태로
					   {LCD_RS, LCD_RW, LCD_DATA} = 10'b0011000000;
				end
				else {LCD_RS, LCD_RW, LCD_DATA} = 10'b0_0_0000_1111;
			end
			CURSOR : begin // 
				if(cnt == 20) begin // 
					case(control_btn) // 토글
						2'b10 : {LCD_RS, LCD_RW, LCD_DATA} = 10'b0_0_0001_0000; // LEFT
						2'b01 : {LCD_RS, LCD_RW, LCD_DATA} = 10'b0_0_0001_0100; // RIGHT
					endcase
				end
				else {LCD_RS, LCD_RW, LCD_DATA} = 10'b0_0_0000_1111;
			end
		endcase
	end
end
always @(posedge clk or negedge rst) begin
	if(!rst) internal <= 0;
	else if(line_posi | line_nega) internal <= 0; // line변화 시 초기화
	else
		if((|btn_number) | btn_control[0]) begin // 버튼을 누르거나 오른쪽 커서 시프트 +1
			if(internal == 21) internal <= 0;
			else internal <= internal + 1;
		end
		else if(btn_control[1]) begin // 왼쪽 커서 시프트 -1
			if(internal == 0)
				internal <= internal; // 0일때 음수 안되도록 경우처리
			else
				internal <= internal - 1;
		end
		else
			internal <= internal;
end
assign LCD_E = clk;

endmodule