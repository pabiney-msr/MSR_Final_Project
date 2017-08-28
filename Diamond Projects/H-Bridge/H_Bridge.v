// H-Bridge
module top (rstn, osc_clk, NEG_MOTOR, POS_MOTOR, clk );
	input 	rstn ;
	output	osc_clk ;
	output 	[7:0] NEG_MOTOR ;
	output 	[7:0] POS_MOTOR ;
	output 	clk ;

	reg		[22:0]c_delay ;

	GSR GSR_INST (.GSR(rstn)) ;  							// Reset occurs when argument is active low.
	OSCC OSCC_1 (.OSC(osc_clk)) ;							// 
	/////////////////////////////////////////////////////////////////////////////////////////////////////////
	// CLOCK STUFF BEGIN
	always @(posedge osc_clk or negedge rstn) begin			// osc_clk delay loop
		c_delay <= (~rstn) ? 32'h0000 : c_delay + 1;		// output clk speed is
	end

	assign 	clk = c_delay[22] ;								// clock set to the c_delay value
	// CLOCK STUFF ENDS
	
	/////////////////////////////////////////////////////////////////////////////////////////////////////////
	// PWM STUFF BEGIN
	wire rst = ~rstn; 										// make reset active high
	wire [7:0] speed;									// PWM speeds for motor
	generate
	genvar i ;
	for (i = 0; i < 8; i = i + 1) begin
		pwm #(.CTR_LEN(3)) pwm_1 (
			.rst(rst),
			.clk(clk),
			.compare(3'd0),
			.pwm(speed[i])
		);
	end;
	endgenerate;
	// PWM STUFF END
	
	/////////////////////////////////////////////////////////////////////////////////////////////////////////
	// H-BRIDGE STUFF BEGIN
	wire [2:0] foo;
	generate
	genvar i;
	for (i = 0; i < 8; i = i + 1) begin
		h_bridge #(.CTR_LEN(3)) h_bridge_1 (
			.direction((i%4)),
			.pwm(speed[i]),
			.neg_motor(NEG_MOTOR[i]),
			.pos_motor(POS_MOTOR[i])
		);
	end
	endgenerate;
	// H-BRIDGE STUFF END
endmodule

module h_bridge #(parameter CTR_LEN = 8) (
	input direction , 									// 
	input pwm,											// 
	output neg_motor,
	output pos_motor);
	
	reg neg_motor_loc;
	reg pos_motor_loc;
	
	assign neg_motor = neg_motor_loc;
	assign pos_motor = pos_motor_loc;
	
	always @(*) begin
		neg_motor_loc = (direction % 2 == 0) ? pwm : 1'b0 ;
		pos_motor_loc = (direction % 2 == 1) ? pwm : 1'b0 ;
	end
endmodule

module pwm #(parameter CTR_LEN = 8) (
    input clk,
    input rst,
    input [CTR_LEN - 1 : 0] compare,
    output pwm);
   
	reg pwm_d, pwm_q;
	reg [CTR_LEN - 1: 0] ctr_d, ctr_q;
   
	assign pwm = pwm_q;
   
	always @(*) begin
		ctr_d = ctr_q + 1'b1;
		pwm_d = (compare > ctr_q) ? 1'b1 : 1'b0;
	end

	always @(posedge clk) begin
		ctr_q <= rst ? 1'b0 : ctr_d;
		pwm_q <= pwm_d;
	end   
endmodule
