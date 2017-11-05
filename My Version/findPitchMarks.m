function pitch_marks = findPitchMarks(x, pitch_period, W)
%x is the signal to be analyzed (in row vector form) and pitch_period is the period of the 
%dominant pitch in the middle subframe in samples (x should contain 3
%subframes of equal length the size (in samples) of the largest
%pitch_period detectable by the calling funcion). W is the size of the
%subframes.

%1st subframe: samples 1 to W
%2nd subframe: samples W+1 to 2W
%3rd subframe: samples 2W+1 to 3W

%step 1 - find the max value in the signal and get its index (this assumes it occurs on a pulse)

[~, max_index] = max(x(W+1:2*W));
max_index = max_index + W;

% plot(x);
% hold on;
% plot(max_index ,x(max_index), 'o', 'MarkerSize', 10, 'Color', 'k');
% line([size(x,2)/3 size(x,2)/3],[min(x) max(x)], 'Color', 'k');
% line([size(x,2)*2/3 size(x,2)*2/3],[min(x) max(x)], 'Color', 'k');
% title('findPitchMarks debugging, black = max index found first (yellow = 2nd guess), green = subsequent found pitch marks');

%in the rare case that the max was at the edge of a frame, search around
%those edges to make sure that a cycle didn't cross a frame and was
%incorrectly identified
%TODO: more rigorously verify this part and analyze from a
%frequency/period standpoint
if(max_index == W + 1 || max_index == 2*W)
    guess_offset = round(.5*pitch_period);
    [~, secondGuess] = max(x(max_index-guess_offset : max_index+guess_offset));
    
    secondGuess = secondGuess + max_index - guess_offset - 1;
    if(secondGuess > 2*W)
        [~, max_index] = max(x(W+1:2*W-guess_offset));
        max_index = max_index + W;
%         plot(max_index ,x(max_index), 'o', 'MarkerSize', 10, 'Color', 'y');
%         pause;
    elseif(secondGuess < W + 1)
        [~, max_index] = max(x(W+1+guess_offset:2*W));
        max_index = max_index + W + guess_offset - 1;
%         plot(max_index ,x(max_index), 'o', 'MarkerSize', 10, 'Color', 'y');
%         pause;
    end
end
       
%step 2 - place other pitch marks to the right of the max based on the
%pitch_period, searching for the max within a certain range around the
%initial placement incase there are errors

%the number 50 below was chosen randomly, it could theoretically correspond
%to the maximum frequency representable by the sampling frequency
upper_pitch_marks = zeros(1, 50);
lower_pitch_marks = zeros(1, 50);

upper_pitch_marks(1) = max_index;
lower_pitch_marks(1) = max_index;

%define the size of the search radius around the estimate, r = [.5, .9]
r = .8;

%search the values to the right of the initial max_index
i = 1;
while(true)
    lower_bound = round(upper_pitch_marks(i) + r*pitch_period);
    upper_bound = round(upper_pitch_marks(i) + (2-r)*pitch_period);
  
    %search around the new estimate in case it didn't align correctly
    [~, offset] = max(x(lower_bound:upper_bound));
    %check to see whether the pitchmark belongs to the current subframe or
    %the next one
    if(lower_bound + offset - 1 > 2*W)
        %in this case the pitch mark belongs to the next subframe and will
        %be found in the next iteration
        break;
    else
        upper_pitch_marks(i+1) = lower_bound + offset - 1;
        i = i + 1;
%         plot(upper_pitch_marks(i) ,x(upper_pitch_marks(i)), 'o', 'MarkerSize', 10, 'Color', 'c');
    end
end

%search the values to the left of the initial estimate
i = 1;
while(true)
    lower_bound = round(lower_pitch_marks(i) - (2-r)*pitch_period);
    upper_bound = round(lower_pitch_marks(i) - r*pitch_period);

    %search around the new estimate in case it didn't align correctly
    [~, offset] = max(x(lower_bound:upper_bound));
    %check to see if the pitch mark belongs to the previous subframe (in
    %which case it would have already been found)
    if(lower_bound + offset - 1 < W + 1)
        break;
    else
        lower_pitch_marks(i+1) = lower_bound + offset - 1;
        i = i + 1;
%         plot(lower_pitch_marks(i) ,x(lower_pitch_marks(i)), 'o', 'MarkerSize', 10, 'Color', 'c');
    end
end

% hold off;

%sort and remove duplicates
pitch_marks = unique([lower_pitch_marks, upper_pitch_marks]);

%remove zero index
pitch_marks = pitch_marks(2:size(pitch_marks,2));
% pause;
