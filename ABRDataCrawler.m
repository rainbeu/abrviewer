classdef ABRDataCrawler < handle
%ABRDATACRAWLER    Summarizes ABR data in folder hierarchy into Excel file
%
%
% Copyright 2021 Rainer Beutelmann, Universität Oldenburg
% ABRViewer by Rainer Beutelmann (Universität Oldenburg) is licensed under CC BY-SA 4.0
% 
   
    properties
        baseFolder = './'
        currentPath
        currentAllPath
        infoFile = './info.xlsx'
        mainTable
        outFilePath = './ABRsummary.xlsx'
        waveNumbers = [1 4]
        levelList = 90:-10:20
        currentStruct
        fileFrequency = NaN
        fileStimulus = ''
        fileEar = ''
        genotypeList
        animalList
    end
    
    methods
        
        function obj = ABRDataCrawler(varargin)
            p = inputParser;
            p.addParameter('folder', obj.baseFolder, @(x)validateattributes(x, {'string', 'char'}, {'scalartext'}));
            p.addParameter('info', obj.infoFile, @(x)validateattributes(x, {'string', 'char'}, {'scalartext'}));
            p.addParameter('save', obj.outFilePath, @(x)validateattributes(x, {'string', 'char'}, {'scalartext'}));
            p.addParameter('waves', obj.waveNumbers, @(x)validateattributes(x, {'numeric'}, {'integer', 'vector', '>=', 1, '<=', 5}));
            p.parse(varargin{:});
            
            obj.baseFolder = p.Results.folder;
            obj.infoFile = p.Results.info;
            obj.outFilePath = p.Results.save;
            obj.waveNumbers = reshape(unique(p.Results.waves), 1, []);
            
            obj.initMainTable;
            
            obj.genotypeList = lower(cellstr(table2cell(readtable(obj.infoFile, 'FileType', 'spreadsheet', ...
                'ReadVariableNames', false, 'TextType', 'string', ...
                'Sheet', 'genotypes', 'Range', 'A:A'))));
            obj.animalList = lower(cellstr(table2cell(readtable(obj.infoFile, 'FileType', 'spreadsheet', ...
                'ReadVariableNames', false, 'TextType', 'string', ...
                'Sheet', 'animalnames', 'Range', 'A:A'))));
            
        end
        
        function run(obj)
            obj.currentPath = obj.baseFolder;
            obj.resetStructData('all');
            obj.checkGenotype(obj.currentPath); 
        end
        
        function folderList = enumerateSubfolders(~, parentPath)
            folderList = dir(parentPath);
            folderList = folderList([folderList.isdir]);
            folderList = folderList(~strcmp({folderList.name}, '.'));
            folderList = folderList(~strcmp({folderList.name}, '..'));
            folderList = {folderList.name};
        end
        
        function fileList = enumerateMatFiles(~, parentPath)
            fileList = dir(fullfile(parentPath, 'datafile*.mat'));
            fileList = {fileList.name};
        end
        
        function checkGenotype(obj, parentPath)
            folderList = obj.enumerateSubfolders(parentPath);
            for idx = 1:length(folderList)
                if obj.isValidGenotype(folderList{idx})
                    obj.currentStruct(1).genotype = folderList{idx};
                    obj.checkAnimal(fullfile(parentPath, folderList{idx}), true);
                    obj.resetStructData('all');
                else
                    fprintf('skipping non-genotype folder %s\n',folderList{idx});
                end
            end
        end
        
        function checkAnimal(obj, parentPath, goLower)
            folderList = obj.enumerateSubfolders(parentPath);
            for idx = 1:length(folderList)
                if obj.isValidAnimal(folderList{idx})
                    obj.currentStruct(1).animal = folderList{idx};
                    obj.currentStruct(1).age = NaN;
                    obj.currentStruct(1).agegroup = 'none';
                    obj.checkPart(fullfile(parentPath, folderList{idx}));
                    obj.resetStructData('animal');
                elseif goLower
                    fprintf('looking for animals one level below %s\n',folderList{idx});
                    obj.checkAnimal(fullfile(parentPath, folderList{idx}), false);
                end
            end
        end        
       
        function checkPart(obj, parentPath)
            folderList = obj.enumerateSubfolders(parentPath);
            allidx = find(contains(folderList, 'all', 'IgnoreCase', true));
            if ~isempty(allidx)
                obj.currentAllPath = folderList{allidx};
            else
                obj.currentAllPath = '';
            end
            for idx = 1:length(folderList)
                if obj.isValidPart(folderList{idx})
                    obj.checkFiles(fullfile(parentPath, folderList{idx}));
                    obj.resetStructData('part');
                elseif ~strcmp(folderList{idx}, obj.currentAllPath)
                    fprintf('skipping non-part folder %s\n',folderList{idx});
                end
            end
        end        
        
        function checkFiles(obj, parentPath)
            fileList = obj.enumerateMatFiles(parentPath);
            for idx = 1:length(fileList)
                if obj.isValidFileName(fileList{idx})
                    obj.currentStruct(1).path = parentPath;
                    obj.currentStruct(1).filename = fileList{idx};
                    obj.loadFileData(parentPath, fileList{idx}, false);
                    obj.addTableRow;
                    obj.resetStructData('file');
                else
                    fprintf('skipping invalid file %s in %s\n',fileList{idx}, parentPath);
                end
            end
            if isempty(fileList)
                obj.addTableRow;
            end                
        end
        
        function loadFileData(obj, parentPath, fileName, isAlternative)
            tryLoadOtherFile = false;
            thisFile = fullfile(parentPath, fileName);
            if exist(thisFile, 'file')
                try
                    data = load(thisFile);
                catch
                    warning('could not read file %s in %s (not a MAT file)!', fileName, parentPath);
                    data = struct;
                end
                if isnan(obj.currentStruct(1).threshold)
                    if isfield(data, 'abr_thr')
                        obj.currentStruct(1).threshold = data.abr_thr;
                        if isinf(obj.currentStruct(1).threshold)
                            if obj.currentStruct(1).threshold > 0
                                obj.currentStruct(1).threshold = max(obj.levelList) + mean(abs(diff(obj.levelList)));
                            else
                                obj.currentStruct(1).threshold = min(obj.levelList) - mean(abs(diff(obj.levelList)));
                            end
                        end
                        obj.currentStruct(1).path = parentPath;
                    else
