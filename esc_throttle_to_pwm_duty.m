function pwm_duty = esc_throttle_to_pwm_duty( throttle )
%Convert a throttle setting to a PWM duty cycle for an Electronic Speed
%Controller
%   throttle    throttle level, between 0 and 1. 0=off, 1=full power
%   pwm_duty    fraction of the cycle for which the pwm signal is high.
%   between 0.05 and 0.10.

% check the input
if throttle < 0 || throttle > 1
    err = MException('InputChk:OutOfRange', ...
        'Input throttle setting must be between 0 and 1, inclusive.');
    throw(err);
end

pwm_duty = 0.05*(throttle) + 0.05;

end

