function crawl_it
%CRAWL_IT   Starts ABRDataCrawler
%
%
% Copyright 2021 Rainer Beutelmann, Universität Oldenburg
% ABRViewer by Rainer Beutelmann (Universität Oldenburg) is licensed under CC BY-SA 4.0
% 

startpath = uigetdir([], 'Please select top folder of ABR data');

if ~isnumeric(startpath) && ~isempty(startpath)
    [file, path] = uiputfile('*.xlsx', 'Please select file(name) to save results', 'ABRsummary.xlsx');
    if ~isnumeric(file) && ~isnumeric(path) && ~isempty(file)
        
        [path, file, ext] = fileparts(fullfile(path, file));
        outfile = fullfile(path, [file, '.xlsx']);
        
        adc = ABRDataCrawler('folder', startpath, 'save', outfile);
        adc.run;
        adc.writeTable;
        
    end
        
end
