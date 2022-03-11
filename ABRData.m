classdef ABRData < ExperimentalData
%ABRDATA    Class for ABR data, derived from ExperimentalData 
%
%
% Copyright 2021 Rainer Beutelmann, Universität Oldenburg
% ABRViewer by Rainer Beutelmann (Universität Oldenburg) is licensed under CC BY-SA 4.0
% 
    properties (Access = public)
        % dimensions are: condition (size(ABR,1)), wave nr, pos=1 neg=2
        wave_amp
        wave_lat
        current_thr
    end
    
    properties (Access = public)
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
        filter_method(1, :) char = 'lowess'
        filter_detrend(1, 1) logical = false
        filter_detrend_order(1, 1) double = 2
        threshold_criterion = 0.5
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
        
        function set.filter_method(self, method)
            if ~strcmpi(method, self.filter_method)
                self.filter_method = method;
                self.filter_updated = true; %#ok<MCSUP>
            end
        end
    
        function set.filter_detrend(self, detrend)
            if ~strcmpi(detrend, self.filter_detrend)
                self.filter_detrend = detrend;
                self.filter_updated = true; %#ok<MCSUP>
            end
        end
        
        function set.filter_detrend_order(self, detrend_order)
            if detrend_order ~= self.filter_detrend_order
                self.filter_detrend_order = detrend_order;
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
                    case 'SMOOTH'
                        self.filtered_data = smoothdata(self.ABR, self.filter_method, self.filter_order);
                end
                if self.filter_detrend
                    self.filtered_data = detrend(self.filtered_data, self.filter_detrend_order);
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
            self.wave_lat = self.wave_lat(idx, :, :);
            self.wave_amp = self.wave_amp(idx, :, :);
        end
        
        function [min_freq, max_freq] = set_filter_limits(self, new_filter_limits)
            if ~isempty(new_filter_limits)
                self.filter_limits = sort(new_filter_limits);
            end
            min_freq = self.filter_limits(1);
            max_freq = self.filter_limits(2);
            self.save_to_file(-1);
        end
        
        function set_polarity(self, switch_state)
            if self.is_switched ~= switch_state
                self.ABR = -self.ABR;
%                 fprintf('DEBUG: data switched now\n');
            end
            self.is_switched = switch_state;
            if self.is_switched
%                 fprintf('DEBUG: data in switched state now\n');
            else
%                 fprintf('DEBUG: data in unswitched state now\n');
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
            if ~isfield(rawdata.St, {'PresentationType'}) || strcmp(rawdata.St.PresentationType, 'L/R/B') 
                if isempty(self.data_index) || self.data_index == 0 % ok if data index is specified, otherwise need to loop over indices
                    throw(MException('abrviewer:multilateraldata', '%1.0f', size(rawdata.Avg, 2)));
                end
            end
            if isfield(rawdata.St, {'LevelThreshold'}) && rawdata.St.LevelThreshold
                % main parameter: level range
                self.parameters = rawdata.St.Level + rawdata.St.ILD;
            elseif isfield(rawdata.St, {'StimulusLevelOffsets'})
                % main parameter: level range
                self.parameters = rawdata.St.Level + rawdata.St.StimulusLevelOffsets;
            else
                error('abrviewer:invaliddata', 'data not valid in data file %s!', file_path);
            end
            
            % constant parameters
            self.fs = rawdata.St.Fs;
            
            % main data
            if isempty(self.data_index) || self.data_index == 0
                self.ABR = rawdata.Avg(:, 1:length(self.parameters));
            else % multilateral/ITD type data, pick one side/ITD
                self.ABR = squeeze(rawdata.Avg(:, self.data_index, 1:length(self.parameters)));
                rawdata.Mic = squeeze(rawdata.Mic(:, :, self.data_index, :));
            end
            [~, channel] = max(range(range(rawdata.Mic,1),3));
            self.Mic = squeeze(rawdata.Mic(:, channel, 1:length(self.parameters)));
            
            % optional (pre-analysed) data
            if isfield(rawdata, 'wave_amp')
                self.wave_amp = rawdata.wave_amp;
                self.wave_lat = rawdata.wave_lat;
            else
                self.wave_amp = nan(size(self.ABR, 2), self.number_of_wave_peaks, 2);
                self.wave_lat = nan(size(self.ABR, 2), self.number_of_wave_peaks, 2);
            end
            % cut wave form data array to expected size
            self.wave_amp(size(self.ABR, 2)+1:end, :, :) = [];
            self.wave_amp(:, self.number_of_wave_peaks+1:end, :) = [];
            self.wave_lat(size(self.ABR, 2)+1:end, :, :) = [];
            self.wave_lat(:, self.number_of_wave_peaks+1:end, :) = [];

            % extend waveform data array to expected size, if necessary
            self.wave_amp(:, :, end+1:2) = NaN;
            self.wave_amp(end+1:size(self.ABR, 2), :, 1:2) = NaN;
            self.wave_amp(:, end+1:self.number_of_wave_peaks, 1:2) = NaN;
            self.wave_lat(:, :, end+1:2) = NaN;
            self.wave_lat(end+1:size(self.ABR, 2), :, :) = NaN;
            self.wave_lat(:, end+1:self.number_of_wave_peaks, :) = NaN;
            
            if isfield(rawdata, 'filter_limits')
                self.filter_limits = rawdata.filter_limits;
            else
                self.filter_limits = [300 3000];
            end
            
            % processed
            self.time = (0:size(self.ABR, 1)-1).'/self.fs;
            self.time = self.time - rawdata.Rc.PreTime;
            % find actual stimulus energy maximum instead of relying on saved position
