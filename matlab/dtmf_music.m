function [Sxxy wy] = dtmf_music(x, p, Fs)
%MUSIC  Implements the MUSIC algorithm of line spectra estimation.
%   x - vector of input signal
%   p - estimated number of independent signal sources in @x
%   Fs - sampling rate
%   
% author: Piotr Gregor, piotr@dataandsignal.com
% date: February 2018

N = length(x);

% 1. Compute correlation matrix
CorrMatrOrd = 2 * p(1);
% x is a vector
x = x(:); % Make it a column
r_x = corrmtx(x, CorrMatrOrd-1, 'cov');

% 2. Compute the eigenvectors and eigenvalues via the SVD
[~,S,eigenvects] = svd(r_x, 0);
eigenvals = diag(S).^2; % We need to square the singular values here

% 3. Separate the signal and noise eigenvectors
p_eff = dtmf_music_determine_signal_space(p, eigenvals);
signal_eigenvects = eigenvects(:,1:p_eff);
noise_eigenvects = eigenvects(:,p_eff+1:end);

% 4. Compute the pseudospectrum
[Sxx,w] = dtmf_music_pseudospectrum(noise_eigenvects, eigenvals, Fs, [], 'half', 0);

% 5. Plot pseudospectrum
narginchk(2,10);
titlestring = 'DTMF Pseudospectrum Estimate via MUSIC';
w = {w};
hps = dspdata.pseudospectrum(Sxx, w{:}, 'SpectrumRange', 'half');
plot(hps);
title(titlestring);
ylabel('Power (dB)');
figure();

% 6. Peak detection
dt = 1 ./ Fs;
t = (0 : dt : (2.*p(1) - 1).*dt);
%f = 689;
f = 1200;
fN = 10;
peaks = zeros(1, fN);
freqs = (f : 1 : f + fN - 1);
i = 0;
while i < fN
    
    f = f + 1;
    omega = 2 .* pi .* f;
    a = exp(j * omega * t);
    peaks(i + 1) = 1 / abs(sum(a * noise_eigenvects));
    
    i = i + 1;
end
plot(freqs, peaks);
legend('peaks');

Sxxy = Sxx;
wy = w;
end

%--------------------------------------------------------------------------------------------
function p_eff = dtmf_music_determine_signal_space(p, eigenvals)
%DETERMINE_SIGNAL_SPACE   Determines the effective dimension of the signal subspace.
%   
%   Inputs:
%
%     p         - (scalar or vector) signal subspace dimension 
%                 (but may contain a desired threshold).
%     eigenvals - (vector) contains the eigenvalues (sorted in decreasing order)
%                 of the correlation matrix
%
%   Outputs:
%
%     p_eff - The effective dimension of the signal subspace. If a threshold
%             is given as p(2), the signal subspace will be equal to the number
%             of eigenvalues, NEIG, greater than the threshold times the smallest
%             eigenvalue. However, the dimension of the signal subspace is at most
%             p(1), so that if NEIG is greater than p(1), p_eff will be equal to
%             p(1). If the threshold criteria results in an empty signal subspace,
%             once again we make p_eff = p(1).


% Use the signal space dimension or the threshold to separate the noise subspace eigenvectors
if length(p) == 2,
   % The threshold will be the input threshold times the smallest eigenvalue
   thresh = p(2)*eigenvals(end); 
   indx = find(eigenvals > thresh);
   if ~isempty(indx)
      p_eff = min( p(1), length(indx) );
   else
      p_eff = p(1);
   end
else
   p_eff = p;
end

end

%---------------------------------------------------------------------------------------------
function [Sxx,w] = dtmf_music_pseudospectrum(noise_eigenvects, eigenvals, nfft, Fs, range, EVFlag)

% compute weights
if EVFlag,
   % Eigenvector method, use eigenvalues as weights
   weights = eigenvals(end-size(noise_eigenvects,2)+1:end); % Use the noise subspace eigenvalues
else
   weights = ones(1,size(noise_eigenvects,2));
end

% Compute the freq. response of each noise subspace eigenfilter via freqz.
% Use freqz to compute the freq vector only when computing the "whole"
% spectrum.
den = 0;
for n = 1:size(noise_eigenvects,2),

   % Don't call freqz with Fs=[], because it will default Fs to 1! Use
   % Fs={}, which gets ignored in varargin.
   if isempty(Fs), sampleRate = {}; else sampleRate{1} = Fs; end 

   % Compute the freq vector directly in Hz to avoid roundoff errors later.
   % Only the "whole" freq vector computed by freqz is valid for spectra.
   [h,w] = freqz(noise_eigenvects(:,n),1,nfft,'whole',sampleRate{:});
   den = den + abs(h).^2./weights(n);
end
s = 1./den; % This is the pseudospectrum

% Calculate the spectrum over the frequency range requested by the user.
[Sxx,w] = dtmf_music_compute_spectrum_range(s, w, range, nfft);
end

%--------------------------------------------------------------------------
function [Sxx,w] = dtmf_music_compute_spectrum_range(Sxx, w, range, nfft)
%Return the correct spectrum range based on the user input argument RANGE.

% Convert input row vectors to columns (if not a matrix).
if any(size(Sxx)==1),   Sxx = Sxx(:); end
w = w(:); 

if strcmpi(range,'half'),
   if rem(nfft,2),   select = 1:(nfft+1)/2;  % ODD
   else              select = 1:nfft/2+1;    % EVEN
   end
   Sxx = Sxx(select,:); % Take only [0,pi] or [0,pi)
   w = w(select);
end
end

