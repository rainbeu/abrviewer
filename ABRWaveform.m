classdef ABRWaveform < handle
    
    properties
        time double
        ABR double
        parameter double
        label string
        id uint32
    end
    
    properties (Access = private)
        parent ABRWaveformCollection
        lineHandle matlab.graphics.primitive.Line
        markerHandles matlab.graphics.primitive.Line
        yOffset double
    end
    
    methods
        
        function obj = ABRWaveform(varargin)
            p = inputParser;
            p.addParameter('parent', obj.parent);
            p.addParameter('time', obj.time);
            p.addParameter('ABR', obj.ABR);
            p.addParameter('parameter', obj.parameter);
            p.addParameter('label', obj.label);
            p.parse(varargin{:});
            
            obj.parent = p.Results.parent;
            obj.time = p.Results.time;
            obj.ABR = p.Results.ABR;
            obj.parameter = p.Results.parameter;
            obj.label = p.Results.label;
        end
        
        function delete(obj)
            delete(obj.lineHandle);
            delete(obj.markerHandles);
            if ~isempty(obj.parent)
                obj.parent.removeWaveform(obj);
            end
        end
        
        function iseq = eq(A, B)
            if isempty(A) || isempty(B)
                iseq = logical([]);
            else
                iseq = ...
                    ~isempty([A.parameter]) & ~isempty([B.parameter]) ...
                    & ~isempty([A.label]) & ~isempty([B.label]) ...
                    & [A.parameter] == [B.parameter] ...
                    & [A.label] == [B.label];
                iseq = iseq(:);
            end
        end
        
    end
    
    methods (Access = public)
        
        function setParent(obj, parent)
            obj.parent = parent;
        end
        
        function createGraph(obj)
        end
        
    end
    
end

