classdef wavequestdlg < handle
%WAVEQUESTDLG   Asks for ABR wave number (to tag waveform amplitude/latency)
%
%
% Copyright 2021 Rainer Beutelmann, Universität Oldenburg
% ABRViewer by Rainer Beutelmann (Universität Oldenburg) is licensed under CC BY-SA 4.0
% 

    properties (GetAccess = public, SetAccess = private)
        number = NaN
    end
    
    properties (Access = private)
        dialogHandle
        textHandle matlab.ui.control.UIControl
        buttonHandles matlab.ui.control.UIControl
    end
    
    methods (Access = public)
        
        function obj = wavequestdlg(varargin)
            if nargin > 0
                fig = varargin{1};
                units = get(fig, 'Units');
                set(fig, 'Units', 'characters');
                pos = get(fig, 'Position');
                set(fig, 'Units', units);
                pos(1) = pos(1) + max(0, (pos(3)-50)*2/3);
                pos(2) = pos(2) + max(0, (pos(4)-10)/2);
            end
            obj.dialogHandle = dialog('ButtonDownFcn', @(s,e)obj.callback(s,e), ...
                'Units', 'characters', 'Position', [pos(1:2) 50 10], ...
                'WindowStyle', 'modal', 'Visible', 'off');
            obj.textHandle = uicontrol('Style', 'text', 'Parent', obj.dialogHandle , ...
                'String' ,'Assign wave number...', ...
                'HorizontalAlignment', 'center', ...
                'FontSize', 14, ...
                'Units', 'normalized', 'Position', [0.05 0.6 0.9 0.2]);
            for nr = 1:5
                obj.buttonHandles(nr) = uicontrol('Parent', obj.dialogHandle, ...
                    'String', num2str(nr), 'Callback', @(s,e)obj.callback(s,e), ...
                    'FontSize', 14, ...
                    'Units', 'normalized', 'Position', [0.05+(nr-1)*0.185 0.1 0.16 0.4]);
            end
        end
        
        function show(obj)
            obj.dialogHandle.Visible = 'on';
            movegui(obj.dialogHandle, 'onscreen');
            uiwait(obj.dialogHandle);
        end
        
        function delete(obj)
            if isvalid(obj.dialogHandle)
                delete(obj.dialogHandle);
            end
        end
        
    end
    
    methods (Access = private)
        
        function callback(obj, src, evt)
            if isa(src, 'matlab.ui.control.UIControl') && strcmp(src.Style, 'pushbutton')
                obj.number = str2double(src.String);
            end
            delete(obj.dialogHandle);
        end
        
    end
    
end
