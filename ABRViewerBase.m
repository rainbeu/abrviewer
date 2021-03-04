classdef ABRViewerBase < handle
%ABRVIEWERBASE  Base class for ABRViewerList and ABRViewerDisplay
%
%
% ABRViewer by Rainer Beutelmann (Universität Oldenburg) is licensed under CC BY-SA 4.0
%  
    properties (Abstract = true, Access = protected)
        figure_tag
    end
        
    properties (Access = protected)
        figure_handle
    end
    
    methods
        
        function obj = ABRViewerBase
            % create figure window (is done automatically)
            % and figure controls
            obj.create_figure_controls;
        end

        function delete(obj)
            delete(obj.figure_handle);
        end
        
    end
    
    methods
        
        function the_handle = get.figure_handle(self)
            if ~isempty(self.figure_handle) && isgraphics(self.figure_handle)
                % figure already exists and handle is valid
                the_handle = self.figure_handle;
                return
            else
                % figure handle is unkown, check for non-connected figure
                the_handle = findall(0, 'tag', self.figure_tag);
                if isempty(the_handle) || ~isgraphics(the_handle)
                    % no other figure exists, create new one
                    if ishandle(the_handle)
                        delete(the_handle);
                    end
                    the_handle = create_figure_window(self);
                end
                self.figure_handle = the_handle;
            end
        end
        
        function position = get_figure_position(self)
            position = self.figure_handle.Position;
        end
        
        function set_figure_position(self, position)
            self.figure_handle.Position = position;
        end
        
    end
    
    methods (Abstract = true, Access = protected)
        the_handle = create_figure_window(self)
        create_figure_controls(self)
    end
    
end
