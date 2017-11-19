% Simulate free oscillations in LC circuit.
% "free" of any external EMF.
%
%           -->
%       i_L == i_C 
% ------ L -----|| ------
% |     v_L     v_C     |
% EMF                   |
% |                     |
% -----------------------
%
% Params:
% t - vector of time stamps [ms]
% L - inductance
% C - capacitance
% V0 - initial voltage across the circuit (potential difference), e.g: battery
% is charging the LC circuit and then removed, there is no EMF, only that
% initial voltage
% EMF - forced oscillations
%
% Piotr Gregor <piotr@dataanadsignal.com>
function [] = lc_oscillator_simulate(t, L, C, V_0, phase)
    global L_
    global C_
    global V_0_ 
    global omega_
    global phase_
    
    global Q_
    
    % Init state of LC circuit
    n = length(t);
    fprintf("n %d\n", n);
   
    L_ = L;
    C_ = C;
    V_0_ = V_0;
    omega_ = 1 / sqrt(L * C);     % LC oscillator frequency
    fprintf("omega: %f (natural circuit's angular frequency)\n", omega_);
    
    phase_ = phase;
    
    Q_ = C * V_0;
    fprintf("Q: %f\n", Q_);
    
    
    % Init vectors
    qC_vec = 1 : n;
    uC_vec = 1 : n;
    iL_vec = 1 : n;
    tmax = max(t);
    fprintf("tmax %f\n", tmax);
    %iLC_vec = 1 : n;
    
    % Simulation
    for i = 1 : n
        
        % Electric charge on capacitor
        qC_vec(i) = Q_ * cos(omega_ * t(i) + phase_);
        %fprintf("-> q(%d): %f\n", i, q_vec(i));
        
        % Potential difference across capacitor
        uC_vec(i) = qC_vec(i) / C;  % same as = V_0_ * cos(omega_ * t(i) + phase_);
        
        % Current through the circuit, current in the inductor is same as
        % current through capacitor: iC = iL = dq / dt
        iL_vec(i) = - omega_ * Q_ * sin(omega_ * t(i) + phase_);
    end
     
    plot_as_one(t, qC_vec, 'qC - charge on Capacitor', uC_vec, 'uC - voltage across capacitor', iL_vec, 'iL - current through the circuit');
    plot_as_sub(t, qC_vec, 'qC - charge on Capacitor', uC_vec, 'uC - voltage across capacitor', iL_vec, 'iL - current through the circuit');
    %plot_all(t, qC_vec, 'qC - charge on Capacitor', uC_vec, 'uC - voltage across capacitor', iL_vec, 'iL - current through the circuit');
end

function [] = plot_as_one(t, y1, s1, y2, s2, y3, s3)
    figure();
    yyaxis left
    plot(t, y1, 'r', t, y2, 'g');
    yyaxis right
    plot(t, y3, 'b');
    legend(s1, s2, s3);
end

function [] = plot_as_sub(t, y1, s1, y2, s2, y3, s3)
    figure();
    subplot(3,1,1), plot(t, y1,'r');
    legend(s1);
    subplot(3,1,2), plot(t, y2,'g');
    legend(s2);
    subplot(3,1,3), plot(t, y3,'b');
    legend(s3);
end

function [] = plot_all(t, y1, s1, y2, s2)
    figure();
    p1 = plot(t, y1, 'r');
    legend(p1, s1);
    figure();
    p2 = plot(t, y2, 'b');
    legend(p2, s2);
end