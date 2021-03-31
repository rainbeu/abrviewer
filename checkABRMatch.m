function checkABRMatch(in, out)
    
    if ~strcmp(in.Hw.CalFile, out.Hw.CalFile)
        warning('non-matching calibration file');
    end
    
    if in.Rc.PreTime ~= out.Rc.PreTime
        error('non-matching pre stimulus time');
    end
    if in.Rc.RecTime ~= out.Rc.RecTime
        error('non-matching recording time');
    end
    
    if in.St.Fs ~= out.St.Fs
        error('non-matching sampling frequency');
    end
    if ~strcmp(in.St.Type, out.St.Type)
        error('non-matching stimulus type');
    end
    
    switch in.St.Type
        case 'click'
        case 'tone'
            if ~strcmp(in.St.Window, out.St.Window)
                error('non-matching window type');
            end
            if ~strcmp(in.St.Window, 'none') && in.St.RampDur ~= out.St.RampDur
                error('non-matching window duration');
            end
            if in.St.Frequency ~= out.St.Frequency
                error('non-matching tone frequency');
            end
            if in.St.Duration ~= out.St.Duration
                error('non-matching tone duration');
            end
        case 'chirp'
            if ~strcmp(in.St.FileName, out.St.FileName)
                error('non-matching chirp file');
            end
            if in.St.FileTimeOffset ~= out.St.FileTimeOffset
                error('non-matching chirp sample position');
            end
        otherwise
            if in.St.Frequency ~= out.St.Frequency
                error('non-matching carrier frequency');
            end
            if in.St.ModulationDepth ~= out.St.ModulationDepth
                error('non-matching modulation depth');
            end
    end
    

    
