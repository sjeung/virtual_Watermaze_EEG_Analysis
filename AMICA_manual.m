eeglab

EEG = pop_loadset('P:\Project_Watermaze\Data\2_basic-EEGLAB\81001\81001_preprocessed.set'); 
chanlocs = EEG.chanlocs; 
clear EEG

removed_chans   = {'W13', 'W17', 'W26', 'G19', 'G23', 'Y1', 'W14', 'W16', 'ref'};

for i = 1:numel(chanlocs)
    
    for j = 1:numel(removed_chans)
        
        if strcmpi(chanlocs(i).labels, removed_chans{j})
            
            removed_chan_index(j) = i;
            disp(['channel ' removed_chans{j} ' is removed'] )
            
        end
    end
    
end

newchanlocs = chanlocs ; 
%newchanlocs(removed_chan_index) = []; 

EEG = pop_loadset('P:\Project_Watermaze\Data\3_spatial-filters\3-1_AMICA\81001_manual\81001_merged_cleanKlaus-Filt1Hz.set'); 
EEG_preprocessed = EEG; 
EEG_preprocessed.chanlocs = newchanlocs; 

ref_channel = 'ref';

x = 1;
y = 1; 

for iterator = 1:129
    
    if  ~ismember(y, removed_chan_index)
        
        matrix(iterator,:) = [x,y];
        x = x + 1;
        
    else
        
        matrix(iterator,:) = [0,y];
        
    end
    
    y = y+ 1;
    
end


% add removed channels back
for iterator = 1:numel(newchanlocs)
    
    if matrix(iterator,1) == 0

        EEG_preprocessed.data(iterator,:) = zeros(1, EEG.pnts);
    
    else 
        
        EEG_preprocessed.data(iterator,:) = EEG.data(matrix(iterator,1),:);
        
    end
end

% add ref channel as zero if specified
EEG_preprocessed.nbchan = EEG.nbchan + numel(removed_chan_index);
%EEG.data(end + 1,:) = zeros(1, EEG.pnts);

disp('Declaring ref for all channels...')
[EEG_preprocessed.chanlocs(:).ref] = deal(ref_channel);

% Resample/downsample to 250 Hz if no other resampling frequency is
% provided

resample_freq = 250; 

if ~isempty(resample_freq)
	EEG_preprocessed = pop_resample(EEG_preprocessed, resample_freq);
	EEG = eeg_checkset( EEG_preprocessed );
	disp(['Resampled data to: ', num2str(resample_freq), 'Hz.']);
end

% save on disk
EEG = pop_saveset( EEG, 'filename','81001_manual_preprocessed','filepath', 'P:\Project_Watermaze\Data\3_spatial-filters\3-1_AMICA\81001_manual\');
disp('preprocessed file saved');

%--------------------------------------------------------------------------
EEG_preprocessed        = EEG; 
chans_to_interp         = removed_chan_index; 
chans_to_interp(end)    = []; 


%% do the interpolation and average referencing (reference is not considering EOGs)
disp('Interpolating bad channels...')
[ALLEEG, EEG_interp_avRef, CURRENTSET] = bemobil_interp_avref( EEG_preprocessed , ALLEEG, CURRENTSET, chans_to_interp,...
    [bemobil_config.filename_prefix num2str(subject) '_' bemobil_config.interpolated_avRef_filename],'P:\Project_Watermaze\Data\3_spatial-filters\3-1_AMICA\81001_manual\');


%% create a new data set 



rank = 120;

% AMICA
disp('Final AMICA computation on cleaned data...');
[ALLEEG, EEG_AMICA_cleaned, CURRENTSET] = bemobil_signal_decomposition(ALLEEG, EEG_interp_avRef, ...
    CURRENTSET, true, bemobil_config.num_models, bemobil_config.max_threads, rank, [], ...
    [bemobil_config.filename_prefix num2str(subject) '_' bemobil_config.amica_filename_output], 'P:\Project_Watermaze\Data\3_spatial-filters\3-1_AMICA\81001_manual\');

% ICLabel  
disp('ICLabel component classification...');
EEG_AMICA_cleaned = iclabel(EEG_AMICA_cleaned,'lite');

% do the warp and dipfit
disp('Dipole fitting...');
[ALLEEG, EEG_AMICA_final, CURRENTSET] = bemobil_dipfit( EEG_AMICA_cleaned , ALLEEG, CURRENTSET, bemobil_config.warping_channel_names,...
    bemobil_config.residualVariance_threshold,...
    bemobil_config.do_remove_outside_head, bemobil_config.number_of_dipoles,...
    [bemobil_config.filename_prefix num2str(subject) '_' bemobil_config.warped_dipfitted_filename], 'P:\Project_Watermaze\Data\3_spatial-filters\3-1_AMICA\81001_manual_dipfitted\');