classdef ABRViewerList < ABRViewerBase
%ABRVIEWERLIST    Displays the ABRViewer file list
%
%
% Copyright 2021 Rainer Beutelmann, Universität Oldenburg
% ABRViewer by Rainer Beutelmann (Universität Oldenburg) is licensed under CC BY-SA 4.0
%
    properties (Access = protected)
        figure_tag = 'ABR_viewer_list'
        config_file_name = './abrviewer_defaults.mat'
    end
    
    properties (Access = private)
        path_handle
        listbox_handle
        overlay_handle
        previous_handle
        next_handle
        print_handle
        export_handle
        print_thr_handle
        average_handle
    end
    
    properties (Access = private)
        display_window(:, 1) ABRViewerDisplay
        average_window(:, 1) ABRViewerAvgDisplay
        data(:, 1) ABRData
        main_entry(1, 1) double
        inhibit_update (1, 1) logical = false
    end
    
    methods
        
        function obj = ABRViewerList
            % open display window
            obj.display_window = ABRViewerDisplay;
            % initialize stuff
            obj.load_config_file;
            % populate figure window with data
            obj.new_file_list;
        end
        
        function delete(obj)
            obj.save_config_file;
        end
        
    end
    
    %% window layout functions
    methods (Access = protected)
        
        function the_handle = create_figure_window(self)
            the_handle = figure('tag', 'ABR file list', 'units', 'characters', ...
                'position', [ 188    17    55    40], 'menubar', 'none', ...
                'CloseRequestFcn', @(src, evt)self.close_request(src, evt), ...
                'name', 'ABR Viewer');
            set(the_handle, 'UserData', {});
        end
        
        function create_figure_controls(self)
            self.path_handle = uicontrol(self.figure_handle, 'style', 'text', 'units', 'normalized', ...
                'position', [0.05 0.93 0.9 0.05], 'tag', 'path');
            self.listbox_handle = uicontrol(self.figure_handle, 'style', 'listbox', 'units', 'normalized', ...
                'position', [0.05 0.18 0.9 0.76], 'tag', 'list', ...
                'callback', @(src,evt)self.listbox_callback(src, evt), 'min', 0, 'max', 1);
            self.overlay_handle = uicontrol(self.figure_handle, 'style', 'checkbox', 'units', 'normalized', ...
                'position', [0.3 0.13 0.5 0.05], 'tag', 'overlay', ...
                'callback', @(src,evt)self.overlay_callback(src, evt), ...
                'String', 'select for comparison', 'Value', 0);
            self.previous_handle = uicontrol(self.figure_handle, 'style', 'pushbutton', 'units', 'normalized', ...
                'position', [0.05 0.025 0.2 0.1], 'tag', 'prev', 'string', '<', ...
                'callback', @(src,evt)self.previous_callback(src, evt));
            self.next_handle = uicontrol(self.figure_handle, 'style', 'pushbutton', 'units', 'normalized', ...
                'position', [0.75 0.025 0.2 0.1], 'tag', 'next', 'string', '>', ...
                'callback', @(src,evt)self.next_callback(src, evt));
            self.print_handle = uicontrol(self.figure_handle, 'style', 'pushbutton', 'units', 'normalized', ...
                'position', [0.30 0.025 0.1875 0.045], 'tag', 'next', 'string', 'print list', ...
                'callback', @(src,evt)self.print_callback(src, evt));
            self.export_handle = uicontrol(self.figure_handle, 'style', 'pushbutton', 'units', 'normalized', ...
                'position', [0.5125 0.025 0.1875 0.045], 'tag', 'next', 'string', 'export list', ...
                'callback', @(src,evt)self.export_callback(src, evt));
            self.print_thr_handle = uicontrol(self.figure_handle, 'style', 'pushbutton', 'units', 'normalized', ...
                'position', [0.30 0.08 0.1875 0.045], 'tag', 'next', 'string', 'print thresholds', ...
                'callback', @(src,evt)self.print_thr_callback(src, evt));
            self.average_handle = uicontrol(self.figure_handle, 'style', 'togglebutton', 'units', 'normalized', ...
                'position', [0.5125 0.08 0.1875 0.045], 'tag', 'average', 'string', 'average', ...
                'callback', @(src,evt)self.average_callback(src, evt));
        end
    end
    
    %% internal structure functions
    methods (Access = protected)
        
        function new_file_list(self)
            [files, path] = uigetfile(fullfile(self.get_path_name, '*.mat'), ...
                'Select files for analysis', 'MultiSelect', 'on');
            if isnumeric(files) && isnumeric(path)
                return
            end
            set(self.path_handle, 'string', path);
            set(self.listbox_handle, 'string', files);
            set(self.listbox_handle, 'Value', 1);
            self.update_display;
        end
        
        function load_config_file(self)
            if exist(self.config_file_name, 'file')
                config = load(self.config_file_name);
                if isfield(config, 'path_name')
                    set(self.path_handle, 'string', config.path_name);
                end
                if isfield(config, 'list_position')
                    self.set_figure_position(config.list_position);
                end
                if isfield(config, 'display_position')
                    self.display_window.set_figure_position(config.display_position);
                end
                if isfield(config, 'threshold_criterion')
                    self.display_window.set_criterion(config.threshold_criterion);
                end
            else
                warning('default config file (%s) not found', self.config_file_name);
            end
        end
        
        function save_config_file(self)
            config.path_name = get(self.path_handle, 'string');
            config.list_position = self.get_figure_position;
            config.display_position = self.display_window.get_figure_position;
            config.threshold_criterion = self.display_window.get_criterion;
            save(self.config_file_name, '-struct', 'config');
        end
        
        function positions = get_current_positions(self)
            positions = get(self.listbox_handle, 'Value');
        end
        
        function main_data = get_main_position(self)
            positions = self.get_current_positions;
            if length(positions) > 1
                main_data = find(ismember(self.get_current_positions, self.main_entry));
            else
                main_data = 1;
            end
        end
        
        function file_names = get_current_files(self)
            positions = self.get_current_positions;
            file_list = self.get_file_list;
            file_names = file_list(positions);
        end
        
        function file_list = get_file_list(self)
            file_list = cellstr(get(self.listbox_handle, 'String'));
        end
        
        function path_name = get_path_name(self)
            path_name = get(self.path_handle, 'String');
        end
    end
    
    %% display and data logic
    methods (Access = protected)
        
        function load_files(self)
            file_list = self.get_current_files;
            positions = self.get_current_positions;
            for idx = 1:length(positions)
                pos = positions(idx);
                if pos > length(self.data)
                    try
                        self.data(pos) = ABRData(fullfile(self.get_path_name, file_list{idx}));
                    catch exc
                        if strcmp(exc.identifier, 'abrviewer:multilateraldata')
                            [tmpdata, tmpfiles] = self.load_multilateral_files(file_list{idx}, str2double(exc.message));
                            num_sides = length(tmpdata);
                            positions(idx+1:end) = positions(idx+1:end) + num_sides - 1;
                            file_list = self.get_file_list;
                            file_list = cat(1, file_list(1:pos-1,:), tmpfiles, file_list(pos+1:end,:));
                            set(self.listbox_handle, 'String', file_list);
                            set(self.listbox_handle, 'Value', positions);
                            if isempty(self.data)
                                self.data(pos+(0:num_sides-1)) = tmpdata;
                            else
                                self.data = cat(1, self.data(1:pos-1,:), tmpdata, self.data(pos+1:end,:));
                            end
                        else
                            rethrow(exc);
                        end
                    end
                elseif (~self.data(pos).data_is_valid ...
                         || ~strcmp(self.data(pos).file_name, fullfile(self.get_path_name, file_list{idx})))
                     tok = regexp(file_list{idx}, '^(Left|Right|Binaural(?=#))?#?(\d+(?=::))?(?:::)?(.*)','tokens');
                     side = str2num(tok{1}{2});
                     file_name = tok{1}{3};
                     self.data(pos).import_from_file(fullfile(self.get_path_name, file_name));
                end
            end
        end
        
        function [tmpdata, tmpfiles] = load_multilateral_files(self, file_name, num_sides)
            for side = 1:num_sides
                tmpdata(side, 1) = ABRData(fullfile(self.get_path_name, file_name), side);
                switch side
                    case 1
                        prefix = 'Left';
                    case 2
                        prefix = 'Right';
                    otherwise
                        prefix = 'Binaural';
                end
                tmpfiles{side, 1} = sprintf('%s#%1.0f::%s', prefix, side, file_name);
            end
        end
        
        function update_display(self)
            if ~self.inhibit_update
                self.load_files;
                self.display_window.update_data(self.data(self.get_current_positions), self.get_main_position);
                self.display_window.criterion_callback;
            end
        end
        
    end
    
    %% callbacks
    methods (Access = private)
        
        function listbox_callback(self, source, event)
            % only set when single item is selected
            item = get(self.listbox_handle, 'Value');
            if length(item) == 1
                self.main_entry = item;
            end
            self.update_display;
        end
        
        function overlay_callback(self, source, event)
            set(self.listbox_handle, 'Min', 0);
            if get(self.overlay_handle, 'Value')
                set(self.listbox_handle, 'Max', 2);
            else
                set(self.listbox_handle, 'Value', self.main_entry);
                set(self.listbox_handle, 'Max', 1);
            end
            self.update_display;
        end
        
        function previous_callback(self, source, event)
            positions = self.get_current_positions;
            if all(positions > 1)
                set(self.listbox_handle, 'Value', positions - 1);
                self.main_entry = self.main_entry - 1;
                self.update_display;
            end
        end
        
        function next_callback(self, source, event)
            positions = self.get_current_positions;
            if all(positions < length(self.get_file_list))
                set(self.listbox_handle, 'Value', positions + 1);
                self.main_entry = self.main_entry + 1;
                self.update_display;
            end
        end
        
        function print_callback(self, source, event)
            for idx = 1:length(self.data)
                self.data(idx).print_data_table(false, []);
            end
        end
        
        function export_callback(self, source, event)
            fid = [];
            for idx = 1:length(self.data)
                fid = self.data(idx).print_data_table(true, fid);
            end
            if ~isempty(fid)
                fclose(fid);
            end
        end
        
        function print_thr_callback(self, source, event)
            file_list = self.get_file_list;
            fprintf('\n\n');
            fprintf('--- START automatically estimated thresholds ---\n\n');
            fprintf('%s;%s;%s;%s;%s;%s;%s;%s;%s;%s;%s;%s\n', ...
                'filename', ...
                'file date','file time','subject name','side',' stimulus',...
                'min level','max level','est. ABR threshold','high/low','criterion','max W1 amp');
            for idx = 1:length(file_list)
                data = ABRData(fullfile(self.get_path_name, file_list{idx}));
                data.threshold_criterion = self.display_window.get_criterion;
                thr = data.estimate_threshold(self.display_window);
                tokens = regexp(file_list{idx}, 'datafile_(\d{4}-\d{2}-\d{2})-(\d{2}-\d{2}-\d{2})[-_]([^_-]+)[-_]([^_-]+)[-_]([^_-]+).*\.mat', 'tokens');
                if isempty(tokens)
                    tokens{1}={'','','','',''};
                end
                if isinf(thr)
                    if thr > 0 
                        highlow = 'too high';
                    else
                        highlow = 'too low';
                    end
                    thr = '';
                else
                    highlow = '';
                end
                
                if ~isempty(data.wave_amp)
                    max_amp = max(max(abs(data.wave_amp(:,1,:))));
                else
                    max_amp = NaN;
                end
                    
                fprintf('%s;%s;%s;%s;%s;%s;%1.1f;%1.1f;%1.1f;%s;%1.3f;%1.1f\n', ...
                    file_list{idx}, ...
                    tokens{1}{:},...
                    min(data.get_parameters), max(data.get_parameters), ...
                    thr, highlow, data.threshold_criterion, max_amp);
            end
            fprintf('\n\n');
            fprintf('--- END automatically estimated thresholds ---\n\n');
        end
        
        function average_callback(self, source, event)
            if ~get(source, 'Value')
                if ishandle(self.average_window)
                    delete(self.average_window);
                end
                % re-enable other UI elements
                set([self.overlay_handle
                        self.previous_handle
                        self.next_handle
                        self.print_handle
                        self.export_handle
                        self.print_thr_handle], 'Enable', 'on');
                overlay_callback(self, [], []);
                self.inhibit_update = false;
                set(self.listbox_handle, 'Callback', @(src,evt)self.listbox_callback(src, evt));
            else
                % disable other UI elements
                set([self.overlay_handle
                         self.previous_handle
                         self.next_handle
                         self.print_handle
                         self.export_handle
                         self.print_thr_handle], 'Enable', 'on');
                % make multi-selection possible
                self.inhibit_update = true;
                set(self.listbox_handle, 'Callback', @(src,evt)self.average_update_list(src, evt));
                set(self.listbox_handle, 'Min', 0);
                set(self.listbox_handle, 'Value', self.get_main_position);
                set(self.listbox_handle, 'Max', 2);
                % create average display window
                self.average_window = ABRViewerAvgDisplay;
                self.average_update_list([], []);
            end
        end
        
        function average_update_list(self, src, evt)
            item = get(self.listbox_handle, 'Value');
            if length(item) == 1
                self.main_entry = item;
            end
            self.load_files;
            self.average_window.updateData(self.data(self.get_current_positions));
        end
        
        function close_request(self, source, event)
            selection = questdlg('Close ABR viewer?', 'ABR Viewer Message', 'Yes', 'No', 'No');
            switch selection
                case 'Yes'
                    self.delete;
                case 'No'
                    return
            end
        end
        
    end
    
end

