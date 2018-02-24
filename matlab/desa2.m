function [amp, freq] = desa2(s)
%DESA2 Summary of this function goes here
%   Detailed explanation goes here

N = length(s);
amp = zeros(N);
freq = zeros(N);

if N < 5
    return;
end

for k = 3 : N - 2
    x0 = s(k-2);
    x1 = s(k-1);
    x2 = s(k);
    x3 = s(k+1);
    x4 = s(k+2);
    
    x2sq = x2 * x2;
    d = 2.0 .* ((x2sq) - (x1 .* x3));
    if d == 0.0
        a = 0.0;
        f = 0.0;
    end
    
    PSI_Xn = ((x2sq) - (x0 * x4));
    NEEDED = ((x1 * x1) - (x0 * x2)) + ((x3 * x3) - (x2 * x4));
    n = ((x2sq) - (x0 * x4)) - NEEDED;
    PSI_Yn = NEEDED + PSI_Xn;
    
    f = 0.5 * acos(n/d);
    a = 2.0 * PSI_Xn / sqrt(PSI_Yn);
    
    freq(k+2) = f;
    amp(k+2) = a;
end
    

end

