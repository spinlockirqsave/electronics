% Simulate forced oscillations in pure capacitive load circuit.
%
%        -->
%        i_C 
% -------|| ------
% |      v_C      |
% EMF             |
% |               |
% ----------------
%
% Params:
% t - vector of time stamps [ms]
% C - capacitance
% EMFm - electromotive force amplitude (max oscillation)
% omega_d - driving angular frequency (omega of the EMF,
%           not to be confused with circuit's natural angular frequency omega)
%
% Piotr Gregor <piotr@dataanadsignal.com>


function [] = c_load_simulate(t, C, EMFm, omega_d)
    global C_
    global EMFm_ 
    global omega_d_
    global phase_
    
    global f_
    global T_
    
    % Init state of the circuit
    n = length(t);
    fprintf("n %d\n", n);
   
    C_ = C;
    EMFm_ = EMFm;           % EMF amplitude
    
    omega_d_ = omega_d;     % driving frequency
    fprintf("driving omega: %f (driving angular frequency of the EMF)\n", omega_d_);
    
    tmax = max(t);
    fprintf("tmax %f\n", tmax);
    
    % The current leads voltage by PI/2 in pure capacitive load circuit.
    phase_ = -pi / 2;
    fprintf("phase %f\n", phase_);
    
    % Circuits frequency
    f_ = omega_d_ / (2 * pi);
    fprintf("freq %f\n  (circuits freq == EMF freq)\n", f_);
    
    % Period
    T_ = 1 / f_;
    fprintf("period %f\n", T_);
    
    % Potential difference through capacitor
    % In pure capacitive load we have from the Kirchhoff's loop rule
    % (2nd law) for voltage:
    % EMF = v_C  where v_C is voltage across the capacitor
    v_C = EMFm * sin(omega_d_ * t);
    
    % Charge on capacitor
    q_C = C * v_C;  % same as  q_C = C * EMFm * sin(omega_d_ * t);
    
    % Current across capacitor i = dq/dt
    % i_C = dq/dt = omega_d_ * C * EMFm * cos(omega_d_ * t);
    % which is same as
    i_C = omega_d_ * C * EMFm * sin(omega_d_ * t - phase_);
    
    % Amplitudes
    fprintf("Amplitudes:\n");
    fprintf("   v_C: %f\n   i_C: %f\n", EMFm, EMFm * C * omega_d_);
     
    plot_as_one(t, v_C, 'v_C - voltage across capacitor', i_C, 'i_C - current through capacitor');
    plot_as_sub(t, v_C, 'v_C - voltage across capacitor', i_C, 'i_C - current through capacitor');
    plot_all(t, q_C, 'q_C - electric charge on capacitor', v_C, 'v_C - voltage across capacitor', i_C, 'i_C - current in the circuit');
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

function [] = plot_all(t, y1, s1, y2, s2, y3, s3)
    figure();
    p1 = plot(t, y1, 'r');
    legend(p1, s1);
    figure();
    p2 = plot(t, y2, 'g');
    legend(p2, s2);
    figure();
    p3 = plot(t, y3, 'b');
    legend(p3, s3);
end