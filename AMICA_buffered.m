eeglab

EEG = pop_loadset('P:\Project_Watermaze\Data\3_spatial-filters\3-1_AMICA\81001\81001_clean_forAMICA_merged.set'); 

boundaryLatencyArray = [EEG.event(strcmp({EEG.event.type},'boundary')).latency]; 

% remove additional 500 ms before and after boundary events
rejectRegion = [];
boundaryLatency = boundaryLatencyArray(1); 
if boundaryLatency < 125
    rejectRegion = [1,boundaryLatency + 125];
else
    rejectRegion = [boundaryLatency - 125,boundaryLatency + 125];
end

for index = 2:numel(boundaryLatencyArray) - 1
    
    boundaryLatency = boundaryLatencyArray(index); 
    
    lower   = boundaryLatency - 125;
    upper   = boundaryLatency + 125;
    

        if rejectRegion(end,2) > lower
            rejectRegion(end,2) = upper;
        else
            rejectRegion(end+1,:) = [lower,upper];
        end

end

boundaryLataency = boundaryLatencyArray(end); 
if boundaryLatency > EEG.pnts -125
      rejectRegion(end+1,:) = [boundaryLatency - 125,EEG.pnts];
else
     rejectRegion(end+1,:) = [boundaryLatency - 125,boundaryLatency + 125];
end

EEG_interp_avRef = eeg_eegrej(EEG, rejectRegion); 

%% create a new data set 
rank = 127;

% AMICA
disp('Final AMICA computation on cleaned data...');
[ALLEEG, EEG_AMICA_cleaned, CURRENTSET] = bemobil_signal_decomposition(ALLEEG, EEG_interp_avRef, ...
    CURRENTSET, true, bemobil_config.num_models, bemobil_config.max_threads, rank, [], ...
    [bemobil_config.filename_prefix num2str(subject) '_' bemobil_config.amica_filename_output], 'P:\Project_Watermaze\Data\3_spatial-filters\3-1_AMICA\81001_buffered\');

% ICLabel  
disp('ICLabel component classification...');
EEG_AMICA_cleaned = iclabel(EEG_AMICA_cleaned,'lite');

% do the warp and dipfit
disp('Dipole fitting...');
[ALLEEG, EEG_AMICA_final, CURRENTSET] = bemobil_dipfit( EEG_AMICA_cleaned , ALLEEG, CURRENTSET, bemobil_config.warping_channel_names,...
    bemobil_config.residualVariance_threshold,...
    bemobil_config.do_remove_outside_head, bemobil_config.number_of_dipoles,...
    [bemobil_config.filename_prefix num2str(subject) '_' bemobil_config.warped_dipfitted_filename], 'P:\Project_Watermaze\Data\3_spatial-filters\3-1_AMICA\81001_buffered_dipfitted\');