%             [~, smp] = max(max(abs(hilbert(self.Mic)),[],2));
%             self.time = self.time - smp/self.fs;
            
            self.set_data_valid(file_path);
            
            self.is_switched = false;
            if isfield(rawdata, 'is_switched')
                if rawdata.is_switched
%                     fprintf('DEBUG: data needs switching\n');
                else
%                     fprintf('DEBUG: data doesn''t need switching\n');
                end
                self.set_polarity(rawdata.is_switched);
                self.is_switched = rawdata.is_switched;
            else
%                 fprintf('DEBUG: data was never switched\n');
            end            
            
            if isfield(rawdata, 'abr_thr')
                self.current_thr = rawdata.abr_thr;
            else
                self.current_thr = [];
            end
            
        end
        
        function save_to_file(self, display_handle)
            % load original data from file into structure and only change
            % additional fields
            rawdata = load(self.file_name);
            
            rawdata.wave_amp = self.wave_amp;
            rawdata.wave_lat = self.wave_lat;
            rawdata.abr_thr = self.current_thr;
            
            rawdata.filter_limits = self.filter_limits;
            
            rawdata.is_switched = self.is_switched;
            
            % load full data structure to file (with fields as variables)
            save(self.file_name, '-struct', 'rawdata');
            if ~isempty(display_handle) && isa(display_handle,'ABRViewerDisplay')
                display_handle.unmark_save_button;
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
        
        function thr = estimate_threshold(self, display_handle)
            %%%% hier heftig aufräumen!!!
            time_limits = [0.5e-3 4.5e-3];

            waveforms = self.get_filtered_data;
            
            if size(size(waveforms ,2)) >= 3 
                idx = self.time >min(time_limits) & self.time < max(time_limits);
                XC = zeros(2*sum(idx)-1, size(waveforms,2)-1);
                for k = 1:size(waveforms ,2)-1
    %                 CC(k,1) = corr(waveforms(idx,k+1),waveforms(idx,k));
                    [XC(:,k), lg] = xcorr(waveforms(idx,k+1),waveforms(idx,k),'coeff');
                end
                t = lg/self.fs;
                CC = max(-1,max(XC(t>=-0.4e-3&t<=0e-3,:))).';

                L = self.get_parameters;
                L = L(1:end-1);
                L = L(:);

                if length(L) >= 4 
                    ps = lsqcurvefit(@(p,x)p(1)+(p(2)-p(1))./(1+10.^(p(4)*(p(3)-x))),...
                                    [0 1 50 0.1],...
                                    L,...
                                    CC,...
                                    [0 self.threshold_criterion min(L) 0.005],...
                                    [self.threshold_criterion 1 max(L) 0.999],...
                                    optimset('Display','none'));
                    pp = lsqcurvefit(@(p,x)p(1)*x.^p(2)+p(3),...
                                    [1 1 0],...
                                    L,...
                                    CC,...
                                    [0 0 -inf],...
                                    [inf inf inf],...
                                    optimset('Display','none'));

                    fit_sigm = ps(1)+(ps(2)-ps(1))./(1+10.^(ps(4)*(ps(3)-L)));
                    fit_power = pp(1)*L.^pp(2)+pp(3);

                    RMSs = rms(fit_sigm-CC);
                    RMSp = rms(fit_power-CC);
                    R2p = corr((fit_power),(CC))^2;

                    thrs = ps(3)-log10((ps(2)-ps(1))./(self.threshold_criterion-ps(1))-1)/ps(4);
                    thrp = ((self.threshold_criterion-pp(3))/pp(1))^(1/pp(2));

                else % not enough data points

                    ps = nan(1,4);
                    pp = nan(1,4);

                    RMSs = NaN;
                    RMSp = NaN;
                    R2p = NaN;

                    thrs = NaN;
                    thrp = NaN;

                end

    %             figure
    %             subplot(1,5,[1 2 3 4]);
    %             plot(self.time, waveforms+(0:size(self.ABR,2)-1), self.time, 0.5*self.Mic./max(abs(self.Mic))+(0:size(self.ABR,2)-1));
    %             set(gca,'ytick',(0:size(self.ABR,2)-1),'YTickLabel', L);
    %             ylim([-1 size(self.ABR,2)]);
    %             line([1;1]*time_limits, [-1;size(self.ABR,2)],'color','k');
    %             xlim([-0.004 0.015]);
    %             grid on
    %             subplot(1,5,5);
    %             l=(0:100).';
    %             plot(CC,L,'x',...
    %                  ps(1)+(ps(2)-ps(1))./(1+10.^(ps(4)*(ps(3)-l))),l,...
    %                  pp(1)*l.^pp(2)+pp(3),l...
    %                  )
    %             line([self.threshold_criterion 0 0;self.threshold_criterion 1 1],[0 thrs thrp;100 thrs thrp],'color','k','linestyle','--')
    %             ylim([min(L)-10 max(L)+10]);
    %             xlim([0 1]);
    %             grid on
    %             pause
    %             close

                if ps(1) < self.threshold_criterion && ps(2) > self.threshold_criterion && ps(4) > 0.005 && ps(4) < 0.999 && RMSs < RMSp && min(CC) < self.threshold_criterion
                    thr = thrs;
                elseif R2p > 0.7 && max(CC) > self.threshold_criterion
                    thr = thrp;
                else
    %                 ps
    %                 pp
    %                 RMSs
    %                 RMSp
    %                 R2p
                    thr = nan;
                    % or find the threshold by 
                    pre = find(CC<self.threshold_criterion, 1, 'last');
                    if pre == length(L)
                        thr = +Inf;
                    elseif isempty(pre)
                        thr = -Inf;
                    else
                        thr = interp1(CC(pre:pre+1),L(pre:pre+1),self.threshold_criterion);
                    end                
                end

                if thr < min(self.get_parameters) 
                    thr = -Inf;
                elseif thr > max(self.get_parameters)
                    thr = +Inf;
                end

                if isempty(self.current_thr) || thr ~= self.current_thr
                    self.current_thr = thr;
                    if ~isempty(display_handle) && isa(display_handle,'ABRViewerDisplay')
                        display_handle.mark_save_button;
                    end
                end
                self.save_to_file(display_handle);
            else
                thr = NaN;
            end
            
        end        
        
        function set_wave(self, peak, location, condition, number, display_handle, posneg)
            
            % prepare NaNs (otherwise will be filled with zeros)
            self.wave_amp(end+1:condition, :, posneg) = NaN;
            self.wave_amp(:, end+1:number, posneg) = NaN;
            self.wave_lat(end+1:condition, :, posneg) = NaN;
            self.wave_lat(:, end+1:number, posneg) = NaN;
            
            % write new values
            self.wave_amp(condition, number, posneg) = peak;
            self.wave_lat(condition, number, posneg) = location;

            display_handle.mark_save_button;
            self.save_to_file(display_handle);
        end
        
        function fid = print_data_table(self, toFile, fid)
            if toFile
                if isempty(fid)
                    [file, path] = uiputfile('*.csv', 'Select file name for export');
                    if isnumeric(file) && isnumeric(path)
                        return
                    end
                    fid = fopen(fullfile(path, file), 'w');
                end
                if isempty(fid)
                    msgbox(sprintf('Could not open file %s for writing', fullfile(path,file)), 'modal', 'error');
                    return
                end
            else
                fid = 1;
            end
            if self.data_is_valid
                fprintf(fid, 'file name;level;wave number;amplitude / µV; latency / ms;wave number;amplitude / µV; latency / ms;\n');
                for k = 1:length(self.parameters)
                    fprintf(fid, '%s;%1.0f;', self.file_name, self.parameters(k));
                    for posneg = 1:2
                        for w = 1:size(self.wave_amp, 2)
                            if ~(self.wave_amp(k, w, posneg) == 0 && self.wave_lat(k, w, posneg) == 0) ...
                                    &&  ~(isnan(self.wave_amp(k, w, posneg)) && isnan(self.wave_lat(k, w, posneg)))
                                fprintf(fid, '%1.0f;%1.3f;%1.03f;', w, self.wave_amp(k, w, posneg), self.wave_lat(k, w, posneg));
                            else
                                fprintf(fid, ';;;');
                            end
                        end
                    end
                    if size(self.wave_amp, 2) >= 4
                        ratio = self.wave_amp(k, 4, 1)/self.wave_amp(k, 1, 1);
                        if ~isinf(ratio) && ~isnan(ratio) && ratio ~= 0
                            fprintf(fid, ';P4:P1;%1.03f;', ratio);
                        else
                            fprintf(fid, ';P4:P1;;');
                        end
                    end
                    fprintf(fid, '\n');
                end
            end
        end
        
    end
    
    methods (Access = private)
    end
    
end
