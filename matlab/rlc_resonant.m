% Find the capacitance value resulting in the circuit natural frequency
% being equal to driving (forced) frequency
%
% Params:
% C_min - capacitance left bounday
% C_max - capacitance right boundary
% f_d - forced frequency of the EMF (driving frequency in Hz)
%
% Details:
% Function is using
% Piotr Gregor <piotr@dataanadsignal.com>

function [ret] = rlc_resonant(f_d, C_min, C_max)
global L_
global C_

global N_  % number of x elements in vector passed to Newton-Raphson method

L_ = 0.02;
C_ = 0.000002;
N_ = 1000;


if (C_min >= C_max)
    fprintf("Err, capacitance is not a range: C_min == C_max == %f\n", C_min);
    ret = 0.0;
end

% Init
dx = (C_max - C_min) / N_; 
x = C_min : dx : C_max;

% Circuit's is in resonance if forced frequency f_d equals natural circuit's
% frequency f = 1/(2*pi*sqrt(LC))
y = 1 ./ (2 * pi * sqrt(L_ * x)) - f_d;
x_min = C_min;
x_max = C_max;
y_prim = -1 ./ (4 * pi * sqrt(x .* x .* x));
y_prim_prim = 3 ./ (8 .* pi .* x .* x .* sqrt(x));

ret = newton_raphson(x, y, x_min , x_max, y_prim, y_prim_prim);

end

function [ret] = newton_raphson(x, y, x_min , x_max, y_prim, y_prim_prim)
global N_

x_n = length(x);
y_n = length(y);
y_prim_n = length(y_prim);
y_prim_prim_n = length(y_prim_prim);

if (x_n == 0 || y_n == 0 || y_prim_n == 0 || y_prim_prim_n == 0)
    fprintf("Err, vector size is 0\n");
    ret = 0.0;
end

if (x_min >= x_max || x_n < 1)
    fprintf("Err, x argument is not a range: x_min == x_max == %f\n", x_min);
    ret = 0.0;
end

if (~(x_n == y_n)  || (x_n ~= y_prim_n) || (x_n ~= y_prim_prim_n))
    fprintf("Err, bad vector sizes\n");
    ret = 0.0;
end

if (y(1) == 0)
    ret = x(1);
end

if (y(y_n) == 0)
    ret = x(x_n);
end

% Check mandatory conditions
if (y(1) * y(y_n) > 0)
    fprintf("Err, bad init condition: y boundaries are same in sign\n");
    ret = 0.0;
end

ret = 13.0;
end