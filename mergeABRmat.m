function merged = mergeABRmat(files, varargin)
    
    files = string(files);
    splitsides = false;
    savefiles = false;
    
    tags = { 'L_', 'R_', 'B_' };
    sides = { 'L', 'R', 'L+R' };
    
    for k = 2:2:nargin
        switch varargin{k-1}
            case 'split'
                splitsides = varargin{k};
            case 'save'
                savefiles = varargin{k};
            otherwise
                warning('option "%s" not known', varargin{k})
        end
    end
    
    for k = 1:length(files)
        tmp = load(files(k));
        fn = fieldnames(tmp);
        for n = 1:length(fn)
            raw(k).(fn{n}) = tmp.(fn{n});
        end
        L{k} = raw(k).St.ILD;
    end
    
    allLevels = cat(2, L{:});
    if numel(unique(allLevels)) < numel(allLevels)
        error('some levels occur more than once, cannot merge simply');
    end
    allLevels = unique(allLevels);
    
    merged = raw(1);
    merged.St.ILD = allLevels(:).';
    
    for k = 1:length(raw)
        for n = 1:length(raw(k).St.ILD)
            idx = find(allLevels == raw(k).St.ILD(n));
            merged.Avg(:, :, idx)    = raw(k).Avg(:, :, n);
            merged.AvgC(:, idx)      = raw(k).AvgC(:, n);
            merged.Mic(:, :, :, idx) = raw(k).Mic(:, :, :, n);
            merged.MicC(:, idx)      = raw(k).MicC(:, n);
        end
    end
    
    if splitsides
        merged = repmat(merged, size(merged.Avg, 2), 1);
        for k = 1:length(merged)
            merged(k).Avg  = squeeze(merged(k).Avg(:, k, :));
            merged(k).AvgC = squeeze(merged(k).AvgC(k, :));
            merged(k).Mic  = squeeze(merged(k).Mic(:, :, k, :));
            merged(k).MicC = squeeze(merged(k).MicC(k, :));
            merged(k).St.PresentationType = 'simple binaural';
            merged(k).St.StimulusSide = sides{k};
            merged(k).St.StimulusLevelOffsets = merged(k).St.ILD;
        end
    end
    
    if savefiles
        for k = 1:length(merged)
            if splitsides
                tag = tags{k};
            else
                tag = 'LRB_';
            end
            savename = regexprep(files{1}, '[0-9]+-[0-9]+dB', ...
                         sprintf('%s%1.0f-%1.0fdB', tag, min(allLevels), max(allLevels)));
            if strcmp(savename, files{1})
                savename = regexprep(files{1}, '\.mat', ...
                         sprintf('_%s%1.0f-%1.0fdB.mat', tag, min(allLevels), max(allLevels)));
            end
            savename = regexprep(savename, '[0-5][0-9]-[0-5][0-9]\.mat', '-----.mat');
            s = merged(k);
            save(savename, '-struct', 's');
        end
    end
