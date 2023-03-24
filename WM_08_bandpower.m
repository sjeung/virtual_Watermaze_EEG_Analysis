function WM_08_bandpower(Pi)
% time-frequency analysis channel level 
%
% Inputs 
%   Pi          : participant ID
%   setup       : 1-'MoBI', 2-'Desktop'
%
% Outputs 
%   none, writes data to disk 
%   saved variable 'TFR'
%       TFR.learn_start 
%       TFR.learn_end
%       TFR.probe_start
%       TFP.probe_end
%
%--------------------------------------------------------------------------

%% load data 
%--------------------------------------------------------------------------
% load configs
WM_config;

[epochedFileName,epochedFileDir]    = assemble_file(config_folder.data_folder, config_folder.epoched_folder, config_folder.epochedFileName, Pi);
[bandFileName,bandFileDir]          = assemble_file(config_folder.results_folder, config_folder.band_folder, '_band.mat', Pi);

EEG = pop_loadset('filepath', epochedFileDir, 'filename', epochedFileName); 

%% learn trials start
eventInds       = find(strcmp('searchtrial:start', {EEG.event.type}) & [EEG.event.session] == 1); 
epochInds       = util_WM_event2epoch(EEG, eventInds);
band_learn_start_mobi = util_WM_band(EEG, epochInds);
figTitle        = [num2str(Pi) ', Learn Start, MoBI, theta']; 
figFilename     = [num2str(Pi) '_band_L_S_M.png'];
util_WM_plot_topo(band_learn_start_mobi, EEG.chanlocs, figTitle, fullfile(bandFileDir, figFilename))

eventInds       = find(strcmp('searchtrial:start', {EEG.event.type}) & [EEG.event.session] == 2); 
epochInds       = util_WM_event2epoch(EEG, eventInds);
band_learn_start_desktop = util_WM_band(EEG, epochInds); 
figTitle        = [num2str(Pi) ', Learn Start, Desktop, theta']; 
figFilename     = [num2str(Pi) '_band_L_S_D.png'];
util_WM_plot_topo(band_learn_start_desktop, EEG.chanlocs, figTitle, fullfile(bandFileDir, figFilename))

%% learn trials end

%% probe trials start
eventInds       = find(contains({EEG.event.type},'guesstrial:start') & [EEG.event.session] == 1); 
epochInds       = util_WM_event2epoch(EEG, eventInds);
[band_probe_start_mobi] = util_WM_band(EEG, epochInds); 
figTitle        = [num2str(Pi) ', Probe Start, MoBI, theta']; 
figFilename     = [num2str(Pi) '_band_P_S_M.png'];
util_WM_plot_topo(band_probe_start_mobi, EEG.chanlocs, figTitle, fullfile(bandFileDir, figFilename))

eventInds       = find(contains({EEG.event.type},'guesstrial:start') & [EEG.event.session] == 2); 
epochInds       = util_WM_event2epoch(EEG, eventInds);
[band_probe_start_desktop] = util_WM_band(EEG, epochInds); 
figTitle        = [num2str(Pi) ', Probe Start, Desktop, theta']; 
figFilename     = [num2str(Pi) '_band_P_S_D.png'];
util_WM_plot_topo(band_probe_start_desktop, EEG.chanlocs, figTitle, fullfile(bandFileDir, figFilename))


%% probe trials end 
if ~isfolder(bandFileDir)
    mkdir(bandFileDir)
end

% save results
save(fullfile(bandFileDir, bandFileName),...
    'band_learn_start_mobi',...
    'band_learn_start_desktop',...
    'band_probe_start_mobi',...
    'band_probe_start_desktop');

end
