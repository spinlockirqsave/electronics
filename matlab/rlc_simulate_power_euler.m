% Simulate power produced by RLC circuit.
%
% Details
% Using improved Euler method for U and I. Using Simpson method for
% integration of instantaneous power.
%
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
% Return
% Power produced by the circuit in time [t0, t0 + n*dt].
%
% Piotr Gregor <piotr@dataanadsignal.com>


function [power] = rlc_simulate_power_euler(t0, dt, n, R, L, C, EMFm, f)
    clearvars -global
    global t0_
    global dt_
    global h_
    global n_
    global R_
    global L_
    global C_
    
    global uC_
    global iL_
    global uCe_
    global iLe_
    global diL_
    
    global EMF_
    global EMFm_
    global f_d_
    global omega_d_
    
    global omega_
    global f_
    global XC_
    global XL_
    global XC_res_
    global XL_res_
    
    power = NaN;
    
    % Vectors
    t = t0 : dt : t0 + n * dt;
    uC_ = t;
    iL_ = t;
    duC = t;
    diL_ = t;
    uCe_ = t;
    dUce = t;
    iLe_ = t;
    
    % Init state of RLC circuit
    t0_ = t0;
    dt_ = dt;
    h_ = dt_ / 2;
    n_ = n;
    R_ = R;
    L_ = L;
    C_ = C;
    
    if (mod(n_, 2))
        fprintf("Err, number of steps must be even\n");
        return;
    end
    p_ = t(1 : n_ / 2);
    p_time_ = 2 * t(1 : n_ / 2);
    
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
    EMFm_ = EMFm;
    if (f_d_ == 0.0)
        EMF_ = EMFm_ * ones(1, n + 1);
    else
        EMF_ = EMFm_ * sin(omega_d_ * t);
    end
    
    uC_(1) = 0;     % initial voltage across capacitor must be zero
    iL_(1) = 0;     % initial current through the circuit is zero
    uCe_(1) = 0;
    iLe_(1) = 0;
    
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
        return;
    end
    
    fprintf("Simulating %d steps...\n", n);
    fprintf("Time step (time differential) dt %f\n", dt_);
    
    % Simulation
    for i = 1 : n + 1
        if (i > 1)
            % uC
            duC(i) = duC_dt(i) .* dt;
            uC_(i) = uC_(i - 1) + duC(i - 1);
        
            % iL
            diL_(i) = diL_dt(i) .* dt;
            iL_(i) = iL_(i - 1) + diL_(i - 1);
            
            % uCe_
            uCe_(i) = uCe_(i - 1) + h_ .* duC_dt_e(i - 1);
            %uCe_(i) = uC_(i);
            
            % iLe_
            iLe_(i) = iLe_(i - 1) + h_ .* diL_dt_e(i - 1);
            
            % Power simulation
            if (mod(i, 2) == 1)
                y_0 = EMF_(i - 2) .* iLe_(i - 2);
                y_mid = EMF_(i - 1) .* iLe_(i - 1);
                y_1 = EMF_(i) .* iLe_(i);
                p = simpson_integral(y_0, y_mid, y_1, dt);
                if (i == 3)
                    p_((i-1) ./ 2) = p;
                else
                    p_((i-1) ./ 2) = p_((i-1) ./ 2 - 1) + p;
                end
            end
        end

        %fprintf("%d -> duC/dt %f, duC %f, diL/dt %f, diL %f iL_e %f uC_e %f\n", i, duC(i)/dt, duC(i), diL_(i)/dt, diL_(i), iLe_(i), uCe_(i));
        %fprintf("%d -> EMF %f, uC %f, iL %f\n", i, EMF_(i), uC_(i), iL_(i));
    end
    
    power = p_(n_ ./ 2);
    % plot
    plot_as_one(t, EMF_, 'EMF', uC_, 'uC', uCe_, 'uC euler', iL_, 'iL', iLe_, 'iL euler');
    plot_one(p_time_, p_, 'Power', 'Time [s]', 'Watt [W]');
end


% Derivation

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

function [duC_dt_e] = duC_dt_e(i)
    global C_
    global iL_
    global h_

    if (i == 1)
        duC_dt_e = 0;
    else
        h05 = h_ ./ 2;
        didt = diL_dt(i);
        duC_dt_e = ((iL_(i - 1) + h05 .* didt) ./ C_);   % estimate uC_dt in half of dt_
    end
end

function [diL_dt_e] = diL_dt_e(i)
    global R_
    global L_
    global iLe_
    global uC_
    global EMF_
    global h_
    
    if (i == 1)
        diL_dt_e = 0;
    else
        h05 = h_ ./ 2;
        didt = (EMF_(i - 1) - R_ .* iLe_(i - 1) - uC_(i - 1)) ./ L_;
        diL_dt_e = (EMF_(i - 1) - R_ .* (iLe_(i - 1) + h05 .* didt) - uC_(i - 1)) ./ L_;
    end
end


% Integration

% Compute integral of y in the range h = x(y_1) - x(y_0) using Simpson's
% method 
function [ret] = simpson_integral(y_0, y_mid, y_1, h)
    ret = (h ./ 3) * (y_0 + 4 .* y_mid + y_1); 
end


% Plotting

function [] = plot_as_one(t, y1, s1, y2, s2, y3, s3, y4, s4, y5, s5)
    figure();
    xlabel('Time [s]');
    yyaxis left
    plot(t, y1, 'r', t, y2, 'g', t, y3, 'blue');
    ylabel('Potential difference [V]');

    yyaxis right
    plot(t, y4, 'black', t, y5, 'blue');
    ylabel('Current [A]');
    legend(s1, s2, s3, s4, s5);
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

function [] = plot_one(t, y1, s1, x_desc, y_desc)
    figure();
    p1 = plot(t, y1, 'r');
    legend(p1, s1);
    xlabel(x_desc);
    ylabel(y_desc);
end