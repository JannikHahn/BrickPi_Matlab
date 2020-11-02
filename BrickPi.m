classdef BrickPi < handle
    %BRICKPI obj = BrickPi(ip_addr,user,pw,[spi_addr])
%       ip_addr:    ip_address of raspberry
%       user:       user name to log into raspberry
%       pw:         corresponding password
%       spi_port:   spi_port Brickpi is connected to. Default 'CE1'
    
    
    properties
        rpi
        spi
        spi_port= 'CE1';
        sensors={}
        motors={}
    end
    properties (Hidden)
        address = 1;
        ip_addr
        user
        pw
    end
    properties (Dependent, Access=private)
        gyro
    end
    
    methods
        function obj = BrickPi(ip_addr,user,pw,spi_port)
            obj.ip_addr=ip_addr;
            obj.user=user;
            obj.pw=pw;
            if nargin>3
                obj.spi_port=spi_port;
            end
        end
        function out = get_voltage_bat(obj)
%             out = get_Voltage_Bat(obj)
            type = 10;
            out = obj.spi_read_16(type)/1000;
        end
        function out = check_voltag_bat(obj)
            V = obj.get_voltage_bat();
            out = V>8;
        end
        function init(obj,noVolt)
            %INIT init(obj)
%                   initializes connection
%                   checks battery voltage
%                   resets and setup of sensors
%                   reset of motor encoders
            if nargin<2
                noVolt = 0;
            end
            if isempty(obj.rpi)
                obj.rpi = raspi(obj.ip_addr,obj.user,obj.pw);
            end
            if isempty(obj.spi)
                obj.spi = spidev(obj.rpi,obj.spi_port);
            end
            bat_vol=obj.get_voltage_bat;
            if bat_vol>8 || strcmp(noVolt,'setup')
                disp(['BrickPi: Successfully connected to ' obj.ip_addr])
                disp(['Battery voltage: ' num2str(bat_vol)])
            else
                obj.rpi=[];
                obj.spi=[];
                error(['Initialized failed. Low battery voltage: ' num2str(bat_vol)])
%                 warning(['Brick initialized BUT low battery voltage: ' num2str(bat_vol) ' V'])
            end
            obj.reset_sensors;
            for i=1:length(obj.motors)
                obj.reset_motor_encoder(obj.motors{i});
            end
                obj.setup_sensors;
            if obj.gyro
                disp('Initializing gyros, do not move gyros for some seconds ...');
                pause(5)
                disp('... done')
            end
        end
        function obj=add_sensor(obj,sensor)
%             obj=add_sensor(obj,sensor)
            if ~isempty(obj.sensors)
                sens= [obj.sensors{:}];
                if find([obj.sensors{:}]==sensor)
                    warning('This sensor is already assigned');
                elseif ~isempty(find([sens.port]==sensor.port,1))
                    error(['sensor port ' num2str(sensor.port) ' already assigned']);
                else
                    obj.sensors{end+1}=sensor;
                end
            else 
                obj.sensors{end+1}=sensor;
            end
        end
        function obj=add_motor(obj,motor)
%             obj=add_motor(obj,motor)
            if ~isempty(obj.motors)
                if find([obj.motors{:}]==motor)
                    error(['motor port ' num2str(motor.port) ' already assigned']);
                else
                    obj.motors{end+1}=motor;
                end
            else
                    obj.motors{end+1}=motor;
            end
            
        end
        
        function setup_sensors(obj)
%             setup_sensors(obj)
           for sen=1:length(obj.sensors)
               type = 12;
               obj.wr(obj.Aout(4,type,2^(obj.sensors{sen}.port-1),obj.sensors{sen}.type));
           end           
        end
        function reset_sensors(obj,port)
%             reset_sensors(obj,port)
           type = 12;
           if nargin<2
               port = bin2dec('1111');
           else
               port = 2^(port-1);
           end
           value = 1;
           obj.wr(obj.Aout(4,type,port,value));
        end
        function out = get_sensor(obj,sensor)
