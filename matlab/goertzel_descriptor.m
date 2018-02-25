% author: Piotr Gregor, piotr@dataandsignal.com
% date: February 2018

classdef goertzel_descriptor < handle
   properties
      f    % (in) frequency this descriptor will search for
      Fs   % (in) sampling rate
      N    % (in) number of samples per detection block
      s0   % present value of the estimator: s(n))
      s1   % previous value of the estimator: s(n - 1)
      k    % assigned index based on sampling rate @Fs and the block size @N
      fac  % 2cos(2*pi*k/N)
      W    % exp(-2*pi*j*k/N)
   end
   methods
       function obj = goertzel_descriptor(f, N, Fs)
           % f  frequency this descriptor will search for
           % Fs sampling rate
           % N  number of samples per detection block
           obj.s0 = 0;
           obj.s1 = 0;
           
           if nargin > 0    % nargin == 0 allows for "default" "constructor"
                            % to be used for "array initialization"
               obj.f = f;
               obj.N = N;
               obj.Fs = Fs;
           
               % assign the k to descriptor based on the number of samples and sampling rate
               obj.k = round((f ./ Fs) .* N);
           
                % assign constants used throughout computations
               obj.fac = 2 .* cos(2 .* pi .* obj.k ./ N);
               obj.W = exp(-2 .* pi .* j .* obj.k ./N);
           else
               obj.f = 0; obj.N = 0; obj.Fs = 0; obj.k = 0; obj.fac = 0; obj.W = 0;
           end
       end
       
       % Accumulate new sample x(n):
       % s(n) = x(n) + 2cos(2*pi*k/N) * s(n - 1) - s(n - 2);
       function [sn] = acc(obj, xn)
           sv2 = obj.s1;
           obj.s1 = obj.s0;
           obj.s0 = xn + obj.fac .* obj.s1 -sv2;
           sn = obj.s0;
       end
       
       % Return result energy estimation at time n:
       % y(n) * conj(y(n))
       % where
       % y(n) = s(n) - W * s(n - 1);
       function [res] = result(obj)
           y = obj.s0 -obj.W .* obj.s1;
           % same as res = (abs(obj.s0 -obj.W .* obj.s1))^2;
           res = y .* conj(y);
           % For real signals this is the same:
           % res = obj.s0 .* obj.s0 + obj.s1 .* obj.s1 - obj.fac .* obj.s0 .* obj.s1;
       end
   end
end









