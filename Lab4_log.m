% Lab 4 Data Logging
% 16.Unified
% Written by Matt Vernacchia, mvernacc@mit.edu , April 2014

% Sensing period [sec]
T = 0.1;

% Analog input pins
PIN_BAT_I = 0; % Battery current sensor on AIN0
PIN_BAT_V = 1; % Battery Voltage measured by AIN1
PIN_THROTTLE = 4; % ESC throttle PWM signal on FIO4

% make LabJack object
ljasm = NET.addAssembly('LJUDDotNet'); %Make the UD .NET assembly visible in MATLAB
ljudObj = LabJack.LabJackUD.LJUD;

% Open the connection to the LabJack and set up the sensing requests
fprintf('Conencting to the LabJack...');
try
    %Open the first found LabJack U3.
    [ljerror, ljhandle] = ljudObj.OpenLabJack(LabJack.LabJackUD.DEVICE.U3, LabJack.LabJackUD.CONNECTION.USB, '0', true, 0);
    
    %Start by using the pin_configuration_reset IOType so that all
    %pin assignments are in the factory default condition.
    chanObj = System.Enum.ToObject(chanType, 0); %channel = 0
    ljudObj.ePut(ljhandle, LabJack.LabJackUD.IO.PIN_CONFIGURATION_RESET, chanObj, 0, 0);
    
    %Set the timer/counter pin offset, which will put the first timer/counter on the throttle pin.
    ljudObj.AddRequest(ljhandle, LabJack.LabJackUD.IO.PUT_CONFIG, LabJack.LabJackUD.CHANNEL.TIMER_COUNTER_PIN_OFFSET, PIN_THROTTLE, 0, 0);
    %Use the 48 MHz timer clock base with divider (LJ_tc48MHZ_DIV = 26).  Since we are using clock with divisor
    %support, Counter0 is not available.
    ljudObj.AddRequest(ljhandle, LabJack.LabJackUD.IO.PUT_CONFIG, LabJack.LabJackUD.CHANNEL.TIMER_CLOCK_BASE, 26, 0, 0);
    
    %Set the divisor to 14 so the actual timer clock is 3.43 MHz.
    ljudObj.AddRequest(ljhandle, LabJack.LabJackUD.IO.PUT_CONFIG, LabJack.LabJackUD.CHANNEL.TIMER_CLOCK_DIVISOR, 14, 0, 0);
    %Enable 1 timer.  It will use FIO4.
    ljudObj.AddRequest(ljhandle, LabJack.LabJackUD.IO.PUT_CONFIG, LabJack.LabJackUD.CHANNEL.NUMBER_TIMERS_ENABLED, 1, 0, 0);
    
    %Configure Timer0 as 16-bit PWM (LJ_tmPWM16 = 0).  Frequency will be 3.42 MHzHz/(2^16) = 52.3 Hz,
    % which is close to the 50 Hz frequency for RC aircraft PWM.
    LJ_tmPWM16 = 0;
    ljudObj.AddRequest(ljhandle, LabJack.LabJackUD.IO.PUT_TIMER_MODE, 0, LJ_tmPWM16, 0, 0);
    
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
filename = ['Unified_Lab4_battery_data_', date_string, '.csv'];
fprintf('Opening log file %s ...', filename);
fileID = fopen(filename, 'W');
fprintf('done\n');

% Set up the stop box:
FS = stoploop({'Click here to stop the test'});
fprintf('Srarting test\n');

% hold the throttle at 0 for several second to get the ESC set up
fprintf('Zero throttle to start ESC...');
try
    %Set the PWM duty cycle.
    duty = esc_throttle_to_pwm_duty(0);
    ljudObj.AddRequest(ljhandle, LabJack.LabJackUD.IO.PUT_TIMER_VALUE, 0, u3_pwm_duty(duty), 0, 0);
    % Execute the requests.
    ljudObj.GoOne(ljhandle);
catch
    showErrorMessage(e)
end
pause(5);
fprintf('done\n');

% Record test start time
t0 = clock;

done = false;
while ~done && ~FS.Stop()
    t_cycle_start = etime(clock,t0);
    % Throttle setting for this cycle
    throttle = throttle_time(t_cycle_start);
    duty = esc_throttle_to_pwm_duty(throttle);
    % Communicate with the labjack
    try
        n = 4; % number of readings to average
        I_values_raw = zeros(1,n);
        I_values_raw = zeros(1,n);
        %Request a single-ended reading from the current sensor.
        ljudObj.AddRequest(ljhandle, LabJack.LabJackUD.IO.GET_AIN, PIN_BAT_I, 0, 0, 0);
        %Request a single-ended reading from the battery voltage pin.
        ljudObj.AddRequest(ljhandle, LabJack.LabJackUD.IO.GET_AIN, PIN_BAT_V, 0, 0, 0);
        %Set the PWM duty cycle.
        ljudObj.AddRequest(ljhandle, LabJack.LabJackUD.IO.PUT_TIMER_VALUE, 0, u3_pwm_duty(duty), 0, 0);
        
        for i = 1:n
            % Execute the requests.
            ljudObj.GoOne(ljhandle);
            
            % Get the result values
            [ljerror, I_values_raw(i)] = ljudObj.GetResult(ljhandle, LabJack.LabJackUD.IO.GET_AIN, PIN_BAT_I, 0);
            [ljerror, V_values_raw(i)] = ljudObj.GetResult(ljhandle, LabJack.LabJackUD.IO.GET_AIN, PIN_BAT_V, 0);
        end
        I_value_raw_mean = mean(I_values_raw);
        V_value_raw_mean = mean(V_values_raw);
    catch e
        showErrorMessage(e)
    end
    % Convert the raw sensor readings to real units
    I_value = ACS714_convert(I_value_raw_mean);
    V_value = V_value_raw_mean;
    
    % Print the readings
    fprintf('Current = %0.2f A, Voltage = %0.2f V\n', I_value, V_value);
    
    % Write to the data log file
    fprintf(fileID, '%.3f,%.3f,%.3f,%.3f\n', t_cycle_start, I_value, V_value, throttle);
    
    % Wait until it's time for the next cycle
    t_used = etime(clock,t0) - t_cycle_start;
    t_wait = T - t_used;
    if t_wait > 0
        pause(t_wait);
    end
end

% turn off the throttle
try
    %Set the PWM duty cycle to 0%.
    ljudObj.AddRequest(ljhandle, LabJack.LabJackUD.IO.PUT_TIMER_VALUE, 0, u3_pwm_duty(0.0), 0, 0);
    % Execute the requests.
    ljudObj.GoOne(ljhandle);
catch
    showErrorMessage(e)
end


% clean up the stop box
FS.Clear(); % Clear up the box
clear FS; % this structure has no use anymore

% close the data log file
fclose(fileID);

% close the connection to the LabJack
ljudObj.Close()

