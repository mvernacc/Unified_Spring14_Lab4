function value = u3_pwm_duty( duty )
%Computes duty cycle values for the LabJack U3 PWM output
%   duty     desired fraction of the period for which the signal is high
%   (between 0.0 and 1.0)
%   value    LabJavk timer value to achieve this duty cycle (int between 0
%   and 65536)
% see  http://labjack.com/support/u3/users-guide/2.9.1.2

% check the input
if duty < 0 || duty > 1
    err = MException('InputChk:OutOfRange', ...
        'Input duty cycle must be between 0 and 1, inclusive.');
    throw(err);
end

% compute the value
value = (1-duty)*65536;
% make the value an integer
value = int32(ceil(value));

end

