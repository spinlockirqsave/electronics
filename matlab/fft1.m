% f_0 - fundamental freq of the signal in Hz
% T - length of the signal in ms

function [] = fft1(f_0, T)

Fs = 8000;              % Sampling frequency                    
dt = 1/Fs;              % Sampling period       
L = T .* 8;             % Length of signal, T ms of samples
t = (0:L-1) * dt;       % Time vector

% Form a signal.
S = 0.7 * sin(2*pi*f_0*t);

% Apply FFT.
Y = fft(S);
P2 = abs(Y/L);
P1 = P2(1:L/2+1);
P1(2:end-1) = 2*P1(2:end-1);

f = Fs * (0:(L/2))/L;
plot(f,P1) 
title('Single-Sided Amplitude Spectrum of S(t)')
xlabel('f (Hz)')
ylabel('|P1(f)|')

end

function [] = plot_as_sub(t, y1, s1, y2, s2)
    figure();
    subplot(2,1,1), plot(t, y1,'g');
    legend(s1);
    subplot(2,1,2), plot(t, y2,'b');
    legend(s2);
end

