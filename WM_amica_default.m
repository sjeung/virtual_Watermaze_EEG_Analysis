close all; clear

if ~exist('eeglab','var'); eeglab; end
if ~exist('mobilab','var'); runmobilab; end
pop_editoptions( 'option_storedisk', 0, 'option_savetwofiles', 1, 'option_saveversion6', 0, 'option_single', 0, 'option_memmapdata', 0, 'option_eegobject', 0, 'option_computeica', 1, 'option_scaleicarms', 1, 'option_rememberfolder', 1, 'option_donotusetoolboxes', 0, 'option_checkversion', 1);

%% ONLY CHANCE THESE PARTS!

subjects = [81002 81003 81004 81005 82001 82003 82004];
bemobil_config.study_folder = 'P:\Project_Watermaze\Data\';
bemobil_config.filename_prefix = '';

% enter channels that you did not use at all (e.g. with the MoBI 160 chan layout, only 157 chans are used):
bemobil_config.channels_to_remove = {};

% enter EOG channel names here:
bemobil_config.eog_channels  = {'G16' 'G32'};

% leave this empty if you have standard channel names that should use standard locations:
% process_config.channel_locations_filename = 'channel_locations.elc';
bemobil_config.channel_locations_filename = 'eloc_edit.elc';
bemobil_config.rigidbody_streams = {'PlayerTransform', 'PlayerTransfom'} ;
bemobil_config.unprocessed_data_streams = {'brainvision_rda_bpn-c023'};
bemobil_config.event_streams = {'ExperimentMarkerstream' };

% rename channels
raw_names = {'G01' 'G02' 'G03' 'G04' 'G05' 'G06' 'G07' 'G08' 'G09' 'G10' 'G11' 'G12' 'G13' 'G14' 'G15' 'G16' 'G17' 'G18' 'G19' 'G20' 'G21' 'G22' 'G23' 'G24' 'G25' 'G26' 'G27' 'G28' 'G29' 'G30' 'G31' 'G32' 'Y01' 'Y02' 'Y03' 'Y04' 'Y05' 'Y06' 'Y07' 'Y08' 'Y09' 'Y10' 'Y11' 'Y12' 'Y13' 'Y14' 'Y15' 'Y16' 'Y17' 'Y18' 'Y19' 'Y20' 'Y21' 'Y22' 'Y23' 'Y24' 'Y25' 'Y26' 'Y27' 'Y28' 'Y29' 'Y30' 'Y31' 'Y32' 'R01' 'R02' 'R03' 'R04' 'R05' 'R06' 'R07' 'R08' 'R09' 'R10' 'R11' 'R12' 'R13' 'R14' 'R15' 'R16' 'R17' 'R18' 'R19' 'R20' 'R21' 'R22' 'R23' 'R24' 'R25' 'R26' 'R27' 'R28' 'R29' 'R30' 'R31' 'R32' 'W01' 'W02' 'W03' 'W04' 'W05' 'W06' 'W07' 'W08' 'W09' 'W10' 'W11' 'W12' 'W13' 'W14' 'W15' 'W16' 'W17' 'W18' 'W19' 'W20' 'W21' 'W22' 'W23' 'W24' 'W25' 'W26' 'W27' 'W28' 'W29' 'W30' 'W31' 'W32'};

for i = 1:numel(raw_names)
    raw_names{i} = ['brainvision_rda_bpn-c023_', raw_names{i}]; 
end

new_names = {'g1' 'g2' 'g3' 'g4' 'g5' 'g6' 'g7' 'g8' 'g9' 'g10' 'g11' 'g12' 'g13' 'g14' 'g15' 'g16' 'g17' 'g18' 'g19' 'g20' 'g21' 'g22' 'g23' 'g24' 'g25' 'g26' 'g27' 'g28' 'g29' 'g30' 'g31' 'g32' 'y1' 'y2' 'y3' 'y4' 'y5' 'y6' 'y7' 'y8' 'y9' 'y10' 'y11' 'y12' 'y13' 'y14' 'y15' 'y16' 'y17' 'y18' 'y19' 'y20' 'y21' 'y22' 'y23' 'y24' 'y25' 'y26' 'y27' 'y28' 'y29' 'y30' 'y31' 'y32' 'r1' 'r2' 'r3' 'r4' 'r5' 'r6' 'r7' 'r8' 'r9' 'r10' 'r11' 'r12' 'r13' 'r14' 'r15' 'r16' 'r17' 'r18' 'r19' 'r20' 'r21' 'r22' 'r23' 'r24' 'r25' 'r26' 'r27' 'r28' 'r29' 'r30' 'r31' 'r32' 'w1' 'w2' 'w3' 'w4' 'w5' 'w6' 'w7' 'w8' 'w9' 'w10' 'w11' 'w12' 'w13' 'w14' 'w15' 'w16' 'w17' 'w18' 'w19' 'w20' 'w21' 'w22' 'w23' 'w24' 'w25' 'w26' 'w27' 'w28' 'w29' 'w30' 'w31' 'w32'}; 

bemobil_config.rename_channels = [raw_names' new_names'];
bemobil_config.ref_channel  = 'ref'; 

%% everything from here is according to the general pipeline, changes only recommended if you know the whole structure

