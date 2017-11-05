t = .500;%time in seconds, make sure this number results in n being an even number
W = 75;%frame size in samples (choose a size such that an integer number of cycles isn't in the frame to make the waveform chunk different for consecutive frames)
fs = 8000;
n = 0:1:t*fs-1;
F0 = 400;
x = sin(2*pi*F0/fs*n);

harmonic_amplitudes = [.3 .4 .12 .6];
for i = 1:size(harmonic_amplitudes, 2)
    x = x + harmonic_amplitudes(i)*sin(2*pi*i*F0/fs*n);
end

%normalize the signal
x = x/max(x);

%apply a linear amplitude envelope
max_amp = 1;
min_amp = .75;
amplitude_envelope = [linspace(min_amp, max_amp, size(x,2)/2), linspace(max_amp, min_amp, size(x,2)/2)];

x = x .* amplitude_envelope;

pitch_period = fs/F0;
num_frames = floor(size(x,2)/W);
for i = 1:num_frames - 2 %skip the last couple frames in case there's a remainder cause i'm too lazy to code for it atm
    %search over three consecutive frames to find pitch marks (we're really
    %only finding the pitch marks in the middle subframe)
    lower_bound_test = (i-1)*W + 1;
    upper_bound_test = (2+i)*W;
    if i ~= 1
        previous_pitch_marks = pitch_marks - W;
    end
    pitch_marks = findPitchMarks(x(lower_bound_test:upper_bound_test), pitch_period, W);
    plot(x(lower_bound_test:upper_bound_test));
    title('testingPitchMarks output - red = pitchMarks found this iteration, green = pitch marks from last iteration');
    hold on;
    line([size(x(lower_bound_test:upper_bound_test),2)/3 size(x(lower_bound_test:upper_bound_test),2)/3],[min(x(lower_bound_test:upper_bound_test)) max(x(lower_bound_test:upper_bound_test))], 'Color', 'k');
    line([size(x(lower_bound_test:upper_bound_test),2)*2/3 size(x(lower_bound_test:upper_bound_test),2)*2/3],[min(x(lower_bound_test:upper_bound_test)) max(x(lower_bound_test:upper_bound_test))], 'Color', 'k');
    for j = 1:size(pitch_marks, 2)
        plot(pitch_marks(j), x((pitch_marks(j)) + lower_bound_test - 1), 'o', 'MarkerSize', 10, 'Color', 'r');
    end
    if i ~= 1
       for j = 1:size(previous_pitch_marks,2)
            plot(previous_pitch_marks(j), x(previous_pitch_marks(j) + lower_bound_test - 1), 'o', 'MarkerSize', 10, 'Color', 'g');
       end
    end
    
    hold off;
    pause;
end