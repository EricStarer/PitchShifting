function sum = cumDiffSquared(x, W, tau)

%since the function is meant to be running continuously in real time don't
%adjust the size of the window due to the fact matlab stories finite-length
%signals

%TODO: Add error checking for input bounds (i.e. if W+tau is greater than
%size(x)). In the use of our YIN implementation x should be twice the size
%of W.

%TODO: Refactor this to not be a loop and take advantage of Matlab's
%matrix/vector capabilities
sum = 0;
for i = 1:W
   sum = sum + (x(i) - x(i+tau))^2;
end