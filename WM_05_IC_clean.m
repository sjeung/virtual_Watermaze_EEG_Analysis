function WM_05_IC_clean(Pi)

% reject components based on ICLabel class probabilities
%--------------------------------------------------------------------------
% classes
% {'Brain'}    {'Muscle'}    {'Eye'}    {'Heart'}    {'Line Noise'}    {'Channel Noise'}    {'Other'}

% load configs
WM_config;

[icaFileName,icaFileDir]            = assemble_file(config_folder.data_folder, config_folder.postAMICA_folder, config_folder.postAMICAFileName, Pi); 
[cleanedFileName,cleanedFileDir]    = assemble_file(config_folder.data_folder, config_folder.cleaned_folder, config_folder.cleanedFileName, Pi);

% load EEG after AMICA
EEG = pop_loadset('filepath', icaFileDir, 'filename', icaFileName); 

ICThreshold = config_param.IC_threshold; 
ICLabel     = EEG.etc.ic_classification.ICLabel;

% indices of muscle and eye components based on the probability threshold
muscleInd   = find(ICLabel.classifications(:,2) > ICThreshold);
eyeInd      = find(ICLabel.classifications(:,3) > ICThreshold);
heartInd    = find(ICLabel.classifications(:,4) > ICThreshold);
chanInd     = find(ICLabel.classifications(:,5) > ICThreshold);
lineInd     = find(ICLabel.classifications(:,6) > ICThreshold);

% find union of all indices
allInds     = union(muscleInd, union(eyeInd, union(heartInd,union(chanInd,lineInd)))); 

% subtract components
cleanedEEG              = pop_subcomp(EEG, allInds); 
cleanedEEG.etc.rank     = size(cleanedEEG.icaweights, 1); 
cleanedEEG.etc.nICrej   = size(allInds); 

% save results
if ~isfolder(cleanedFileDir)
   mkdir(cleanedFileDir) 
end

pop_saveset(cleanedEEG,'filepath',cleanedFileDir,'filename',cleanedFileName); 

% generate plots
% removed ICs 
f = bemobil_plot_patterns(EEG.icawinv(:,allInds), EEG.chanlocs);
savefig(f,fullfile(cleanedFileDir, [cleanedFileName(1:end-4) '_removed_IC.fig']))
print(f,fullfile(cleanedFileDir, [cleanedFileName(1:end-4) '_removed_IC.png']),'-dpng')
close(f)

% saved ICs
f = bemobil_plot_patterns(cleanedEEG.icawinv, EEG.chanlocs);
savefig(f,fullfile(cleanedFileDir, [cleanedFileName(1:end-4) '_kept_IC.fig']))
print(f,fullfile(cleanedFileDir, [cleanedFileName(1:end-4) '_kept_IC.png']),'-dpng')
close(f)
end