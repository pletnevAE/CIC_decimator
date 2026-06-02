%================================================================================
%       The script is a designed to generate a multi-segment stimulus signal.
%       The bit depth, sign, and length of stimulus segments can be adjusted
%       using variables.
%
%       Variables:
%           bits - Signal Bit Depth;
%           is_signed - Signal Significance;
%           fs - Sampling Frequency;
%           f_sig - Signal Frequency;
%           A - Amplitude;
%           N_sine - Number of Sine Samples;
%           noise_std - Standart Deviation of Noise;
%           pulse_duty - Pulse Duty Cycle;
%           N_segment(1,3,5,7,9) - Number of samples of the n Hold Cycle;
%           value_segment(1,3,5,7,9) - Hold Cycle Hold Value;
%           OutFile - Path to the Output File.
%
%       Upon completion of the script, a file containing the recorded stimulus
%       samples in decimal nonation will be created at the path specified in
%       the OutFile variable. A graph of the generated stimulus signal will
%       also be displayed.
%================================================================================

clear; clc;

%================================================================================
%% Main Parameters
%================================================================================
bits = 12; % Signal Bit Depth
is_signed = true;   % Signal Significance
fs = 1000; % Sampling Frequency
f_sig = 10; % Signal Frequency
N_sine = 1000; % Number of Sine Samples
A = 0.9; % Amplitude

noise_std = 0.05; % Standart Deviation of Noise

pulse_duty = 0.5; % Pulse Duty Cycle

N_segment1 = 200; % Number of samples of the first Hold Cycle
value_segment1 = 0.3; % First Hold Cycle Hold Value
N_segment3 = 200;  % Number of samples of the second Hold Cycle
value_segment3 = 0; % Second Hold Cycle Hold Value
N_segment5 = 200;  % Number of samples of the third Hold Cycle
value_segment5 = 0; % Third Hold Cycle Hold Value
N_segment7 = 200;  % Number of samples of the fourth Hold Cycle
value_segment7 = 0; % Fourth Hold Cycle Hold Value
N_segment9 = 200;  % Number of samples of the fifth Hold Cycle
value_segment9 = 0; % Fifth Hold Cycle Hold Value

OutFile = 'stimulus.txt'; % Path to the Output File

%================================================================================
%% MAX and MIN value depending on th sign
%================================================================================
if is_signed
    max_code = 2^(bits - 1) - 1;
    min_code = -2^(bits - 1);
else
    max_code = 2^bits - 1;
    min_code = 0;
end

%================================================================================
%% Functions
%================================================================================
quantize_double = @(val_frac) round((is_signed * (val_frac * max_code) + (~is_signed) * (max_code / 2 + val_frac * max_code/2)));
clip = @(x) min(max(x, min_code), max_code);

%================================================================================
%% Sine Wave Segment
%================================================================================
t = (0:N_sine - 1) / fs;
sine_wave = A * sin(2 * pi * f_sig * t);
segment2 = clip(quantize_double(sine_wave));

%================================================================================
%% Noisy Sine Wave Segment
%================================================================================
noise = noise_std * randn(1, N_sine);
sine_noisy = A * sin(2 * pi * f_sig * t) + noise;
segment4 = clip(quantize_double(sine_noisy));

%================================================================================
%% Triangular Wave Segment
%================================================================================
tri_wave = (2/pi) * asin(sin(2 * pi * f_sig * t));
tri_wave = A * tri_wave;
segment6 = clip(quantize_double(tri_wave));

%================================================================================
%% Pulse Segment
%================================================================================
pulse_wave = A * (2 * (mod(t * f_sig, 1) < pulse_duty) - 1);
segment8 = clip(quantize_double(pulse_wave));

%================================================================================
%% Hodl Segments
%================================================================================
segment1 = clip(quantize_double(value_segment1)) * ones(1, N_segment1);
segment3 = clip(quantize_double(value_segment3)) * ones(1, N_segment3);
segment5 = clip(quantize_double(value_segment5)) * ones(1, N_segment5);
segment7 = clip(quantize_double(value_segment7)) * ones(1, N_segment7);
segment9 = clip(quantize_double(value_segment9)) * ones(1, N_segment9);

%================================================================================
%% Stimulus Generation
%================================================================================
stimulus = [segment1, segment2, segment3, segment4, segment5, segment6, segment7, segment8, segment9];
N_total = length(stimulus);

%================================================================================
%% Writing Stimulus to the file
%================================================================================
fid = fopen(OutFile, 'w');
if fid < 0
    error('Failed to open file for writing: %s', OutFile);
end

for k = 1 : N_total
    fprintf(fid, '%d\n', stimulus(k));
end

fclose(fid);

%================================================================================
%% Output Signal graph
%================================================================================
t_in = (0:length(stimulus) - 1) / fs;

figure;
plot(t_in, stimulus, 'LineWidth', 0.8);
xlabel('Time, sec');
ylabel('Code');
title(sprintf('Stimulus Signal (%d bits)', bits));
grid on;
ylim padded;