function throttle = throttle_time( time )
%Defines a throttle setting vs time profile for the test
%   time     The time since the test start [sec]
%   throttle The throttle setting for that time [0 to 1]

%%%% User-Changeable Section %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
throttle = 0.50 + 0.40*sin(time/2);
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

assert(throttle >= 0 && throttle <= 1,...
    'throttle setting msut be in [0,1] for all times');

end

