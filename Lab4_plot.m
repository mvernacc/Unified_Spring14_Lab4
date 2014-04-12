% Lab 4 Data Logging
% 16.Unified
% Written by Matt Vernacchia, mvernacc@mit.edu , April 2014

%%%% User-Changeable Section %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% filename of .csv file containing the data log
filename = 'Unified_Lab4_battery_data_12-Apr-2014_13-06-10.csv';
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%% Battery data
% Battery maxiumum safe voltage [V]
bat_v_max = 4.2*2;
% Battery minimum safe voltage [V]
bat_v_min = 3.5*2;

%% Load data
M = csvread(filename);

% Time [s]
t = M(:,1);
% Battery current [A]
I = M(:,2);
% Battery voltage [V]
V = M(:,3);
% throttle setting [0 to 1]
throttle = M(:,4);

%% Integrate the battery charge
% battery charge level relative to test start [Coulombs]
c = zeros(size(t));
for i = 2:length(t)
    dt = t(i)-t(i-1);
    c(i) = c(i-1) - I(i)*dt;
end
% battery charge level relative to test start [mA hr]
c_mahr = c*0.2778;

%% Plot time traces
figure('Name', 'Lab4 Time Traces')
% current
subplot(4,1,1)
plot(t,I)
grid on
xlabel('Time since test start [s]')
ylabel('Battery current [A]')
% voltage
subplot(4,1,2)
plot(t,V)
grid on
xlabel('Time since test start [s]')
ylabel('Battery voltage [V]')
% battery charge
subplot(4,1,3)
plot(t,c_mahr)
grid on
xlabel('Time since test start [s]')
ylabel('Battery charge [mA hr]')
% throttle
subplot(4,1,4)
plot(t,throttle)
grid on
xlabel('Time since test start [s]')
ylabel('Throttle [0 to 1]')

%% Plot discharge curve
figure('Name', 'Lab4 Battery Dischage Curve')
hold on
plot(c_mahr, V)
plot(c_mahr, bat_v_max*ones(size(c_mahr)), 'r:')
plot(c_mahr, bat_v_min*ones(size(c_mahr)), 'r:')
grid on
xlabel('Battery charge level, reltive to start [mA hr]')
ylabel('Battery voltage [V]')
title('Battery Discharge curve')

%% Plot throttle vs power
figure('Name', 'Power Level vs Throttle Setting')
plot(throttle, V.*I)
xlabel('Throttle setting [0 to 1]')
ylabel('Power drawn from battery, [W]')
title(sprintf('Electronic Speed Controller\nPower Draw vs Throttle Setting'))

