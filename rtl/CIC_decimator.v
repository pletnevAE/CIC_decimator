//=====================================================================================
//			CIC Decimation Filter Module
//			
//			Parameters:
//				IN_WIDTH - Input Bit Depth;
//				OUT_WIDTH - Output Bit Depth;
//				N - Filter Order (number of integrators and combs);
//				R - Decimation Coefficient;
//				M - Differential Delay.
//
//			Control Signals:
//				clk - Clock Signal;
//				rst_n - reset (Active-Low);
//				clk_enable - Clock Enable Signal.
//
//			Data:
//				data_in - CIC input data;
//				data_out - CIC output data;
//				out_clk_enable - Output Sample Strobe.
//
//=====================================================================================

module CIC_decimator
#(
	parameter IN_WIDTH = 12,
	parameter OUT_WIDTH = 16,
	parameter N = 3,
	parameter R = 4,
	parameter M = 1
)
(
	input clk, // Clock
	input rst_n, // Reset
	input clk_enable, // Clock Enable
	input signed [IN_WIDTH - 1:0] data_in, // Input data
	output reg out_clk_enable, // Output enable
	output reg signed [OUT_WIDTH - 1:0] data_out // Output data
);

localparam ACC_WIDTH = IN_WIDTH + ($clog2(R * M) * N); // Accumulators Bit Depth
localparam CNT_WIDTH = $clog2(R); // Decimation Counter Bit Depth

wire signed [ACC_WIDTH - 1:0] integ_wire [0:N]; // Integrator Outputs
reg [CNT_WIDTH - 1:0] count; // Decimation counter
reg dec_pulse; // Low frequency enable signal
wire signed [ACC_WIDTH - 1:0] comb_wire [0:N]; // Comb Outputs

genvar i, j;

//=====================================================================================
// Integrator Block - operates at the input clock frequency
//=====================================================================================
assign integ_wire[0] = {{(ACC_WIDTH - IN_WIDTH){data_in[IN_WIDTH - 1]}}, data_in};

generate
	for (i = 0; i < N; i = i + 1) begin : INTEG
		reg signed [ACC_WIDTH - 1:0] acc;
		
		always @ (posedge clk, negedge rst_n) begin
			if (!rst_n) begin
				acc <= {ACC_WIDTH{1'b0}};
			end
			else begin
				if (clk_enable) begin
					acc <= acc + integ_wire[i];
				end
			end
		end
		
		assign integ_wire[i + 1] = acc;
	end
endgenerate

//=====================================================================================
// Decimation Counter
//=====================================================================================
always @ (posedge clk, negedge rst_n) begin
	if (!rst_n) begin
		count <= {CNT_WIDTH{1'b0}};
		dec_pulse <= 1'b0;
	end
	else begin
		if (clk_enable) begin
			if (count == R - 1) begin
				count <= {CNT_WIDTH{1'b0}};
				dec_pulse <= 1'b1;
			end
			else begin
				count <= count + 1'b1;
				dec_pulse <= 1'b0;
			end
		end
		else begin
			dec_pulse <= 1'b0;
		end
	end
end

//=====================================================================================
// Comb Block - operates at the dec_pulse signal
//=====================================================================================
assign comb_wire[0] = integ_wire[N];

generate
	for (i = 0; i < N; i = i + 1) begin : COMB
		reg signed [ACC_WIDTH - 1:0] sr [0:M - 1];
		
		for (j = 0; j < M; j = j + 1) begin : SR // Shift Register
			always @ (posedge clk, negedge rst_n) begin
				if (!rst_n) begin
					sr[j] <= {ACC_WIDTH{1'b0}};
				end
				else begin
					if (dec_pulse) begin
						sr[j] <= (j == 0) ? comb_wire[i] : sr[j - 1];
					end
				end
			end
		end
		
		assign comb_wire[i + 1] = comb_wire[i] - sr[M - 1]; // Differentiator
	end
endgenerate


//=====================================================================================
// Output Register - truncation of the output to a given bit depth
//=====================================================================================
always @ (posedge clk, negedge rst_n) begin
	if (!rst_n) begin
		data_out <= {OUT_WIDTH{1'b0}};
		out_clk_enable <= 1'b0;
	end
	else begin
		out_clk_enable <= dec_pulse;
		if (dec_pulse) begin
			data_out <= comb_wire[N][ACC_WIDTH - 1 -:OUT_WIDTH];
		end
	end
end

endmodule