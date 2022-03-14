classdef ABRViewerParamList < ABRViewerBase
%ABRVIEWERPARAMLIST   Displays the averaged waveforms
%
%
% Copyright 2022 Rainer Beutelmann, Universität Oldenburg
% ABRViewer by Rainer Beutelmann (Universität Oldenburg) is licensed under CC BY-SA 4.0
%
    properties (Access = protected)
        figure_tag = 'ABR_viewer_param_display'
    end
    
    properties (Access = private)
        parent (:,1) ABRViewerAvgDisplay
        axes_handle
        label_handle
        param_handle
    end
    
    properties (Access = public)
        debug_mode(1, 1) logical = false
    end
    
    methods
        
        function obj = ABRViewerParamList(varargin)
            p = inputParser;
            p.addParameter('parent', obj.parent);
            p.parse(varargin{:});
            
            obj.parent = p.Results.parent;
        end
        
        function delete(obj)
        end
        
        function updateLists(obj, labels, parameters)
            labels = unique(labels);
            oldLabels = get(obj.label_handle, 'String');
            set(obj.label_handle, 'String', labels);
            if ~isempty(oldLabels)
                set(obj.label_handle, 'Value', find(ismember(labels, oldLabels)));
            else
                set(obj.label_handle, 'Value', 1:length(labels));
            end

            parameters = unique(parameters);
            oldParameters = str2num(get(obj.param_handle, 'String'));
            oldParameters = oldParameters(get(obj.param_handle, 'Value'));
            set(obj.param_handle, 'String', num2str(parameters(:)));
            if ~isempty(oldParameters) && ~all(isnan(oldParameters))
                set(obj.param_handle, 'Value', find(ismember(parameters, oldParameters)));
            else
                set(obj.param_handle, 'Value', 1:length(parameters));
            end
        end
        
        function [labels, parameters] = getSelection(obj)
            labels = string(get(obj.label_handle, 'String'));
            labels = labels(get(obj.label_handle, 'Value'));
            parameters = str2num(get(obj.param_handle, 'String'));
            parameters = parameters(get(obj.param_handle, 'Value'));
        end
        
    end
    
    %% callbacks
    methods (Access = protected)
        
        function the_handle = create_figure_window(obj)
            the_handle = figure('tag', obj.figure_tag, 'units', 'characters', ...
                'position', [167    12   148    43], 'menubar', 'none',  ...
                'WindowButtonDownFcn', @(src, evt)obj.mouse_click_callback(src, evt), ...
                'name', 'ABR Parameter Select');
        end
        
        function create_figure_controls(obj)
            obj.label_handle = uicontrol(obj.figure_handle, 'style', 'listbox', 'units', 'normalized', ...
                'position', [0.05 0.18 0.4 0.76], 'tag', 'list', ...
                'callback', @(src,evt)obj.label_callback(src, evt), 'min', 0, 'max', 2);
            obj.param_handle = uicontrol(obj.figure_handle, 'style', 'listbox', 'units', 'normalized', ...
                'position', [0.55 0.18 0.4 0.76], 'tag', 'list', ...
                'callback', @(src,evt)obj.param_callback(src, evt), 'min', 0, 'max', 2);
            
        end
        
        
    end
    
    methods (Access = private)
        
        function label_callback(obj, src, evt)
            obj.parent.update;
        end

        function param_callback(obj, src, evt)
            obj.parent.update;
        end
        
        function mouse_click_callback(obj, src, evt)
        end
        
    end

    
end


