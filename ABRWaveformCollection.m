classdef ABRWaveformCollection < handle
    
    properties
        waveforms (:,1) ABRWaveform
        parent
    end
    
    methods
        
        function obj = ABRWaveformCollection(varargin)
            p = inputParser;
            p.addParameter('parent', obj.parent);
            p.parse(varargin{:});
            
            obj.parent = p.Results.parent;
        end
        
        function delete(obj)
        end
        
    end
    
    methods (Access = public)
        
        function addWaveform(obj, wf)
            wf.setParent(obj);
            obj.waveforms(end+1) = wf;
        end
        
        function removeWaveform(obj, wf)
            obj.removeWaveformNr(find(ismember(obj.waveforms, wf)));
        end
        
        function removeWaveformNr(obj, nr)
            for n = 1:length(nr)
                if isvalid(obj.waveforms(nr(n)))
                    obj.waveforms(nr(n)).setParent([]);
                end
            end
            obj.waveforms(nr) = [];
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
            if ~isempty(toRemove)
                obj.removeWaveformNr(toRemove);
            end
        end
        
        function labels = getlabels(obj)
            labels = cat(2, obj.waveforms.label);
        end
        
        function parameters = getparameters(obj)
            parameters = cat(2, obj.waveforms.parameter);
        end
        
        function updateWaveforms(obj, labels, parameters)
            obj.setSpacing(1);
            for n = 1:length(obj.waveforms)
                if    ismember(obj.waveforms(n).label, labels) ...
                   && ismember(obj.waveforms(n).parameter, parameters)
                    obj.waveforms(n).updateGraph;
                    obj.waveforms(n).switchGraph(true);
                else
                    obj.waveforms(n).switchGraph(false);
                end
            end
        end
        
        function hax = getAxes(obj)
            if isempty(obj.parent) || ~isvalid(obj.parent)
                hax = gca;
            else
                hax = obj.parent.getAxes;
                if isempty(hax)
                    hax = gca;
                end
            end
        end
        
        function setSpacing(obj, ratio)
            parameters = obj.getparameters;
            P = unique(parameters);
            step = 0;
            ticks = [];
            for n = length(P):-1:1
                idx = find(ismember(parameters, P(n)));
                mx = 0;
                for k = 1:length(idx)
                    mx = max(mx, obj.waveforms(idx(k)).setOffset(step));
                end
                ticks(n) = step;
                step = step - ratio * mx;
            end
            obj.parent.setTicks(P, ticks);
        end
        
    end
    
end
