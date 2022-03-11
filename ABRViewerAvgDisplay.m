classdef ABRViewerAvgDisplay < ABRViewerBase
%ABRVIEWERAVGDISPLAY   Displays the averaged waveforms
%
%
% Copyright 2022 Rainer Beutelmann, Universität Oldenburg
% ABRViewer by Rainer Beutelmann (Universität Oldenburg) is licensed under CC BY-SA 4.0
%
    properties (Access = protected)
        figure_tag = 'ABR_viewer_avg_display'
    end
    
    properties (Access = private)
        axes_handle
        param_figure_handle (:,1) ABRViewerParamList
        wfcoll (:,1) ABRWaveformCollection
    end
    
    properties (Access = private)
        data(:, 1) ABRWaveformCollection
    end
    
    properties (Access = public)
        debug_mode(1, 1) logical = false
    end
    
    methods
        
        function obj = ABRViewerAvgDisplay
            obj.wfcoll = ABRWaveformCollection('parent', obj);
            obj.param_figure_handle = ABRViewerParamList('parent', obj);
        end
        
        function delete(obj)
            delete(obj.param_figure_handle);
        end
        
    end
    
    
    
    methods (Access = public)
        
        function updateData(obj, data)
            wfc = ABRWaveformCollection;
            for n = 1:length(data)
                wfc.merge(data(n).getWaveformCollection);
            end
            % add new files
            obj.wfcoll.merge(wfc);
            % remove deselected files
            obj.wfcoll.purge(wfc);
            obj.updateLists;
            obj.updateDisplay;
        end
        
        function hax = getAxes(obj)
            hax = obj.axes_handle;
        end
        
        function update(obj)
            obj.updateDisplay;
        end
        
        function setTicks(obj, params, ticks)
            set(obj.axes_handle, 'YTick', ticks, 'YTickLabel', params);
            set(obj.axes_handle, 'XTick', -100:100);
            set(obj.axes_handle, 'XGrid', 'on', 'YGrid', 'on');
        end
        
    end    
    
    methods
        
        function the_handle = get.axes_handle(self)
            if ~isvalid(self.axes_handle)
                self.create_figure_controls;
            end
            the_handle = self.axes_handle;
        end
        
    end
    
    %% callbacks
    methods (Access = protected)
        
        function the_handle = create_figure_window(self)
            the_handle = figure('tag', self.figure_tag, 'units', 'characters', ...
                'position', [167    12   148    43], 'menubar', 'none',  ...
                'WindowButtonDownFcn', @(src, evt)self.mouse_click_callback(src, evt), ...
                'name', 'ABR Average Display');
            set(the_handle, 'menubar', 'figure');
        end
        
        function create_figure_controls(self)
            self.axes_handle = axes('parent', self.figure_handle, ...
                'Box', 'on', 'BoxStyle', 'full');
            self.param_figure_handle = ABRViewerParamList;
        end
        
        
    end
    
    methods (Access = private)
        
        function mouse_click_callback(self, src, evt)

        end
        
        function updateLists(obj)
            obj.param_figure_handle.updateLists(obj.wfcoll.getlabels, obj.wfcoll.getparameters);
        end
        
        function updateDisplay(obj)
            [labels, parameters] = obj.param_figure_handle.getSelection;
            obj.wfcoll.updateWaveforms(labels, parameters);
        end
        
        
    end

    
end


