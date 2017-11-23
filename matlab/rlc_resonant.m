% Find the capacitance value resulting in the circuit natural frequency
% being equal to driving (forced) frequency.
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

global N_  % max number of iterations performed in Newton-Raphson method

L_ = 0.02;
N_ = 1000;
epsilon = 0.000001;   % accuracy of root searching in Newton-Raphson

if ((C_min == 0) || (C_max == 0))
    fprintf("Err, capacitance cannot be 0 in 'proper' RLC circuit.");
    fprintf(" Please change the range\n");
    ret = NaN;
    return;
end

if (C_min >= C_max)
    fprintf("Err, capacitance is not a range: C_min == C_max == %f\n", C_min);
    ret = NaN;
    return;
end

% Init
dx = (C_max - C_min) / N_; 
x = C_min : dx : C_max;

% Circuit's is in resonance if forced frequency f_d equals natural circuit's
% frequency f = 1/(2*pi*sqrt(LC))
y = @(x) 1.0 ./ (2.0 .* pi * sqrt(L_ .* x)) - f_d;
x_min = C_min;
x_max = C_max;
y_prim = @(x) -1.0 ./ (4.0 * pi * sqrt(L_ .* x .* x .* x));
y_prim_prim = @(x) 3.0 ./ (8.0 .* pi .* x .* x .* sqrt(L_ .* x));

ret = newton_raphson(x, y, x_min , x_max, y_prim, y_prim_prim, N_, epsilon);

end

function [ret] = newton_raphson(x, y, x_min , x_max, y_prim, y_prim_prim, N, epsilon)
global N_

if (y(x_min) == 0)
    ret = x_min;
    return;
end

if (y(x_max) == 0)
    ret = x_max;
    return;
end

if (x_min > x_max)
    fprintf("Err, x argument is not a range: x_min == x_max == %f\n", x_min);
    ret = NaN;
    return;
end

% Check mandatory conditions
if (y(x_min) * y(x_max) > 0)
    fprintf("Err, bad init condition: y boundaries are same in sign\n");
    fprintf("Please consider increasing range or shifting it.\n");
    ret = NaN;
    return;
end

% Choose starting point
x = x_min;
if (y(x_max) * y_prim_prim(x_max) > 0)
    x = x_max;
end

% Iterative computation
i = 1;
x_vec = 1 : 1 : 1000;
y_vec = 1 : 1 : 1000;
x_vec(1) = x;
y_vec(1) = y(x);
while ((i < N) && (abs(y(x)) > epsilon))
    x_vec(i + 1) = x;
    y_vec(i + 1) = y(x);
    x = x - y(x) / y_prim(x);
    i = i + 1;
end

if ((i > 1) && (i < N))
    x_vec(i + 1) = x;
    y_vec(i + 1) = y(x);
    i = i + 1;
end

if (i < N)
    x_vec = x_vec(1 : i);
    y_vec = y_vec(1 : i);
end

sz = linspace(100, 1, i);
color = linspace(1, 10, i);
scatter(x_vec, y_vec, sz, color, 'filled');
xlabel("Capacitnace [F]");
ylabel("Frequency [Hz]");
legend({['f - f_d : diff between' char(10) 'circuits frequency' char(10) 'at the given capacitance' char(10) 'and the driving EMF''s freq']});

ret = x;

end