%                         fprintf('missing threshold data from %s in %s\n', ...
%                             fileName, parentPath);
                        tryLoadOtherFile = true;
                    end
                end
                % maxlevel = NaN; maxidx = [];
                dataLevels = NaN;
                if isfield(data, 'St')
                    if isfield(data.St, {'LevelThreshold'}) && data.St.LevelThreshold
                        dataLevels = data.St.Level + data.St.ILD;
                    elseif isfield(data.St, {'StimulusLevelOffsets'})
                        dataLevels = data.St.Level + data.St.StimulusLevelOffsets;
                    else
%                         fprintf('missing level steps data from %s in %s\n', ...
%                             fileName, parentPath);
                        tryLoadOtherFile = true;
                    end
                end
                [maxlevel, maxidx] = max(dataLevels);
                if isnan(obj.currentStruct(1).maxlevel)
                    obj.currentStruct(1).maxlevel = maxlevel;
                    obj.currentStruct(1).path = parentPath;
                end
                for l = 1:length(obj.levelList)
                    waveRow = find(dataLevels == obj.levelList(l));
                    if ~isempty(waveRow)
                        obj.currentStruct(1).level(l) = dataLevels(waveRow);
                        for w = obj.waveNumbers
                            if isnan(obj.currentStruct(1).(sprintf('w%1.0f_amplitude', w))(l))
                                if isfield(data, 'wave_amp')
                                    value = data.wave_amp(waveRow, w, 1);
                                    if value == 0; value = NaN; end
                                    obj.currentStruct(1).(sprintf('w%1.0f_amplitude', w))(l) = value;
                                    obj.currentStruct(1).path = parentPath;
                                else
        %                             fprintf('missing wave amplitude data from %s in %s\n', ...
        %                                 fileName, parentPath);
                                    tryLoadOtherFile = true;
                                end
                            end
                            if isnan(obj.currentStruct(1).(sprintf('w%1.0f_latency', w))(l))
                                if isfield(data, 'wave_lat')
                                    value = data.wave_lat(waveRow, w, 1);
                                    if value == 0; value = NaN; end
                                    obj.currentStruct(1).(sprintf('w%1.0f_latency', w))(l) = value;
                                    obj.currentStruct(1).path = parentPath;
                                else
        %                             fprintf('missing wave latency data from %s in %s\n', ...
        %                                 fileName, parentPath);
                                    tryLoadOtherFile = true;
                                end
                            end
                        end
                        obj.currentStruct(1).ratio_4_1(l) = ...
                            obj.currentStruct(1).w4_amplitude(l) ...
                            / ...
                            obj.currentStruct(1).w1_amplitude(l);
                    end
                end
                if isfield(data, 'St')
                    if isfield(data.St, {'Type'}) 
                        obj.currentStruct(1).stimulus = data.St.Type;
                        obj.currentStruct(1).path = parentPath;
                    end
                    if isfield(data.St, {'Frequency'})
                        obj.currentStruct(1).frequency = data.St.Frequency/1e3;
                        if strcmp(obj.currentStruct(1).stimulus, 'click')
                            obj.currentStruct(1).frequency = 0;
                        end
                    end
                    if isfield(data.St, {'PresentationType'}) ...
                             && strcmp(data.St.PresentationType, 'simple binaural') ...
                             && isfield(data.St, {'StimulusSide'})
                        obj.currentStruct(1).ear = data.St.StimulusSide;
                    end
                    obj.currentStruct(1).path = parentPath;
                end
                obj.currentStruct(1).isbestear = false;
            elseif ~isAlternative
                warning('file %s in %s not found!', fileName, parentPath);
            end
            
