// 3D Printer Controller Based around the Anycubic Pulley kit
// FPGA:			MACHXO2280
// FTDI Cable:		SPI 3.3V
// 
// Fan A:			12V
//					FPGA out: PWM	- a PWM wave controlling speed, 1'b0 (off) or 1'b1 (on)
// Fan B:			12V
//					FPGA out: PWM	- a PWM wave controlling speed, 1'b0 (off) or 1'b1 (on)
// Thermistor ADC:  ADC141S626
//					1 (Vref): 3.3V
//					2 (+IN): Thermistor Circuit
//					3 (-IN): GND
//					4 (GND): GND
//					5 (GND): GND
//					6 (CS): Thermistor_CS (FPGA out)
//					7 (Dout): Thermistor_Data (FPGA in; 14bit 2s compliment)
//					8 (SCLK): Thermistor_Clock (FPGA out)
//					9 (Vio): 3.3V
//					10 (Va): 3.3V
// HotEnd:			12V
//					FPGA out: 1'b0 (off) or 1'b1 (on)
// StepperControl: 	A4988
// 					1 (Enable): FPGA out
//					2 (MS1): FPGA out
//					3 (MS2): FPGA out
//					4 (MS3): FPGA out
//					5 (RESET): FPGA out
//					6 (SLEEP): FPGA out
//					7 (STEP): FPGA out
//					8 (DIR): FPGA out
//					9 (GND): Vdd GND
//					10 (Vdd): 3.3V
//					11 (1B): MOT
//					12 (1A): MOT
//					13 (2A): MOT
//					14 (2B): MOT
//					15 (GND): VMOT GND
//					16 (VMOT): 12V

