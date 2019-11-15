function convert_ABR_threshold_mode(filename)
    
    if iscellstr(filename)
        
        for fx = 1:length(filename)
            try
                convert_ABR_threshold_mode(filename{fx});
            catch exc
                fprintf('ERROR: %s\n', exc.message);
            end
        end
        
    else
        
        side = {
            'left', 'L'
            'right', 'R'
            'binaural', 'L+R'
            };
        
        assert(exist(filename, 'file')==2, 'convertABR:filenotexisting', 'file %s does not exist', filename);
        
        in = load(filename);
        
        assert(isfield(in, 'St'), 'convertABR:invalidstructure', 'not a valid ABR data structure');
        assert(isfield(in.St, 'LevelThreshold'), 'convertABR:invalidstructure', 'not a valid ABR data structure');
        assert(in.St.LevelThreshold, 'convertABR:invalidmeasurement', 'not a valid ABR threshold measurement');
        assert(~isfield(in.St, 'PresentationType') || strcmp(in.St.PresentationType, 'L/R/B'), 'convertABR:invalidmeasurement', 'not an old threshold measurement - no need to convert');
        assert(size(in.Avg, 2) == 3, 'convertABR:invalidmeasurement', 'incorrect measurement type');
        
        for sx = 1:size(side, 1)
            
            out = in;
            out.Avg = squeeze(out.Avg(:, sx, :));
            out.Mic = squeeze(out.Mic(:, :, sx, :));
            out.AvgC = squeeze(out.AvgC(sx, :));
            out.MicC = squeeze(out.MicC(:, sx, :));
            
            out.St.PresentationType      = 'simple binaural';
            out.St.StimulusSide =  side{sx, 2};
            out.St.MaskerSide   =  side{sx, 2};
            
            out.St.CarrierFrequency = [];
            out.St.LowPassFrequency = [];
            out.St.Frozen = false;
            
            out.St.BufferLen             = [];
            out.St.IAC                   = [];
            out.St.CenterFreq            = [];
            out.St.Bandwidth             = [];
            out.St.MaskerLevel           = [];
            out.St.MaskerDuration        = [];
            out.St.StimOnsetDelay        = [];
            out.St.MaskerLevelOffsets    = [];
            out.St.StimulusLevelOffsets  = out.St.ILD;
            out.St.MaskerRampDur         = [];
            out.St.MaskerFrozen          = false;
            
            [path,name,ext] = fileparts(filename);
            
            save(fullfile(path, sprintf('%s_%s%s', name, side{sx, 1}, ext)), '-struct', 'out');
            
        end
        
    end
