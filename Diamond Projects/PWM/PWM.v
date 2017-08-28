// PWM LED
module PWM (rstn, osc_clk, LED, clk );
	input 	rstn ;
	output	osc_clk ;
	output 	[7:0]LED ;			// 8 seperate LEDs
	output 	clk ;

	reg		[22:0]c_delay ;

	GSR GSR_INST (.GSR(rstn)) ;  							// Reset occurs when argument is active low.
	OSCC OSCC_1 (.OSC(osc_clk)) ;							// 
	/////////////////////////////////////////////////////////////////////////////////////////////////////////
	// CLOCK STUFF BEGIN
	always @(posedge osc_clk or negedge rstn) begin			// osc_clk delay loop
		c_delay <= (~rstn) ? 32'h0000 : c_delay + 1;		// output clk speed is 0.5 Hz
	end

	assign 	clk = c_delay[22] ;								// clock set to the c_delay value
	// CLOCK STUFF ENDS

	/////////////////////////////////////////////////////////////////////////////////////////////////////////
	// PWM STUFF BEGIN
	wire rst = ~rstn; 										// make reset active high
	wire [7:0] compare_value [0:7] ;
	assign compare_value[0] = 3'd0;
	assign compare_value[1] = 3'd1;
	assign compare_value[2] = 3'd2;
	assign compare_value[3] = 3'd3;
	assign compare_value[4] = 3'd4;
	assign compare_value[5] = 3'd5;
	assign compare_value[6] = 3'd6;
	assign compare_value[7] = 3'd7;
	generate
		genvar i ;
		for (i = 0; i < 8; i = i + 1) begin
			pwm #(.CTR_LEN(3)) pwms (
				.rst(rst),
				.clk(clk),
				.compare(compare_value[i]),
				.pwm(LED[i])
			);
		end;
	endgenerate;
	// PWM STUFF END
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
