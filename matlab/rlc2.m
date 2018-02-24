function [] = rlc2()
L=0.1;
C=0.001;
R=25/3;
a=1/(2*R*C);

a =60.0000;

w0=1/sqrt(L*C);       
w0 =100;
wd=sqrt(w0^2 - a^2);
wd =80.0000;
B1=10;
B2=(a/wd)*B1 - 10/(wd*R*C) + 0.6/(wd*C);
B2 =-1.7764e-15;
 t=0:0.001:0.12;
 v=B1*exp(-a*t).*cos(wd*t) + B2*exp(-a*t).*sin(wd*t);
hold on
plot(1000*t,v,'b+-');
 R=20;
 a=1/(2*R*C);
 wd=sqrt(w0*w0 - a*a);
 B2=(a/wd)*B1 - 10/(wd*R*C) + 0.6/(wd*C);
v=B1*exp(-a*t).*cos(wd*t) + B2*exp(-a*t).*sin(wd*t);
plot(1000*t,v,'mo-');
 R=50;
 a=1/(2*R*C);
 wd=sqrt(w0*w0 - a*a);
 B2=(a/wd)*B1 - 10/(wd*R*C) + 0.6/(wd*C);
 v=B1*exp(-a*t).*cos(wd*t) + B2*exp(-a*t).*sin(wd*t);
 plot(1000*t,v,'kx-');
 R=100;
 a=1/(2*R*C);
wd=sqrt(w0*w0 - a*a);
 B2=(a/wd)*B1 - 10/(wd*R*C) + 0.6/(wd*C);
v=B1*exp(-a*t).*cos(wd*t) + B2*exp(-a*t).*sin(wd*t);

 plot(1000*t,v,'rd-'); hold on
legend('R=25/3','R=20','R=50','R=100')
 ylabel('v_n(t), V');
 xlabel('t, ms');
 title('Natural Response of an Underdamped Parallel RLC Circuit');
end

