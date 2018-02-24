% Simulate forced oscillations in pure resistive load circuit.
%
%       -->
%       i_R 
% ------/\/\-----
% |     v_R      |
% EMF            |
% |              |
% ---------------
%
% Params:
% t - vector of time stamps [ms]
% R - resistance
% EMFm - electromotive force amplitude (max oscillation)
% omega_d - driving angular frequency (omega of the EMF,
%           not to be confused with circuit's natural angular frequency omega)
%
% Piotr Gregor <piotr@dataanadsignal.com>


function [] = r_load_simulate(t, R, EMFm, omega_d)
    clearvars -global
    global R_
    global EMFm_ 
    global omega_d_
    global phase_
    
    global f_
    global T_
    
    % Init state of the circuit
    n = length(t);
    fprintf("n %d\n", n);
   
    R_ = R;
    EMFm_ = EMFm;           % EMF amplitude
    
    omega_d_ = omega_d;     % driving frequency
    fprintf("driving omega: %f (driving angular frequency of the EMF)\n", omega_d_);
    
    tmax = max(t);
    fprintf("tmax %f\n", tmax);
    
    % The voltage is in resonance with current in R load.
    phase_ = 0;
    fprintf("phase %f\n", phase_);
    
    % Circuits frequency
    f_ = omega_d_ / (2 * pi);
    fprintf("freq %f\n  (circuits freq == EMF freq)\n", f_);
    
    % Period
    T_ = 1 / f_;
    fprintf("period %f\n", T_);
    
    % Amplitudes
    fprintf("Amplitudes:\n");
    fprintf("   v_R: %f\n   i_R: %f\n", EMFm, EMFm / R);
    
    % Init vectors
    v_R_vec = 1 : n;
    i_R_vec = 1 : n;
    
    % Simulation
    for i = 1 : n
        
        % Potential difference through resistor
        % In R load we have from the Kirchhoff's loop rule (2nd law) for voltage:
        % EMF = v_R  where v_R is voltage through the resistor
        v_R_vec(i) = EMFm * sin(omega_d_ * t(i));
        
        % Current through resistor
        i_R_vec(i) = v_R_vec(i) / R;  % same as EMFm / R * sin(omega_d_ * t(i));
    end
     
    plot_as_one(t, v_R_vec, 'v_R - voltage across resistor', i_R_vec, 'i_R - current through resistor');
    plot_as_sub(t, v_R_vec, 'v_R - voltage across resistor', i_R_vec, 'i_R - current through resistor');
    plot_all(t, v_R_vec, 'v_R - voltage across resistor', i_R_vec, 'i_R - current through the circuit');
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