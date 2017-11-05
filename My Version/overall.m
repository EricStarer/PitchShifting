%overall script
%[x, Fs, ~] = wavread('A string.wav');
%[x, Fs, ~] = wavread('Bend.wav');
[x, Fs, ~] = wavread('C major scale.wav');
r = 12;
x = decimate(x, r);
x = x';
Fs = Fs/r;
%normalize the signal with respect to the largest postivie or negative
%value
x = x / max(abs(min(x)), abs(max(x)));
% t = 0:4000-1; % Time Samples
% f = 100; % Input Signal Frequency
% Fs = 8000; % Sampling Frequency
% phase = pi/6;
% x = sin(2*pi*f/Fs*t + phase);% Generate Sine Wave
% x = x';

%minimum fundamental frequency detectable by the algorithm
min_F0 = 50;
%size of the analyis frame to be used (two consecutive frames will be used for estimating F0)
W = ceil(Fs/min_F0);
frames = floor(size(x,1)/W);
%threshold for determining when to accept a new value for the minimum lag
differenceThresh = .1;
%threshold for determining F0 without needing to fully examine all the data
%(computations could be saved by stopping function evaluation in implementation)
absoluteThresh = .1;
%threshold for NRG levels used to determine whether to count a frame as
%silence or not (perhaps analyze this part more and develop a model for the
%input signal and it's characteristics)
silenceThresh = .11;

%initialize variables that will be changed every frame
pitchPeriod = round(Fs/200); %200 Hz was selected somewhat arbitarily to try and make it so there would be 4 pitch marks in a frame
pitchMarks = 0;
previousPitchMarks = 0;
numPrevSynthMarks = 0;
synthesisMarks = zeros(1,20);%it's more efficient to allocate a bunch of space than have the size change dynamically
                             %there might also be heurisitcs or more
                             %calculated ways of figuring out the max size
                             %based on shift size limitations
overlapSynthMark = 1;

B = 1.25; %shift amount, keep it at 1 to make things simple at the moment                             
                             
prevPitchPeriod = -69;
subframe_NRG = -69;

%set up buffer to hold NRG values 
NRG_plot_data = zeros(1, frames - 2);%see loop below for -2 explanation

%set up buffer to hold modified signal
x_processed = zeros(1, size(x,1));

for i = 1:frames - 2 %avoid the last two frames to deal with the remainder problem
    %choose indexes such that the section of x inspected is length 2*W
    first = (i-1)*W + 1;
    middle1 = i*W;
    middle2 = (1+i)*W;
    last = (2+i)*W;
    
    %step 0. check to see if the frame is silence or not (no point in
    %running YIN algorithm on a un-pitched segment)
    last_NRG = subframe_NRG;
    subframe_NRG = calcSignalNRG(x(middle1+1:middle2));
    
    if subframe_NRG < silenceThresh
        isSilence = 'true';
    else
        isSilence = 'false';
    end
    
    %search for the fundamental frequency if the frame isn't declared as
    %silence
    if strcmp(isSilence,'false')
        %search for tau that maximizes the function over the half the frame
        minLag = 1;
        firstEstimate = 0;
        result = ones(1,W); %result needs to be large enough that the < check in the following 
                            %for loop passes the first time (or add an if statement there depending
                            %on what numbers can be represented on the system of implementation)

        %step 1. find the fundamental frequency/pitch period of the current frame                    
        for lag = 1:W
            %cumMeanNormDiff should be given at least 2*W worth of data
            %by starting at middle1 we're ignoring the first W worth of data
            %points but since the system is designed to run in real time it
            %will just require a brief setup period
            result(lag) = cumMeanNormDiff(x(middle1+1:last), W, lag);
            if(firstEstimate == 0 && result(lag) < absoluteThresh)
                firstEstimate = lag;
            end
            if(result(minLag) - result(lag) > differenceThresh)
                minLag = lag;
            end
        end
        
        %update the previous pitch period
        prevPitchPeriod = pitchPeriod;

        %determine the pitch period for the frame
        pitchPeriod = minLag;
        %in the case where one of the higher-order dips was lower than the period dip
        %make sure to use the period dip (which should have been found
        %first)
        if(firstEstimate ~= 0 && firstEstimate < minLag)
            pitchPeriod = firstEstimate;
        end
    else
        %set the pitch period to what was determined in the previous frame
        %this entails doing nothing and keeping it at the same value but
        %the variables that keep track of previous values need to be
        %updated (consider case where silence is detected after a voiced
        %frame)
        prevPitchPeriod = pitchPeriod;
    end

    %adjust the previous pitch marks for record keeping and graphing
    previousPitchMarks = pitchMarks - W; 
    
    subplot(2,1,1);
    %plot the cumulative mean normalized difference function
%     plot(result);
%     title(sprintf('Frame = %d/%d, MinLag = %d samples, Min F0 = %.05f Hz, First = %d, First F0 = %.05f', i, frames-2, minLag, F0_est, firstEstimate, F0_first));

    %plot the signal energy for each frame to try and establish a pattern
    NRG_plot_data(i) = subframe_NRG;
    plot(NRG_plot_data);
    title(sprintf('Frame NRGs - Current Frame %d/%d - LPP = %d, TPP = %d, LF0est = %.05f, TF0est = %.05f', i, frames, prevPitchPeriod, pitchPeriod, Fs/prevPitchPeriod, Fs/pitchPeriod));
    
    %step 2. find the pitch marks for the current frame based on the pitch
    %period estimate
    subplot(2,1,2);
    pitchMarks = findPitchMarks(x(first:last)', pitchPeriod, W);
    
    %step 3. calculate the synthesis pitch marks
    
    %store the last subframe's making sure to trim and remove 0's
    if i ~= 1
        previousSynthMarks = unique(synthesisMarks(1:synthMarkIndex) - W);
        %previousSynthMarks = previousSynthMarks(2:size(previousSynthMarks,2))
    end

    %initialize the first synthesis pitch mark as the first pitch mark
    %in general (it's gotta be initialzied somehow, think more about
    %the best way to do this somehow)
    if i == 1
        overlapSynthMark = pitchMarks(1);
    end
    
    if B == 1
        %zero pad the vector to keep it at it's original size
        synthesisMarks = [pitchMarks zeros(1, 20-size(pitchMarks, 2))];
        synthMarkIndex = size(pitchMarks, 2);
    else
        synthMarkIndex = 1; %refers to the index in the array holding the synthesized pitch marks
        synthesisMarks(synthMarkIndex) = overlapSynthMark;
        while true
            %TODO: use the closest pitch mark to calculate the "true pitch
            %period" and see how using that value affects the end result as
            %opposed to using the pitch period for the frame
            if synthMarkIndex == 1
                searchMarks = [previousPitchMarks(end) pitchMarks];
            else
                searchMarks = pitchMarks;
            end

            closest = findClosestPitchMark(synthesisMarks(synthMarkIndex), searchMarks);
            %TODO: calculate the difference between the next pitch mark and the
            %closest to find the true period
            %truePitchPeriod = ;

            %refers to the index in the overall subframe
            nextSynthMark = synthesisMarks(synthMarkIndex) + pitchPeriod/B;
            %if the next synthesis mark lies out of the frame then we're
            %done with this frame and figure out how far into the next one
            %it is
            if nextSynthMark > 2*W 
                overlapSynthMark = nextSynthMark - W;
                break;
            else
                synthMarkIndex = synthMarkIndex + 1;
                synthesisMarks(synthMarkIndex) = nextSynthMark;
            end
        end
    end
    
    %last step: make a bunch of fancy graphs to impress other people
    %plot the window of the signal
    plot(x(first:last));
    hold on;
    %add the pitch marks to the signal plot
    for j = 1:size(pitchMarks, 2)
        plot(pitchMarks(j), x((pitchMarks(j)) + first - 1), 'o', 'MarkerSize', 10, 'Color', 'r');
    end
    if i ~= 1 
        for j = 1:size(previousPitchMarks,2)
            plot(previousPitchMarks(j), x(previousPitchMarks(j) + first - 1), 'o', 'MarkerSize', 10, 'Color', 'g');
        end 
    end
    
    %print synthesis marks
    for j = 1:synthMarkIndex
        %plot them on the bottom for now, devise a good way to display the
        %information
        plot(synthesisMarks(j), -1, '+', 'MarkerSize', 10, 'Color', 'r');
    end
    %display previous synthesis marks
    if i ~= 1
        for j = 1:size(previousSynthMarks,2)
            plot(previousSynthMarks(j), -1, '+', 'MarkerSize', 10, 'Color', 'g');
        end
    end
    %create line to show division between the windows, the lines occur on
    %the last sample of a subframe(i.e. 74 and 148 if W = 74)
%     title(sprintf('Last PP = %d, Last F0est = %.05f, Last F0first = %.05f, NRG = %.05f, last NRG = %.05f', prevPitchPeriod, last_F0_est, last_F0_first, subframe_NRG, last_NRG));
    title(sprintf('NRG = %.05f, last NRG = %.05f, Silence = %s', subframe_NRG, last_NRG, isSilence));
    axis([1 3*W -1 1]);
%     line([size(x(first:last),1)/3 size(x(first:last),1)/3],[min(x(first:last)) max(x(first:last))], 'Color', 'k');
%     line([size(x(first:last),1)*2/3 size(x(first:last),1)*2/3],[min(x(first:last)) max(x(first:last))], 'Color', 'k');
    line([size(x(first:last),1)/3 size(x(first:last),1)/3],[-1 1], 'Color', 'k');
    line([size(x(first:last),1)*2/3 size(x(first:last),1)*2/3],[-1 1], 'Color', 'k');
    hold off;
    pause;
end
