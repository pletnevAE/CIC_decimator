%================================================================================
% This script compares a filter implemented in Verilog with a filter generated 
% using MATLAB Filter Designer, Simulink, and HDL Coder.
%
% The script will display graphs of the frequency response, filter output 
% signals, and absolute error.
%
% Files containing filter output samples must be located in the same directory 
% as the script (or the values ​​of the variables rtl_output_file and 
% matlab_output_file can be changed).
%================================================================================

clc; clear;

%================================================================================
%% Main Parameters
%================================================================================
IN_WIDTH = 12; % Input Bit Depth
OUT_WIDTH = 16; % Output Bit Depth
N = 3; % Filter Order (number of integrators and combs)
M = 1; % Differential Delay
R = 4; % Decimation Coefficient

rtl_output_file = 'output_rtl.txt'; % RTL output file name
matlab_output_file = 'output_matlab.txt'; % Simulink output file name

%================================================================================
%% Frequency response
%================================================================================
Fs_in = 1e6;
NFFT = 2048;
f_norm = linspace(0, 0.5, NFFT/2 + 1);
H_mag = abs((1 - exp(-1j * 2 * pi * f_norm * R * M)) ./ (1 - exp(-1j * 2 * pi * f_norm) + 1e-300)) .^N;
H_mag_dB = 20 * log10(H_mag / max(H_mag) + 1e-300);

%================================================================================
%% Reading RTL output samples
%================================================================================
fid = fopen(rtl_output_file, 'r');
if fid == -1
    error('Failed to open file: %s', rtl_output_file);
end
rtl_out = fscanf(fid, '%d');
fclose(fid);
rtl_out = rtl_out(:).';

%================================================================================
%% Reading Simulink output samples
%================================================================================
fid = fopen(matlab_output_file, 'r');
if fid == -1
    error('Failed to open file: %s', matlab_output_file);
end
matlab_out = fscanf(fid, '%d');
fclose(fid);
matlab_out = matlab_out(:).';

%================================================================================
%% Determining the length of signals for comparison 
% (For the simullink, the samples are taken starting from the second one, 
% since the model issues an enable signal on the first clock cycle after reset.)
%================================================================================
L_m = length(matlab_out);
L_r = length(rtl_out);
compare_len = min(L_m, L_r);

m_ref = matlab_out(2:compare_len + 1);
r_ref = rtl_out(1:compare_len);

%================================================================================
%% Calculating the absolute error
%================================================================================
diff = abs(double(r_ref) - double(m_ref));
max_abs_diff = max(diff);

%================================================================================
%% Graphs
%================================================================================
fprintf('\n---Comparison result---\n');
fprintf('Maximum absolute difference: %d\n', max_abs_diff);

figure;
subplot(3, 1, 1);
plot(f_norm * Fs_in / 1e3, H_mag_dB, 'b', 'LineWidth', 1.5);
xlabel('Frequency (kHz)');
ylabel('Frequency response (dB)');
title(sprintf('Frequency response CIC (R = %d, M = %d, N = %d)', R, M, N));
xlim([0, Fs_in/2/1e3]);
ylim([-120, 5]);
grid on;
xline(Fs_in/R/2/1e3, 'r--', 'f_{Nyq,out}', 'LabelVerticalAlignment','bottom');

subplot(3, 1, 2);
plot(0:compare_len - 1, m_ref, 'b-', 'LineWidth', 1.2);
hold on;
plot(0:compare_len - 1, r_ref, 'r--', 'LineWidth', 1.2);
xlabel('Output sample number');
ylabel('Code');
legend('MATLAB reference', 'Verilog RTL');
title('Comparison of CIC output signals');
grid on;

subplot(3, 1, 3);
plot(0:compare_len - 1, diff, 'Marker', 'none');
xlabel('Output sample number');
ylabel('Difference (RTL - MATLAB)');
title('Absolute difference');
grid on;