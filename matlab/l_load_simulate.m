% Simulate forced oscillations in pure inductive load circuit.
%
%        -->
%        i_L 
% ------- L ------
% |      v_L      |
% EMF             |
% |               |
% ----------------
%
% Params:
% t - vector of time stamps [ms]
% L - capacitance
% EMFm - electromotive force amplitude (max oscillation)
% omega_d - driving angular frequency (omega of the EMF,
%           not to be confused with circuit's natural angular frequency omega)
%
% Piotr Gregor <piotr@dataanadsignal.com>


function [] = l_load_simulate(t, L, EMFm, omega_d)
    global L_
    global EMFm_ 
    global omega_d_
    global phase_
    
    global f_
    global T_
    
    % Init state of the circuit
    n = length(t);
    fprintf("n %d\n", n);
   
    L_ = L;
    EMFm_ = EMFm;           % EMF amplitude
    
    omega_d_ = omega_d;     % driving frequency
    fprintf("driving omega: %f (driving angular frequency of the EMF)\n", omega_d_);
    
    tmax = max(t);
    fprintf("tmax %f\n", tmax);
    
    % The current lags voltage by PI/2 in pure inductive load circuit.
    phase_ = pi / 2;
    fprintf("phase %f\n", phase_);
    
    % Circuits frequency
    f_ = omega_d_ / (2 * pi);
    fprintf("freq %f\n  (circuits freq == EMF freq)\n", f_);
    
    % Period
    T_ = 1 / f_;
    fprintf("period %f\n", T_);
    
    % Potential difference through inductor
    % In pure inductive load we have from the Kirchhoff's loop rule
    % (2nd law) for voltage:
    % v_L = EMF
    v_L = EMFm * sin(omega_d_ * t);
    
    % Current across inductor
    % Faradays law tells us that voltage across inductor can also
    % be written as v_L = L * di_L / dt
    % Thus di_L / dt = EMFm * sin(omega * t) / L
    % Integrating this we get
    % i_L = Int(di_L/dt) = -EMFm * cos(omega * t) / (L * omega)
    i_L = - EMFm * cos(omega_d_ * t) / (L * omega_d_);
    
    % Amplitudes
    fprintf("Amplitudes:\n");
    fprintf("   v_L: %f\n   i_L: %f\n", EMFm, EMFm / (L * omega_d_));
     
    plot_as_one(t, v_L, 'v_L - voltage across inductor', i_L, 'i_L - current through inductor');
    plot_as_sub(t, v_L, 'v_L - voltage across inductor', i_L, 'i_L - current through inductor');
    plot_all(t, v_L, 'v_L - voltage across inductor', i_L, 'current across inductor');
end

function [] = plot_as_one(t, y1, s1, y2, s2)
    figure();
    yyaxis left
    plot(t, y1, 'r');
    yyaxis right
    plot(t, y2, 'b');
    legend(s1, s2);
end

function [] = plot_as_sub(t, y1, s1, y2, s2)
    figure();
    subplot(2,1,1), plot(t, y1,'r');
    legend(s1);
    subplot(2,1,2), plot(t, y2,'g');
    legend(s2);
end

function [] = plot_all(t, y1, s1, y2, s2)
    figure();
    p1 = plot(t, y1, 'r');
    legend(p1, s1);
    figure();
    p2 = plot(t, y2, 'b');
    legend(p2, s2);
end