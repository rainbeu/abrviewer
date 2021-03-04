classdef ExperimentalData < matlab.mixin.Copyable
%EXPERIMENTALDATA   Base class for generic experimental data
%
%
% ABRViewer by Rainer Beutelmann, Universität Oldenburg is licensed under CC BY-SA 4.0
% 

    properties (Access = public)
        file_name
        data_index
    end
    
    methods
        
        function obj = ExperimentalData(varargin)
            if nargin > 0
                if nargin >= 2
                    obj.data_index = varargin{2};
                end
                obj.import_from_file(varargin{1});
            end
        end
        
    end
    
    methods (Access = public)
        
        function import_from_file(self, file_path)
            assert(~isempty(file_path), 'no file name specified for import!');
            assert(2 == exist(file_path, 'file'), 'data file %s notfound!', file_path);
            self.file_name = [];
        end
        
        function isvalid = data_is_valid(self)
            isvalid = ~isempty(self.file_name);
        end
        
    end

    methods (Access = protected)
        
        function set_data_valid(self, file_path)
            if ~isempty(file_path)
                self.file_name = file_path;
            end
        end
        
    end
    
end

