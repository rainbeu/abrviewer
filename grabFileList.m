%GRABFILELIST   Creates list of all files in and below the current folder
%
%
% Copyright 2021 Rainer Beutelmann, Universität Oldenburg
% ABRViewer by Rainer Beutelmann (Universität Oldenburg) is licensed under CC BY-SA 4.0
% 

d = dir('**/*.mat');
fid = fopen('matfilelist.txt','w');
for k = 1:length(d)
    fprintf(fid,'%s;%s;%1.0f\n',d(k).folder,d(k).name,d(k).bytes);
end
fclose(fid);
