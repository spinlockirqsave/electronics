function [] = myplot2()
%UNTITLED3 Summary of this function goes here
%   Detailed explanation goes here
x = 1:0.1:3*pi;
s = sin(x);
c = cos(x);
plot(x,s,'r-o',x,c,'b-x');
legend('sin(x)','cos(x)');
end

