function current = ACS714_convert( raw_volts )
%Reading converter for the ACS714 Current Sensor
%   raw_volts    sensor analog output [volts]
%   current      sensed current corresponding to raw_volts [amps]
% see http://www.pololu.com/product/1187

current = (raw_volts - 2.5) / (0.066);

end

