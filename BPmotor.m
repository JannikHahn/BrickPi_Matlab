classdef BPmotor
    %BPMOTOR obj = BPmotor(port)
%       port: 1-4 or A-D
    
    properties
        port
    end
    properties (Hidden)
        port_name
    end
    properties (Constant, Hidden)
        names={'A','B','C','D'};
    end
        
    
    methods
        function obj = BPmotor(port)
            %BPMOTOR Construct an instance of this class
            %   Detailed explanation goes here
            if isa(port,'double')
                if port > 4
                    error('invalid number');
                else
                    obj.port = port;
                    obj.port_name =obj.names{port};
                end
            elseif isa(port,'char')
                obj.port = find(ismember(obj.names,upper(port)));
                if isempty(obj.port)
                    error('invalid motor name')
                else
                    obj.port_name = upper(port);
                end
            end
        end
        
        function out = eq(obj1,obj2)
            %METHOD1 Summary of this method goes here
            %   Detailed explanation goes here
            for i=1:length(obj1)
                out(i) = obj1(i).port == obj2.port;
            end
        end
    end
end

