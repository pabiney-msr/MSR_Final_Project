// XYZ Stepper Motor Controller with LED feedback for X and Y
// Stepper motor control is inspired from https://trandi.wordpress.com/2014/09/17/fpga-rc-servo-and-stepper-motor/
// but has been adapted to work with the MACHXO

module TOP (rstn, osc_clk, LED, X_Motor, Y_Motor, Z_Motor, X_Limit, Y_Limit, Z_Limit, clk );
	input 	rstn ;
	output	osc_clk ;
	output 	[7:0]LED ;				// 8 LEDS
	output 	[3:0]X_Motor ;			// 4 Pins to H-Bridge for X Motor
	output 	[3:0]Y_Motor ;			// 4 Pins to H-Bridge for Y Motor
	output 	[3:0]Z_Motor ;			// 4 Pins to H-Bridge for Z Motor
	input 	X_Limit ;				// Limit Button for X Motor
	input 	Y_Limit ;				// Limit Button for Y Motor
	input 	Z_Limit ;				// Limit Button for Z Motor
	output 	clk ;
	wire 	[3:0] X_Motor;			// X_Motor as a register
	wire 	[3:0] Y_Motor;			// Y_Motor as a register
	wire 	[3:0] Z_Motor;			// Z_Motor as a register
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
	reg [31:0] clockCount;
 
	localparam SECOND_DIVIDER = 50000000;
 
	always @ (posedge osc_clk) begin
		if(secondsCounter == 3'b111 || rstn == 0) secondsCounter <= 1'b0;
		clockCount <= clockCount + 1'b1;
		if(clockCount == SECOND_DIVIDER) begin
			clockCount <= 1'b0;
			secondsCounter <= secondsCounter + 1'b1;
        end
	end
	// CLOCK STUFF ENDS
	
	/////////////////////////////////////////////////////////////////////////////////////////////////////////
	// Speed STUFF BEGINS
	reg [31:0] X_Speed = 50000;
	reg [31:0] Y_Speed = 50000;
	reg [31:0] Z_Speed = 50000;
	// Speed STUFF ENDS
	
	/////////////////////////////////////////////////////////////////////////////////////////////////////////
	// Menu STUFF BEGINS
	
	// Menu STUFF ENDS
	
	/////////////////////////////////////////////////////////////////////////////////////////////////////////
	// Screen STUFF BEGINS
	
	// Screen STUFF ENDS
	
	/////////////////////////////////////////////////////////////////////////////////////////////////////////
	// End-Switch STUFF BEGINS
	reg X_dir = 1'b1 ; // Forward
	reg Y_dir = 1'b1 ; // Forward
	reg Z_dir = 1'b1 ; // Forward
	
	always @ (posedge X_Limit) begin
		X_dir <= 1'b0 ;
	end
	always @ (posedge Y_Limit) begin
		Y_dir <= 1'b0 ;
	end
	always @ (posedge Z_Limit) begin
		Z_dir <= 1'b0 ;
	end
	// End-Switch STUFF ENDS	
	
	/////////////////////////////////////////////////////////////////////////////////////////////////////////
	// XYZ Motor Control STUFF STARTS
	Stepper_Controller #(.CTR_LEN(0)) X_Step (
		.Motor(X_Motor),
		.osc_clk(osc_clk),
		.secondsCounter(secondsCounter),
		.direction(X_dir),
		.STEPPER_DIVIDER(X_Speed)
	);
	Stepper_Controller #(.CTR_LEN(0)) Y_Step (
		.Motor(Y_Motor),
		.osc_clk(osc_clk),
		.secondsCounter(secondsCounter),
		.direction(Y_dir),
		.STEPPER_DIVIDER(Y_Speed)
	);
	Stepper_Controller #(.CTR_LEN(0)) Z_Step (
		.Motor(Z_Motor),
		.osc_clk(osc_clk),
		.secondsCounter(secondsCounter),
		.direction(Z_dir),
		.STEPPER_DIVIDER(Z_Speed)
	);
	// XYZ Motor Control STUFF ENDS
	
	/////////////////////////////////////////////////////////////////////////////////////////////////////////
	// LED Feedback STUFF STARTS
	generate
		genvar i;
		for( i = 0; i < 4; i = i + 1) begin
			assign LED[i] = X_Motor[i];					// Use 4 LEDs as Feedback for the X stepper control.
		end
		for( i = 0; i < 4; i = i + 1) begin
			assign LED[4 + i] = Y_Motor[i];				// Use 4 LEDs as Feedback for the Y stepper control.
		end
	endgenerate
	// LED Feedback Stuff Ends
	
endmodule

module Stepper_Controller #(CTR_LEN = 8) (
	output Motor,
	input osc_clk,
	input secondsCounter,
	input direction,
	input STEPPER_DIVIDER
	);
	
	reg	[3:0] Motor;

	reg [31:0] clockCount;
	reg [2:0] step; 									// 8 positions for half steps
	reg initialize = 1'b1 ; 							// bool bit to initialize variables on first pos edge
	
	always @ (posedge osc_clk) begin
		if(clockCount >= STEPPER_DIVIDER * (secondsCounter + 1)) begin
			step <= direction == 1'b1 ? step + 1'b1 : step - 1'b1;
			clockCount <= 1'b0;
		end
		else
			clockCount <= clockCount + 1'b1;
	end

	always @ (step) begin
		case(step)
			0: Motor <= 4'b0111;
			1: Motor <= 4'b0011;
			2: Motor <= 4'b1011;
			3: Motor <= 4'b1001;
			4: Motor <= 4'b1101;
			5: Motor <= 4'b1100;
			6: Motor <= 4'b1110;
			7: Motor <= 4'b0110;
		endcase
	end
endmodule
