function WM_09_ERSP_spatial(Pi, elecGroup)
% time-frequency analysis channel level
% plot overlaid over physical space 
%
% Inputs
%   Pi          : participant ID
%   elecGroup   : struct 
%
% Outputs
%   none, writes data to disk
%
%--------------------------------------------------------------------------

%% configuration & load data 
%--------------------------------------------------------------------------
WM_config;                                                                  % load configs

[erspFileName,erspFileDir]  = assemble_file(config_folder.results_folder, config_folder.ersp_folder, '', Pi);
[~,epochedFileDir]          = assemble_file(config_folder.data_folder, config_folder.epoched_folder, '', Pi);
[behFileName,behFileDir]    = assemble_file(config_folder.results_folder, config_folder.beh_folder, config_folder.behFileName, Pi);
splitName = strsplit(behFileDir,'\'); 
behFileDir = strjoin(splitName(1:end-1), '\');                              % this operation is because beh mats are not in subject subdirectories

% load output saved in util_WM_basecorrect
ERSPLearnS = load(fullfile(erspFileDir, [erspFileName '_learn_stat_' elecGroup.key '_ERSP.mat']), 'ERSPcorr');
ERSPLearnM = load(fullfile(erspFileDir, [erspFileName '_learn_mobi_' elecGroup.key '_ERSP.mat']), 'ERSPcorr');
ERSPProbeS = load(fullfile(erspFileDir, [erspFileName '_probe_stat_' elecGroup.key '_ERSP.mat']), 'ERSPcorr');
ERSPProbeM = load(fullfile(erspFileDir, [erspFileName '_probe_mobi_' elecGroup.key '_ERSP.mat']), 'ERSPcorr');

% load motion data 
MotionLearnS = load(fullfile(epochedFileDir, [erspFileName '_learn_stat_motion_epoched.mat']), 'ftMotion');
MotionLearnM = load(fullfile(epochedFileDir, [erspFileName '_learn_mobi_motion_epoched.mat']), 'ftMotion');
MotionProbeS = load(fullfile(epochedFileDir, [erspFileName '_probe_stat_motion_epoched.mat']), 'ftMotion');
MotionProbeM = load(fullfile(epochedFileDir, [erspFileName '_probe_mobi_motion_epoched.mat']), 'ftMotion');

% load trial data 
load(fullfile(behFileDir, behFileName), 'TrialLearnS', 'TrialLearnM', 'TrialProbeS', 'TrialProbeM') 

% stupid but pull the struct field up as a variable
ERSPLearnS = ERSPLearnS.ERSPcorr; 
ERSPLearnM = ERSPLearnM.ERSPcorr; 
ERSPProbeS = ERSPProbeS.ERSPcorr; 
ERSPProbeM = ERSPProbeM.ERSPcorr; 

MotionLearnS = MotionLearnS.ftMotion;
MotionLearnM = MotionLearnM.ftMotion;
MotionProbeS = MotionProbeS.ftMotion;
MotionProbeM = MotionProbeM.ftMotion;

fBand                   = [8,12]; 
util_WM_ERSP_spatial_map(ERSPLearnS, MotionLearnS, TrialLearnS, 'stat_learn', Pi, fBand, elecGroup.key)
util_WM_ERSP_spatial_map(ERSPLearnM, MotionLearnM, TrialLearnM, 'mobi_learn', Pi, fBand, elecGroup.key)
util_WM_ERSP_spatial_map(ERSPProbeS, MotionProbeS, TrialProbeS, 'stat_probe', Pi, fBand, elecGroup.key)
util_WM_ERSP_spatial_map(ERSPProbeM, MotionProbeM, TrialProbeM, 'mobi_probe', Pi, fBand, elecGroup.key)

end