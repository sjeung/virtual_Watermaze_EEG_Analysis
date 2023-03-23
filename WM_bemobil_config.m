clear bemobil_config

%% General Setup
bemobil_config.study_folder = config_folder.data_folder; %(NEEDS to have a filesep at the end, sorry!) 
bemobil_config.filename_prefix = 'sub-';

% foldernames (NEED to have a filesep at the end, sorry!) 
bemobil_config.raw_EEGLAB_data_folder = [config_folder.trimmed_folder filesep];
bemobil_config.EEG_preprocessing_data_folder = [config_folder.preprocessed_folder filesep];
bemobil_config.spatial_filters_folder = [config_folder.spatial_filters_folder filesep];
bemobil_config.spatial_filters_folder_AMICA = ['4-1_AMICA' filesep];
bemobil_config.single_subject_analysis_folder = [config_folder.postAMICA_folder filesep];
bemobil_config.motion_analysis_folder = ['6_single-subject-motion-analysis' filesep];

% filenames
bemobil_config.merged_filename = config_folder.trimmedFileNameEEG;
bemobil_config.basic_prepared_filename = 'basic_prepared.set';
bemobil_config.preprocessed_filename = 'preprocessed.set';
bemobil_config.filtered_filename = 'filtered.set';
bemobil_config.amica_filename_output = 'AMICA.set';
bemobil_config.dipfitted_filename = 'dipfitted.set';
bemobil_config.preprocessed_and_ICA_filename = 'preprocessed_and_ICA.set';
bemobil_config.single_subject_cleaned_ICA_filename = 'cleaned_with_ICA.set';
bemobil_config.processed_motion_filename = 'motion_processed.set';


%% Preprocessing

% enter channels that you did not use at all (e.g. with our custom MoBI 160 chan layout, only 157 chans are used), leave
% empty, if all channels are used
% process_config.channels_to_remove = {'N29' 'N30' 'N31'};
bemobil_config.channels_to_remove = [];

% enter EOG channel names here:
% bemobil_config.eog_channels  = {'VEOG', 'HEOG'};
bemobil_config.eog_channels  = {'G16', 'G32'};

% if you add a channel here it needs to have a location as well. this means a new channel will be created and the old
% reference will be back in the dataset 
% bemobil_config.ref_channel  = 'FCz';
bemobil_config.ref_channel  = 'ref'; 

% If all channels have a prefix it can be removed here, by entering a single char in the cell array. it's also possible
% to rename single channels here if needed. for this, enter a matrix of channel names (nbchans,2 (from->to))
bemobil_config.rename_channels = {'BrainVision RDA_'};  

% resample frequency during preprocessing (leave empty if you resample before, or your data is already correctly
% sampled)
bemobil_config.resample_freq = []; 

% automatic channel cleaning:
%   chancorr_crit                       - Correlation threshold. If a channel is correlated at less than this value
%                                           to its robust estimate (based on other channels), it is considered abnormal in
%                                           the given time window. OPTIONAL, default = 0.8.
%   chan_max_broken_time                - Maximum time (either in seconds or as fraction of the recording) during which a 
%                                           retained channel may be broken. Reasonable range: 0.1 (very aggressive) to 0.6
%                                           (very lax). OPTIONAL, default = 0.5.
%   chan_detect_num_iter                - Number of iterations the bad channel detection should run (default = 10)
%   chan_detected_fraction_threshold	- Fraction how often a channel has to be detected to be rejected in the final
%                                           rejection (default 0.5)
%   flatline_crit                       - Maximum duration a channel can be flat in seconds (default 'off')
%   line_noise_crit                     - If a channel has more line noise relative to its signal than this value, in
%                                           standard deviations based on the total channel population, it is considered
%                                           abnormal. (default: 'off')

bemobil_config.chancorr_crit = 0.7;
bemobil_config.chan_max_broken_time = 0.3;
bemobil_config.chan_detect_num_iter = 10;
bemobil_config.chan_detected_fraction_threshold = 0.5;
bemobil_config.flatline_crit = 'off';
bemobil_config.line_noise_crit = 'off';

% channel locations: leave this empty if you have standard channel names that should use standard 10-20 locations,
% otherwise every dataset needs to have a channel locations file in the raw_data folder, and the chanloc file needs to
% have the correct participant prefix!

