% Low-Pass filter on array of recorded data
% Written by Matt Vernacchia, mvernacc@mit.edu , Dec 2013

function y = lowPass(x, a)
y = zeros(1, length(x));
y(1) = x(1);
for i  = 2:length(x)
    y(i) = a*x(i) + (1-a)*y(i-1);
end