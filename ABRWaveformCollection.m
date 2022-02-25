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
            obj.removeWaveformNr(idx);
        end
        
        function removeWaveformNr(obj, nr)
            for n = 1:length(nr)
                obj.waveforms(nr(n)).setParent([]);
                obj.waveforms(nr(n)) = [];
                nr(nr>nr(nr)) = nr(nr>nr(nr)) - 1; 
            end
        end        
        
        function merge(obj, wfc)
            for n = 1:length(wfc.waveforms)
                if ~ismember(wfc.waveforms(n), obj.waveforms)
                    obj.addWaveform(wfc.waveforms(n));
                end
            end
        end
        
        function purge(obj, wfc)
            toRemove = [];
            for n = 1:length(obj.waveforms)
                if ~ismember(obj.waveforms(n), wfc.waveforms)
                    toRemove = [toRemove; n];
                end
            end
            obj.removeWaveformNr(toRemove);
        end
        
        function labels = getlabels(obj)
            labels = cat(2, obj.waveforms.label);
        end
        
        function parameters = getparameters(obj)
            parameters = cat(2, obj.waveforms.parameter);
        end
        
    end
    
end
