function [] = myplot1()
t = 0:pi/200:4*pi; omega = 1;
e_a = 10 + sin(omega*t) + sin(3*omega*t) + sin(5*omega*t);
h = plot(t, e_a);
set(h, 'Color', [1 0 0], 'LineWidth', 2);
title('Napiecie odksztalcone');
xlabel('Czas t [s]');
ylabel('U [V]');
end