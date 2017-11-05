%[x, Fs, ~] = wavread('claire_oubli_flute.wav');
t = 0:4000; % Time Samples
f = 100; % Input Signal Frequency
Fs = 8000; % Sampling Frequency
phase = pi/6;
x = sin(2*pi*f/Fs*t + phase);% Generate Sine Wave

min_F0 = 50;
L = 2*Fs/min_F0; %frame size, should be twice the window
W = Fs/min_F0;

maxLag = 0;
maxLagValue = 0;
result = zeros(1, W);
for lag = 1:W;
    result(lag) = cumDiffSquared(x(1:L), W, lag);
    if(result(lag) > maxLagValue)
        maxLagValue = result;
        maxLag = lag;
    end
end

plot(result);