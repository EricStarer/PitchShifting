function closest = findClosestPitchMark(pitchMark, pitchMarks)
%returns the index of the closest pitch mark in the vector pitchMarks to
%the pitch mark specified in pitchMark, think of a better way to name the
%variables so it's less confusing for other people

distances = abs(pitchMarks - pitchMark);
[~, closest] = min(distances);
