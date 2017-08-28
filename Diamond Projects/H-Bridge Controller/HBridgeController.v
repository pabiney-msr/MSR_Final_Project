// H-Bridge Controller & Stepper Motor Controller with LED feedback
// Stepper motor control is inspired from https://trandi.wordpress.com/2014/09/17/fpga-rc-servo-and-stepper-motor/
// but has been adapted to work with the MACHXO
module TOP (rstn, osc_clk, LED, X_Motor, clk );
	input 	rstn ;
	output	osc_clk ;
	output 	[3:0]LED ;				// 4 LEDS
	output 	[3:0]X_Motor ;			// 4 Pins to H-Bridge for X Motor
	output 	clk ;
	reg 	[3:0] X_Motor;			// X_Motor as a register
	reg		[22:0]c_delay ;

	GSR GSR_INST (.GSR(rstn)) ;  							// Reset occurs when argument is active low.
	OSCC OSCC_1 (.OSC(osc_clk)) ;							// 
	/////////////////////////////////////////////////////////////////////////////////////////////////////////
	// CLOCK STUFF BEGIN
	always @(posedge osc_clk or negedge rstn) begin			// osc_clk delay loop
		c_delay <= (~rstn) ? 32'h0000 : c_delay + 1;		// output clk speed is 0.5 Hz
	end

	assign 	clk = c_delay[22] ;								// clock set to the c_delay value
	
	reg [2:0] secondsCounter;
	reg [31:0] clockCount1;
 
	localparam SECOND_DIVIDER = 50000000;
 
	always @ (posedge osc_clk)
	begin
		if(secondsCounter == 3'b111 || rstn == 0) secondsCounter <= 1'b0;
		clockCount1 <= clockCount1 + 1'b1;
		if(clockCount1 == SECOND_DIVIDER) begin
			clockCount1 <= 1'b0;
			secondsCounter <= secondsCounter + 1'b1;
        end
	end
	// CLOCK STUFF ENDS

	parameter STEPPER_DIVIDER = 50000; // every 1ms

	reg [31:0] clockCount;
	reg [2:0] step; // 8 positions for half steps
 
	always @ (posedge osc_clk)
	begin
		if(clockCount >= STEPPER_DIVIDER * (secondsCounter + 1))
			begin
				step <= step + 1'b1;
				clockCount <= 1'b0;
			end
		else
			clockCount <= clockCount + 1'b1;
	end

	always @ (step)
	begin
		case(step)
			0: X_Motor <= 4'b0111;
			1: X_Motor <= 4'b0011;
			2: X_Motor <= 4'b1011;
			3: X_Motor <= 4'b1001;
			4: X_Motor <= 4'b1101;
			5: X_Motor <= 4'b1100;
			6: X_Motor <= 4'b1110;
			7: X_Motor <= 4'b0110;
		endcase
	end
	
	assign LED = X_Motor;			// Use the 4 LEDs as Feedback for the stepper control.
endmodule