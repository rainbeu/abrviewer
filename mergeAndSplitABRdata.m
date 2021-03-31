function mergeAndSplitABRdata(fileListFile)
    %MERGEANDSPLITABRDATA   Merges and splits single level binaurally (L/R/B) measured ABR threshold files
    %
    %
    % Copyright 2021 Rainer Beutelmann, Universität Oldenburg
    % ABRViewer by Rainer Beutelmann (Universität Oldenburg) is licensed under CC BY-SA 4.0
    %
    
    if ~exist('fileListFile', 'var')
        fileListFile = '';
    end
    
    if isempty(fileListFile) || exist(fileListFile, 'dir')
        
        % ask for files interactively
        
        [files, path] = uigetfile(fullfile(fileListFile, '*.mat'), 'Please select set of files to merge', 'MultiSelect', 'on');
        if isnumeric(path) && isnumeric(files)
            warning('No files selected');
            return
        end
        
        fileList = strcat(path, files(:));
        
    else
        
        % read file list from text file
        setIdx = 1;
        fileIdx = 1;
        fid = fopen(fileListFile, 'r');
        while ~feof(fid)
            textLine = strtrim(fgetl(fid));
            if ~isempty(textLine)
                fileList{fileIdx, setIdx} = textLine;
                fileIdx = fileIdx + 1;
            else
                fileIdx = 1;
                setIdx = setIdx + 1;
            end
        end
        fclose(fid);
        
    end
    
    
    %% basic parameters
    side = {
        'left', 'L'
        'right', 'R'
        'binaural', 'L+R'
        };
    
    %% check
    
    for setIdx = 1:size(fileList, 2)
        
        levelIdx = 0;
        
        for fileIdx = 1:size(fileList, 1)
            
            filename = fileList{fileIdx, setIdx};
            
            if ~isempty(filename)
                
                assert(exist(filename, 'file')==2, 'convertABR:filenotexisting', 'file %s does not exist', filename);
                
                lastgood = filename;
                
                in = load(filename);
                
                assert(isfield(in, 'St'), 'convertABR:invalidstructure', 'not a valid ABR data structure');
                assert(isfield(in.St, 'LevelThreshold'), 'convertABR:invalidstructure', 'not a valid ABR data structure');
%                 assert(in.St.LevelThreshold, 'convertABR:invalidmeasurement', 'not a valid ABR threshold measurement');
%                 assert(~isfield(in.St, 'PresentationType') || strcmp(in.St.PresentationType, 'L/R/B'), 'convertABR:invalidmeasurement', 'not an old threshold measurement - no need to convert');
%                 assert(size(in.Avg, 2) >= 3, 'convertABR:invalidmeasurement', 'incorrect measurement type');

                levels = in.St.Level + in.St.ILD;
                insertIdx = levelIdx + (1:length(levels));                    
                
                for sx = 1:size(side, 1)

                    if sx <= 2
                        itdIdx = sx;
                    else
                        itdIdx = 2 + find(in.St.ITD == 0);
                    end
                    
                    if fileIdx == 1
                        % set first entry
                        out(sx).Hw = in.Hw;
                        out(sx).St = in.St;
                        out(sx).Rc = in.Rc;
                        
                        out(sx).Avg = squeeze(in.Avg(:, itdIdx, :));
                        out(sx).Mic = squeeze(in.Mic(:, :, itdIdx, :));
                        out(sx).AvgC = squeeze(in.AvgC(itdIdx, :));
                        out(sx).MicC = squeeze(in.MicC(itdIdx, :));
                        
                        out(sx).St.Level = 0;
                        out(sx).St.StimulusLevelOffsets = levels;
                        
                        out(sx).St.LevelThreshold = false;
                        out(sx).St.PresentationType      = 'simple binaural';
                        out(sx).St.StimulusSide =  side{sx, 2};
                        out(sx).St.MaskerSide   =  side{sx, 2};
                        
                    else
                        % check match of settings
                        checkABRMatch(in, out(sx));
                        
                        out(sx).Avg(:, insertIdx) = squeeze(in.Avg(:, itdIdx, 1:length(levels)));
                        out(sx).Mic(:, :, insertIdx) = squeeze(in.Mic(:, :, itdIdx, 1:length(levels)));
                        out(sx).AvgC(insertIdx, 1) = squeeze(in.AvgC(itdIdx, 1:length(levels)));
                        out(sx).MicC(insertIdx, 1) = squeeze(in.MicC(itdIdx, 1:length(levels)));                        
                        out(sx).St.StimulusLevelOffsets(insertIdx) = levels;
                    end
                    
                    
                end
                
                levelIdx = max(insertIdx);
                
            end
            
        end
        
        for sx = 1:size(side, 1)
            
            [out(sx).St.StimulusLevelOffsets, order] = sort(out(sx).St.StimulusLevelOffsets);
            out(sx).Avg  = out(sx).Avg(:, order);
            out(sx).Mic  = out(sx).Mic(:, :, order);
            out(sx).AvgC = out(sx).AvgC(order);
            out(sx).MicC = out(sx).MicC(order);
            
            [path,name,ext] = fileparts(lastgood);
            % replace single level with range
            name = regexprep(name,'_[0-9]+dB',sprintf('_%1.0f-%1.0fdB',min(out(sx).St.StimulusLevelOffsets),max(out(sx).St.StimulusLevelOffsets)));
        
            tmp = out(sx);
            fprintf('%s\n', fullfile(path, sprintf('%s_%s%s\n', name, side{sx, 1}, ext)));
            save(fullfile(path, sprintf('%s_%s%s', name, side{sx, 1}, ext)), '-struct', 'tmp');
            
        end
        
    end
