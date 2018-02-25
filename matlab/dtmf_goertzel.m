function [ret] = dtmf_goertzel(x, N, Fs, want_plot, res2plot)
%DTMF_GOERTZEL Implements Goertzel algorithm for DTMF detection.
%   x - vector of input signal
%   N - number of samples per block of detection
%   Fs - sampling rate
%   want_plot - if 1 then plots of energy estimates from Goertzel
%               Descriptors is created
%   res2plot - results to be plotted, only meaningful if @want_plot
%               is not 0. If @want_plot is not 0 then: if @res2plot is zero
%               then plot full vector of energy estimations, otherwise plot
%               only up to @res2plot samples of result vector. If @want_plot
%               is zero then do not plot, regardless of what @res2plot is.
%   
% author: Piotr Gregor, piotr@dataandsignal.com
% date: February 2018

n = length(x);
if n < N
    fprintf("Err: Block size must be smaller than the number of samples\n")
    return;
end

fN = 8;
freqs = [697.0 770.0 852.0 941.0 1209.0 1336.0 1477.0 1633.0];

res = zeros(n - N, fN);

gD(1, fN) = goertzel_descriptor();
i = 0;
while i < fN 
    gD(i + 1) = goertzel_descriptor(freqs(i + 1), N, Fs);
    i = i + 1;
end

i = 0;
while i < n

    ig = 0;
    while ig < fN 
        acc(gD(ig + 1), x(i + 1));
        
        if i + 1 > N - 1
            res(i + 1 - N + 1, ig + 1) = result(gD(ig + 1));
        end
        
        ig = ig + 1;
    end
    
    i = i + 1;
end

% Charts plotting
if want_plot ~= 0
    figure;
    i = 0;
    dt = 1/8000;
    if res2plot == 0
        res2plot =  size(res,1); % if @resplot is zero, plot full vector
    else
        res2plot = min(size(res,1), res2plot); % plot only up to @res2plot
    end
    x = (N : 1 : N + res2plot - 1) .* dt;
    while i < fN
        sp = subplot(8, 1, i + 1);
        plot(sp, x, res([1:res2plot], [i + 1]));
        t = strcat("Goertzel descriptor for ", num2str(freqs(i + 1)), ". k = ", num2str(gD(i + 1).k));
        strcat(t, " Hz");
        title(sp, t); 
    
        i = i + 1;
    end
    t = strcat("Detection block: ", "\{ samples: ", num2str(N), ", time window: ", num2str(N .* dt .* 1000), " ms \} Result samples displayed: ", num2str(res2plot));
    dim = [0 1 0 0];
    annotation('textbox',dim,'String',t,'FitBoxToText','on');
end

ret = res;
end













