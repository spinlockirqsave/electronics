% Simulate RLC circuit.
% Params:
% t0 - start time [ms]
% dt - time resolution [ms]
% n - number of steps (total simulation time = n * dt)
% R - resistance
% L - inductance
% C - capacitance
% EMFm - max value of electromotive force EMF (amplitude)
% f - frequency of the EMF (driving frequency in Hz)
%
% Piotr Gregor <piotr@dataanadsignal.com>


function [] = rlc_simulate(t0, dt, n, R, L, C, EMFm, f)
    clearvars -global
    global t0_
    global dt_
    global n_
    global R_
    global L_
    global C_
    
    global uC_
    global iL_
    
    global EMF_
    global f_d_
    global omega_d_
    
    global omega_
    global f_
    global XC_
    global XL_
    global XC_res_
    global XL_res_
    
    % Vectors
    t = t0 : dt : t0 + n * dt;
    uC_ = t;
    iL_ = t;
    duC = t;
    diL = t;
    
    % Init state of RLC circuit
    t0_ = t0;
    dt_ = dt;
    n_ = n;
    R_ = R;
    L_ = L;
    C_ = C;
    
    
    % Driving angular frequency
    f_d_ = f;
    omega_d_ = 2 * pi * f;
    XL_ = omega_d_ * L;
    XC_ = 1 / (omega_d_ * C);
    
    % Circuit's natural frequency
    omega_ = 1 / sqrt(L * C);
    f_ = omega_ / (2 * pi);
    XL_res_ = omega_ * L;
    XC_res_ = 1 / (omega_ * C);
    
    % Initial inputs of EMF, voltage across capacitor and current through inductor
    EMF_ = EMFm * sin(omega_d_ * t);
    uC_(1) = 0;     % initial voltage across capacitor must be zero
    iL_(1) = 0;     % initial current through the circuit is zero
    
    % Print info
    fprintf("Circuit's parameters:\n");
    fprintf("EMF:\n     max %f\n", EMFm);
    fprintf("Frequency:\n");
    fprintf("    freq %f [Hz]\n    angular driving freq %f [rad/s] (omega), T %f\n", f_d_, omega_d_, 1/f_d_);
    fprintf("Natural freq (resonanant)\n");
    fprintf("    freq %fHz\n    angular natural freq %f [rad/s] (omega), T %f\n", f_, omega_, 1/f_);
    fprintf("Reactance:\n");
    fprintf("    XL %f\n    XC %f", XL_, XC_);
    if (XL_ > XC_)
        fprintf("    circuit is INDUCTIVE\n");
    else
        if (XL_ < XC_)
            fprintf("    circuit is CAPACITIVE\n");
        else
            fprintf("    circuit is RESISTIVE\n");
        end
    end
    fprintf("Reactance (resonant):\n");
    fprintf("    XL(at resonance) %f\n    XC(at resonance) %f\n", XL_res_, XC_res_);
    
    % Error checking
    if (n < 2)
        fprintf("\nErr, cannot run simulation. Number of steps too small...\n");
        return
    end
    
    fprintf("Simulating %d steps...\n", n);
    
    % Simulation
    for i = 1 : n + 1
        if (i > 1)
            % uC
            duC(i) = duC_dt(i) .* dt;
            uC_(i) = uC_(i - 1) + duC(i - 1);
        
            % iL
            diL(i) = diL_dt(i) .* dt;
            iL_(i) = iL_(i - 1) + diL(i - 1);
        end

        fprintf("%d -> duC/dt %f, duC %f, diL/dt %f, diL %f\n", i, duC(i)./dt, duC(i), diL(i)./dt, diL(i));
        fprintf("%d -> EMF %f, uC %f, iL %f\n", i, EMF_(i), uC_(i), iL_(i));
    end
    
    % plot
    plot_as_one(t, EMF_, 'EMF', uC_, 'uC', iL_, 'iL');
end

function [duC_dt] = duC_dt(i)
    global C_
    global iL_
    
    if (i == 1)
        duC_dt = 0;
    else
        duC_dt = (iL_(i - 1) ./ C_);
    end
end

function [diL_dt] = diL_dt(i)
    global R_
    global L_
    global iL_
    global uC_
    global EMF_
    
    if (i == 1)
        diL_dt = 0;
    else
        diL_dt = (EMF_(i - 1) - R_ .* iL_(i - 1) - uC_(i - 1)) ./ L_;
    end
end

% plotting

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