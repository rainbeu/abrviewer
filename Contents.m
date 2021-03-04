% ABR waveform viewer and analysis tool 
% Version 0.9 04-Mar-2021
%
%
% ABRViewer Main Classes
%   ABRViewer                  - ABR waveform viewer and analysis tool
%   ABRViewerBase              - Base class for ABRViewerList and ABRViewerDisplay
%   ABRViewerList              - Displays the ABRViewer file list
%   ABRViewerDisplay           - Displays the waveforms and analysis tools
%   ExperimentalData           - Base class for generic experimental data
%   ABRData                    - Class for ABR data, derived from ExperimentalData 
%
% ABRViewer Helper Functions
%   convert_ABR_threshold_mode - Converts binaurally (L/R/B) measured ABR threshold file
%   grabFileList               - Creates list of all files in and below the current folder
%   wavequestdlg               - Asks for ABR wave number (to tag waveform amplitude/latency)
%
% Version Control Utilities
%   bootstrap                  - Initializes Git version control and downloads ABRViewer
%   updater                    - Downloads the latest release version of ABRViewer
%
% Data Crawler Tool for Summarizing Folder Hierarchy
%   ABRDataCrawler             - Summarizes ABR data in folder hierarchy into Excel file
%   crawl_it                   - Starts ABRDataCrawler
%
%
%
% ABRViewer by Rainer Beutelmann (Universität Oldenburg) is licensed under CC BY-SA 4.0
%
% <a href="https://gitlab.uni-oldenburg.de/teer6901/abrviewer">Download</a>
% <a href="https://uol.de/suche/person?username=RBeutelmann2">Support</a>
% <a href="http://creativecommons.org/licenses/by-sa/4.0/">License</a>
%



