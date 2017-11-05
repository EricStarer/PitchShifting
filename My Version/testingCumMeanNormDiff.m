%[x, Fs, ~] = wavread('claire_oubli_flute.wav');
t = 0:4000; % Time Samples
f = 100; % Input Signal Frequency
Fs = 8000; % Sampling Frequency
phase = pi/6;
x = sin(2*pi*f/Fs*t + phase);% Generate Sine Wave

min_F0 = 50;
L = 2*Fs/min_F0; %frame size, should be twice the window
W = Fs/min_F0;

minLag = 1;
result = ones(1, W);
for lag = 1:W;
    result(lag) = cumMeanNormDiff(x(1:L), W, lag);
    if(result(lag) < result(minLag));
        minLag = lag;
    end
end

plot(result);
F0_est = Fs/minLag;
title(sprintf('MinLag = %d samples, F0 = %.05f Hz', minLag, F0_est));
pause;