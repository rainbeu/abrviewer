classdef ABRWaveformCollection < handle
    
    properties
        waveforms (:,1) ABRWaveform
    end
    
    methods
        
        function obj = ABRWaveformCollection(varargin)
        end
        
        function delete(obj)
            for n = 1:length(obj.waveforms)
                obj.waveforms(n).setParent([]);
            end
        end
        
    end
    
    methods (Access = public)
        
        function addWaveform(obj, wf)
            wf.setParent(obj);
            obj.waveforms(end+1) = wf;
        end
        
        function removeWaveform(obj, wf)
            idx = find(ismember(obj.waveforms, wf));
            for n = 1:length(idx)
                obj.waveforms(idx(n)).setParent([]);
                obj.waveforms(idx(n)) = [];
            end
        end
        
    end
    
end
