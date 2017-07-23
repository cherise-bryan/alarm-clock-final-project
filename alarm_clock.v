module alarm_clock(SW, HEX7, HEX6, HEX5, HEX4, HEX3, HEX2, HEX1, HEX0, CLOCK_50, KEY, LEDG);
    input [9:0] SW;
    input CLOCK_50;
    input [2:0] KEY;
    output [6:0] HEX7, HEX6, HEX5, HEX4, HEX3, HEX2, HEX1, HEX0;
    output [0:0] LEDG;

    wire resetn, load, alarm_reset, alarm_en, alarm_out;
    wire [3:0] min1, min2, hour1, hour2, sec1, sec2, timer1, timer2;
    assign load = ~KEY[1];
    assign resetn = ~KEY[0];
    assign alarm_reset = ~KEY[2];
    assign alarm_out = LEDG[0];


    myClock c0(
  	      	.clk(CLOCK_50),
          	.resetn(resetn),
          	.alarm_reset(alarm_reset),
          	.go(load),
	  	.data_in(SW[3:0]),
	  	.alarm_start(SW[5]),
	  	.min1(min1),
	  	.min2(min2),
	  	.hour1(hour1),
	  	.hour2(hour2),
	  	.sec1(sec1),
	 	.sec2(sec2),
	  	.timer1(timer1),
	  	.timer2(timer2),
	  	.alarm_out(alarm_out)
	 	);

    hex_decoder_9MAX H7(
          .hex_digit(hour1),
          .segments(HEX7)
          );

    hex_decoder_9MAX H6(
          .hex_digit(hour2),
          .segments(HEX6)
          );

    hex_decoder_9MAX H5(
          .hex_digit(min1),
          .segments(HEX5)
          );

    hex_decoder_9MAX H4(
          .hex_digit(min2),
          .segments(HEX4)
          );

    hex_decoder_9MAX H3(
          .hex_digit(sec1),
          .segments(HEX3)
          );

    hex_decoder_9MAX H2(
          .hex_digit(sec2),
          .segments(HEX2)
          );

    hex_decoder_9MAX H1(
          .hex_digit(timer1),
          .segments(HEX1)
          );

    hex_decoder_9MAX H0(
          .hex_digit(timer2),
          .segments(HEX0)
          );
endmodule

