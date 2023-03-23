function WM_03_preprocess(Pi)
% preprocess continuous EEG data
%--------------------------------------------------------------------------

% load configs
WM_config; 
WM_bemobil_config;

% make sure the data is stored in double precision, large datafiles are supported, and no memory mapped objects are
% used but data is processed locally
try
    pop_editoptions( 'option_saveversion6', 0, 'option_single', 0, 'option_memmapdata', 0);
catch
    warning('Could NOT edit EEGLAB memory options!!');
end

[trimmedFileNameEEG,trimmedFileDirEEG]      = assemble_file(config_folder.data_folder, config_folder.trimmed_folder,config_folder.trimmedFileNameEEG, Pi); 

% load data 
EEG = pop_loadset('filename', trimmedFileNameEEG, 'filepath', trimmedFileDirEEG);

force_recompute = 0;

disp(['Preprocessing subject #' num2str(Pi)]);

%% processing wrappers for basic processing and AMICA
% do basic preprocessing, line noise removal, and channel interpolation
bemobil_process_all_EEG_preprocessing(Pi, bemobil_config, [], EEG, [], force_recompute);


end