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
        param_figure_handle (1,1) ABRViewerParamDisplay
    end
    
    properties (Access = private)
        data(:, 1) ABRWaveformCollection
    end
    
    properties (Access = public)
        debug_mode(1, 1) logical = false
    end
    
    methods
        
        function obj = ABRViewerAvgDisplay
        end
        
        function delete(obj)
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
        end
        
        function create_figure_controls(self)
            self.axes_handle = axes('parent', self.figure_handle, ...
                'Box', 'on', 'BoxStyle', 'full');
            self.param_figure_handle = ABRViewerParamDisplay;
        end
        
        
    end
    
    methods (Access = public)
        
        function mouse_click_callback(self, src, evt)

        end
        
    end

    
end


