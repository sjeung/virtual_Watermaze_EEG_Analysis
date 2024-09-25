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

%--------------------------------------------------------------------------
[~,overlayResultsDir]           = assemble_file(config_folder.results_folder, config_folder.spatial_overlay_folder, '', Pi);
[~,overlayFigureDir]            = assemble_file(config_folder.figures_folder, config_folder.spatial_overlay_folder, '', Pi);
[~,overlayTargetResultsDir]     = assemble_file(config_folder.results_folder, config_folder.spatial_overlay_target_folder, '', Pi);
[~,overlayTargetFigureDir]      = assemble_file(config_folder.figures_folder, config_folder.spatial_overlay_target_folder, '', Pi);
[~,distResultsDir]              = assemble_file(config_folder.results_folder, config_folder.spatial_dist_folder, '', Pi);
[~,distFigureDir]               = assemble_file(config_folder.figures_folder, config_folder.spatial_dist_folder, '', Pi);
[~,avResultsDir]                = assemble_file(config_folder.results_folder, config_folder.spatial_av_folder, '', Pi);
[~,avFigureDir]                 = assemble_file(config_folder.figures_folder, config_folder.spatial_av_folder, '', Pi);


if ~isfolder(overlayResultsDir);        mkdir(overlayResultsDir);       end
if ~isfolder(overlayFigureDir);         mkdir(overlayFigureDir);        end
if ~isfolder(overlayTargetResultsDir);  mkdir(overlayTargetResultsDir); end
if ~isfolder(overlayTargetFigureDir);   mkdir(overlayTargetFigureDir);  end
if ~isfolder(distResultsDir);           mkdir(distResultsDir);          end
if ~isfolder(distFigureDir);            mkdir(distFigureDir);           end
if ~isfolder(avResultsDir);             mkdir(avResultsDir);            end
if ~isfolder(avFigureDir);              mkdir(avFigureDir);             end

for Fi = 1:numel(config_param.FOI_lower)
    
    fBand               = [config_param.FOI_lower(Fi), config_param.FOI_upper(Fi)];
    
    % a. overlay of power values onto space
    WM_09a_power_spatial_overlay(ERSPLearnS, MotionLearnS, 'stat_learn', Pi, fBand, elecGroup.key, overlayResultsDir, overlayFigureDir)
    WM_09a_power_spatial_overlay(ERSPLearnM, MotionLearnM, 'mobi_learn', Pi, fBand, elecGroup.key, overlayResultsDir, overlayFigureDir)
    WM_09a_power_spatial_overlay(ERSPProbeS, MotionProbeS, 'stat_probe', Pi, fBand, elecGroup.key, overlayResultsDir, overlayFigureDir)
    WM_09a_power_spatial_overlay(ERSPProbeM, MotionProbeM, 'mobi_probe', Pi, fBand, elecGroup.key, overlayResultsDir, overlayFigureDir)
    
    % b. overlay of power values onto space, centered around target
    WM_09b_power_spatial_overlay_target(ERSPLearnS, MotionLearnS, TrialLearnS, 'stat_learn', Pi, fBand, elecGroup.key, overlayTargetResultsDir, overlayTargetFigureDir)
    WM_09b_power_spatial_overlay_target(ERSPLearnM, MotionLearnM, TrialLearnM, 'mobi_learn', Pi, fBand, elecGroup.key, overlayTargetResultsDir, overlayTargetFigureDir)
    WM_09b_power_spatial_overlay_target(ERSPProbeS, MotionProbeS, TrialProbeS, 'stat_probe', Pi, fBand, elecGroup.key, overlayTargetResultsDir, overlayTargetFigureDir)
    WM_09b_power_spatial_overlay_target(ERSPProbeM, MotionProbeM, TrialProbeM, 'mobi_probe', Pi, fBand, elecGroup.key, overlayTargetResultsDir, overlayTargetFigureDir)
    
   
end
 
% c. power ordered by distance to target/center
WM_09c_power_spatial_dist(ERSPLearnS, MotionLearnS, TrialLearnS, 'stat_learn', Pi, elecGroup.key, distResultsDir, distFigureDir)
WM_09c_power_spatial_dist(ERSPLearnM, MotionLearnM, TrialLearnM, 'mobi_learn', Pi, elecGroup.key, distResultsDir, distFigureDir)
WM_09c_power_spatial_dist(ERSPProbeS, MotionProbeS, TrialProbeS, 'stat_probe', Pi, elecGroup.key, distResultsDir, distFigureDir)
WM_09c_power_spatial_dist(ERSPProbeM, MotionProbeM, TrialProbeM, 'mobi_probe', Pi, elecGroup.key, distResultsDir, distFigureDir)

% c. power ordered by distance to target/center
WM_09d_power_angular_velocity(ERSPLearnS, MotionLearnS, 'stat_learn', Pi, elecGroup.key, avResultsDir, avFigureDir)
WM_09d_power_angular_velocity(ERSPLearnM, MotionLearnM, 'mobi_learn', Pi, elecGroup.key, avResultsDir, distFigureDir)
WM_09d_power_angular_velocity(ERSPProbeS, MotionProbeS, 'stat_probe', Pi, elecGroup.key, distResultsDir, distFigureDir)
WM_09d_power_angular_velocity(ERSPProbeM, MotionProbeM, 'mobi_probe', Pi, elecGroup.key, distResultsDir, distFigureDir)


end