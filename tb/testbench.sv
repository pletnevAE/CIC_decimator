`timescale 1ns / 1ps

//=====================================================================================
// 		CIC Decimation Filter Testbench Module
//
//			The module is used to feed the stimulus signal to the CIC filter Verilog
//			module being verified and the reference model generated using MATLAB Filter
//			Designer, Simulink and HDL Coder. The module output signals are written to
//			separate files using the enable signal.
//
//=====================================================================================

module testbench;

//=====================================================================================
// Testbench parameters
//=====================================================================================
parameter IN_WIDTH = 12;
parameter OUT_WIDTH = 16;
parameter N = 3;
parameter R = 4;
parameter M = 1;

parameter CLK_PERIOD = 10;
parameter RESET_CYCLES = 10;
parameter CLK_EN_PERIOD = 0;

//=====================================================================================
// Testbench signals
//=====================================================================================	
logic clk;
logic rst_n;
logic clk_enable;
logic signed [IN_WIDTH - 1:0] data_in;
logic out_clk_enable;
logic signed [OUT_WIDTH - 1:0] data_out;
logic out_clk_enable_req;
logic signed [OUT_WIDTH - 1:0] data_out_req;

//=====================================================================================
// CIC Decimation Filter Instantiation
//=====================================================================================
CIC_decimator #(.IN_WIDTH(IN_WIDTH), .OUT_WIDTH(OUT_WIDTH), .N(N), .R(R), .M(M)) dut
(
	.clk(clk),
	.rst_n(rst_n),
	.clk_enable(clk_enable),
	.data_in(data_in),
	.out_clk_enable(out_clk_enable),
	.data_out(data_out)
);

//=====================================================================================
// Reference Simulink Model Instantiation
//=====================================================================================
CIC_Simulink dut_req 
(
	.clk(clk),
	.reset(rst_n),
	.clk_enable(clk_enable),
	.Input_rsvd(data_in),
	.ce_out(out_clk_enable_req),
	.Output_rsvd(data_out_req)
);

//=====================================================================================
// Clock signal generation
//=====================================================================================
initial begin
	clk = 0;
	forever clk = #(CLK_PERIOD/2) ~clk;
end

//=====================================================================================
// Variables
//=====================================================================================
integer stim_file, out_file_rtl, out_file_matlab; // File paths
integer stim_values [$]; // Storage for Stimulus
integer sample_idx; // Storage index
integer wait_cycles; // Number of cycles to wait for simulation completion
int value; // Read sample
int scanf_ret; // File descriptor
integer en_cnt, sample_en_cnt; // clk enable and next sample counter

initial begin
//=====================================================================================
// Reading from a file
//=====================================================================================
	stim_file = $fopen("./MATLAB/stimulus.txt", "r");
	if (stim_file == 0) begin
		$display("ERROR");
		$stop;
	end
	
	while (!$feof(stim_file)) begin
		scanf_ret = $fscanf(stim_file, "%d\n", value);
		if (scanf_ret == 1) begin
			$display("Read Value: %0d", value);
			stim_values.push_back(value);
		end
	end
	$fclose(stim_file);
	
	$display("Loaded %0d samples from stimulus.txt", stim_values.size());
//=====================================================================================
// Opening output files	
//=====================================================================================
	out_file_rtl = $fopen("./MATLAB/output_rtl.txt", "w");
	if (out_file_rtl == 0) begin
		$display("ERROR");
		$stop;
	end
	
	out_file_matlab = $fopen("./MATLAB/output_matlab.txt", "w");
	if (out_file_matlab == 0) begin
		$display("ERROR");
		$stop;
	end

//=====================================================================================
// Starting value of signals	
//=====================================================================================
	rst_n = 1'b0;
	clk_enable = 1'b0;
	data_in = 0;
	sample_idx = 0;
	en_cnt = 0;
	sample_en_cnt = 0;
	

//=====================================================================================
// Removing the reset	
//=====================================================================================
	repeat (RESET_CYCLES) @(posedge clk);
	rst_n = 1'b1;
	$display("Reset off");
	
//=====================================================================================
// Generation of enable signal and index increment
//=====================================================================================	
	while (sample_idx < stim_values.size()) begin
		@(posedge clk);
		if (en_cnt == CLK_EN_PERIOD) begin
			clk_enable = 1;
			en_cnt = 0;
		end
		else begin
			clk_enable = 1'b0;
			en_cnt++;
		end
		if (sample_en_cnt == CLK_EN_PERIOD) begin
			sample_en_cnt = 0;
			data_in = stim_values[sample_idx];
			sample_idx++;
		end
		else begin
			sample_en_cnt++;
		end
	end
	clk_enable = 1'b0;
//=====================================================================================	
// Waiting for the simulation to complete	
//=====================================================================================	
	wait_cycles = (R + N + 10) * CLK_EN_PERIOD;
	repeat (wait_cycles) @(posedge clk);
	$display("Simulation finished.");
	$fclose(out_file_rtl);
	$fclose(out_file_matlab);
	$stop;
	
end

//=====================================================================================	
// Writing samples to a file
//=====================================================================================	
always @ (posedge clk) begin
	if (clk_enable) begin
		if (out_clk_enable) begin
			$fwrite(out_file_rtl, "%d\n", data_out);
		end
	
		if (out_clk_enable_req) begin
			$fwrite(out_file_matlab, "%d\n", data_out_req);
		end
	end
end

endmodule