module myClock(
    input clk,
    input resetn, alarm_reset, alarm_start, go,
    input [3:0] data_in,
    output [3:0] hour1, hour2, min1, min2, sec1, sec2, timer1, timer2,
    output alarm_out
    );

    // lots of wires to connect our datapath and control
    wire ld_min1, ld_min2, ld_hour1, ld_hour2, ld_alarm, start;

    control C0(
		.clk(clk),
		.resetn(resetn),
		.reset_alarm(alarm_reset),
		.go(go),
		.ld_alarm(ld_alarm),
		.ld_hour1(ld_hour1),
		.ld_hour2(ld_hour2),
		.ld_min1(ld_min1),
		.ld_min2(ld_min2),
		.start(start)
		);

    datapath D0(
		.clk(clk),
		.resetn(resetn),
		.reset_alarm(alarm_reset),
		.alarm_start(alarm_start),
		.ld_hour1(ld_hour1),
		.ld_hour2(ld_hour2),
		.ld_min1(ld_min1),
		.ld_min2(ld_min2),
		.start(start),
		.data_in(data_in),
		.hour1(hour1),
		.hour2(hour2),
		.min1(min1),
		.min2(min2),
		.sec1(sec1),
		.sec2(sec2),
		.timer1(timer1),
		.timer2(timer2),
		.alarm_out(alarm_out)
		);


 endmodule

 module control(
		input clk,
		input resetn,
		input reset_alarm,
		input go,

		output reg  ld_min1, ld_min2, ld_hour1, ld_hour2, ld_alarm, start
		);

    reg [5:0] current_state, next_state;

    localparam  s_ld_hour1        = 5'd0,
                s_ld_hour1_wait   = 5'd1,
                s_ld_hour2        = 5'd2,
                s_ld_hour2_wait   = 5'd3,
                s_ld_min1         = 5'd4,
                s_ld_min1_wait    = 5'd5,
                s_ld_min2         = 5'd6,
                s_ld_min2_wait    = 5'd7,
                s_ld_alarm        = 5'd8,
                s_ld_alarm_wait   = 5'd9,
                s_end             = 5'd10;

    always@(*)
    begin: state_table
            case (current_state)
                s_ld_hour1:           next_state = go ? s_ld_hour1_wait : s_ld_hour1;
                s_ld_hour1_wait:      next_state = go ? s_ld_hour1_wait : s_ld_hour2;
                s_ld_hour2:           next_state = go ? s_ld_hour2_wait : s_ld_hour2;
                s_ld_hour2_wait:      next_state = go ? s_ld_hour2_wait : s_ld_min1;
                s_ld_min1:            next_state = go ? s_ld_min1_wait : s_ld_min1;
                s_ld_min1_wait:       next_state = go ? s_ld_min1_wait : s_ld_min2;
                s_ld_min2:            next_state = go ? s_ld_min2_wait : s_ld_min2;
                s_ld_min2_wait:       next_state = go ? s_ld_min2_wait : s_ld_alarm;
                s_ld_alarm:           next_state = go ? s_ld_alarm_wait : s_ld_alarm;
                s_ld_alarm_wait:      next_state = go ? s_ld_alarm_wait : s_end;
                s_end:                next_state = s_end; // stop updating the values of HH:MM and alarm
            default:                  next_state = s_ld_hour1;
        endcase
    end


    // Output logic aka all of our datapath control signals
    always @(*)
    begin: enable_signals
        // By default make all our signals 0
        ld_min1 <= 1'b0;
        ld_min2 <= 1'b0;
        ld_hour1 <= 1'b0;
        ld_hour2 <= 1'b0;
        ld_alarm <= 1'b0;
        start <= 1'b0; // signal to start computing seconds

        case (current_state)
            s_ld_hour1: begin
                ld_hour1 <= 1'b1;
                end
            s_ld_hour2: begin
                ld_hour2 <= 1'b1;
                end
            s_ld_min1: begin
                ld_min1 <= 1'b1;
                end
            s_ld_min2: begin
                ld_min2 <= 1'b1;
                end
            s_ld_alarm: begin
                ld_alarm <= 1'b1;
                end
            s_end: begin // don't update the values of HH:MM, begin computing seconds
                start <= 1'b1;
                ld_hour1 <= 1'b0;
                ld_hour2 <= 1'b0;
                ld_min1 <= 1'b0;
                ld_min2 <= 1'b0;
                ld_alarm <= 1'b0;
                end
        endcase
    end

    always@(posedge clk)
    begin: clock_FFs
        if(resetn) // reset the clock and the alarm
            current_state <= s_ld_hour1;
	else if(reset_alarm) // reset the alarm only
	    current_state <= s_ld_alarm;
	else
	    current_state <= next_state;
    	end
endmodule


