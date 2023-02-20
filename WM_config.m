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
config_folder.set_folder               = '1_basic-EEGLAB';
    config_folder.rawFileNameEEG              = '_WM_EEG.set'; 
    config_folder.rawFileNameMotion           = '_WM_MOTION_Unity.set'; 
config_folder.trimmed_folder           = '2_trimmed'; 
    config_folder.trimmedFileNameEEG          = '_WM_EEG_trimmed.set';
    config_folder.trimmedFileNameMotion       = '_WM_MOTION_trimmed.set';
config_folder.preprocessedFolder      = '3_preprocessed';
config_folder.spatialFiltersFolder    = '4_spatial-filters'; 
config_folder.postAMICAFolder         = '5_post-AMICA'; 
    config_folder.postAMICAFileName           = '_preprocessed_and_ICA.set';                       
config_folder.cleanedFolder           = '6_cleaned'; 
    config_folder.cleanedFileName             = '_cleaned.set';       
config_folder.epochedFolder           = '7_epoched';                          % from here on .set is not used anymore and mainly fieldtrip is used                 
    config_folder.epochedBeamFileName         = '_epoched.mat';

    
% file name parts to be used for single participants 
%--------------------------------------------------------------------------
% construction : 
% VN_E1_Data\1_BIDS-Data\sub-0X\sub-0X_filename.ext

% file names for aggregated files 
%--------------------------------------------------------------------------


%% Participant information 
% participants 
% excluded due to technical error
% excluded due to strong nausea
allParticipants = [81001:81011, 82001:82011, 83001:83011];
excluded        = [81005, 82005, 83005]; % patient 81005 excluded due to psychosis   
allParticipants = setdiff(allParticipants,excluded);

%% Parameters 
% Preprocessing parameters (BeMoBIL pipeline)
%--------------------------------------------------------------------------





% Beamforming ? 
%--------------------------------------------------------------------------
config_param.ROI_names       = {'Hippocampus_L', 'Hippocampus_R', 'Parahippocampus_L', 'Parahippocampus_R'};
config_param.FOI_lower       = [5,  8,  14, 30, 60];
config_param.FOI_upper       = [8,  14, 30, 60, 120]; 

% Behavioral anaylsis 
%--------------------------------------------------------------------------
config_param.memscore_iterations = []; 

% Hexadirectional analysis 
%--------------------------------------------------------------------------
config_param.symmetries          = [4,5,6,7,8]; 
config_param.kfold_split         = 0; % number of subsets for GLM1 in hexadirectional analysis
