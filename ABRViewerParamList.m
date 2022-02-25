classdef ABRViewerParamDisplay < ABRViewerBase
%ABRVIEWERPARAMDISPLAY   Displays the averaged waveforms
%
%
% Copyright 2022 Rainer Beutelmann, Universität Oldenburg
% ABRViewer by Rainer Beutelmann (Universität Oldenburg) is licensed under CC BY-SA 4.0
%
    properties (Access = protected)
        figure_tag = 'ABR_viewer_param_display'
    end
    
    properties (Access = private)
        axes_handle
        label_handle
        param_handle
    end
    
    properties (Access = public)
        debug_mode(1, 1) logical = false
    end
    
    methods
        
        function obj = ABRViewerParamDisplay
        end
        
        function delete(obj)
        end
        
    end
    
    %% callbacks
    methods (Access = protected)
        
        function the_handle = create_figure_window(self)
            the_handle = figure('tag', self.figure_tag, 'units', 'characters', ...
                'position', [167    12   148    43], 'menubar', 'none',  ...
                'WindowButtonDownFcn', @(src, evt)self.mouse_click_callback(src, evt), ...
                'name', 'ABR Parameter Select');
        end
        
        function create_figure_controls(self)
            self.label_handle = uicontrol(self.figure_handle, 'style', 'listbox', 'units', 'normalized', ...
                'position', [0.05 0.18 0.4 0.76], 'tag', 'list', ...
                'callback', @(src,evt)self.label_callback(src, evt), 'min', 0, 'max', 1);
            self.param_handle = uicontrol(self.figure_handle, 'style', 'listbox', 'units', 'normalized', ...
                'position', [0.55 0.18 0.4 0.76], 'tag', 'list', ...
                'callback', @(src,evt)self.param_callback(src, evt), 'min', 0, 'max', 1);
            
        end
        
        
    end
    
    methods (Access = private)
        
        function label_callback(self, src, evt)
        end

        function param_callback(self, src, evt)
        end
        
        function mouse_click_callback(self, src, evt)
        end
        
    end

    
end


