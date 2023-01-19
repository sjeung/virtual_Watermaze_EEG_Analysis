% initialize EEGLAB
eeglab

% initialize fieldtrip
ft_defaults

if strcmp(pwd, 'P:\Berrak_Hosgoren\WM_analysis_channel_level')
    projectPath = 'P:\Berrak_Hosgoren';
else
    projectPath = 'C:\Users\BERRAK\Desktop\BPNLab\Watermaze';
end


% add other utilities to path
addpath(genpath(fullfile(projectPath,'\Analysis')))

% participant IDs for each loop 
participantsPreproc     = [81001:81010,82001,82002, 83001:83003, 83005:83009];

% configuration
WM_config; 

force_recompute = 0;

%% STEP 01: Import files

% WM_01_import.m


%% STEP 02: Preprocessing %%

% loop over participants

for Pi = 1:numel(participantsPreproc)
    
    subject = participantsPreproc(Pi);
    participantFolder = fullfile(bemobil_config.study_folder, bemobil_config.raw_EEGLAB_data_folder, [num2str(subject)]);
    
    % Trim files
    %--------------------------------------------------------------------------------------------------------------------------
    
    rawFileNameEEG          = [num2str(subject') '_merged_EEG.set'];
    trimmedFileNameEEG      = [num2str(subject) '_merged_EEG_trimmed.set'];
    
    if ~exist(fullfile(participantFolder, trimmedFileNameEEG), 'file')
        
        rawEEG       = pop_loadset('filepath', participantFolder ,'filename', rawFileNameEEG);
        [trimmedEEG] = WM_02_trim(rawEEG);
        pop_saveset(trimmedEEG, 'filepath', participantFolder ,'filename', trimmedFileNameEEG)
        
    else
        trimmedEEG =  pop_loadset('filepath', participantFolder ,'filename', trimmedFileNameEEG);
    end
    

    % Preprocess Data 
    %--------------------------------------------------------------------------------------------------------------------------
    
    % prepare filepaths and check if already done
	disp(['Subject #' num2str(subject)]);
    
	STUDY = []; CURRENTSTUDY = 0; ALLEEG = [];  CURRENTSET=[]; EEG=[]; EEG_interp_avref = []; EEG_single_subject_final = [];
	
	input_filepath = [bemobil_config.study_folder bemobil_config.raw_EEGLAB_data_folder bemobil_config.filename_prefix num2str(subject)];
	output_filepath = [bemobil_config.study_folder bemobil_config.single_subject_analysis_folder bemobil_config.filename_prefix num2str(subject)];
	
	try
		% load completely processed file
		EEG_single_subject_final = pop_loadset('filename', [ bemobil_config.filename_prefix num2str(subject)...
			'_' bemobil_config.single_subject_cleaned_ICA_filename], 'filepath', output_filepath);
    catch
        disp('...failed. Computing now.')
    end
	
    
	if ~force_recompute && exist('EEG_single_subject_final','var') && ~isempty(EEG_single_subject_final)
		clear EEG_single_subject_final
		disp('Subject is completely preprocessed already.')
		continue  
    end
	
	% load data that is provided by the BIDS importer
    % make sure the data is stored in double precision, large datafiles are supported, and no memory mapped objects are
    % used but data is processed locally
	
    try 
        pop_editoptions( 'option_saveversion6', 0, 'option_single', 0, 'option_memmapdata', 0);
    catch
        warning('Could NOT edit EEGLAB memory options!!'); 
    end
    
    % load files that were created from xdf to BIDS to EEGLAB
    EEG = trimmedEEG;

    % processing wrappers for basic processing and AMICA
    
    % do basic preprocessing, line noise removal, and channel interpolation
	[ALLEEG, EEG_preprocessed, CURRENTSET] = bemobil_process_all_EEG_preprocessing(subject, bemobil_config, ALLEEG, EEG, CURRENTSET, force_recompute);
    
    % start the processing pipeline for AMICA
	bemobil_process_all_AMICA(ALLEEG, EEG_preprocessed, CURRENTSET, subject, bemobil_config, force_recompute);
    
    
end

subject

disp('PROCESSING DONE! YOU CAN CLOSE THE WINDOW NOW!')




%---------------------------------------------------------------------------


% Apply bandpass filter

% Before epoching bandpass filter (4-8 Hz) was applied to the data by using eeglab
% FIR(finite impulse response) filter was used.
% First low pass filter then high pass filter was applied. 



%% STEP 03: Extract epochs


% loop over participants
for Pi = 1:numel(participantsPreproc)
   
    subject = participantsPreproc(Pi);
    participantFolder = fullfile(bemobil_config.study_folder, bemobil_config.single_subject_analysis_folder, [num2str(subject)]);
    
    bandpassedFileNameEEG      = [num2str(subject') '_bandpass_filtered.set'];
    epochedFileNameEEG         = [num2str(subject') '_epoched.set'];
    epochedBaselineFileNameEEG = [num2str(subject') '_epoched_baseline.set'];
    
    
    if ~exist(fullfile(participantFolder, epochedFileNameEEG), 'file') && ~exist(fullfile(participantFolder, epochedBaselineFileNameEEG), 'file')
        
        bandpassedEEG =  pop_loadset('filepath', participantFolder ,'filename', bandpassedFileNameEEG);        
        [epochedEEG, epochedEEG_baseline] = WM_03_epoch(bandpassedEEG);       
        pop_saveset(epochedEEG, 'filepath', participantFolder ,'filename', epochedFileNameEEG)
        pop_saveset(epochedEEG_baseline, 'filepath', participantFolder ,'filename', epochedBaselineFileNameEEG)
        
    else
        epochedEEG          =  pop_loadset('filepath', participantFolder ,'filename', epochedFileNameEEG);
        epochedEEG_baseline =  pop_loadset('filepath', participantFolder ,'filename', epochedBaselineFileNameEEG);
    end
      
end    


%% STEP 04.1: ERD Calculation / Main 
% create theta matricies and tables that includes all participants
% encoding/retrieval/baseline intertrial variance
% ERD 

% seperate patient and control participants
patients = [];
controls = [];
count_p = 1; % patients count
count_c = 1; % controls count

% 1. Create matricies that includes each electrodes separetely
%----------------------------------------------------------------

% loop over participants
for Pi = 1:numel(participantsPreproc)
    
    subject                    = participantsPreproc(Pi);
    participantFolder          = fullfile(bemobil_config.study_folder, bemobil_config.single_subject_analysis_folder, [num2str(subject)]);
    epochedFileNameEEG         = [num2str(subject') '_epoched.set'];
    epochedBaselineFileNameEEG = [num2str(subject') '_epoched_baseline.set'];
    epochedEEG                 =  pop_loadset('filepath', participantFolder ,'filename', epochedFileNameEEG);
    epochedEEG_baseline        =  pop_loadset('filepath', participantFolder ,'filename', epochedBaselineFileNameEEG);

    
    % create different matricies for patients and controls
    if contains(num2str(subject), '81') == 1
     
        [variance_fm, variance_allEloc, erd_fm, erd_allEloc] = WM_04_ERD1_main(epochedEEG,epochedEEG_baseline);
        
        varEnMobi_fm_pat(:,:,count_p)  = variance_fm(:,:,1);
        varEnDesk_fm_pat(:,:,count_p)  = variance_fm(:,:,2);
        varRetMobi_fm_pat(:,:,count_p) = variance_fm(:,:,3);
        varRetDesk_fm_pat(:,:,count_p) = variance_fm(:,:,4);
        varBasMobi_fm_pat(:,:,count_p) = variance_fm(:,:,5);
        varBasDesk_fm_pat(:,:,count_p) = variance_fm(:,:,6);
        
        varEnMobi_allEloc_pat(:,:,count_p)  = variance_allEloc(:,:,1);
        varEnDesk_allEloc_pat(:,:,count_p)  = variance_allEloc(:,:,2);
        varRetMobi_allEloc_pat(:,:,count_p) = variance_allEloc(:,:,3);
        varRetDesk_allEloc_pat(:,:,count_p) = variance_allEloc(:,:,4);
        varBasMobi_allEloc_pat(:,:,count_p) = variance_allEloc(:,:,5);
        varBasDesk_allEloc_pat(:,:,count_p) = variance_allEloc(:,:,6);
        
        
        erdEnMobi_fm_pat(:,:,count_p)  = erd_fm(:,:,1);
        erdEnDesk_fm_pat(:,:,count_p)  = erd_fm(:,:,2);
        erdRetMobi_fm_pat(:,:,count_p) = erd_fm(:,:,3);
        erdRetDesk_fm_pat(:,:,count_p) = erd_fm(:,:,4);
        
        erdEnMobi_allEloc_pat(:,:,count_p)  = erd_allEloc(:,:,1);
        erdEnDesk_allEloc_pat(:,:,count_p)  = erd_allEloc(:,:,2);
        erdRetMobi_allEloc_pat(:,:,count_p) = erd_allEloc(:,:,3);
        erdRetDesk_allEloc_pat(:,:,count_p) = erd_allEloc(:,:,4);
       
        
        patients(count_p) = subject;
        count_p = count_p + 1;
        
    else
        
        [variance_fm, variance_allEloc, erd_fm, erd_allEloc] = WM_04_ERD1_main(epochedEEG,epochedEEG_baseline);
        
        varEnMobi_fm_cont(:,:,count_c)  = variance_fm(:,:,1);
        varEnDesk_fm_cont(:,:,count_c)  = variance_fm(:,:,2);
        varRetMobi_fm_cont(:,:,count_c) = variance_fm(:,:,3);
        varRetDesk_fm_cont(:,:,count_c) = variance_fm(:,:,4);
        varBasMobi_fm_cont(:,:,count_c) = variance_fm(:,:,5);
        varBasDesk_fm_cont(:,:,count_c) = variance_fm(:,:,6);
        
        varEnMobi_allEloc_cont(:,:,count_c)  = variance_allEloc(:,:,1);
        varEnDesk_allEloc_cont(:,:,count_c)  = variance_allEloc(:,:,2);
        varRetMobi_allEloc_cont(:,:,count_c) = variance_allEloc(:,:,3);
        varRetDesk_allEloc_cont(:,:,count_c) = variance_allEloc(:,:,4);
        varBasMobi_allEloc_cont(:,:,count_c) = variance_allEloc(:,:,5);
        varBasDesk_allEloc_cont(:,:,count_c) = variance_allEloc(:,:,6);
        
        
        erdEnMobi_fm_cont(:,:,count_c)  = erd_fm(:,:,1);
        erdEnDesk_fm_cont(:,:,count_c)  = erd_fm(:,:,2);
        erdRetMobi_fm_cont(:,:,count_c) = erd_fm(:,:,3);
        erdRetDesk_fm_cont(:,:,count_c) = erd_fm(:,:,4);
        
        erdEnMobi_allEloc_cont(:,:,count_c)  = erd_allEloc(:,:,1);
        erdEnDesk_allEloc_cont(:,:,count_c)  = erd_allEloc(:,:,2);
        erdRetMobi_allEloc_cont(:,:,count_c) = erd_allEloc(:,:,3);
        erdRetDesk_allEloc_cont(:,:,count_c) = erd_allEloc(:,:,4);
        
        
        controls(count_c) = subject;  
        count_c = count_c + 1;
        
    end    
          
end


% save the matricies
% 3D matricies: 
% First dimension: electrodes
% Second dimension: data points
% Third dimension: participants

table_path = 'C:\Users\BERRAK\Desktop\BPNLab\Watermaze\Analysis\Tables\IntertrialVariance';

save(fullfile(table_path,'varEnMobi_fm_pat.mat'), 'varEnMobi_fm_pat');
save(fullfile(table_path,'varEnMobi_fm_cont.mat'), 'varEnMobi_fm_cont');
save(fullfile(table_path,'varEnDesk_fm_pat.mat'), 'varEnDesk_fm_pat');
save(fullfile(table_path,'varEnDesk_fm_cont.mat'), 'varEnDesk_fm_cont');
save(fullfile(table_path,'varRetMobi_fm_pat.mat'), 'varRetMobi_fm_pat');
save(fullfile(table_path,'varRetMobi_fm_cont.mat'), 'varRetMobi_fm_cont');
save(fullfile(table_path,'varRetDesk_fm_pat.mat'), 'varRetDesk_fm_pat');
save(fullfile(table_path,'varRetDesk_fm_cont.mat'), 'varRetDesk_fm_cont');
save(fullfile(table_path,'varBasMobi_fm_pat.mat'), 'varBasMobi_fm_pat');
save(fullfile(table_path,'varBasMobi_fm_cont.mat'), 'varBasMobi_fm_cont');
save(fullfile(table_path,'varBasDesk_fm_pat.mat'), 'varBasDesk_fm_pat');
save(fullfile(table_path,'varBasDesk_fm_cont.mat'), 'varBasDesk_fm_cont');

save(fullfile(table_path,'varEnMobi_allEloc_pat.mat'), 'varEnMobi_allEloc_pat');
save(fullfile(table_path,'varEnMobi_allEloc_cont.mat'), 'varEnMobi_allEloc_cont');
save(fullfile(table_path,'varEnDesk_allEloc_pat.mat'), 'varEnDesk_allEloc_pat');
save(fullfile(table_path,'varEnDesk_allEloc_cont.mat'), 'varEnDesk_allEloc_cont');
save(fullfile(table_path,'varRetMobi_allEloc_pat.mat'), 'varRetMobi_allEloc_pat');
save(fullfile(table_path,'varRetMobi_allEloc_cont.mat'), 'varRetMobi_allEloc_cont');
save(fullfile(table_path,'varRetDesk_allEloc_pat.mat'), 'varRetDesk_allEloc_pat');
save(fullfile(table_path,'varRetDesk_allEloc_cont.mat'), 'varRetDesk_allEloc_cont');
save(fullfile(table_path,'varBasMobi_allEloc_pat.mat'), 'varBasMobi_allEloc_pat');
save(fullfile(table_path,'varBasMobi_allEloc_cont.mat'), 'varBasMobi_allEloc_cont');
save(fullfile(table_path,'varBasDesk_allEloc_pat.mat'), 'varBasDesk_allEloc_pat');
save(fullfile(table_path,'varBasDesk_allEloc_cont.mat'), 'varBasDesk_allEloc_cont');

table_path = 'C:\Users\BERRAK\Desktop\BPNLab\Watermaze\Analysis\Tables\ERD';

save(fullfile(table_path,'erdEnMobi_fm_pat.mat'), 'erdEnMobi_fm_pat');
save(fullfile(table_path,'erdEnMobi_fm_cont.mat'), 'erdEnMobi_fm_cont');
save(fullfile(table_path,'erdEnDesk_fm_pat.mat'), 'erdEnDesk_fm_pat');
save(fullfile(table_path,'erdEnDesk_fm_cont.mat'), 'erdEnDesk_fm_cont');
save(fullfile(table_path,'erdRetMobi_fm_pat.mat'), 'erdRetMobi_fm_pat');
save(fullfile(table_path,'erdRetMobi_fm_cont.mat'), 'erdRetMobi_fm_cont');
save(fullfile(table_path,'erdRetDesk_fm_pat.mat'), 'erdRetDesk_fm_pat');
save(fullfile(table_path,'erdRetDesk_fm_cont.mat'), 'erdRetDesk_fm_cont');

save(fullfile(table_path,'erdEnMobi_allEloc_pat.mat'), 'erdEnMobi_allEloc_pat');
save(fullfile(table_path,'erdEnMobi_allEloc_cont.mat'), 'erdEnMobi_allEloc_cont');
save(fullfile(table_path,'erdEnDesk_allEloc_pat.mat'), 'erdEnDesk_allEloc_pat');
save(fullfile(table_path,'erdEnDesk_allEloc_cont.mat'), 'erdEnDesk_allEloc_cont');
save(fullfile(table_path,'erdRetMobi_allEloc_pat.mat'), 'erdRetMobi_allEloc_pat');
save(fullfile(table_path,'erdRetMobi_allEloc_cont.mat'), 'erdRetMobi_allEloc_cont');
save(fullfile(table_path,'erdRetDesk_allEloc_pat.mat'), 'erdRetDesk_allEloc_pat');
save(fullfile(table_path,'erdRetDesk_allEloc_cont.mat'), 'erdRetDesk_allEloc_cont');


% 2. Create theta matricies and tables that includes average of ERD values
% over data points
%---------------------------------------------------------------------------

% loop over patients
for Pi = 1:(count_p-1)
    
    meanTime_fm_pat(:,1,Pi) = mean(erdEnMobi_fm_pat(:,:,Pi), 2);
    meanTime_fm_pat(:,2,Pi) = mean(erdEnDesk_fm_pat(:,:,Pi), 2);
    meanTime_fm_pat(:,3,Pi) = mean(erdRetMobi_fm_pat(:,:,Pi), 2);
    meanTime_fm_pat(:,4,Pi) = mean(erdRetDesk_fm_pat(:,:,Pi), 2);
    
    meanTime_allEloc_pat(:,1,Pi) = mean(erdEnMobi_allEloc_pat(:,:,Pi), 2);
    meanTime_allEloc_pat(:,2,Pi) = mean(erdEnDesk_allEloc_pat(:,:,Pi), 2);
    meanTime_allEloc_pat(:,3,Pi) = mean(erdRetMobi_allEloc_pat(:,:,Pi), 2);
    meanTime_allEloc_pat(:,4,Pi) = mean(erdRetDesk_allEloc_pat(:,:,Pi), 2);
    
    
end    

% loop over controls
for Ci = 1:(count_c-1)
    
    meanTime_fm_cont(:,1,Ci) = mean(erdEnMobi_fm_cont(:,:,Ci), 2);
    meanTime_fm_cont(:,2,Ci) = mean(erdEnDesk_fm_cont(:,:,Ci), 2);
    meanTime_fm_cont(:,3,Ci) = mean(erdRetMobi_fm_cont(:,:,Ci), 2);
    meanTime_fm_cont(:,4,Ci) = mean(erdRetDesk_fm_cont(:,:,Ci), 2);
    
    meanTime_allEloc_cont(:,1,Ci) = mean(erdEnMobi_allEloc_cont(:,:,Ci), 2);
    meanTime_allEloc_cont(:,2,Ci) = mean(erdEnDesk_allEloc_cont(:,:,Ci), 2);
    meanTime_allEloc_cont(:,3,Ci) = mean(erdRetMobi_allEloc_cont(:,:,Ci), 2);
    meanTime_allEloc_cont(:,4,Ci) = mean(erdRetDesk_allEloc_cont(:,:,Ci), 2);
end


% save them

table_path = 'C:\Users\BERRAK\Desktop\BPNLab\Watermaze\Analysis\Tables\AverageOverTime';

save(fullfile(table_path,'meanTime_fm_pat.mat'), 'meanTime_fm_pat');
save(fullfile(table_path,'meanTime_fm_cont.mat'), 'meanTime_fm_cont');
save(fullfile(table_path,'meanTime_allEloc_pat.mat'), 'meanTime_allEloc_pat');
save(fullfile(table_path,'meanTime_allEloc_cont.mat'), 'meanTime_allEloc_cont');


% 3. Create theta matricies and tables that includes average of ERD values
% over electrodes (time is already averaged)
%---------------------------------------------------------------------------

% loop over patients
for Pi = 1:(count_p-1)
    
    meanEloc_fm_pat(Pi,:)      = mean(meanTime_fm_pat(:,:,Pi), 1);
    meanEloc_allEloc_pat(Pi,:) = mean(meanTime_allEloc_pat(:,:,Pi), 1);
    
end    

% loop over controls
for Ci = 1:(count_c-1)
    
    meanEloc_fm_cont(Ci,:)      = mean(meanTime_fm_cont(:,:,Ci), 1);
    meanEloc_allEloc_cont(Ci,:) = mean(meanTime_allEloc_cont(:,:,Ci), 1);
    
end


table_path = 'C:\Users\BERRAK\Desktop\BPNLab\Watermaze\Analysis\Tables\AverageOverEloc';

patients = cellstr(string(patients));
controls = cellstr(string(controls));

column_names = {'Encoding-MoBI','Encoding-Desktop','Retrieval-MoBI','Retrieval-Desktop'};

% create theta tables and save them
%-----------------------------------
table_meanEloc_fm_pat       = array2table(meanEloc_fm_pat, 'VariableNames', column_names, 'RowNames',patients);
table_meanEloc_fm_cont      = array2table(meanEloc_fm_cont, 'VariableNames', column_names, 'RowNames',controls);
table_meanEloc_allEloc_pat  = array2table(meanEloc_allEloc_pat, 'VariableNames', column_names, 'RowNames',patients);
table_meanEloc_allEloc_cont = array2table(meanEloc_allEloc_cont, 'VariableNames', column_names, 'RowNames',controls);

save(fullfile(table_path,'table_meanEloc_fm_pat.mat'),'table_meanEloc_fm_pat');
save(fullfile(table_path,'table_meanEloc_fm_cont.mat'),'table_meanEloc_fm_cont');
save(fullfile(table_path,'table_meanEloc_allEloc_pat.mat'),'table_meanEloc_allEloc_pat');
save(fullfile(table_path,'table_meanEloc_allEloc_cont.mat'),'table_meanEloc_allEloc_cont');

%--------------------------------------
% save them also as matricies
save(fullfile(table_path,'meanEloc_fm_pat.mat'), 'meanEloc_fm_pat');
save(fullfile(table_path,'meanEloc_fm_cont.mat'), 'meanEloc_fm_cont');
save(fullfile(table_path,'meanEloc_allEloc_pat.mat'), 'meanEloc_allEloc_pat');
save(fullfile(table_path,'meanEloc_allEloc_cont.mat'), 'meanEloc_allEloc_cont');



%% STEP 04.2: ERD Calculation / Rotation
% create matricies and tables that includes all participants
% rotated/unrotated retrieval epochs

% seperate patient and control participants
patients = [];
controls = [];
count_p = 1; % patients count
count_c = 1; % controls count


% 1. Create matricies that includes each electrodes separetely
%----------------------------------------------------------------------

% loop over participants
for Pi = 1:numel(participantsPreproc)
    
    subject                    = participantsPreproc(Pi);
    participantFolder          = fullfile(bemobil_config.study_folder, bemobil_config.single_subject_analysis_folder, [num2str(subject)]);
    epochedFileNameEEG         = [num2str(subject') '_epoched.set'];
    epochedEEG                 =  pop_loadset('filepath', participantFolder ,'filename', epochedFileNameEEG);
  
    
    % create different matricies for patients and controls
    if contains(num2str(subject), '81') == 1
        [rotation_var_fm, rotation_var_allEloc] = WM_04_ERD2_rotation(epochedEEG);
        
        rot0MoBI_varfm_p(:,:,count_p)   = rotation_var_fm(:,:,1);
        rot0Desk_varfm_p(:,:,count_p)   = rotation_var_fm(:,:,2);
        rot90MoBI_varfm_p(:,:,count_p)  = rotation_var_fm(:,:,3);
        rot90Desk_varfm_p(:,:,count_p)  = rotation_var_fm(:,:,4);
        rot180MoBI_varfm_p(:,:,count_p) = rotation_var_fm(:,:,5);
        rot180Desk_varfm_p(:,:,count_p) = rotation_var_fm(:,:,6);
        rot270MoBI_varfm_p(:,:,count_p) = rotation_var_fm(:,:,7);
        rot270Desk_varfm_p(:,:,count_p) = rotation_var_fm(:,:,8);
        
        rot0MoBI_varall_p(:,:,count_p)   = rotation_var_allEloc(:,:,1);
        rot0Desk_varall_p(:,:,count_p)   = rotation_var_allEloc(:,:,2);
        rot90MoBI_varall_p(:,:,count_p)  = rotation_var_allEloc(:,:,3);
        rot90Desk_varall_p(:,:,count_p)  = rotation_var_allEloc(:,:,4);
        rot180MoBI_varall_p(:,:,count_p) = rotation_var_allEloc(:,:,5);
        rot180Desk_varall_p(:,:,count_p) = rotation_var_allEloc(:,:,6);
        rot270MoBI_varall_p(:,:,count_p) = rotation_var_allEloc(:,:,7);
        rot270Desk_varall_p(:,:,count_p) = rotation_var_allEloc(:,:,8);
        
        patients(count_p) = subject; 
        count_p = count_p + 1;
        
    else
        [rotation_var_fm, rotation_var_allEloc] = WM_04_ERD2_rotation(epochedEEG);

        rot0MoBI_varfm_c(:,:,count_c)   = rotation_var_fm(:,:,1);
        rot0Desk_varfm_c(:,:,count_c)   = rotation_var_fm(:,:,2);
        rot90MoBI_varfm_c(:,:,count_c)  = rotation_var_fm(:,:,3);
        rot90Desk_varfm_c(:,:,count_c)  = rotation_var_fm(:,:,4);
        rot180MoBI_varfm_c(:,:,count_c) = rotation_var_fm(:,:,5);
        rot180Desk_varfm_c(:,:,count_c) = rotation_var_fm(:,:,6);
        rot270MoBI_varfm_c(:,:,count_c) = rotation_var_fm(:,:,7);
        rot270Desk_varfm_c(:,:,count_c) = rotation_var_fm(:,:,8);
        
        rot0MoBI_varall_c(:,:,count_c)   = rotation_var_allEloc(:,:,1);
        rot0Desk_varall_c(:,:,count_c)   = rotation_var_allEloc(:,:,2);
        rot90MoBI_varall_c(:,:,count_c)  = rotation_var_allEloc(:,:,3);
        rot90Desk_varall_c(:,:,count_c)  = rotation_var_allEloc(:,:,4);
        rot180MoBI_varall_c(:,:,count_c) = rotation_var_allEloc(:,:,5);
        rot180Desk_varall_c(:,:,count_c) = rotation_var_allEloc(:,:,6);
        rot270MoBI_varall_c(:,:,count_c) = rotation_var_allEloc(:,:,7);
        rot270Desk_varall_c(:,:,count_c) = rotation_var_allEloc(:,:,8);
        
        controls(count_c) = subject; 
        count_c = count_c + 1;
        
    end    
    
end    


% save the matricies
% 3D matricies: 
% First dimension: electrodes
% Second dimension: data points
% Third dimension: participants

table_path = 'C:\Users\BERRAK\Desktop\BPNLab\Watermaze\Analysis\Tables\IntertrialVariance\Rotation';

save(fullfile(table_path,'rot0MoBI_varfm_p.mat'), 'rot0MoBI_varfm_p');
save(fullfile(table_path,'rot0Desk_varfm_p.mat'), 'rot0Desk_varfm_p');
save(fullfile(table_path,'rot90MoBI_varfm_p.mat'), 'rot90MoBI_varfm_p');
save(fullfile(table_path,'rot90Desk_varfm_p.mat'), 'rot90Desk_varfm_p');
save(fullfile(table_path,'rot180MoBI_varfm_p.mat'), 'rot180MoBI_varfm_p');
save(fullfile(table_path,'rot180Desk_varfm_p.mat'), 'rot180Desk_varfm_p');
save(fullfile(table_path,'rot270MoBI_varfm_p.mat'), 'rot270MoBI_varfm_p');
save(fullfile(table_path,'rot270Desk_varfm_p.mat'), 'rot270Desk_varfm_p');

save(fullfile(table_path,'rot0MoBI_varall_p.mat'), 'rot0MoBI_varall_p');
save(fullfile(table_path,'rot0Desk_varall_p.mat'), 'rot0Desk_varall_p');
save(fullfile(table_path,'rot90MoBI_varall_p.mat'), 'rot90MoBI_varall_p');
save(fullfile(table_path,'rot90Desk_varall_p.mat'), 'rot90Desk_varall_p');
save(fullfile(table_path,'rot180MoBI_varall_p.mat'), 'rot180MoBI_varall_p');
save(fullfile(table_path,'rot180Desk_varall_p.mat'), 'rot180Desk_varall_p');
save(fullfile(table_path,'rot270MoBI_varall_p.mat'), 'rot270MoBI_varall_p');
save(fullfile(table_path,'rot270Desk_varall_p.mat'), 'rot270Desk_varall_p');

save(fullfile(table_path,'rot0MoBI_varfm_c.mat'), 'rot0MoBI_varfm_c');
save(fullfile(table_path,'rot0Desk_varfm_c.mat'), 'rot0Desk_varfm_c');
save(fullfile(table_path,'rot90MoBI_varfm_c.mat'), 'rot90MoBI_varfm_c');
save(fullfile(table_path,'rot90Desk_varfm_c.mat'), 'rot90Desk_varfm_c');
save(fullfile(table_path,'rot180MoBI_varfm_c.mat'), 'rot180MoBI_varfm_c');
save(fullfile(table_path,'rot180Desk_varfm_c.mat'), 'rot180Desk_varfm_c');
save(fullfile(table_path,'rot270MoBI_varfm_c.mat'), 'rot270MoBI_varfm_c');
save(fullfile(table_path,'rot270Desk_varfm_c.mat'), 'rot270Desk_varfm_c');

save(fullfile(table_path,'rot0MoBI_varall_c.mat'), 'rot0MoBI_varall_c');
save(fullfile(table_path,'rot0Desk_varall_c.mat'), 'rot0Desk_varall_c');
save(fullfile(table_path,'rot90MoBI_varall_c.mat'), 'rot90MoBI_varall_c');
save(fullfile(table_path,'rot90Desk_varall_c.mat'), 'rot90Desk_varall_c');
save(fullfile(table_path,'rot180MoBI_varall_c.mat'), 'rot180MoBI_varall_c');
save(fullfile(table_path,'rot180Desk_varall_c.mat'), 'rot180Desk_varall_c');
save(fullfile(table_path,'rot270MoBI_varall_c.mat'), 'rot270MoBI_varall_c');
save(fullfile(table_path,'rot270Desk_varall_c.mat'), 'rot270Desk_varall_c');


% calculate the erd/ers values from intertrial variances
%---------------------------------------------------------

% load the baseline intertrial variance
load('C:\Users\BERRAK\Desktop\BPNLab\Watermaze\Analysis\Tables\IntertrialVariance\varBasMobi_fm_pat.mat');
load('C:\Users\BERRAK\Desktop\BPNLab\Watermaze\Analysis\Tables\IntertrialVariance\varBasDesk_fm_pat.mat');
load('C:\Users\BERRAK\Desktop\BPNLab\Watermaze\Analysis\Tables\IntertrialVariance\varBasMobi_fm_cont.mat');
load('C:\Users\BERRAK\Desktop\BPNLab\Watermaze\Analysis\Tables\IntertrialVariance\varBasDesk_fm_cont.mat');

load('C:\Users\BERRAK\Desktop\BPNLab\Watermaze\Analysis\Tables\IntertrialVariance\varBasMobi_allEloc_pat.mat');
load('C:\Users\BERRAK\Desktop\BPNLab\Watermaze\Analysis\Tables\IntertrialVariance\varBasDesk_allEloc_pat.mat');
load('C:\Users\BERRAK\Desktop\BPNLab\Watermaze\Analysis\Tables\IntertrialVariance\varBasMobi_allEloc_cont.mat');
load('C:\Users\BERRAK\Desktop\BPNLab\Watermaze\Analysis\Tables\IntertrialVariance\varBasDesk_allEloc_cont.mat');


% all electrodes

% iterate over patients
for Pi = 1:numel(patients)
    rot0MoBI_erdall_p(:,:,Pi) = ((rot0MoBI_varall_p(:,:,Pi) - varBasMobi_allEloc_pat(:,:,Pi))./varBasMobi_allEloc_pat(:,:,Pi)).*100;
    rot0Desk_erdall_p(:,:,Pi) = ((rot0Desk_varall_p(:,:,Pi) - varBasDesk_allEloc_pat(:,:,Pi))./varBasDesk_allEloc_pat(:,:,Pi)).*100;
    rot90MoBI_erdall_p(:,:,Pi) = ((rot90MoBI_varall_p(:,:,Pi) - varBasMobi_allEloc_pat(:,:,Pi))./varBasMobi_allEloc_pat(:,:,Pi)).*100;
    rot90Desk_erdall_p(:,:,Pi) = ((rot90Desk_varall_p(:,:,Pi) - varBasDesk_allEloc_pat(:,:,Pi))./varBasDesk_allEloc_pat(:,:,Pi)).*100;
    rot180MoBI_erdall_p(:,:,Pi) = ((rot180MoBI_varall_p(:,:,Pi) - varBasMobi_allEloc_pat(:,:,Pi))./varBasMobi_allEloc_pat(:,:,Pi)).*100;
    rot180Desk_erdall_p(:,:,Pi) = ((rot180Desk_varall_p(:,:,Pi) - varBasDesk_allEloc_pat(:,:,Pi))./varBasDesk_allEloc_pat(:,:,Pi)).*100;
    rot270MoBI_erdall_p(:,:,Pi) = ((rot270MoBI_varall_p(:,:,Pi) - varBasMobi_allEloc_pat(:,:,Pi))./varBasMobi_allEloc_pat(:,:,Pi)).*100;
    rot270Desk_erdall_p(:,:,Pi) = ((rot270Desk_varall_p(:,:,Pi) - varBasDesk_allEloc_pat(:,:,Pi))./varBasDesk_allEloc_pat(:,:,Pi)).*100;
end

% iterate over controls
for Ci = 1:numel(controls)
    rot0MoBI_erdall_c(:,:,Ci) = ((rot0MoBI_varall_c(:,:,Ci) - varBasMobi_allEloc_cont(:,:,Ci))./varBasMobi_allEloc_cont(:,:,Ci)).*100;
    rot0Desk_erdall_c(:,:,Ci) = ((rot0Desk_varall_c(:,:,Ci) - varBasDesk_allEloc_cont(:,:,Ci))./varBasDesk_allEloc_cont(:,:,Ci)).*100;
    rot90MoBI_erdall_c(:,:,Ci) = ((rot90MoBI_varall_c(:,:,Ci) - varBasMobi_allEloc_cont(:,:,Ci))./varBasMobi_allEloc_cont(:,:,Ci)).*100;
    rot90Desk_erdall_c(:,:,Ci) = ((rot90Desk_varall_c(:,:,Ci) - varBasDesk_allEloc_cont(:,:,Ci))./varBasDesk_allEloc_cont(:,:,Ci)).*100;
    rot180MoBI_erdall_c(:,:,Ci) = ((rot180MoBI_varall_c(:,:,Ci) - varBasMobi_allEloc_cont(:,:,Ci))./varBasMobi_allEloc_cont(:,:,Ci)).*100;
    rot180Desk_erdall_c(:,:,Ci) = ((rot180Desk_varall_c(:,:,Ci) - varBasDesk_allEloc_cont(:,:,Ci))./varBasDesk_allEloc_cont(:,:,Ci)).*100;
    rot270MoBI_erdall_c(:,:,Ci) = ((rot270MoBI_varall_c(:,:,Ci) - varBasMobi_allEloc_cont(:,:,Ci))./varBasMobi_allEloc_cont(:,:,Ci)).*100;
    rot270Desk_erdall_c(:,:,Ci) = ((rot270Desk_varall_c(:,:,Ci) - varBasDesk_allEloc_cont(:,:,Ci))./varBasDesk_allEloc_cont(:,:,Ci)).*100;
end


% interested electrodes

% interested eloctrode names: {'y1','y2','y3','y25','y32'}
eloc = [33,34,35,57,64];


rot0MoBI_erdfm_p(:,:,:)   = rot0MoBI_erdall_p(eloc,:,:);
rot0Desk_erdfm_p(:,:,:)   = rot0Desk_erdall_p(eloc,:,:);
rot90MoBI_erdfm_p(:,:,:)  = rot90MoBI_erdall_p(eloc,:,:);
rot90Desk_erdfm_p(:,:,:)  = rot90Desk_erdall_p(eloc,:,:);
rot180MoBI_erdfm_p(:,:,:) = rot180MoBI_erdall_p(eloc,:,:); 
rot180Desk_erdfm_p(:,:,:) = rot180Desk_erdall_p(eloc,:,:);
rot270MoBI_erdfm_p(:,:,:) = rot270MoBI_erdall_p(eloc,:,:); 
rot270Desk_erdfm_p(:,:,:) = rot270Desk_erdall_p(eloc,:,:);

rot0MoBI_erdfm_c(:,:,:)   = rot0MoBI_erdall_c(eloc,:,:);
rot0Desk_erdfm_c(:,:,:)   = rot0Desk_erdall_c(eloc,:,:);
rot90MoBI_erdfm_c(:,:,:)  = rot90MoBI_erdall_c(eloc,:,:);
rot90Desk_erdfm_c(:,:,:)  = rot90Desk_erdall_c(eloc,:,:);
rot180MoBI_erdfm_c(:,:,:) = rot180MoBI_erdall_c(eloc,:,:);
rot180Desk_erdfm_c(:,:,:) = rot180Desk_erdall_c(eloc,:,:);
rot270MoBI_erdfm_c(:,:,:) = rot270MoBI_erdall_c(eloc,:,:);
rot270Desk_erdfm_c(:,:,:) = rot270Desk_erdall_c(eloc,:,:);


% save the matricies
%---------------------------------------------------------

table_path = 'C:\Users\BERRAK\Desktop\BPNLab\Watermaze\Analysis\Tables\ERD\Rotation';

save(fullfile(table_path,'rot0MoBI_erdfm_p.mat'), 'rot0MoBI_erdfm_p');
save(fullfile(table_path,'rot0Desk_erdfm_p.mat'), 'rot0Desk_erdfm_p');
save(fullfile(table_path,'rot90MoBI_erdfm_p.mat'), 'rot90MoBI_erdfm_p');
save(fullfile(table_path,'rot90Desk_erdfm_p.mat'), 'rot90Desk_erdfm_p');
save(fullfile(table_path,'rot180MoBI_erdfm_p.mat'), 'rot180MoBI_erdfm_p');
save(fullfile(table_path,'rot180Desk_erdfm_p.mat'), 'rot180Desk_erdfm_p');
save(fullfile(table_path,'rot270MoBI_erdfm_p.mat'), 'rot270MoBI_erdfm_p');
save(fullfile(table_path,'rot270Desk_erdfm_p.mat'), 'rot270Desk_erdfm_p');

save(fullfile(table_path,'rot0MoBI_erdall_p.mat'), 'rot0MoBI_erdall_p');
save(fullfile(table_path,'rot0Desk_erdall_p.mat'), 'rot0Desk_erdall_p');
save(fullfile(table_path,'rot90MoBI_erdall_p.mat'), 'rot90MoBI_erdall_p');
save(fullfile(table_path,'rot90Desk_erdall_p.mat'), 'rot90Desk_erdall_p');
save(fullfile(table_path,'rot180MoBI_erdall_p.mat'), 'rot180MoBI_erdall_p');
save(fullfile(table_path,'rot180Desk_erdall_p.mat'), 'rot180Desk_erdall_p');
save(fullfile(table_path,'rot270MoBI_erdall_p.mat'), 'rot270MoBI_erdall_p');
save(fullfile(table_path,'rot270Desk_erdall_p.mat'), 'rot270Desk_erdall_p');

save(fullfile(table_path,'rot0MoBI_erdfm_c.mat'), 'rot0MoBI_erdfm_c');
save(fullfile(table_path,'rot0Desk_erdfm_c.mat'), 'rot0Desk_erdfm_c');
save(fullfile(table_path,'rot90MoBI_erdfm_c.mat'), 'rot90MoBI_erdfm_c');
save(fullfile(table_path,'rot90Desk_erdfm_c.mat'), 'rot90Desk_erdfm_c');
save(fullfile(table_path,'rot180MoBI_erdfm_c.mat'), 'rot180MoBI_erdfm_c');
save(fullfile(table_path,'rot180Desk_erdfm_c.mat'), 'rot180Desk_erdfm_c');
save(fullfile(table_path,'rot270MoBI_erdfm_c.mat'), 'rot270MoBI_erdfm_c');
save(fullfile(table_path,'rot270Desk_erdfm_c.mat'), 'rot270Desk_erdfm_c');

save(fullfile(table_path,'rot0MoBI_erdall_c.mat'), 'rot0MoBI_erdall_c');
save(fullfile(table_path,'rot0Desk_erdall_c.mat'), 'rot0Desk_erdall_c');
save(fullfile(table_path,'rot90MoBI_erdall_c.mat'), 'rot90MoBI_erdall_c');
save(fullfile(table_path,'rot90Desk_erdall_c.mat'), 'rot90Desk_erdall_c');
save(fullfile(table_path,'rot180MoBI_erdall_c.mat'), 'rot180MoBI_erdall_c');
save(fullfile(table_path,'rot180Desk_erdall_c.mat'), 'rot180Desk_erdall_c');
save(fullfile(table_path,'rot270MoBI_erdall_c.mat'), 'rot270MoBI_erdall_c');
save(fullfile(table_path,'rot270Desk_erdall_c.mat'), 'rot270Desk_erdall_c');



% 2. Create theta matricies and tables that includes average of ERD values
% over data points
%---------------------------------------------------------------------------

% loop over patients
for Pi = 1:(count_p-1)
    
    rot_meanTime_fm_p(:,1,Pi) = mean(rot0MoBI_erdfm_p(:,:,Pi), 2);
    rot_meanTime_fm_p(:,2,Pi) = mean(rot0Desk_erdfm_p(:,:,Pi), 2);
    rot_meanTime_fm_p(:,3,Pi) = mean(rot90MoBI_erdfm_p(:,:,Pi), 2);
    rot_meanTime_fm_p(:,4,Pi) = mean(rot90Desk_erdfm_p(:,:,Pi), 2);
    rot_meanTime_fm_p(:,5,Pi) = mean(rot180MoBI_erdfm_p(:,:,Pi), 2);
    rot_meanTime_fm_p(:,6,Pi) = mean(rot180Desk_erdfm_p(:,:,Pi), 2);
    rot_meanTime_fm_p(:,7,Pi) = mean(rot270MoBI_erdfm_p(:,:,Pi), 2);
    rot_meanTime_fm_p(:,8,Pi) = mean(rot270Desk_erdfm_p(:,:,Pi), 2);
    
    rot_meanTime_all_p(:,1,Pi) = mean(rot0MoBI_erdall_p(:,:,Pi), 2);
    rot_meanTime_all_p(:,2,Pi) = mean(rot0Desk_erdall_p(:,:,Pi), 2);
    rot_meanTime_all_p(:,3,Pi) = mean(rot90MoBI_erdall_p(:,:,Pi), 2);
    rot_meanTime_all_p(:,4,Pi) = mean(rot90Desk_erdall_p(:,:,Pi), 2);
    rot_meanTime_all_p(:,5,Pi) = mean(rot180MoBI_erdall_p(:,:,Pi), 2);
    rot_meanTime_all_p(:,6,Pi) = mean(rot180Desk_erdall_p(:,:,Pi), 2);
    rot_meanTime_all_p(:,7,Pi) = mean(rot270MoBI_erdall_p(:,:,Pi), 2);
    rot_meanTime_all_p(:,8,Pi) = mean(rot270Desk_erdall_p(:,:,Pi), 2);
    
    
end    

% loop over controls
for Ci = 1:(count_c-1)
    
    rot_meanTime_fm_c(:,1,Ci) = mean(rot0MoBI_erdfm_c(:,:,Ci), 2);
    rot_meanTime_fm_c(:,2,Ci) = mean(rot0Desk_erdfm_c(:,:,Ci), 2);
    rot_meanTime_fm_c(:,3,Ci) = mean(rot90MoBI_erdfm_c(:,:,Ci), 2);
    rot_meanTime_fm_c(:,4,Ci) = mean(rot90Desk_erdfm_c(:,:,Ci), 2);
    rot_meanTime_fm_c(:,5,Ci) = mean(rot180MoBI_erdfm_c(:,:,Ci), 2);
    rot_meanTime_fm_c(:,6,Ci) = mean(rot180Desk_erdfm_c(:,:,Ci), 2);
    rot_meanTime_fm_c(:,7,Ci) = mean(rot270MoBI_erdfm_c(:,:,Ci), 2);
    rot_meanTime_fm_c(:,8,Ci) = mean(rot270Desk_erdfm_c(:,:,Ci), 2);
    
    rot_meanTime_all_c(:,1,Ci) = mean(rot0MoBI_erdall_c(:,:,Ci), 2);
    rot_meanTime_all_c(:,2,Ci) = mean(rot0Desk_erdall_c(:,:,Ci), 2);
    rot_meanTime_all_c(:,3,Ci) = mean(rot90MoBI_erdall_c(:,:,Ci), 2);
    rot_meanTime_all_c(:,4,Ci) = mean(rot90Desk_erdall_c(:,:,Ci), 2);
    rot_meanTime_all_c(:,5,Ci) = mean(rot180MoBI_erdall_c(:,:,Ci), 2);
    rot_meanTime_all_c(:,6,Ci) = mean(rot180Desk_erdall_c(:,:,Ci), 2);
    rot_meanTime_all_c(:,7,Ci) = mean(rot270MoBI_erdall_c(:,:,Ci), 2);
    rot_meanTime_all_c(:,8,Ci) = mean(rot270Desk_erdall_c(:,:,Ci), 2);
    
end


% save them

table_path = 'C:\Users\BERRAK\Desktop\BPNLab\Watermaze\Analysis\Tables\AverageOverTime\Rotation';

save(fullfile(table_path,'rot_meanTime_fm_p.mat'), 'rot_meanTime_fm_p');
save(fullfile(table_path,'rot_meanTime_fm_c.mat'), 'rot_meanTime_fm_c');
save(fullfile(table_path,'rot_meanTime_all_p.mat'), 'rot_meanTime_all_p');
save(fullfile(table_path,'rot_meanTime_all_c.mat'), 'rot_meanTime_all_c');


% 3. Create theta matricies and tables that includes average of ERD values
% over electrodes (time is already averaged)
%---------------------------------------------------------------------------

% loop over patients
for Pi = 1:(count_p-1)
    
    rot_meanEloc_fm_p(Pi,:)  = mean(rot_meanTime_fm_p(:,:,Pi), 1);
    rot_meanEloc_all_p(Pi,:) = mean(rot_meanTime_all_p(:,:,Pi), 1);
    
end    

% loop over controls
for Ci = 1:(count_c-1)
    
    rot_meanEloc_fm_c(Ci,:)  = mean(rot_meanTime_fm_c(:,:,Ci), 1);
    rot_meanEloc_all_c(Ci,:) = mean(rot_meanTime_all_c(:,:,Ci), 1);
    
end



table_path = 'C:\Users\BERRAK\Desktop\BPNLab\Watermaze\Analysis\Tables\AverageOverEloc\Rotation';

patients = cellstr(string(patients));
controls = cellstr(string(controls));

column_names = {'Rotation0-MoBI','Rotation0-Desktop','Rotation90-MoBI','Rotation90-Desktop','Rotation180-MoBI','Rotation180-Desktop','Rotation270-MoBI','Rotation270-Desktop'};

% create theta tables and save them
%-----------------------------------
table_rot_meanEloc_fm_p   = array2table(rot_meanEloc_fm_p, 'VariableNames', column_names, 'RowNames',patients);
table_rot_meanEloc_fm_c   = array2table(rot_meanEloc_fm_c, 'VariableNames', column_names, 'RowNames',controls);
table_rot_meanEloc_all_p  = array2table(rot_meanEloc_all_p, 'VariableNames', column_names, 'RowNames',patients);
table_rot_meanEloc_all_c  = array2table(rot_meanEloc_all_c, 'VariableNames', column_names, 'RowNames',controls);

save(fullfile(table_path,'table_rot_meanEloc_fm_p.mat'),'table_rot_meanEloc_fm_p');
save(fullfile(table_path,'table_rot_meanEloc_fm_c.mat'),'table_rot_meanEloc_fm_c');
save(fullfile(table_path,'table_rot_meanEloc_all_p.mat'),'table_rot_meanEloc_all_p');
save(fullfile(table_path,'table_rot_meanEloc_all_c.mat'),'table_rot_meanEloc_all_c');

%--------------------------------------
% save them also as matricies
save(fullfile(table_path,'rot_meanEloc_fm_p.mat'), 'rot_meanEloc_fm_p');
save(fullfile(table_path,'rot_meanEloc_fm_c.mat'), 'rot_meanEloc_fm_c');
save(fullfile(table_path,'rot_meanEloc_all_p.mat'), 'rot_meanEloc_all_p');
save(fullfile(table_path,'rot_meanEloc_all_c.mat'), 'rot_meanEloc_all_c');


%% STEP 04.3: Topographic Map


% load theta matricies 
load('C:\Users\BERRAK\Desktop\BPNLab\Watermaze\Analysis\Tables\AverageOverTime\meanTime_allEloc_cont.mat')
load('C:\Users\BERRAK\Desktop\BPNLab\Watermaze\Analysis\Tables\AverageOverTime\meanTime_allEloc_pat.mat')


% seperate patient and control participants
count_p = 1; % patients count
count_c = 1; % controls count
patients = [];
controls = [];

% loop over subjects
for Si = 1:numel(participantsPreproc)
    
    subject = participantsPreproc(Si);
    
    if contains(num2str(subject), '81') == 1
        patients(count_p) = subject;
        count_p = count_p + 1;
        
    else
        controls(count_c) = subject;
        count_c = count_c + 1;
        
    end    
end


% loop over patients
for Pi = 1:numel(patients)
    
    subject                    = patients(Pi);
    participantFolder          = fullfile(bemobil_config.study_folder, bemobil_config.single_subject_analysis_folder, [num2str(subject)]);
    epochedFileNameEEG         = [num2str(subject') '_epoched.set'];
    epochedEEG                 =  pop_loadset('filepath', participantFolder ,'filename', epochedFileNameEEG);

    % Encoding-MoBI
    f1 = figure(1);
    set(gcf,'Name','Patients Encoding-MoBI')
    set(gcf, 'Position', get(0, 'Screensize'));
    subplot(3,4,Pi)
    title(num2str(subject))
    topoplot(meanTime_allEloc_pat(:,1,Pi), epochedEEG.chanlocs)
    sgtitle('Patients Encoding-MoBI','fontweight','bold','fontsize',18)
    
    % Encoding-Desktop
    f2 = figure(2);
    set(gcf,'Name','Patients Encoding-Desktop')
    set(gcf, 'Position', get(0, 'Screensize'));
    subplot(3,4,Pi)
    title(num2str(subject))
    topoplot(meanTime_allEloc_pat(:,2,Pi), epochedEEG.chanlocs)
    sgtitle('Patients Encoding-Desktop','fontweight','bold','fontsize',18)
    
    % Retrieval-MoBI
    f3 = figure(3);
    set(gcf,'Name','Patients Retrieval-MoBI')
    set(gcf, 'Position', get(0, 'Screensize'));
    subplot(3,4,Pi)
    title(num2str(subject))
    topoplot(meanTime_allEloc_pat(:,3,Pi), epochedEEG.chanlocs)
    sgtitle('Patients Retrieval-MoBI','fontweight','bold','fontsize',18)
    
    % Retrieval-Desktop
    f4 = figure(4);
    set(gcf,'Name','Patients Retrieval-Desktop')
    set(gcf, 'Position', get(0, 'Screensize'));
    subplot(3,4,Pi)
    title(num2str(subject))
    topoplot(meanTime_allEloc_pat(:,4,Pi), epochedEEG.chanlocs)
    sgtitle('Patients Retrieval-Desktop','fontweight','bold','fontsize',18)

end


% loop over controls
for Ci = 1:numel(controls)
    
    subject                    = controls(Ci);
    participantFolder          = fullfile(bemobil_config.study_folder, bemobil_config.single_subject_analysis_folder, [num2str(subject)]);
    epochedFileNameEEG         = [num2str(subject') '_epoched.set'];
    epochedEEG                 =  pop_loadset('filepath', participantFolder ,'filename', epochedFileNameEEG);

    % Encoding-MoBI
    f5 = figure(5);
    set(gcf,'Name','Controls Encoding-MoBI')
    set(gcf, 'Position', get(0, 'Screensize'));
    subplot(3,4,Ci)
    title(num2str(subject))
    topoplot(meanTime_allEloc_cont(:,1,Ci), epochedEEG.chanlocs)
    sgtitle('Controls Encoding-MoBI','fontweight','bold','fontsize',18)

    % Encoding-Desktop
    f6 = figure(6);
    set(gcf,'Name','Controls Encoding-Desktop')
    set(gcf, 'Position', get(0, 'Screensize'));
    subplot(3,4,Ci)
    title(num2str(subject))
    topoplot(meanTime_allEloc_cont(:,2,Ci), epochedEEG.chanlocs)
    sgtitle('Controls Encoding-Desktop','fontweight','bold','fontsize',18)
    
    % Retrieval-MoBI
    f7 = figure(7);
    set(gcf,'Name','Controls Retrieval-MoBI')
    set(gcf, 'Position', get(0, 'Screensize'));
    subplot(3,4,Ci)
    title(num2str(subject))
    topoplot(meanTime_allEloc_cont(:,3,Ci), epochedEEG.chanlocs)
    sgtitle('Controls Retrieval-MoBI','fontweight','bold','fontsize',18)
    
    % Retrieval-Desktop
    f8 = figure(8);
    set(gcf,'Name','Contols Retrieval-Desktop')
    set(gcf, 'Position', get(0, 'Screensize'));
    subplot(3,4,Ci)
    title(num2str(subject))
    topoplot(meanTime_allEloc_cont(:,4,Ci), epochedEEG.chanlocs)
    sgtitle('Contols Retrieval-Desktop','fontweight','bold','fontsize',18)

end


% save the figures
path = 'C:\Users\BERRAK\Desktop\BPNLab\Watermaze\Analysis\Graphs';

f = [f1,f2,f3,f4,f5,f6,f7,f8];

for i = 1:8
    
    saveas(f(i),fullfile(path,[['topo' num2str(i)],'.png']));

end


%% STEP 05: Theta Power Graphs

% WM_05_graphs


%% STEP 06: Regression Graphs

% Create search duration, distance error and position matricies
%------------------------------------------------------------------------

% seperate patient and control participants
count_p = 1; % patients count
count_c = 1; % controls count
patients = [];
controls = [];


% loop over subjects
for Si = 1:numel(participantsPreproc)
    
    subject = participantsPreproc(Si);
    
    if contains(num2str(subject), '81') == 1
        patients(count_p) = subject;
        count_p = count_p + 1;
        
    else
        controls(count_c) = subject;
        count_c = count_c + 1;
        
    end    
end
%


% create seperated matricies of search duration, distance error and positions for patients and controls
searchduration_patients = [];
searchduration_controls = [];
distance_error_patients = [];
distance_error_controls = [];
positions_patients      = [];
position_controls       = [];


% loop over patients
for Pi = 1:numel(patients)
    
    subject                    = patients(Pi);
    participantFolder          = fullfile(bemobil_config.study_folder, bemobil_config.single_subject_analysis_folder, [num2str(subject)]);
    preprocessedFileNameEEG    = [num2str(subject') '_cleaned_with_ICA.set'];
    EEG                        =  pop_loadset('filepath', participantFolder ,'filename', preprocessedFileNameEEG);
    
    [search_duration1,positions1,distance_error1] = WM_06_behavioral(EEG);
    searchduration_patients(:,Pi) = search_duration1;
    positions_patients(:,:,Pi)    = positions1;
    distance_error_patients(:,Pi) = distance_error1;
    

end


% loop over controls
for Ci = 1:numel(controls)
    
    subject                    = controls(Ci);
    participantFolder          = fullfile(bemobil_config.study_folder, bemobil_config.single_subject_analysis_folder, [num2str(subject)]);
    preprocessedFileNameEEG    = [num2str(subject') '_cleaned_with_ICA.set'];
    EEG                        =  pop_loadset('filepath', participantFolder ,'filename', preprocessedFileNameEEG);
    
    [search_duration2,positions2,distance_error2] = WM_06_behavioral(EEG);
    searchduration_controls(:,Ci) = search_duration2;
    positions_controls(:,:,Ci)    = positions2;
    distance_error_controls(:,Ci) = distance_error2;
    

end

% save them

table_path = 'C:\Users\BERRAK\Desktop\BPNLab\Watermaze\Analysis\Tables\Behavioral';

save(fullfile(table_path,'searchduration_patients.mat'), 'searchduration_patients');
save(fullfile(table_path,'searchduration_controls.mat'), 'searchduration_controls');
save(fullfile(table_path,'positions_patients.mat'), 'positions_patients');
save(fullfile(table_path,'positions_controls.mat'), 'positions_controls');
save(fullfile(table_path,'distance_error_patients.mat'), 'distance_error_patients');
save(fullfile(table_path,'distance_error_controls.mat'), 'distance_error_controls');


% Third: Regression Graph
%-----------------------------------------------------------------------------

% WM_06_regression

