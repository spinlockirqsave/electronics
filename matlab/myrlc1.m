function [] = myrlc1()


% Question Number 1
fprintf(1,'%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%.\n');
fprintf(1,'                                                                                              .\n');
fprintf(1,'                    MATLAB RLC CIRCUIT ANALYSIS                                                .\n');
fprintf(1,'                                                                                               .\n');
fprintf(1,'%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%.\n');
fprintf(1,'                                                                                              .\n');
fprintf(1,'                                                                                              .\n');
fprintf(1,' Description .\n');
fprintf(1,'------------. \n');
fprintf(1,' This matlab code is used to analyze the current through a series RLC circuit at different values of frequencies \n,'); 
fprintf (1,' as the freqeuncy changes from 100kHz to 10MHz we will analyze the behaviour of current with its magnitude and \n ');
fprintf(1,'phase observation and how does it effect the response of the circuit and the capacitive and inductive elements .\n');
fprintf(1,'which are the function of freqeuncy \n');

% wait for question 2
h = waitbar(0,'Please wait for Question 2');
a = 500;
for a = 1:a
  
    waitbar(a / a)
end
close(h) 

% Question Number 2
fprintf(1,'Question # 2 \n')
fprintf(1,'--------------\n')
r=100; % resistance
c=0.25*10^-9; % capacitance
l=0.1*10^-3; % inductance
% since we need to specify frequency
f=[100*10^3:50*10^3:10*10^6];
w=2*pi*f;
i=120./(r+(1./(1i.*w.*c))+(1i.*w.*l));
im=imag(i); % imaginary current
ireal=real(i);% real current
iabs=abs(i); % magnitude current
iphase1=angle(i);% angle current in radian
iphase=(180/pi)*iphase1; % angle in degrees
a=f'; b=im'; c=ireal'; d=iabs'; e=iphase'; % assigning all the variables in tabular form
disp('                                                                               ');
disp('                                                                                ');
disp('                                                                                 ');
fprintf(1,'Frequency\t              Current                             Phase Angle                       Magnitude\n')
fprintf(1,'Hz\t                       A                                  Degrees                          A\n')
fprintf(1,'-----------\t           ------                                --------                      ----------\n')
fprintf(1,'             \t     (Real+Imaginary)\n') 
% Loop through temperature and time arrays
for kl = 1:199
   fprintf(1, '%d\t        ( %g + %g )                %g                        %g\n', a(kl),b(kl),c(kl),e(kl),d(kl))
end



% wait for question 3
h = waitbar(0,'Please wait for Question 3');
a = 500;
for a = 1:a
  
    waitbar(a / a)
end
close(h) 

% Question Number 3
% Graph between I (mag) and F

fprintf(1,'Question # 3 \n')
fprintf(1,'--------------\n')
figure
plot(f,iabs)
xlabel('Frequency')
ylabel('Current magnitude')
title(' Linear Graph between Current & Frequency')

figure
semilogx(f,iabs)
xlabel('Frequency')
ylabel('Current magnitude')
title('  Log-Linear Graph between Current & Frequency')

% wait for question 4
h = waitbar(0,'Please wait for Question 4');
a = 500;
for a = 1:a
  
    waitbar(a / a)
end
close(h) 

% Question Number 4
% Graph between I (angle) and F 

fprintf(1,'Question # 4 \n')
fprintf(1,'--------------\n')
figure
plot(f,iphase)
xlabel('Frequency')
ylabel('Current Phase Angle')
title(' Linear Graph between Current & Frequency')

figure
semilogx(f,iphase)
xlabel('Frequency')
ylabel('Current Phase Angle')
title('  Log-Linear Graph between Current & Frequency')

% wait for question 5
h = waitbar(0,'Please wait for Question 5');
a = 500;
for a = 1:a
  
    waitbar(a / a)
end
close(h) 

% Question Number 5
% Graph between I (angle) and F and I (angle) and F using subplot
figure
subplot(2,1,1)
plot(f,iphase)
xlabel('Frequency')
ylabel('Current Phase Angle')
title(' Linear Graph between Current & Frequency')
subplot(2,1,2)
semilogx(f,iabs)
xlabel('Frequency')
ylabel('Current magnitude')
title('  Log-Linear Graph between Current & Frequency')

% wait for question 6
h = waitbar(0,'Please wait for Question 6');
a = 500;
for a = 1:a
  
    waitbar(a / a)
end
close(h) 

% Question Number 6

% plot current using plot3

figure
plot3(ireal,im,f)
title('Plot i(f) using plot3')
xlabel(' I Real')
ylabel(' I (Imaginary)')
zlabel('F')
grid on
axis square

end
