classdef ABRTrace < handle
    
    properties
        time double
        ABR double
        parameter double
    end
    
    properties (Access = private)
        lineHandle matlab.graphics.primitive.Line
        markerHandles matlab.graphics.primitive.Line
        yOffset double
    end
    
    methods
        
        function obj = ABRTrace(varargin)
        end
        
        function delete(obj)
            delete(obj.lineHandle);
            delete(obj.markerHandles);
            obj.parent.remove(obj);
        end
        
    end
    
    methods (Access = public)
        
        function createGraph(obj)
        end
        
    end
    
end

