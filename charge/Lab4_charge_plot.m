% Lab 4 Data Logging
% 16.Unified
% Written by Matt Vernacchia, mvernacc@mit.edu , April 2014

% look for needed files in the directory 1 level up
addpath('..')

%% Battery data
% Battery maxiumum safe voltage [V]
bat_v_max = 4.2;
% Battery minimum safe voltage [V]
bat_v_min = 3.5;

%% Load data from test log
% filename of .csv file containing the data log
filename = uigetfile({'.csv'});

M = csvread(filename);

% Time [s]
t = M(:,1);
% Battery current [A]
I_bat_unfilt = M(:,2);
% Battery voltage [V]
V_bat_unfilt = M(:,3);
% Solar panel current [A]
I_sol_unfilt = M(:,4);
% Solar panel voltage [V]
V_sol_unfilt = M(:,5);


%% Filter the voltage and current
I_bat = lowPass(I_bat_unfilt,0.2);
V_bat = lowPass(V_bat_unfilt,0.2);
I_sol = lowPass(I_sol_unfilt,0.2);
V_sol = lowPass(V_sol_unfilt,0.2);

%% Integrate the battery charge
% battery charge level relative to test start [Coulombs]
c = zeros(size(t));
for i = 2:length(t)
    dt = t(i)-t(i-1);
    c(i) = c(i-1) + I_bat(i)*dt;
end
% battery charge level relative to test start [mA hr]
c_mahr = c*0.2778;

%% Power
% Power output of the solar panel [W]
P_sol = I_sol.*V_sol;
% Power delivered to the batteries [W]
P_bat = I_bat.*V_bat;

%% Charger efficiency
eta = P_bat./P_sol;

%% Plot time traces
figure('Name', 'Lab4 Time Traces')
% current
subplot(4,1,1)
plot(t,I_bat,'r', t,I_bat_unfilt,':r', t,I_sol,'b', t,I_sol_unfilt,'b:');
grid on
xlabel('Time since test start [s]')
ylabel('Battery current [A]')
legend('Battery, Filtered', 'Battery, Unfiltered', 'Solar Panel, Filtered', 'Solar Panel, Unfiltered')
% voltage
subplot(4,1,2)
plot(t,V_bat,'r', t,V_bat_unfilt,':r', t,V_sol,'b', t,V_sol_unfilt,'b:');
grid on
xlabel('Time since test start [s]')
ylabel('Battery voltage [V]')
legend('Battery, Filtered', 'Battery, Unfiltered', 'Solar Panel, Filtered', 'Solar Panel, Unfiltered')
% battery charge
subplot(4,1,3)
plot(t,c_mahr)
grid on
xlabel('Time since test start [s]')
ylabel('Battery charge [mA hr]')
% power
subplot(4,1,4)
plot(t,P_bat,'r', t,P_sol,'b')
grid on
xlabel('Time since test start [s]')
ylabel('Power [W]')
legend('Battery', 'Solar Panel')

%% Plot charging curve
figure('Name', 'Lab4 Battery Dischage Curve')
hold on
plot(c_mahr, V_bat)
plot(c_mahr, bat_v_max*ones(size(c_mahr)), 'r:')
plot(c_mahr, bat_v_min*ones(size(c_mahr)), 'r:')
grid on
xlabel('Battery charge level, reltive to start [mA hr]')
ylabel('Battery voltage [V]')
title('Battery Charging Curve')

%% Plot charger efficiency
figure('Name', 'Lab4 Charger Efficiency')
plot(P_sol, eta)
xlabel('Power draw from solar panel [W]')
ylabel('Charger Efficiency [-]')
title('Charger Efficiency')