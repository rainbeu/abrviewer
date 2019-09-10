classdef ABRViewerDisplay < ABRViewerBase
    %ABRViewerDisplay
    %
    
    properties (Access = protected)
        figure_tag = 'ABR_viewer_display'
    end
    
    properties (Access = private)
        axes_handle
        switch_handle
        slider_handle
        mic_handle
        save_handle
        minfreq_handle
        maxfreq_handle
        legend_handles
    end
    
    properties (Access = private)
        data(:, 1) ABRData
        flags(1, :) cell = {'marker'}
        parameters(1, :) double
        offsets(1, :) double
        spread(1, 1) double = 1
        max_abr(1, 1) double = 1
        mic_scale(1, 1) double = 1
        point_offset(1, 1) double = 0
        marker_size(1, 1) double = 6
        main_entry(1, 1) double
    end
    
    properties (Access = public)
        debug_mode(1, 1) logical = false
    end
    
    methods
        
        function obj = ABRViewerDisplay
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
            the_handle = figure('tag', 'ABR viewer', 'units', 'characters', ...
                'position', [330.14  11.125  126.71  62.312], 'menubar', 'none',  ...
                'WindowButtonDownFcn', @(src, evt)self.mouse_click_callback(src, evt), ...
                'name', 'ABR Display');
        end
        
        function create_figure_controls(self)
            self.axes_handle = axes('parent', self.figure_handle);
            self.switch_handle = uicontrol(self.figure_handle, 'style', 'togglebutton', 'units', 'normalized', ...
                'position', [0.025 0.025 0.15 0.05], 'tag', 'switch', 'string', 'switch +/-',...
                'callback', @(src,evt)self.callback('switch', src, evt), 'value', 1);
            uicontrol(self.figure_handle, 'style', 'pushbutton', 'units', 'normalized', ...
                'position', [0.825 0.025 0.15 0.05], 'tag', 'pdf', 'string', 'PDF',...
                'callback', @(src,evt)self.callback('pdf', src, evt));
            self.slider_handle = uicontrol(self.figure_handle, 'style', 'slider', 'units', 'normalized', ...
                'position', [0.2 0.0375 0.6 0.025], 'tag', 'offset', 'string', 'offset',...
                'callback', @(src,evt)self.callback('update', src, evt), 'Min', 0.001, 'Max', 10, 'Value', 1);
            self.mic_handle = uicontrol(self.figure_handle, 'style', 'togglebutton', 'units', 'normalized', ...
                'position', [0.025 0.935 0.10 0.05], 'tag', 'mic', 'string', 'Mic on/off',...
                'callback', @(src,evt)self.callback('miconoff', src, evt), 'value', 0);
            self.save_handle = uicontrol(self.figure_handle, 'style', 'pushbutton', 'units', 'normalized', ...
                'position', [0.155 0.935 0.13 0.05], 'tag', 'save', 'string', 'Save',...
                'callback', @(src,evt)self.callback('save', src, evt));
            uicontrol(self.figure_handle, 'style', 'text', 'units', 'normalized', ...
                'position', [0.66 0.95 0.04 0.025], 'string', 'Filter:');
            self.minfreq_handle = uicontrol(self.figure_handle, 'style', 'edit', 'units', 'normalized', ...
                'position', [0.7 0.955 0.06 0.025], 'tag', 'minfreq', 'string', '300',...
                'callback', @(src,evt)self.frequency_callback);
            uicontrol(self.figure_handle, 'style', 'text', 'units', 'normalized', ...
                'position', [0.76 0.95 0.04 0.025], 'string', '-');
            self.maxfreq_handle = uicontrol(self.figure_handle, 'style', 'edit', 'units', 'normalized', ...
                'position', [0.8 0.955 0.06 0.025], 'tag', 'maxfreq', 'string', '3000',...
                'callback', @(src,evt)self.frequency_callback);
            uicontrol(self.figure_handle, 'style', 'text', 'units', 'normalized', ...
                'position', [0.86 0.95 0.04 0.025], 'string', 'Hz');
            %             uicontrol(self.figure_handle, 'style', 'togglebutton', 'units', 'normalized', ...
            %                 'position', [0.15 0.935 0.10 0.05], 'tag', 'overlay', 'string', 'Overlay',...
            %                 'callback', @(src,evt)self.callback('overlay', src, evt));
            %             uicontrol(self.figure_handle, 'style', 'pushbutton', 'units', 'normalized', ...
            %                 'position', [0.26 0.935 0.10 0.05], 'tag', 'clearovl', 'string', 'Clear Overlay',...
            %                 'callback', @(src,evt)self.callback('clearovl', src, evt));
        end
        
        
    end
    
    %% callbacks
    methods (Access = public)
        
        function mouse_click_callback(self, src, evt)
            if ishandle(self.axes_handle)
                click_position = get(self.axes_handle, 'CurrentPoint');
                click_x = click_position(1, 1);
                click_y = click_position(1, 2);
                if self.debug_mode
                    hl = line(click_x,click_y,'marker','o','color','g');
                end
                line_handles = findall(self.axes_handle, 'type', 'line', 'Tag', 'ABR');
                Xdata = get(line_handles, 'xdata');
                Ydata = get(line_handles, 'ydata');
                if ~isempty(Xdata) && ~isempty(Ydata)
                    if iscell(Xdata) && iscell(Ydata)
                        distance = cellfun(@(x,y)(x - click_x).^2 + (y - click_y).^2, ...
                            Xdata, Ydata, 'UniformOutput', false);
                    else
                        distance = { (x - click_x).^2 + (y - click_y).^2 };
                    end
                    minimal_distance = cellfun(@min, distance);
                    [~, nearest_line] = min(minimal_distance);
                    if self.debug_mode
                        set(line_handles(nearest_line), 'linewidth', 2);
                    end
                    if ~strcmp(get(line_handles(nearest_line), 'Marker'), 'none')
                        self.check_marker_delete(get(line_handles(nearest_line), 'UserData'), [click_x click_y]);
                    else
                        self.process_peaks(get(line_handles(nearest_line), 'UserData'), [click_x click_y]);
                    end
                    if self.debug_mode
                        if ~isempty(hl) && ishandle(hl)
                            delete(hl);
                        end
                        if isvalid(line_handles(nearest_line))
                            set(line_handles(nearest_line), 'linewidth', 0.5);
                        end
                    end
                    self.update;
                    % self.plot_legend;
                end
            end
        end
        
        function callback(self, command, src, evt)
            do_update = false;
            switch command
                case 'update'
                    do_update = true;
                case 'miconoff'
                    if get(self.mic_handle, 'Value')
                        self.flags = union(self.flags, 'mic');
                    else
                        self.flags = setdiff(self.flags, 'mic');
                    end
                    do_update = true;
                case 'switch'
                    self.switch_data;
                    do_update = true;
                case 'pdf'
                    self.pdf_callback;
                case 'save'
                    self.data(self.main_entry).save_to_file(self.save_handle);
                otherwise
                    warning('callback %s not yet implemented', command);
            end
            if do_update
                self.update;
            end
        end
        
        function frequency_callback(self)
            min_freq = str2double(get(self.minfreq_handle, 'String'));
            max_freq = str2double(get(self.maxfreq_handle, 'String'));
            for idx = 1:length(self.data)
                [min_freq, max_freq] = self.data(idx).set_filter_limits([min_freq, max_freq]);
            end
            set(self.minfreq_handle, 'String', sprintf('%1.0f', min_freq));
            set(self.maxfreq_handle, 'String', sprintf('%1.0f', max_freq));
            self.update;
        end
        
        function pdf_callback(self)
            answer = questdlg('Save all to PDF?', 'Question', 'All', 'Single', 'Cancel', 'All');
            if strcmp(answer, 'Cancel')
                return;
            end
            if strcmp(answer, 'Single')
                answer = inputdlg('Please enter levels', 'Wave selection', 1, cellstr(sprintf('%1.0f ', self.parameters)));
                answer = replace(answer{1}, ',', ' ');
                answer = replace(answer, '.', ' ');
                answer = replace(answer, '[', ' ');
                answer = replace(answer, ']', ' ');
                level_choice = intersect(self.parameters, sscanf(answer, '%f'));
            else
                level_choice = self.parameters;
            end
            hf = figure;
            ha = axes;
            pdfdata = copy(self.data);
            file_title = {};
            for k = 1:length(pdfdata)
                pdfdata(k).restrict_parameters_to(level_choice);
                [~, file_title{k}] = fileparts(pdfdata(k).file_name);
            end
            file_title = file_title([self.main_entry setdiff(1:end, self.main_entry)]);
            
            axes_saved = self.axes_handle;
            data_saved = self.data;
            self.axes_handle = ha;
            self.data = pdfdata;
            
            self.update;
            xlabel('time / ms');
            ylabel('sound level / dB SPL');
            title_string = sprintf('%s\n', file_title{:});
            title(title_string(1:end-1));
            print(hf, replace(pdfdata(self.main_entry).file_name, '.mat', '.pdf'), '-dpdf', '-fillpage');
            close(hf);
            
            self.data = data_saved;
            self.axes_handle = axes_saved;
            self.update;
        end
        
    end
    
    %% interface methods
    methods (Access = public)
        
        function update_data(self, data, main_data)
            if ~isempty(data)
                self.data = data;
                self.main_entry = main_data;
                self.update;
                self.switch_handle.Value = self.data.is_polarity_switched;
            end
        end
        
        function update(self)
            self.prepare_plot;
            
            for idx = 1:length(self.data)
                if any(ismember(self.flags, 'mic'))
                    self.plot_mic(idx);
                end
                self.plot_abr(idx, idx == self.main_entry);
            end
            
            self.plot_annotations;
            self.calculate_plot_dimensions;
            
            for idx = 1:length(self.data)
                if any(ismember(self.flags, 'marker'))
                    self.plot_marker(idx);
                end
            end
            self.draw_ratio;
            
            plot_legend(self);
        end
        
    end
    
    methods (Access = protected)
        
        function prepare_plot(self)
            cla(self.axes_handle);
            self.parameters = [];
            self.legend_handles = [];
            self.max_abr = 0;
            max_mic = 0;
            for idx = 1:length(self.data)
                self.parameters = union(self.parameters, self.data(idx).get_parameters);
                self.max_abr = max(self.max_abr, max(max(abs(self.data(idx).get_filtered_data))));
                max_mic = max(max_mic, max(max(abs(self.data(idx).get_mic_data))));
            end
            self.spread = get(self.slider_handle, 'Value');
            self.offsets = (0:length(self.parameters)-1) * self.spread * self.max_abr;
            self.mic_scale = self.max_abr/max_mic;
            set(self.axes_handle, 'NextPlot', 'add');
        end
        
        function plot_abr(self, idx, is_main)
            params = self.data(idx).get_parameters;
            pos = ismember(self.parameters, params);
            time = self.data(idx).get_time;
            ABR = self.data(idx).get_filtered_data;
            hp = plot(self.axes_handle, time/1e-3, ABR + self.offsets(pos));
            [~, order] = sort(cellfun(@mean, get(hp, 'YData')));
            hp = hp(order);
            cmap = squeeze(hsv2rgb((0:length(hp)-1).'/length(hp),1*ones(length(hp),1),0.7*ones(length(hp),1)));
            for k = 1:length(hp)
                set(hp(k), 'UserData', [idx k], 'Tag', 'ABR', 'Color', cmap(k, :));
            end
            if is_main
                set(hp, 'linestyle', '-');
            else
                switch idx
                    case 1
                        set(hp, 'linestyle', ':');
                    case 2
                        set(hp, 'linestyle', '--');
                    case 3
                        set(hp, 'linestyle', '-.');
                end
            end
            if ~isempty(hp)
                self.legend_handles = cat(1, self.legend_handles, hp(1));
            end
        end
        
        function plot_marker(self, idx)
            params = self.data(idx).get_parameters;
            pos = find(ismember(self.parameters, params));
%             main_data = self.data(self.main_entry);
            main_data = self.data(idx);
            noise_ci = main_data.get_noise_confidence_int;
            for wave_nr = 1:min(size(main_data.wave_amp, 2), size(main_data.wave_lat, 2))
                n_waveforms = min(size(main_data.wave_amp, 1), size(main_data.wave_lat, 1));
                cmap = squeeze(hsv2rgb((0:n_waveforms-1).'/n_waveforms,1*ones(n_waveforms,1),0.7*ones(n_waveforms,1)));
                for cond = 1:n_waveforms
                    amplitude = main_data.wave_amp(cond, wave_nr);
                    latency = main_data.wave_lat(cond, wave_nr);
                    
                    if ~isnan(amplitude) && ~isnan(latency) && (amplitude ~= 0 || latency ~= 0)
                        hl = line(latency, amplitude + self.point_offset + self.offsets(pos(cond)), ...
                            'color', cmap(cond, :), 'MarkerSize', self.marker_size, ...
                            'marker', 'v', 'parent', self.axes_handle, 'Tag', 'ABR');
                        if abs(amplitude) > noise_ci(cond)
                            set(hl, 'MarkerFaceColor', cmap(cond, :));
                        else
                            set(hl, 'MarkerFaceColor', 'none');
                        end         
                        switch idx
                            case 1
                                set(hl, 'Marker', 'v');
                                text(latency, amplitude + 1.5*self.point_offset + self.offsets(pos(cond)), ...
                                    num2str(wave_nr), ...
                                    'color', 'r', 'horizontalalignment', 'center', ...
                                    'verticalalignment', 'bottom', 'parent', self.axes_handle);
                            case 2
                                set(hl, 'Marker', '+', 'MarkerSize', 8, 'Linewidth', 1.5);
                            case 3
                                set(hl, 'Marker', 'x', 'MarkerSize', 8, 'Linewidth', 1.5);
                        end
                    end
                end
            end
        end
        
        function draw_ratio(self)
            main_data = self.data(self.main_entry);
            amps = main_data.wave_amp;
            lats = main_data.wave_lat;
            for idx = 1:size(amps, 1)
                if size(amps, 2) >= 4
                    ratio = amps(idx, 4) ./ amps(idx, 1);
                    if ~isinf(ratio) && ~isnan(ratio)
                        text(mean([lats(idx,1), lats(idx,4)]), self.offsets(idx) + amps(idx, 1)/2, sprintf('%1.3f', ratio), ...
                            'horizontalalignment', 'center', 'verticalalignment', 'bottom', ...
                            'fontsize', 8, 'parent', self.axes_handle);
                    end
                end
            end
        end
        
        function plot_mic(self, idx)
            params = self.data(idx).get_parameters;
            pos = ismember(self.parameters, params);
            time = self.data(idx).get_time;
            mic = self.data(idx).get_mic_data;
            plot(self.axes_handle, time/1e-3, mic * self.mic_scale + self.offsets(pos), 'color', [0.6 0.6 0.6]);
        end
        
        function plot_annotations(self)
            main_data = self.data(self.main_entry);
            set(self.axes_handle, 'ytick', self.offsets, 'yticklabel', main_data.get_parameters, ...
                'xtick', -1:9, 'xlim', [-2 10], ...
                'ylim', [0 +1]*max(self.offsets)+[-1.5 1.5].*max(abs(main_data.get_data_limits)), ...
                'xgrid', 'on', 'ygrid', 'on');
            [~, file_name_only] = fileparts(main_data.file_name);
            title(self.axes_handle, file_name_only, 'interpreter', 'none');
            line(bsxfun(@plus, [-1;-1], -0.05*(0:length(self.offsets)-1)), bsxfun(@plus, [0;1], self.offsets), ...
                'color', 'k', 'linewidth', 2, 'parent', self.axes_handle);
            line([-2;12], reshape([-1;-1;1;1]*main_data.get_noise_confidence_int+repmat(self.offsets,4,1),2,[]), ...
                'color', [0.9 0.9 0.9], 'parent', self.axes_handle);
            text(-1.1, 0.5, '1µV', 'horizontalalignment', 'right', 'verticalalignment', 'bottom', ...
                'fontsize', 8, 'parent', self.axes_handle);
        end
        
        function plot_legend(self)
            tmp = regexp({self.data.file_name},'-[0-9]+_([_A-Za-z0-9 ]+).mat','tokens');
            if length(self.legend_handles) > 1
                legend(self.legend_handles, cellfun(@(x)x{1},tmp,'UniformOutput',true), 'Interpreter', 'none');
            else
                delete(findall(self.figure_handle, 'type', 'legend'));
            end
        end
        
        function calculate_plot_dimensions(self)
            set(self.axes_handle, 'Units', 'Points');
            pos = get(self.axes_handle, 'Position');
            set(self.axes_handle, 'Units', 'Normalized');
            limits = get(self.axes_handle, 'YLim');
            self.point_offset = self.marker_size/2 / pos(4) * (limits(2)-limits(1));
        end
        
        function check_marker_delete(self, line_number, start_point)
            main_data = self.data(self.main_entry);
            [mn, cond_idx] = min((main_data.wave_amp-(start_point(2)-self.offsets(8))).^2+(main_data.wave_lat-start_point(1)).^2);
            [~, wave_idx] = min(mn);
            cond_idx = cond_idx(wave_idx);
            answer = questdlg('Delete Marker?', 'Question', 'Yes', 'No', 'All', 'No');
            if strcmp(answer, 'Yes')
                self.save_handle.String = '* Save *';
                main_data.wave_lat(cond_idx, wave_idx) = NaN;
                main_data.wave_amp(cond_idx, wave_idx) = NaN;
                main_data.save_to_file(self.save_handle);
            elseif strcmp(answer, 'All')
                main_data.wave_lat(:, :) = NaN;
                main_data.wave_amp(:, :) = NaN;
            end
            self.update;
        end
        
        function process_peaks(self, line_number, start_point)
            if line_number(1) > 0 && line_number(1) <= length(self.data)
                if line_number(2) > 0 && line_number(2) <= length(self.offsets)
                    answer = questdlg('Maximum or minimum?', 'Question', 'Maximum', 'Minimum', 'Cancel', 'Maximum');
                    if strcmp(answer, 'Maximum')
                        find_max = true;
                    else
                        find_max = false;
                    end
                    if ~strcmp(answer, 'Cancel')
                        answer = questdlg('Assign wave number...', 'Question', '1', '4', '1');
                        wave_number = str2double(answer);
                        while line_number(2) > 0
                            [peak, location] = self.data(line_number(1)).find_peak(line_number(2), start_point - [0 self.offsets(line_number(2))], find_max);
                            hl = line(location, peak + self.offsets(line_number(2)), 'color', 'r', 'marker', 'v');
                            answer = questdlg('Use this peak?', 'Question', 'Yes', 'No', 'Yes');
                            if strcmp(answer, 'No')
                                delete(hl);
                                return
                            else
                                % save wave data
                                if self.debug_mode
                                    fprintf('idx: %1.0f, number: %1.0f, wave_number: %1.0f, peak: %1.1f, location: %1.1f\n', line_number, wave_number, peak, location);
                                end
                                self.save_handle.String = '* Save *';
                                self.data(line_number(1)).set_wave(peak, location, line_number(2), wave_number, self.save_handle);
                            end
                            line_number(2) = line_number(2) - 1;
                            if line_number(2) > 0
                                start_point = [location, peak] + [0 self.offsets(line_number(2))];
                            end
                        end
                    end
                end
            end
        end
        
    end
    
    methods (Access = private)
        
        function switch_is_on = switch_is_on(self)
            switch_is_on = get(self.switch_handle, 'Value');
        end
        
        function switch_data(self)
            for idx = 1:length(self.data)
                self.data(idx).switch_polarity;
            end
        end
        
    end
    
end