%             out = get_sensor(obj,sensor)
            sidx = find([obj.sensors{:}]==sensor);
            if isempty(sidx)
                error('unknown sensor');
            end
            sens = obj.sensors{sidx};
            
            switch sens.type
                case {4 5 6 14 18 19 20 25 26}
                    spi_length = 7;
                case {7 8 9 10 11 13 15 16 23 24}
                    spi_length  = 8;
                case {3 21 17 28}
                    spi_length  = 10;
                case {12}
                    spi_length  = 12;
                case {22 27}
                    spi_length  = 14;
                case 2
                    error('not implemented');
                otherwise
                    error('somethings wrong')
            end
            type = 12+sens.port;
            in = obj.wr(obj.Aout(spi_length,type));
            raw_val_8=uint8(nan);
            raw_val_16=uint16(nan);
            raw_val_16_2=uint16(nan);
         
            switch spi_length
                case 7
                    raw_val_8 = in(7);
                case 8
                    raw_val_8 = in(7);
                    raw_val_16 = in(7)*2^8 + in(8);
                case {10, 12 ,14}
                    raw_val_8 = in(7);
                    raw_val_16 = in(7)*2^8 + in(8);
                    raw_val_16_2 = in(9)*2^8 + in(10);
            end          
            val_8 = obj.us2s(raw_val_8,8);
            val_16 = obj.us2s(raw_val_16,16);
            val_16_2 = obj.us2s(raw_val_16_2,16);  
            
            switch sens.type
                case {4 5 6}
                    out.pressed = val_8;
                case 14
                    out.cm = val_8;
                    out.inch = val_8/2.54;
                case 18
                    out.reflected_red = val_8;
                case 19
                    out.ambient = val_8;
                case 20
                    out.color = val_8;
                case 25
                    out.presence = val_8;
                case 26
                    out.proximity = val_8;
                case 7
                    out.reflected = val_16;
                case 8
                    out.ambient = val_16;
                case 9
                    out.reflected_red = val_16;
                case 10
                    out.reflected_green = val_16;
                case 11
                    out.reflected_blue = val_16;
                case 13
                    out.ambient = val_16;
                case 15
                    out.deg = val_16;
                case 16
                    out.dps = val_16;
                case 23
                    out.cm = val_16/10;
                    out.inch = val_16/25.4;
                case 24
                    out.cm = val_16*0.254;
                    out.inc = val_16/10;
                case {2 3 28 12 22 27}
                    error('not implemented')
                case 21
                    out.reflected_red = val_16;
                case 17
                    out.deg = val_16;
                    out.dps = val_16_2;
                otherwise
                    error('somethings wrong')
            end
        end
        
        function set_LED(obj,value)
%             set_LED(obj,value)
           type=6;
           obj.spi_write_8(type,value);
        end
        
        function out = get_motor_status(obj,motor)