module datapath(
    input clk,
    input resetn, reset_alarm,
    input alarm_start,
    input [3:0] data_in,
    input ld_min1, ld_min2, ld_hour1, ld_hour2, ld_alarm, start,
    output reg [3:0] hour1,
    output reg [3:0] hour2,
    output reg [3:0] min1,
    output reg [3:0] min2,
    output reg [3:0] sec1,
    output reg [3:0] sec2,
    output reg [3:0] timer1,
    output reg [3:0] timer2,
    output reg alarm_out
    );

    // time will be displayed on the hex diplays in the form: hour1:hour2 min1:min2 sec1:sec2
    reg [3:0] hour1_val, hour2_val, min1_val, min2_val, sec1_val, sec2_val, timer1_val, timer2_val;
    reg [7:0] alarm_max;
    reg [27:0] counter_1s; // counter to edit the frequency of the clock from 50MHz to 1Hz
    localparam counter_1s_max = 28'b10111110101111000001111111;

    always@(posedge clk) begin

        if(resetn) begin
            hour1 <= 4'b0;
            hour2 <= 4'b0;
            min1 <= 4'b0;
            min2 <= 4'b0;
            sec1 <= 4'b0;
            sec2 <= 4'b0;
            timer1 <= 4'b0;
            timer2 <= 4'b0;
        end

        if (reset_alarm) begin
            timer1 <= 4'b0;
            timer2 <= 4'b0;
        end

        else begin
            counter_1s <= 28'd0;
            if(ld_hour1) begin
               	hour1 <= data_in; // give hour1 the value of SW[2:0]
		hour1_val <= data_in;
		end
            if(ld_hour2) begin
		hour2 <= data_in;  // give hour2 the value of SW[2:0]
		hour2_val <= data_in;
		end
            if(ld_min1) begin
		min1 <= data_in;  // give min1 the value of SW[2:0]
		min1_val <= data_in;
		end
            if(ld_min2) begin
		min2 <= data_in;  // give min2 the value of SW[2:0]
		min2_val <= data_in;
		end
            if(ld_alarm) begin   // select the alarm using SW[1:0]
                timer1 <= timer1_val;
                timer2 <= timer2_val;
                case(data_in)
                4'b0000:
                        begin
                        timer1_val <= 4'd1;  // 15 second timer
                        timer2_val <= 4'd5;
                        end
                4'b0001:
                        begin
                        timer1_val <= 4'd3; // 30 second timer
                        timer2_val <= 4'd0;
                        end
                4'b0010:
                        begin
                        timer1_val <= 4'd4; // 45 second timer
                        timer2_val <= 4'd5;
                        end
                4'b0011:
                        begin
                        timer1_val <= 4'd6; // 60 second timer
                        timer2_val <= 4'd0;
                        end
                default:
                        begin // 0 second timer which will only go off if alarm_start = 1
                        timer1_val <= 4'd0;
                        timer2_val <= 4'd0;
                        end
                endcase
                end
	end

    		if (start) begin // clock starts
			hour1 <= hour1_val; // display hex values
			hour2 <= hour2_val;
			min1 <= min1_val;
			min2 <= min2_val;
			sec1 <= sec1_val;
			sec2 <= sec2_val;
			timer1 <= timer1_val;
			timer2 <= timer2_val;
			counter_1s <= counter_1s + 1'b1;

			if (counter_1s == counter_1s_max) begin

			if (alarm_start) begin // timer countdown starts
				timer2_val <= timer2_val - 1'b1;

			if ((timer1_val > 4'd0) && (timer2_val == 4'd0)) begin
				timer2_val <= 4'd9;
				timer1_val <= timer1_val - 1'b1;
				end

			if ({timer1_val, timer2_val} == 8'b0) begin
				alarm_out <= 1'b1;
				end
		        end

    			counter_1s <= 28'b0; // reset the counter to zero
		        sec2_val <= sec2_val + 1'b1; // the least significant value of SS will be decremented with each 1 second clock pulse

			if (sec2_val >= 9) begin
				sec1_val <= sec1_val + 1'b1;
				sec2_val <= 4'd0;
				end

			if ({sec1_val, sec2_val} >= 8'h59) begin
				sec1_val <= 4'd0;
				sec2_val <= 4'd0;
				min2_val <= min2_val + 1'b1;
				end

			if (min2_val >= 9) begin
				min1_val <= min1_val + 1'b1;
				min2_val <= 4'd0;
			end

			if ({min1_val, min2_val} >= 8'h59) begin
				min1_val <= 4'd0;
				min2_val <= 4'd0;
				hour2_val <= hour2_val + 1'b1;
			end

			if ({hour1_val, hour2_val} >= 8'h24) begin
				hour1_val <= 4'b0;
				hour2_val <= 4'b0;
			end
		end
	end
end
endmodule

module hex_decoder_9MAX(hex_digit, segments);
    input [3:0] hex_digit;
    output reg [6:0] segments;

    always @(*)
        case (hex_digit)
            4'h0: segments = 7'b100_0000;
            4'h1: segments = 7'b111_1001;
            4'h2: segments = 7'b010_0100;
            4'h3: segments = 7'b011_0000;
            4'h4: segments = 7'b001_1001;
            4'h5: segments = 7'b001_0010;
            4'h6: segments = 7'b000_0010;
            4'h7: segments = 7'b111_1000;
            4'h8: segments = 7'b000_0000;
            4'h9: segments = 7'b001_1000;
            default: segments = 7'b100_0000;
        endcase
endmodule
