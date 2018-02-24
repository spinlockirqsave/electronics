% f_1 - freq of the signal in Hz
% f_2 - filter freq in Hz
% band - filter bandwidth in Hz
% T - length of the signal in ms

function [] = filter1(f_1, f_2, band, T)

Fs = 8000;              % Sampling frequency in Hz                    
dt = 1/Fs;              % Sampling period in s       
L = T .* Fs/1000;       % Length of signal in samples, T ms of samples
t = (0:L-1) * dt;       % Time vector in s

% Form a signal.
s1 = sin(2*pi*f_1*t);
fir = sin(2*pi*f_2*t);

% Apply FFT.
Y = fft(s1);
P2 = abs(Y/L);
P1 = P2(1:L/2+1);
P1(2:end-1) = 2*P1(2:end-1);

f = Fs * (0:(L/2))/L;
plot(f,P1) 
title('Single-Sided Amplitude Spectrum of S(t)')
xlabel('f (Hz)')
ylabel('|P1(f)|')
figure();

b = fir1(68,[(f_2-band)/(Fs/2) (f_2+band)/(Fs/2)], chebwin(35,30));
freqz(b,1,512);
figure();

Y = fft(s1);
P2 = abs(Y/L);
P1 = P2(1:L/2+1);
P1(2:end-1) = 2*P1(2:end-1);

f = Fs * (0:(L/2))/L;
plot(f,P1) 
title('Single-Sided Amplitude Spectrum of S(t)*fir')
xlabel('f (Hz)')
ylabel('|P1(f)|')

out = filter(b,1,s1);

figure();
subplot(2,1,1)
plot(t,s1)
title('Original Signal')

subplot(2,1,2)
plot(t,out)
title('Filtered Signal')
xlabel('Time (s)')
figure();

Y = fft(out);
P2 = abs(Y/L);
P1 = P2(1:L/2+1);
P1(2:end-1) = 2*P1(2:end-1);

f = Fs * (0:(L/2))/L;
plot(f,P1) 
title('Single-Sided Amplitude Spectrum of S(t) filtered')
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