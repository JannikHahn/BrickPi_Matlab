classdef BPsensor
    %BPSENSOR obj = BPsensor(type,port)
%       port: 1-4
%       type: name or number from list
%
%       to get list: >> sensor = BPsensor(1,1)
%                    >> sensor.names
    
    properties
        type_name
        port
    end
    properties (Hidden) 
        type
    end
    properties (Constant, Hidden)
        names = {
                  'NONE'
                  'I2C'
                  'CUSTOM'  % Choose 9v pullup, pin 5 and 6 configuration, and what to read back (ADC 1 and/or ADC 6 (always reports digital 5 and 6)).

                  'TOUCH'   % Touch sensor. When this mode is selected, automatically configure for NXT/EV3 as necessary.
                  'TOUCH_NXT' % 5
                  'TOUCH_EV3'

                  'NXT_LIGHT_ON'
                  'NXT_LIGHT_OFF'

                  'NXT_COLOR_RED'
                  'NXT_COLOR_GREEN'     % 10
                  'NXT_COLOR_BLUE'
                  'NXT_COLOR_FULL'
                  'NXT_COLOR_OFF'

                  'NXT_ULTRASONIC'

                  'EV3_GYRO_ABS'        % 15
                  'EV3_GYRO_DPS'
                  'EV3_GYRO_ABS_DPS'

                  'EV3_COLOR_REFLECTED'
                  'EV3_COLOR_AMBIENT'
                  'EV3_COLOR_COLOR'     % 20
                  'EV3_COLOR_RAW_REFLECTED'
                  'EV3_COLOR_COLOR_COMPONENTS'

                  'EV3_ULTRASONIC_CM'
                  'EV3_ULTRASONIC_INCHES'
                  'EV3_ULTRASONIC_LISTEN'   %25

                  'EV3_INFRARED_PROXIMITY'
                  'EV3_INFRARED_SEEK'
                  'EV3_INFRARED_REMOTE'};
    end
    methods
        function obj = BPsensor(type,port)
            if isa(type,'double')
                if type > 28
                    error('invalid number');
                else
                    obj.type = type;
                    obj.type_name = obj.names{type};
                end
            elseif isa(type,'char')
                obj.type = find(ismember(obj.names,upper(type)));
                if isempty(obj.type)
                    error('invalid sensor name')
                else
                    obj.type_name = upper(type);
                end
            end
            obj.port = port;
        end
        

        
        function out = eq(obj1,obj2)
            out=[];
            for i=1:length(obj1)
                out(i) = obj1(i).type == obj2.type && obj1(i).port == obj2.port;
            end
        end
    end
end