module TOP (rstn, osc_clk, clk,
	LED,
	Fan_A, Fan_B,
	Thermistor_Data, Thermistor_CS, Thermistor_Clock,
	HotEnd,
	X_Motor, Y_Motor, Z_Motor, F_Motor,
	X_Limit, Y_Limit, Z_Limit);
	input 	rstn;					// Reset pin for clock
	output	osc_clk;				// ~22 MHz (18-26MHz)
	output 	clk;					// ~0.5 Hz Clock
	
	output 	[7:0]LED;				// 8 LEDS for debug
	
	output 	Fan_A;					// Fan_A
	output 	Fan_B;					// Fan_B
	
	input	Thermistor_Data;
	output	Thermistor_CS;
	output	Thermistor_Clock;
	
	output	HotEnd;
	
	output 	[7:0]X_Motor ;			// 8 Pins to A4988 for X Motor
	output 	[7:0]Y_Motor ;			// 8 Pins to A4988 for Y Motor
	output 	[7:0]Z_Motor ;			// 8 Pins to A4988 for Z Motor
	output 	[7:0]F_Motor ;			// 8 Pins to A4988 for Feed Motor
	
	input 	X_Limit ;				// Limit Button for X Motor
	input 	Y_Limit ;				// Limit Button for Y Motor
	input 	Z_Limit ;				// Limit Button for Z Motor

	/////////////////////////////////////////////////////////////////////////////////////////////////////////
	// CLOCK SETUP BEGIN
	wire clk_2;
	Clock_Setup clock_divider (.rstn(rstn), .osc_clk(osc_clk), .clk(clk), .clk_2(clk_2));
	// CLOCK SETUP ENDS
	
	/////////////////////////////////////////////////////////////////////////////////////////////////////////
	// XYZ Motor Control SETUP STARTS
	wire rst = ~rstn;
	reg X_enable, Y_enable, Z_enable;
	reg X_direction, Y_direction, Z_direction;
	initial begin
	X_enable <= 1'b0;
	X_direction <= 1'b0;
	Y_enable <= 1'b0;
	Y_direction <= 1'b0;
	Z_enable <= 1'b0;
	Z_direction <= 1'b0;	
	end
	StepperControll(.clk(clk_2),.rst(rst),.direction(X_direction),.enable(X_enable),.Motor(X_Motor));	
	StepperControll(.clk(clk_2),.rst(rst),.direction(Y_direction),.enable(Y_enable),.Motor(Y_Motor));	
	StepperControll(.clk(clk_2),.rst(rst),.direction(Z_direction),.enable(Z_enable),.Motor(Z_Motor));	
	// debug	
	StepperControll(.clk(clk_2),.rst(rst),.direction(X_direction),.enable(X_enable),.Motor(LED));	
	// XYZ Motor Control SETUP ENDS
	
	/////////////////////////////////////////////////////////////////////////////////////////////////////////
	// Feed Control SETUP STARTS
	reg F_enable;
	initial begin
		F_enable = 1'b1; // initialize to off
	end
	StepperControll(.clk(clk_2),.rst(rst),.direction(1'b0),.enable(F_enable),.Motor(F_Motor));
	// Feed Control SETUP ENDS
	
	/////////////////////////////////////////////////////////////////////////////////////////////////////////
	// Fan STUFF STARTS
	reg [2:0] speed [0:1];
	initial begin
		speed[0] <= 3'd4;
		speed[1] <= 3'd4;
	end
	// PWM for fan A
	PWM fan_a (.rst(rst),.clock(clk),.compare(speed[0]),.pwm(Fan_A));
	// PWM for fan B
	PWM fan_b (.rst(rst),.clock(clk),.compare(speed[1]),.pwm(Fan_B));
	// Fan STUFF ENDS

endmodule
module Clock_Setup (
	inout rstn,
	inout osc_clk,
	output clk,
	output clk_2
	);
	GSR GSR_INST (.GSR(rstn)) ;  							// Reset occurs when argument is active low.
	OSCC OSCC_1 (.OSC(osc_clk)) ;							// ~22 MHz 
	reg	[22:0]c_delay;
	always @(posedge osc_clk or negedge rstn) begin			// osc_clk delay loop
		c_delay <= (~rstn) ? 32'h0000 : c_delay + 1;		// output clk speed is 0.5 Hz (4 seconds)
	end
	assign 	clk = c_delay[22];							// clock set to the c_delay value
	
	// clock experiment
	// 1Hz
	reg	[13:0]c_delay_2;
	always @(posedge osc_clk or negedge rstn) begin			// osc_clk delay loop
		c_delay_2 <= (~rstn) ? 32'h0000 : c_delay_2 + 1;
	end
	assign 	clk_2 = c_delay_2[13];							// 1/128 seconds
endmodule
module PWM (
	input rst,
    input clock,
    input [2:0] compare,
    output pwm);
	reg pwm_d, pwm_q;
	reg [2:0] ctr_d, ctr_q;
   
	assign pwm = pwm_q;
   
	always @(*) begin
		ctr_d = ctr_q + 1'b1;
		pwm_d = (compare > ctr_q) ? 1'b1 : 1'b0;
	end

	always @(posedge clock) begin
		ctr_q <= rst ? 1'b0 : ctr_d;
		pwm_q <= pwm_d;
	end
endmodule
module StepperControll(
	input clk,
	input rst,
	input direction,
	input enable,
	output [7:0] Motor
	);	
	reg [6:0] settings;
	
	// assign motor to always equal the settings
	assign Motor[0] 	= settings[0];
	assign Motor[1] 	= settings[1];
	assign Motor[2] 	= settings[2];
	assign Motor[3] 	= settings[3];
	assign Motor[4] 	= settings[4];
	assign Motor[5] 	= settings[5];
	assign Motor[7] 	= settings[6];
	
	always @(*) begin
		settings[0] <= enable; // enable: 0 (output motor commands) or 1 (block motor commands)
							 // F	1/2		1/4		1/8		1/16
		settings[1] <= 1'b1; //	1	0		0		1		1
		settings[2] <= 1'b1; // 1	1		1		1		1
		settings[3] <= 1'b1; // 1	1 		0		0		1
									
		settings[4] <= 1'b1; // reset, must be low
		settings[5] <= 1'b1; // sleep, must be low
		settings[6] <= direction; // dir 0 for forward, 1 for backward
	end
	// the 7th pin of the controller is for a pwm to drive the current step
	PWM test2 (
		.rst(rst),
		.clock(clk),
		.compare(3'd7),
		.pwm(Motor[6]));	
endmodule
module Configure_Thermistor(
	input cs,
	input clock, 		//0.9 MHz to 4.5 MHz
	output Thermistor_CS,
	output Thermistor_Clock);
	reg Thermistor_CS;
	reg Thermistor_Clock;
	always @(*) begin
		Thermistor_CS = cs;
		Thermistor_Clock = clock;
	end
endmodule
module Read_ADC(
	input clock, 		//0.9 MHz to 4.5 MHz
	inout Thermistor_CS,
	input Thermistor_Data,
	output signed [13:0] adc_val
	);
	reg Thermistor_CS;
	integer curr_edge = 0;
	reg signed [13:0] incoming_data = 13'b0;
	initial begin
	// set up read
		@(negedge clock) begin
			Thermistor_CS = 1'b0;
		end
		while( curr_edge < 16 ) begin
			@(posedge clock) begin
				// first two rising clock edges are nothing
				if(curr_edge > 1) begin
					incoming_data[curr_edge-2] = Thermistor_Data;
				end
				curr_edge = curr_edge + 1;
			end
		end
		// end read	
		@(negedge clock) begin
			Thermistor_CS = 1'b1;
		end
	end
	assign adc_val = incoming_data;
endmodule

module HotEndTempController (
	input Thermistor_Data,
	output Thermistor_CS,
	output Thermistor_Clock,
	output [2:0] fan_speed [0:1], // 2 3bit numbers
	output HotEnd);
	reg [13:0] adc_val;
	Read_ADC thermistor_read( .clock(clock), .Thermistor_CS(Thermistor_CS), .Thermistor_Clock(Thermistor_Clock), .Thermistor_Data(Thermistor_Data), .adc_val(adc_val)); 
	
	// calculate temperature based on measured voltage
	real desired_temp = 100.0; // IN KELVIN!!!!!!
	// convert undigned 14 bit adc_val to real
	real tempOutput = 0.0;
	// the 14 bit value is a 2's compliment value.
	// ranging from 3.3 V to -3.3 V

	// to make 25 degrees C be 0V, modify the value by ___ V
	real modValue = 1.0;
	real Vth = tempOutput * modValue;
	
	// Calculate Temperature based on voltage equation of a thermistor and voltage divider circuit
	real T1 = 298.15; // Kelvin
	real R1 = 100000.0; // Ohms (Thermistor resistance at T1)
	real Rs = 100000.0; // Ohms (Other Resistor In Divider)
	real B  = 3950.0; // Kelvin	
	real measured_temp = -(T1/($ln((R1*(3.30-Vth))/(Rs*Vth))*(T1/B)-1.0));
	
	// HotEnd On/Off Logic
	if(desired_temp < measured_temp) begin
		// too hot
		// Are fans turned all the way high?
		if (fan_speed[1] != 3'b111 ) begin
			// turn fans higher 1 at a time to double number of fan speeds
			if (fan_speed[0] != fan_speed[1]) assign fan_speed[1] = fan_speed[0];
			else assign fan_speed[0] = fan_speed[0] + 3'b001;
		end
		// turn hotend off
		assign HotEnd = 1'b0;
	end
	else if(desired_temp > measured_temp) begin
		// too cold
		// are fans all the way down?
		if (fan_speed[1] != 3'b000 ) begin
			// turn fans higher 1 at a time to double number of fan speeds
			if (fan_speed[0] != fan_speed[1]) assign fan_speed[1] = fan_speed[0];
			else assign fan_speed[0] = fan_speed[0] - 3'b001;
		end
		// turn HotEnd on
		assign HotEnd = 1'b1;
	end
endmodule