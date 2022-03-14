function getpreview
%UPDATER    Downloads the latest release version of ABRViewer
%
%
% Copyright 2021 Rainer Beutelmann, Universität Oldenburg
% ABRViewer by Rainer Beutelmann (Universität Oldenburg) is licensed under CC BY-SA 4.0
% 
    [status, result] = system('git --version');
    
    if status ~= 0 || ~contains(result, 'git version')
        error(sprintf(['git version control not found on this computer\n' ...
                       'Please install from\n' ...
                       '<a href="https://git-scm.com/download">https://git-scm.com/download</a>\n\n']));
    end
    
    if ~exist('.git', 'dir')
        fprintf('============================================================\n');
        fprintf('    git version control will be initialized...\n');
        fprintf('\n');
        syscall('git init');
        syscall('git remote add origin https://gitlab.uni-oldenburg.de/teer6901/abrviewer.git');
        syscall('git fetch origin development');
        syscall('git checkout -f development');
        syscall('git checkout -B local');
        fprintf('\n');
        fprintf('    git version control is ready to be used.\n');
        fprintf('============================================================\n');
    else
        fprintf('============================================================\n');
        fprintf('    updating git version control\n');
        fprintf('\n');
        syscall('git checkout -B local');
        syscall('git fetch origin development');
        syscall('git reset --hard development');
        fprintf('\n');
        fprintf('============================================================\n');
    end
end

function syscall(command)
    [status, result]  = system(command);
    if status == 0
        fprintf('%s\n', result);
    else
        error('git_updater:system_error', '%s\n', result);
    end
end
