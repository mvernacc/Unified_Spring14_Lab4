% Lab 4 Data Logging
% 16.Unified
% Written by Matt Vernacchia, mvernacc@mit.edu , April 2014

% look for needed files in the directory 1 level up
addpath('..')

% Sensing period [sec]
T = 0.1;

% Analog input pins
PIN_BAT_I = 0; % Battery current sensor on AIN0
PIN_BAT_V = 1; % Battery voltage measured by AIN1
PIN_SOL_I = 2; % Solar panel current sensor on AIN2
PIN_SOL_V = 3; % Solar panel voltage measured by AIN3

% make LabJack object
ljasm = NET.addAssembly('LJUDDotNet'); %Make the UD .NET assembly visible in MATLAB
ljudObj = LabJack.LabJackUD.LJUD;

% Open the connection to the LabJack and set up the sensing requests
fprintf('Conencting to the LabJack...');
try
    %Open the first found LabJack U3.
    [ljerror, ljhandle] = ljudObj.OpenLabJack(LabJack.LabJackUD.DEVICE.U3, LabJack.LabJackUD.CONNECTION.USB, '0', true, 0);
    
    %Used for casting a value to a CHANNEL enum
    chanType = LabJack.LabJackUD.CHANNEL.LOCALID.GetType;
    
    %Start by using the pin_configuration_reset IOType so that all
    %pin assignments are in the factory default condition.
    chanObj = System.Enum.ToObject(chanType, 0); %channel = 0
    ljudObj.ePut(ljhandle, LabJack.LabJackUD.IO.PIN_CONFIGURATION_RESET, chanObj, 0, 0);
    
    % Execute the requests.
    ljudObj.GoOne(ljhandle);
catch e
    showErrorMessage(e)
end
fprintf('done\n');

% Open a data log file
date_string = datestr(now);
date_string = strrep(date_string, ':', '-');
date_string = strrep(date_string, ' ', '_');
filename = ['Unified_Lab4_charge_data_', date_string, '.csv'];
fprintf('Opening log file %s ...', filename);
fileID = fopen(filename, 'W');
fprintf('done\n');

% Set up the stop box:
FS = stoploop({'Click here to stop the test'});
fprintf('Starting test\n');

% Record test start time
t0 = clock;

done = false;
while ~done && ~FS.Stop()
    t_cycle_start = etime(clock,t0);
    % Communicate with the labjack
    I_bat_value_raw_mean=0; V_bat_value_raw_mean=0;
    I_sol_value_raw_mean=0; V_sol_value_raw_mean=0;
    try
        n = 16; % number of readings to average
        I_bat_values_raw = zeros(1,n);
        V_bat_values_raw = zeros(1,n);
        I_sol_values_raw = zeros(1,n);
        V_sol_values_raw = zeros(1,n);
        %Request a single-ended reading from the battery current sensor.
        ljudObj.AddRequest(ljhandle, LabJack.LabJackUD.IO.GET_AIN, PIN_BAT_I, 0, 0, 0);
        %Request a single-ended reading from the battery voltage pin.
        ljudObj.AddRequest(ljhandle, LabJack.LabJackUD.IO.GET_AIN, PIN_BAT_V, 0, 0, 0);
        %Request a single-ended reading from the solar panel current sensor.
        ljudObj.AddRequest(ljhandle, LabJack.LabJackUD.IO.GET_AIN, PIN_SOL_I, 0, 0, 0);
        %Request a single-ended reading from the solar panel voltage pin.
        ljudObj.AddRequest(ljhandle, LabJack.LabJackUD.IO.GET_AIN, PIN_SOL_V, 0, 0, 0);
        
        for i = 1:n
            % Execute the requests.
            ljudObj.GoOne(ljhandle);
            
            % Get the result values
            [ljerror, I_bat_values_raw(i)] = ljudObj.GetResult(ljhandle, LabJack.LabJackUD.IO.GET_AIN, PIN_BAT_I, 0);
            [ljerror, V_bat_values_raw(i)] = ljudObj.GetResult(ljhandle, LabJack.LabJackUD.IO.GET_AIN, PIN_BAT_V, 0);
            [ljerror, I_sol_values_raw(i)] = ljudObj.GetResult(ljhandle, LabJack.LabJackUD.IO.GET_AIN, PIN_SOL_I, 0);
            [ljerror, V_sol_values_raw(i)] = ljudObj.GetResult(ljhandle, LabJack.LabJackUD.IO.GET_AIN, PIN_SOL_V, 0);
        end
        I_bat_value_raw_mean = mean(I_bat_values_raw);
        V_bat_value_raw_mean = mean(V_bat_values_raw);
        I_sol_value_raw_mean = mean(I_sol_values_raw);
        V_sol_value_raw_mean = mean(V_sol_values_raw);
    catch e
        showErrorMessage(e)
    end
    % Convert the raw sensor readings to real units
    I_bat_value = ACS714_convert(I_bat_value_raw_mean);
    V_bat_value = V_bat_value_raw_mean;
    I_sol_value = ACS714_convert(I_sol_value_raw_mean);
    V_sol_value = V_sol_value_raw_mean;
    
    % Print the readings
    fprintf('Solar Panel Voltage = %0.2f V, Battery Voltage = %0.2f V\n', V_sol_value, V_bat_value);
    
    % Write to the data log file
    fprintf(fileID, '%.3f,%.3f,%.3f,%.3f,%.3f\n', t_cycle_start, I_bat_value, V_bat_value, I_sol_value, V_sol_value);
    
    % Wait until it's time for the next cycle
    t_used = etime(clock,t0) - t_cycle_start;
    t_wait = T - t_used;
    if t_wait > 0
        pause(t_wait);
    end
end

% clean up the stop box
FS.Clear(); % Clear up the box
clear FS; % this structure has no use anymore

% close the data log file
fclose(fileID);
fprintf('Test data saved to log file %s\n', filename);

% close the connection to the LabJack
ljudObj.Close()

