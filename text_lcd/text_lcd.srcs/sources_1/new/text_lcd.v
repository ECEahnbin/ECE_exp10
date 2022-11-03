module text_lcd(clk, rst, LCD_E, LCD_RS, LCD_RW, LCD_DATA, LED_out, number_btn, control_btn);
input clk, rst;
input [9:0] number_btn;
input [1:0] control_btn;

output reg LCD_RS, LCD_RW;
output LCD_E;
output reg [7:0] LCD_DATA, LED_out;

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
oneshot_universal #(.WIDTH(12)) U1(clk, rst, {number_btn[9:0], control_btn[1:0]}, {btn_number[9:0], btn_control[1:0]});

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
			FUNCTION_SET : // 데이터 입출력 비트 수와 사용 LCD 라인 수 세팅
				{LCD_RS, LCD_RW, LCD_DATA} = 10'b0_0_0011_1000;
			DISP_ONOFF : // 디스플레이, 커서, 반짝임 세팅
				{LCD_RS, LCD_RW, LCD_DATA} = 10'b0_0_0000_1111; // C=1, B=1
			ENTRY_MODE :
				{LCD_RS, LCD_RW, LCD_DATA} = 10'b0_0_0000_0110;
			SET_ADDRESS : // 커서 위치 초기화
				{LCD_RS, LCD_RW, LCD_DATA} = 10'b0_0_0000_0010;
			DELAY_T : // 아무것도 안함
				{LCD_RS, LCD_RW, LCD_DATA} = 10'b0_0_0000_1111;
			WRITE : begin // 숫자 눌렀을 때 LCD출력
				if(cnt == 20) begin // 한 번만 동작하도록
					case(btn_number)
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
				else {LCD_RS, LCD_RW, LCD_DATA} = 10'b0_0_0000_1111;
			end
			CURSOR : begin // *이나 #버튼 눌렀을때 커서 쉬프트
				if(cnt == 20) begin // 한 번만 동작하도록
					case(btn_control)
						2'b10 : {LCD_RS, LCD_RW, LCD_DATA} = 10'b0_0_0001_0000; // LEFT
						2'b01 : {LCD_RS, LCD_RW, LCD_DATA} = 10'b0_0_0001_0100; // RIGHT
					endcase
				end
				else {LCD_RS, LCD_RW, LCD_DATA} = 10'b0_0_0000_1111;
			end
		endcase
	end
end

assign LCD_E = clk;

endmodule