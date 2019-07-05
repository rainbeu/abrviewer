classdef ABRData < ExperimentalData
    %ABRData
    %   Class for storage and display of ABR recordings
    
    
    properties (Access = public)
        wave_amp
        wave_lat
    end
    
    properties (Access = protected)
        ABR
        Mic
        time
        parameters
        fs
        filtered_data
        is_switched
    end
    
    properties (Access = protected)
        polarity_switched = false
        filter_updated = true
    end
    
    properties (Access = public)
        filter_order(1, 1) double = 512
        filter_limits(1, 2) double = [300 3000]
        filter_type(1, :) char = 'FIR'
    end
    
    properties (Access = private, Constant = true)
        number_of_wave_peaks(1, 1) double = 5
    end
    
    methods
        
        function obj = ABRData(varargin)
            obj@ExperimentalData(varargin{:});
        end
        
        function delete(obj)
        end
        
    end
    
    methods
        
        function set.filter_order(self, order)
            if order ~= self.filter_order
                self.filter_order = order;
                self.filter_updated = true; %#ok<MCSUP>
            end
        end
        
        function set.filter_limits(self, limits)
            if any(limits ~= self.filter_limits)
                self.filter_limits = limits;
                self.filter_updated = true; %#ok<MCSUP>
            end
        end
        
        function set.filter_type(self, type)
            if ~strcmpi(type, self.filter_type)
                self.filter_type = type;
                self.filter_updated = true; %#ok<MCSUP>
            end
        end
        
    end
    
    methods (Access = public)
        
        function data = get_filtered_data(self)
            if self.filter_updated
                switch upper(self.filter_type)
                    case 'FIR'
                        self.filtered_data = fftfilt(fir1(self.filter_order, self.filter_limits/self.fs*2), [self.ABR; zeros(ceil(self.filter_order/2), size(self.ABR, 2))]);
                        self.filtered_data = self.filtered_data(1+floor(self.filter_order/2):end, :);
                    case 'IIR'
                        %                     [z, p, k] = butter(self.filter_order, self.filter_limits/self.fs*2);
                        %                     [z, p, k] = cheby1(self.filter_order, 1, self.filter_limits/self.fs*2);
                        [z, p, k] = cheby2(self.filter_order, 1, self.filter_limits/self.fs*2);
                        sos = zp2sos(z, p, k);
                        gd = grpdelay(sos, [self.filter_limits(1) exp(mean(log(self.filter_limits))) self.filter_limits(2)], 48000);
                        self.filtered_data = sosfilt(sos, [self.ABR; zeros(round(mean(gd)), size(self.ABR, 2))]);
                        self.filtered_data = self.filtered_data(round(mean(gd))+(1:size(self.ABR, 1)), :);
                end
            end
            data = self.filtered_data;
        end
        
        function mic_data = get_mic_data(self)
            mic_data = self.Mic;
        end
        
        function time = get_time(self)
            time = self.time;
        end
        
        function limits = get_data_limits(self)
            limits = quantile(self.get_filtered_data, [0 1]);
            limits = [min(limits(:)) max(limits(:))];
        end
        
        function robust_std = get_noise_confidence_int(self)
            % 95% confidence interval
            robust_std = 1.96 * median(abs(self.get_filtered_data/0.6745));
        end
        
        function parameters = get_parameters(self)
            parameters = self.parameters;
        end
        
        function restrict_parameters_to(self, parameter_list)
            idx = ismember(self.parameters, parameter_list);
            self.parameters = self.parameters(idx);
            self.ABR    = self.ABR(:, idx);
            self.filter_updated = true;
            self.Mic    = self.Mic(:, idx);
            self.wave_lat = self.wave_lat(idx, :);
            self.wave_amp = self.wave_amp(idx, :);
        end
        
        function [min_freq, max_freq] = set_filter_limits(self, new_filter_limits)
            self.filter_limits = sort(new_filter_limits);
            min_freq = self.filter_limits(1);
            max_freq = self.filter_limits(2);
            self.save_to_file(-1);
        end
        
        function switch_polarity(self, varargin)
            polarity = -1;
            if ~isempty(varargin)
                polarity = sign(varargin{1});
            end
            if ~self.polarity_switched && polarity < 0
                self.ABR = -self.ABR;
                self.is_switched = true;
            end
            if self.polarity_switched && polarity > 0
                self.ABR = -self.ABR;
                self.is_switched = false;
            end
            self.save_to_file(-1);
        end
        
        function polarity_is_switched = is_polarity_switched(self)
            polarity_is_switched = self.is_switched;
        end
        
        function import_from_file(self, file_path)
            
            % check basics
            import_from_file@ExperimentalData(self, file_path);
            
            rawdata = load(file_path);
            
            assert(isstruct(rawdata), 'no data found in data file %s!', file_path);
            assert(all(isfield(rawdata, {'St', 'Avg', 'Mic'})), 'data not valid in data file %s!', file_path);
            assert(all(isfield(rawdata.St, {'StimulusLevelOffsets'})), 'data not valid in data file %s!', file_path);
            
            % constant parameters
            self.fs = rawdata.St.Fs;
            
            % main parameter: level range
            self.parameters = rawdata.St.StimulusLevelOffsets;
            
            % main data
            self.ABR = rawdata.Avg(:, 1:length(self.parameters));
            [~, channel] = max(range(range(rawdata.Mic,1),3));
            self.Mic = squeeze(rawdata.Mic(:, channel, 1:length(self.parameters)));
            
            % optional (pre-analysed) data
            if isfield(rawdata, 'wave_amp')
                self.wave_amp = rawdata.wave_amp;
                self.wave_lat = rawdata.wave_lat;
            else
                self.wave_amp = nan(size(self.ABR, 2), self.number_of_wave_peaks);
                self.wave_lat = nan(size(self.ABR, 2), self.number_of_wave_peaks);
            end
            self.wave_amp(size(self.ABR, 2)+1:end, :) = [];
            self.wave_amp(:, self.number_of_wave_peaks+1:end) = [];
            self.wave_lat(size(self.ABR, 2)+1:end, :) = [];
            self.wave_lat(:, self.number_of_wave_peaks+1:end) = [];
            
            if isfield(rawdata, 'filter_limits')
                self.filter_limits = rawdata.filter_limits;
            else
                self.filter_limits = [300 3000];
            end
            
            if isfield(rawdata, 'is_switched')
                self.is_switched = rawdata.is_switched;
                self.ABR = -self.ABR;
            else
                self.is_switched = false;
            end
            
            % processed
            self.time = (0:size(self.ABR, 1)-1).'/self.fs;
            self.time = self.time - rawdata.Rc.PreTime;
            
            self.set_data_valid(file_path);
            
        end
        
        function save_to_file(self, button_handle)
            % load original data from file into structure and only change
            % additional fields
            rawdata = load(self.file_name);
            
            rawdata.wave_amp = self.wave_amp;
            rawdata.wave_lat = self.wave_lat;
            
            rawdata.filter_limits = self.filter_limits;
            
            rawdata.is_switched = self.is_switched;
            
            % load full data structure to file (with fields as variables)
            save(self.file_name, '-struct', 'rawdata');
            if ~isempty(button_handle) && ishandle(button_handle)
                button_handle.String = 'Save';
            end
        end
       
        function [peak, location] = find_peak(self, condition, start_point, find_max)
            waveform = self.get_filtered_data;
            if condition < 1
                condition = 1;
            end
            if condition > size(waveform, 2)
                condition = size(waveform, 2);
            end
            waveform = waveform(:, condition);
            if find_max 
                [peaks, locations] = findpeaks(waveform, self.time/1e-3);
            else
                [peaks, locations] = findpeaks(-waveform, self.time/1e-3);
                peaks = -peaks;
            end          
            [~, idx] = min(sum(bsxfun(@minus, start_point, [locations(:) peaks(:)]).^2, 2));
            peak = peaks(idx);
            location = locations(idx);
        end
        
        function set_wave(self, peak, location, condition, number, button_handle)
            % prepare NaNs (otherwise will be filled with zeros)
            self.wave_amp(end+1:condition, :) = NaN;
            self.wave_amp(:, end+1:number) = NaN;
            self.wave_lat(end+1:condition, :) = NaN;
            self.wave_lat(:, end+1:number) = NaN;
            
            % write new values
            self.wave_amp(condition, number) = peak;
            self.wave_lat(condition, number) = location;

            self.save_to_file(button_handle);
        end
        
        function print_data_table(self)
            if self.data_is_valid
                fprintf('file name;level;wave number;amplitude / µV; latency / ms;wave number;amplitude / µV; latency / ms;\n');
                for k = 1:length(self.parameters)
                    fprintf('%s;%1.0f;', self.file_name, self.parameters(k));
                    for w = 1:3:size(self.wave_amp, 2)
                        if ~(self.wave_amp(k, w) == 0 && self.wave_lat(k, w) == 0) &&  ~(isnan(self.wave_amp(k, w)) && isnan(self.wave_lat(k, w)))
                            fprintf('%1.0f;%1.3f;%1.03f;', w, self.wave_amp(k, w), self.wave_lat(k, w));
                        else
                            fprintf(';;;');
                        end
                    end
                    if size(self.wave_amp, 2) >= 4
                        ratio = self.wave_amp(k, 4)/self.wave_amp(k, 1);
                        if ~isinf(ratio) && ~isnan(ratio) && ratio ~= 0
                            fprintf(';4:1;%1.03f;', self.wave_amp(k, 4)/self.wave_lat(k, 1));
                        else
                            fprintf(';4:1;;', self.wave_amp(k, 4)/self.wave_lat(k, 1));
                        end
                    end
                    fprintf('\n');
                end
            end
        end
        
    end
    
    methods (Access = private)
    end
    
end
