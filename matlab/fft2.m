

% f_1 - first freq of the DTMF signal in Hz
% f_2 - second freq of the DTMF signal in Hz
% T - length of the signal in ms

function [] = fft2(f_1, f_2, T)

Fs = 8000;              % Sampling frequency in Hz                    
dt = 1/Fs;              % Sampling period in s       
L = T .* Fs/1000;       % Length of signal in samples, T ms of samples
t = (0:L-1) * dt;       % Time vector in s

% Form a signal.
s1 = sin(2*pi*f_1*t);
s2 = sin(2*pi*f_2*t);
S = 0.7 * (s1 + s2);

% Apply FFT.
Y = fft(S);
P2 = abs(Y/L);
P1 = P2(1:L/2+1);
P1(2:end-1) = 2*P1(2:end-1);

f = Fs * (0:(L/2))/L;
plot(f,P1) 
title('Single-Sided Amplitude Spectrum of DTMF S(t)')
xlabel('f (Hz)')
ylabel('|P1(f)|')

text1 = sprintf('%d Hz', f_1);
text2 = sprintf('%d Hz', f_2);
plot_as_sub(t, s1, text1, s2, text2);

end

function [] = plot_as_sub(t, y1, s1, y2, s2)
    figure();
    subplot(2,1,1), plot(t, y1,'g');
    legend(s1);
    subplot(2,1,2), plot(t, y2,'b');
    legend(s2);
end