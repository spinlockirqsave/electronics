function [amp, freq] = desa1(s,rate)
%DESA2 Summary of this function goes here
%   Detailed explanation goes here

N = length(s);
amp = zeros(1,N);
freq = zeros(1,N);

if N < 5
    return;
end

diff0 = 0.0;  % delayed differences
diff1 = 0.0;
diff2 = 0.0;
diff3 = 0.0;
x1 = 0.0;     % delayed inputs
x2 = 0.0;
x3 = 0.0;
 
num = 0; % numerator
den = 0; % denominator
 
for k = 1: N
    
    a = 0.0;
    f = 0.0;
    
    diff0 = s(k) - x1;
    num = diff2 .* diff2 - diff1 .* diff3 + diff1 .* diff1 - diff0 .* diff2;
    den = x2 .* x2 - x1 .* x3;
    
    if isnan(den) || isinf(den) || den == 0
        den = 0.00001;
    end
    
    if isnan(num) || isinf(num) || num == 0
        num = 0.00001;
    end
    
    div = num ./ den;
    
    if isnan(div) || isinf(div) || div < 0 || div > 8.0
    else
        omega = 2.0 .* asin(sqrt(div ./ (8.0)));
        f = rate .* omega ./ pi;
        if div == 0
        else
            arg = den ./ (1 - ((1 - div./4.0).^2));
            if isnan(arg) || isinf(arg) || arg < 0
            else
                a = sqrt(arg);
            end
        end
    end
    
    diff3 = diff2;
    diff2 = diff1;
    diff1 = diff0;
    x3 = x2;
    x2 = x1;
    x1 = s(k);
    
    freq(k) = f;
    amp(k) = a;
end
    
end
