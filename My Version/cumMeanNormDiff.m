function result = cumMeanNormDiff(x, W, tau)

if(tau == 1)
    result = 1;
else
   sum = 0;
   for lag = 1:tau
       sum = sum + cumDiffSquared(x, W, lag);
   end
   sum = sum / tau;
   result = cumDiffSquared(x, W, tau) / sum;
end