bemobil_config.channel_locations_filename = [];

% ZapLine-Plus to reduce line noise frequencies. Automatically finds noise frequencies and removes them as good as
% possible with Zapline. See 'help clean_data_with_zapline_plus' for more info about parameter tweaking.

% If the 'noisefreqs' field is set to empty, searches automatically, but you can also enter predefined noise frequencies
% here as a vector.

% Set the whole 'bemobil_config.zaplineConfig' field to [] if no noise is present in your data (haha).
bemobil_config.zaplineConfig.noisefreqs = [50, 90]; 

%% AMICA Parameters

% filter for AMICA:
% See Klug & Gramann (2020) for an investigation of filter effect on AMICA -> 1.25 Hz should be a good compromise if you
% don't know how much movement exists, otherwise even higher may be good, up to 2Hz, and you need to subtract 0.25 to
% obtain the correct cutoff value for a filter order of 1650
bemobil_config.filter_lowCutoffFreqAMICA = 2; % 1.75 is 1.5Hz cutoff!
bemobil_config.filter_AMICA_highPassOrder = 1650; % was used by Klug & Gramann (2020)
bemobil_config.filter_highCutoffFreqAMICA = []; % not used
bemobil_config.filter_AMICA_lowPassOrder = []; 

% additional AMICA settings
bemobil_config.num_models = 1; % default 1
bemobil_config.AMICA_autoreject = 1; % uses automatic rejection method of AMICA. no time-cleaning (manual or automatic) is needed then!
bemobil_config.AMICA_n_rej = 10; % default 10
bemobil_config.AMICA_reject_sigma_threshold = 3; % default 3
bemobil_config.AMICA_max_iter = 1000; % default 2000

% on some PCs AMICA may crash before the first iteration if the number of threads and the amount the data does not suit
% the algorithm. Jason Palmer has been informed, but no fix so far. just roll with it. if you see the first iteration
% working there won't be any further crashes. in this case just press "close program" or the like and the
% bemobil_spatial_filter algorithm will AUTOMATICALLY reduce the number of threads and start AMICA again. this way you
% will always have the maximum number of threads that should be used for AMICA. check in the task manager how many
% threads you have theoretically available and think how much computing power you want to devote for AMICA. 

% 4 threads are most effective for single subject speed, more threads don't really shorten the calculation time much.
% best efficiency is using just 1 thread and have as many matlab instances open as possible (limited by the CPU usage).
% Remember your RAM limit in this case.

bemobil_config.max_threads = 4; % default 4

% for warping the electrode locations to the standard 10-20 locations (leave
% empty if using standard locations)
% bemobil_config.warping_channel_names = {3,'FTT9h';45,'FTT10h';84,'AFz';87,'Cz'};
bemobil_config.warping_channel_names = {2, 'FTT9h'; 26, 'FTT10h'; 84, 'C5'; 52, 'C6'; 33, 'AFz'; 92, 'POz'; 41, 'Cz'};

% dipfit settings
bemobil_config.residualVariance_threshold = 100;
bemobil_config.do_remove_outside_head = 'off';
bemobil_config.number_of_dipoles = 1;

% IC_label settings
% 'default' classifier did not lead to good classification of muscles (see Klug & Gramann (2020)), 'lite' was better
% overall.
bemobil_config.iclabel_classifier = 'lite';

% 'Brain', 'Muscle', 'Eye', 'Heart', 'Line Noise', 'Channel Noise', 'Other'
bemobil_config.iclabel_classes = [1,7]; % don't really clean

% if the threshold is set to -1, the popularity classifier is used (i.e. every IC gets the class with the highest
% probability), if it is set to a value, the summed score of the iclabel_classes must be higher than this threshold to
% keep an IC. Must be in the [0 1] range!
bemobil_config.iclabel_threshold = 0.7; 


%% finalization

% filtering the final dataset
bemobil_config.final_filter_lower_edge = 0.2; % this should not lead to any issues downstream but remove all very slow drifts
bemobil_config.final_filter_higher_edge = [];

%% Motion Processing Parameters
bemobil_config.lowpass_motion = 6;
bemobil_config.lowpass_motion_after_derivative = 18;