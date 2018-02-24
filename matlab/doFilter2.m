function y = doFilter2(x)
%DOFILTER Filters input x and returns output y.

% MATLAB Code
% Generated by MATLAB(R) 9.3 and DSP System Toolbox 9.5.
% Generated on: 18-Feb-2018 22:49:17

persistent Hd;

if isempty(Hd)
    
    Fstop1 = 0.27725;  % First Stopband Frequency
    Fpass1 = 0.28975;  % First Passband Frequency
    Fpass2 = 0.31475;  % Second Passband Frequency
    Fstop2 = 0.32725;  % Second Stopband Frequency
    Astop1 = 60;       % First Stopband Attenuation (dB)
    Apass  = 0.5;      % Passband Ripple (dB)
    Astop2 = 60;       % Second Stopband Attenuation (dB)
    
    h = fdesign.bandpass('fst1,fp1,fp2,fst2,ast1,ap,ast2', Fstop1, Fpass1, ...
        Fpass2, Fstop2, Astop1, Apass, Astop2);
    
    Hd = design(h, 'equiripple', ...
        'MinOrder', 'any');
    
    
    
    set(Hd,'PersistentMemory',true);
    
end

y = filter(Hd,x);

