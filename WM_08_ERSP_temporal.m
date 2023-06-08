function WM_08_ERSP_temporal(Pi, elecGroup)
% time-frequency analysis channel level
%
% Inputs
%   Pi          : participant ID
%   elecInds    : 'none' or channel indices
%
% Outputs
%   none, writes data to disk
%
%--------------------------------------------------------------------------

%% configuration & load data 
%--------------------------------------------------------------------------
WM_config;                                                                  % load configs

[erspFileName,erspFileDir] = assemble_file(config_folder.results_folder, config_folder.ersp_folder, '', Pi);

% load output saved in util_WM_basecorrect
ERSPLearnS = load(fullfile(erspFileDir, [erspFileName '_learn_stat_' elecGroup.key '_ERSP.mat']), 'ERSPcorr');
ERSPLearnM = load(fullfile(erspFileDir, [erspFileName '_learn_mobi_' elecGroup.key '_ERSP.mat']), 'ERSPcorr');
ERSPProbeS = load(fullfile(erspFileDir, [erspFileName '_probe_stat_' elecGroup.key '_ERSP.mat']), 'ERSPcorr');
ERSPProbeM = load(fullfile(erspFileDir, [erspFileName '_probe_mobi_' elecGroup.key '_ERSP.mat']), 'ERSPcorr');

% stupid but pull the struct field up as a variable
ERSPLearnS = ERSPLearnS.ERSPcorr; 
ERSPLearnM = ERSPLearnM.ERSPcorr; 
ERSPProbeS = ERSPProbeS.ERSPcorr; 
ERSPProbeM = ERSPProbeM.ERSPcorr; 

%% Analysis of the start and end of trials
util_WM_cut_windows(ERSPLearnS, 5, Pi, ['learn_stat_' elecGroup.key]);
util_WM_cut_windows(ERSPLearnM, 5, Pi, ['learn_mobi_' elecGroup.key]);
util_WM_cut_windows(ERSPProbeS, 5, Pi, ['probe_stat_' elecGroup.key]);
util_WM_cut_windows(ERSPProbeM, 5, Pi, ['probe_mobi_' elecGroup.key]);


end