% general foldernames and filenames
bemobil_config.raw_data_folder = '0_raw-data\';
bemobil_config.mobilab_data_folder = '1_mobilab-data\';
bemobil_config.raw_EEGLAB_data_folder = '2_basic-EEGLAB\';
bemobil_config.spatial_filters_folder = '3_spatial-filters\';
bemobil_config.spatial_filters_folder_AMICA = '3-1_AMICA\';
bemobil_config.single_subject_analysis_folder = '4_single-subject-analysis\';

bemobil_config.merged_filename = 'merged.set';
bemobil_config.preprocessed_filename = 'preprocessed.set';
bemobil_config.interpolated_avRef_filename = 'interpolated_avRef.set';
bemobil_config.filtered_filename = 'filtered.set';
bemobil_config.amica_raw_filename_output = 'postAMICA_raw.set';
bemobil_config.amica_chan_no_eye_filename_output = 'preAMICA_no_eyes.set';
bemobil_config.amica_filename_output = 'postAMICA_cleaned.set';
bemobil_config.warped_dipfitted_filename = 'warped_dipfitted.set';
bemobil_config.copy_weights_interpolate_avRef_filename = 'interp_avRef_ICA.set';
bemobil_config.single_subject_cleaned_ICA_filename = 'cleaned_with_ICA.set';


%%% AMICA

% on some PCs AMICA may crash before the first iteration if the number of
% threads and the amount the data does not suit the algorithm. Jason Palmer
% has been informed, but no fix so far. just roll with it. if you see the
% first iteration working there won't be any further crashes. in this case
% just press "close program" or the like and the bemobil_spatial_filter
% algorithm will AUTOMATICALLY reduce the number of threads and start AMICA
% again. this way you will always have the maximum number
% of threads that should be used for AMICA. check in the
% task manager how many threads you have theoretically available and think
% how much computing power you want to devote for AMICA. on the bpn-s1
% server, 12 is half of the capacity and can be used. be sure to check with
% either Ole or your supervisor and also check the CPU usage in the task
% manager before!

% 4 threads are most effective for single subject speed, more threads don't
% really shorten the calculation time much. best efficiency is using just 1
% thread and have as many matlab instances open as possible (limited by the
% CPU usage). Remember your RAM limit in this case.

bemobil_config.resample_freq = 250;
%bemobil_config.prepro_lowCutoffFreq = 0.2;
%bemobil_config.prepro_highCutoffFreq = 100;
bemobil_config.filter_lowCutoffFreqAMICA = 1;
bemobil_config.filter_highCutoffFreqAMICA = [];
bemobil_config.max_threads = 12;
bemobil_config.num_models = 1;

% warp electrodemontage and run dipfit
bemobil_config.warping_channel_names = [];
bemobil_config.residualVariance_threshold = 100;
bemobil_config.do_remove_outside_head = 'off';
bemobil_config.number_of_dipoles = 1;

% IC_label
bemobil_config.eye_threshold = 0.7;

% FHs cleaning
bemobil_config.buffer_length = 0.49;
bemobil_config.automatic_cleaning_threshold_to_keep = 0.70;

% Selective cleaning 
bemobil_config.selective_cleaning   = 1; % 0 when not using selective cleaning, 1 when using 
bemobil_config.selec_segment_names  = {'desktop', 'VR'}; % cell array of strings containing segment names
bemobil_config.selec_segment_function = 'WM_selec_segments'; % name of the function used to segment the data
bemobil_config.selec_thresholds     = [.8, .6]; % thresholds for each session, number of elements have to match the number of segment names

% Line noise frequency in Hz to remove with zapline
bemobil_config.selec_lineNoiseFreq  =  {50 [50 90]}; 

bemobil_config.mocap_lowpass = 6;
bemobil_config.rigidbody_derivatives = 1;

%% processing loop

if ~exist('eeglab','var'); eeglab; end
if ~exist('mobilab','var'); runmobilab; end
addpath(genpath('P:\Sein_Jeung\NoiseTools'))

% note : use the fieldtrip version inside the eeglab plugin folder
% version compatibility issues encounterd with Matlab 2017a
% when using a newer version of FieldTrip for dipfitting 

for subject = subjects
    
    disp(['Subject #' num2str(subject)]);
    
    if subject == 81003
        bemobil_config.filenames = {'desktop_old','desktop' 'VR'};
    else
        bemobil_config.filenames = {'desktop' 'VR'};
    end
    STUDY = []; CURRENTSTUDY = 0; ALLEEG = []; EEG=[]; CURRENTSET=[];
    force_recompute = 0;
    
    %   % import data and preprocess (no filtering)
    [ALLEEG, EEG_interp_avRef, CURRENTSET] = bemobil_process_all_mobilab(subject, bemobil_config, ALLEEG, CURRENTSET, mobilab, force_recompute);
    
    EEG_interp_avRef = pop_loadset(['P:\Project_Watermaze\Data\2_basic-EEGLAB\' num2str(subject) '\' num2str(subject) '_interpolated_avRef.set']);
    
    % AMICA on the merged data
    % [ALLEEG, EEG_AMICA_final, CURRENTSET] = bemobil_process_all_AMICA(ALLEEG, EEG_interp_avRef, CURRENTSET, subject, bemobil_config);
    [ALLEEG, EEG_AMICA_final, CURRENTSET] = bemobil_process_all_AMICA(ALLEEG, EEG_interp_avRef, CURRENTSET, subject, bemobil_config);
    
    
    
end