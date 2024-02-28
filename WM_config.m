%% Directory management
% folder names
%--------------------------------------------------------------------------
config_folder.project_folder   = 'P:\Sein_Jeung\Project_Watermaze';
config_folder.data_folder      = fullfile(config_folder.project_folder, 'WM_EEG_Data'); 
config_folder.analysis_folder  = fullfile(config_folder.project_folder, 'WM_EEG_Analysis'); 
config_folder.results_folder   = fullfile(config_folder.project_folder, 'WM_EEG_Results');
config_folder.figures_folder   = fullfile(config_folder.project_folder, 'WM_EEG_Figures');

% data folder and file names 
%--------------------------------------------------------------------------
config_folder.bids_folder              = '0_BIDS-data';
config_folder.set_folder               = '1_basic-EEGLAB_HMD_only';         % means that no torso mocap streams are imported
    config_folder.rawFileNameEEG              = '_merged_EEG.set'; 
    config_folder.rawFileNameMotion           = '_merged_MOTION.set'; 
config_folder.trimmed_folder           = '2_trimmed'; 
    config_folder.trimmedFileNameEEG          = '_WM_EEG_trimmed.set';
    config_folder.trimmedFileNameMotion       = '_WM_MOTION_trimmed.set';
config_folder.preprocessed_folder      = '3_preprocessed';
config_folder.spatial_filters_folder    = '4_spatial-filters'; 
config_folder.postAMICA_folder         = '5_post-AMICA'; 
    config_folder.postAMICAFileName           = '_preprocessed_and_ICA.set';                       
config_folder.cleaned_folder           = '6_cleaned'; 
    config_folder.cleanedFileName             = '_cleaned.set';       
config_folder.epoched_folder           = '7_epoched';                       % from here on .set is not used anymore and mainly fieldtrip is used                 
    config_folder.epochedFileName         = '_epoched.mat';
    
% results folder and file names 
%--------------------------------------------------------------------------
config_folder.ersp_folder           = 'ERSP'; 
config_folder.band_folder           = 'bandpower'; 
config_folder.beh_folder            = 'BEH_output'; 
    config_folder.behFileName       = '_beh_trials.mat'; 
    config_folder.behStructFileName     = 'P:\Sein_Jeung\Project_Watermaze\WM_EEG_Results\WP8_WM_table.mat'; % this is the og output from beh anaylsis
config_folder.spatial_overlay_folder  = 'spatial_overlay'; 
config_folder.spatial_overlay_target_folder  = 'spatial_overlay_target'; 
config_folder.spatial_dist_folder   = 'spatial_dist'; 
config_folder.pruned_ERSP_folder    = 'ERSP_pruned'; 
config_folder.band_powers_folder    = 'Band_powers';
    config_folder.bandPowerFileName = '_band_powers.mat'; 


%% Parameters 
% IC cleaning 
%--------------------------------------------------------------------------
config_param.IC_threshold    = 0.8; 

% Beamforming 
%--------------------------------------------------------------------------
config_param.ROI_names       = {'RSC', 'Prefrontal_cortex'};
config_param.FOI_lower       = [4,  8,  12, 30];
config_param.FOI_upper       = [8,  12, 30, 60]; 

% Behavioral anaylsis 
%--------------------------------------------------------------------------
config_param.memscore_iterations = []; 

% ERSP analysis
%--------------------------------------------------------------------------
config_param.ERSP_freq_range = [3,60];

% Band definition 
%--------------------------------------------------------------------------
config_param.band_names     = {'theta', 'alpha', 'beta', 'gamma'};  
config_param.band_bounds    = [4,8;  8,12;  12,30;  30,60];         % a vector of 2 X number of fBands; 

load('ExampleChanLoc.mat', 'exampleChanLoc'); % only load to match channel names with channel indices
chanLabels                  = {exampleChanLoc.labels}; 

% figure out channel labels by matching with 10-20 system
mElecFile = 'P:\Sein_Jeung\Project_Watermaze\WM_EEG_Data\source-data\Eloc and impedances\standard_MoBI_128.elc'; 
sElecFile = 'P:\Sein_Jeung\Project_Watermaze\WM_EEG_Data\source-data\Eloc and impedances\standard_1020.elc'; 
% sElec    = ft_read_sens('P:\Sein_Jeung\Project_Watermaze\WM_EEG_Data\source-data\Eloc and impedances\standard_1020.elc');
% mElec    = ft_read_sens('P:\Sein_Jeung\Project_Watermaze\WM_EEG_Data\source-data\Eloc and impedances\standard_MoBI_128.elc','FileType', 'text');
% 
% [newlocs transform] = coregister(mElecFile, sElecFile, 'warp', 'auto', 'manual', 'off');

config_param.chanGroups(1).key           = 'FM';
config_param.chanGroups(1).full_name     = 'Frontal-midline';
config_param.chanGroups(1).chan_names    = {'y1','y2','y3','y25','y32'}; 

config_param.chanGroups(2).key           = 'PM';
config_param.chanGroups(2).full_name     = 'Parietal-midline';
%config_param.chanGroups(2).standard_names  = {'Pz', 'P1', 'P2'}; 
config_param.chanGroups(2).chan_names    = {'r9', 'r10', 'r11', 'r27', 'r32'}; 

config_param.chanGroups(3).key           = 'LT';
config_param.chanGroups(3).full_name     = 'Left-temporal';
%config_param.chanGroups(3).standard_names  = {'FT7', 'TP7', 'T7'};
config_param.chanGroups(3).chan_names    = {'g1', 'y16', 'r15', 'r13'}; 

config_param.chanGroups(4).key           = 'RT';
config_param.chanGroups(4).full_name     = 'Right-temporal';
%config_param.chanGroups(4).standard_names  = {'FT8', 'TP8', 'T8'};
config_param.chanGroups(4).chan_names    = {'g24','y20', 'r18', 'r20'}; 

% 
% for Gi = 2:numel(config_param.chanGroups)
%     for Si = 1:numel(config_param.chanGroups(Gi).standard_names)
%         sInd = find(strcmp(sElec.label, config_param.chanGroups(Gi).standard_names{Si}));
%         sPos = sElec.chanpos(sInd,:); 
%         
%         % compute distances between mobi chanloc and standard chanloc
%         distanceVec = sqrt((newlocs.pnt(:,1)- sPos(1)).^2 + (newlocs.pnt(:,2)- sPos(2)).^2 + (newlocs.pnt(:,3)- sPos(3)).^2); 
%         [val,ind]  = min(distanceVec);
%         
%         disp(['Matched channel ' config_param.chanGroups(Gi).standard_names{Si} ' with channel ' newlocs.label{ind} ' with distance ' num2str(val)])
%         
%     end
% end

for CGi = 1:numel(config_param.chanGroups)
    
    for Ni = 1:numel(config_param.chanGroups(CGi).chan_names)
        config_param.chanGroups(CGi).chan_inds(Ni)   = find(strcmpi(chanLabels, config_param.chanGroups(CGi).chan_names{Ni}));
    end
    
end


%% Colors 
config_visual.pColor = [8,97,89]/225; 
config_visual.cColor = [120, 120, 120]/225; 