%             if tryLoadOtherFile
%                 if ~isempty(obj.currentAllPath)
%                     alternativePath = fullfile(fileparts(parentPath), obj.currentAllPath);
%                     if ~strcmp(parentPath, alternativePath)
% %                         fprintf('--> trying to load data from %s (was: %s) for %s\n', ...
% %                             alternativePath, parentPath, fileName);
%                         obj.loadFileData(alternativePath, fileName, true);
%                     end
%                 end
%             end
        end
        
        function resetStructData(obj, resetType)
            if ismember(resetType, {'all'})
                obj.currentStruct(1).genotype = '';
            end

            if ismember(resetType, {'all', 'animal'})
                obj.currentStruct(1).animal = '';
                obj.currentStruct(1).age = NaN;
                obj.currentStruct(1).agegroup = '';
            end

            if ismember(resetType, {'all', 'animal', 'part'})
                obj.currentStruct(1).part = '';
                obj.currentStruct(1).path = '';
            end
            
            if ismember(resetType, {'all', 'animal', 'part', 'file'})
                obj.currentStruct(1).filename = '';
                obj.currentStruct(1).ear = '';
                obj.currentStruct(1).isbestear = false;
                obj.currentStruct(1).frequency = NaN;
                obj.currentStruct(1).stimulus = '';
                obj.currentStruct(1).threshold = NaN;
                obj.currentStruct(1).maxlevel = NaN;
                for l = 1:length(obj.levelList)
                    obj.currentStruct(1).level(l) = NaN;
                    for w = obj.waveNumbers
                        obj.currentStruct(1).(sprintf('w%1.0f_amplitude', w))(l) = NaN;
                        obj.currentStruct(1).(sprintf('w%1.0f_latency', w))(l) = NaN;
                    end
                    obj.currentStruct(1).ratio_4_1(l) = NaN;
                end
            end
        end
        
    end
        
    methods
        
        function checkBestEars(obj)
            for row = 1:height(obj.mainTable)
                obj.mainTable.isbestear(row) = obj.isBestEar(obj.mainTable(row,:));
            end
        end
        
        function isbest = isBestEar(obj, thisRow)
            idx = obj.mainTable.animal == thisRow.animal ...
                    & obj.mainTable.genotype == thisRow.genotype ...
                    & obj.mainTable.part == thisRow.part ...
                    & obj.mainTable.frequency == thisRow.frequency ...
                    & obj.mainTable.stimulus == thisRow.stimulus;
            thresholds = obj.mainTable(idx, :).threshold;
            isbest = thisRow.threshold == min(thresholds);
            if isempty(isbest)
                isbest = false;
            end
        end
        
        function writeTable(obj)
            obj.checkBestEars;
            writetable(obj.mainTable, obj.outFilePath, ...
                       'FileType', 'spreadsheet',  'Sheet', 'ABR summary', ...
                       'WriteVariableNames', true);
        end
        
        function addTableRow(obj)
            if obj.fileFrequency ~= obj.currentStruct(1).frequency ...
                    || ~strcmp(obj.fileStimulus, obj.currentStruct(1).stimulus) ...
                    || ~strcmp(obj.fileEar, obj.currentStruct(1).ear)
                obj.currentStruct(1).mismatch = true;
            else
                obj.currentStruct(1).mismatch = false;
            end
            
            for l = 1:length(obj.levelList)
                tmpStruct = obj.currentStruct(1);
                tmpStruct.level = tmpStruct.level(l);
                for w = obj.waveNumbers
                    tmpStruct.(sprintf('w%1.0f_amplitude', w)) = obj.currentStruct(1).(sprintf('w%1.0f_amplitude', w))(l);
                    tmpStruct.(sprintf('w%1.0f_latency', w)) = obj.currentStruct(1).(sprintf('w%1.0f_latency', w))(l);
                end
                tmpStruct.ratio_4_1 = obj.currentStruct(1).ratio_4_1(l);                
                obj.mainTable = [ obj.mainTable ; struct2table(tmpStruct, 'AsArray', true)];
            end
        end
        
    end
        
    methods
        
        function valid = isValidGenotype(obj, genotype)
            valid = ismember(lower(genotype), obj.genotypeList);
        end
        
        function valid = isValidAnimal(obj, animal)
            valid = ismember(lower(animal), obj.animalList);
        end

        function valid = isValidPart(obj, part)
            valid = false;
            tok = regexp(part, '[_ ]([1-3])$|[_ ]([1-3])[_ ]|^([1-3])[_ st]|(all)|(pre)|(post)|(last)', 'tokens', 'ignorecase');
            if ~isempty(tok)
                if strcmpi(tok{1}{1}, 'all')
                    return
                end
                number = str2double(tok{1}{1});
                if ~isempty(number)
                    valid = true;
                    obj.currentStruct(1).part = sprintf('ABR %1.0f', number);
                end
            end
        end
        
        function valid = isValidFileName(obj, file)
            % check if name hints at test file
            if ~isempty(regexp(file, '[tT][esES]+[tT]', 'start'))
                valid = false;
                return
            end
            
            % check if name has standard beginning and datetime
            tokens = regexp(file, 'datafile_(?<date>[0-9-]+)(?<tag>.*)\.mat', 'names');
            date = datenum(tokens.date, 'yyyy-mm-dd-HH-MM-SS');
            
            if isempty(date)
                valid = false;
                return
            end
            
            stdtags = regexp(tokens.tag, '_(?<name>[^_]+)_(?<ear>L|R)_(?<stim>(5|10|20)[kK][hH][zZ]|[Cc]lick)(?<extra>.*)', 'names', 'ignorecase');
            
            if isempty(stdtags)
                % TODO: ask for validity
                stimulus = regexp(tokens.tag, '(5|10|20|cl?ick)', 'tokens', 'ignorecase');
                ear = regexp(tokens.tag, '(L|R)', 'tokens');
                if isempty(stimulus) || isempty(ear)
                    valid = false;
                    return
                else
                    stdtags(1).stim = stimulus{1}{1};
                    stdtags(1).ear = ear{1}{1};
                    stdtags(1).name = '';
                end
            end
            obj.fileFrequency = sscanf(stdtags.stim, '%f');
            if isempty(obj.fileFrequency)
                obj.fileStimulus = 'click';
                obj.fileFrequency = 0;
            else
                obj.fileStimulus = 'tone';
            end
            namefile = stdtags.name; % TODO: ask for name match
            obj.fileEar = stdtags.ear;
            valid = true;
        end
        
        
    end
    
    methods
        
        function initMainTable(obj)
            
            varNamesTypes = {
                'animal', 'categorical'; ...
                'genotype', 'categorical'; ...
                'age', 'double'; ...
                'agegroup', 'categorical'; ...
                'path', 'string'; ...
                'filename', 'string'; ...
                'mismatch', 'logical'; ...
                'part', 'categorical'; ...
                'ear', 'categorical'; ...
                'isbestear', 'logical'; ...
                'frequency', 'double'; ...
                'stimulus', 'categorical'; ...
                'threshold', 'double'; ...
                'maxlevel', 'double'; ...
                'level', 'double'
            };
            for w = obj.waveNumbers
                varNamesTypes(end+1, :) = { sprintf('w%1.0f_amplitude', w), 'double' };
                varNamesTypes(end+1, :) = { sprintf('w%1.0f_latency', w), 'double' };
            end
            varNamesTypes(end+1, :) = { 'ratio_4_1', 'double' };
            
            obj.mainTable = table('Size', [1 size(varNamesTypes,1)], ...
                                  'VariableNames', varNamesTypes(:,1), ...
                                  'VariableTypes', varNamesTypes(:,2));
                              
            obj.currentStruct = table2struct(obj.mainTable);
            
        end
        
    end
    
end
