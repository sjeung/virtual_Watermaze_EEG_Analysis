function [numBrainICs, meanProbMax, meanProbAll, meanRV, RVs] = AMICA_results_quickcheck(EEG)

% find brain ICs
brainClassIndex     =  find(strcmpi(EEG.etc.ic_classification.ICLabel.classes,'Brain')); 
classifications         = EEG.etc.ic_classification.ICLabel.classifications;

% find the max label 
[maxVal, maxClassIndex] = max(classifications,[],2);

% brain IC indices 
brainICIndices          = find(maxClassIndex == brainClassIndex); 

% number of ICs with max. brain
numBrainICs             = numel(brainICIndices);

% mean brain probability among brain ICs
meanProbMax             = mean(classifications(brainICIndices,brainClassIndex)); 

% mean brain probability among all ICs 
meanProbAll             = mean(classifications(:,brainClassIndex)); 

% mean RV among brain ICs
meanRV                  = mean([EEG.dipfit.model(brainICIndices).rv]); 

% RVs
RVs                     = [EEG.dipfit.model.rv]; 