%             out = get_motor_status(obj,motor)
            mot = obj.ident_motor(motor);
            type = 33+mot.port;         % BPSPI_MESSAGE_GET_MOTOR_A_STATUS till -D
            in = obj.wr(obj.Aout(12,type));
            out.state = in(5);
            out.power = obj.us2s(in(6),8);
            out.position = obj.us2s(in(7:10)*2.^[24 16 8 0]',32);
            out.dps = obj.us2s(in(11:12)*2.^[8 0]',16);
        end
        function out = get_motor_encoder(obj,motor)
%             out = get_motor_encoder(obj,motor)
            mot = obj.ident_motor(motor);
            type = 29 + mot.port;
            out = obj.spi_read_32(type);
        end
        
        function set_motor_power(obj,motor,value)
%             set_motor_power(obj,motor,value)
            mot = obj.ident_motor(motor);
            if isa(value,'double')
                if ~(-100<=value && value <=100)
                    warning(['BPmotor in saturation: Port-' num2str(mot.port_name) ' Value-' num2str(value)]);
					if value>100
						value=100;
					elseif value<-100
						value=-100;
					end
%                 else
                end
                value_uint8=obj.s2us(value,8);
				if value<0
					value_uint8=value+255;
				end
            elseif isa(value,'char')
                if strcmp(value,'float')
                    value_uint8=128;
                end
            end
            type = 21;                  % BPSPI_MESSAGE_SET_MOTOR_POWER
            in = obj.wr(obj.Aout(4,type,mot.port,value_uint8));
        end
        function set_motor_encoder(obj,motor,value)
%             set_motor_encoder(obj,motor,value)
            mot = obj.ident_motor(motor);
            obj.reset_motor_encoder(mot);
            obj.offset_motor_encoder(mot,value);
        end
        function offset_motor_encoder(obj,motor,value)
%             offset_motor_encoder(obj,motor,value)
            mot = obj.ident_motor(motor);
            type = 29;                  % BPSPI_MESSAGE_OFFSET_MOTOR_ENCODER
            value = -value;
            value_uint32 = obj.s2us(value,32);
            val_bin=dec2bin(value_uint32,32);
            if value < 0
                val_bin(1)='1';
            end
            bit=8;
            for i=1:4
               val{i} = bin2dec(val_bin((i-1)*bit+1:i*bit));
            end
            in = obj.wr(obj.Aout(7,type,mot.port,val{:}));
        end
        function reset_motor_encoder(obj,motor)
%             reset_motor_encoder(obj,motor)
            mot = obj.ident_motor(motor);
            pos = obj.get_motor_encoder(mot);
            obj.offset_motor_encoder(mot,-pos);
        end
        function reset_motors(obj,port)
%             reset_motors(obj,port)
            type = 21;
            if nargin<2
                port = bin2dec('1111');
            else
                port = 2^(port-1);
            end
            value = 128;
            obj.wr(obj.Aout(4,type,port,value));
        end
        function display(obj)
            if ~isempty(obj.rpi) && ~isempty(obj.spi)
                disp('---')
                disp('BrickPi connected')
            else
                disp('BrickPi unconnected:')
            end
            if ~isempty(obj.sensors)
                str_sens = 'sensors: ';
                for i=1:length(obj.sensors)
                   str_sens = [str_sens  obj.sensors{i}.type_name ' on P' num2str(obj.sensors{i}.port) ', ']; 
                end
            end
            disp(str_sens);
            if ~isempty(obj.motors)
                str_mot = 'motors on port: ';
                for i=1:length(obj.motors)
                   str_mot = [str_mot num2str(obj.motors{i}.port_name) ', ']; 
                end
            end
            disp(str_mot);
            if ~isempty(obj.rpi) && ~isempty(obj.spi)
                disp(['Battery voltage: ' num2str(obj.get_voltage_bat)]);
            end
            disp('---')
        end
        function out = get.gyro(obj)
            sens=[obj.sensors{:}];
            out =  any([[sens.type]==15 [sens.type]==16 [sens.type]==17]);
        end
    end
    methods (Access = private)
        function index = ident_motor(obj,motor)
            midx = find([obj.motors{:}]==motor);
            if isempty(midx)
                error('unknown motor');
            end
            index = obj.motors{midx};
        end
        function out = spi_write_8(obj,type,value)
           out = obj.wr(obj.Aout(3,type,value)); 
        end
        function out = spi_read_8(obj,type)
            out = obj.wr(obj.Aout(3,type,255));
        end
        function out = spi_read_16(obj,type)
            in = obj.wr(obj.Aout(6,type));
            out = obj.us2s(in(5)*2^8+in(6),16);
        end
        function out = spi_read_32(obj,type)
           in = obj.wr(obj.Aout(8,type));
           out = obj.us2s(in(5:8)*2.^[24 16 8 0]',32);
        end
        function out = Aout(obj,spi_length,varargin)
           out = uint8(zeros(1,spi_length));
           out(1) = obj.address;
           for i=1:length(varargin)
              out(i+1)=varargin{i}; 
           end
        end
        function out = wr(obj,Array_out)
%             Array_out
            if isempty(obj.rpi) && isempty(obj.spi)
                error('Missing connection to BrickPi. Run obj.init!')
            end
            in = double(writeRead(obj.spi,Array_out));
            if length(in)>3
                if in(4)~=165
                    errror('somethings wrong')
                end
            end
            out = in;
        end
        
        function delete(obj)
           if ~isempty(obj.spi) && ~isempty(obj.rpi)
               obj.reset_sensors;
               obj.reset_motors;
               obj.set_LED(255);
           end
           disp(['BrickPi: connection to ' obj.ip_addr ' closed.'])
        end

    end
    methods (Static, Access = private)
        function out = us2s(value,bit)
           val_neg = int32(bitget(value,bit));
           out = double(int32(bitset(value,bit,0)) + (-2^(bit-1))*val_neg);
        end
        function out = s2us(value,bit)
            if 0<= value
                out = value;
            elseif value <0
                out = value+2^(bit-1);
            end
        end
    end
end

