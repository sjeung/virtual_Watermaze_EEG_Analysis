% comparison AMICA on desktop vs AMICA on VR + desktop 

subjects        = [81001 81002 81003 81004 81005 82001 82003 82004];
nSubjects       = numel(subjects); 
paths           = {'P:\Project_Watermaze\Data\AMICA_desktop', 'P:\Project_Watermaze\Data\AMICA_desktop_vr'}; 
conditionNames  = {'Desktop','DesktopAndVR'}; 
nConditions     = numel(paths); 


% initialize matrices to store values for each condition and participant
numBrainICs     = NaN(nConditions, nSubjects); 
meanProbMax     = NaN(nConditions, nSubjects);
meanProbAll     = NaN(nConditions, nSubjects);
meanRV          = NaN(nConditions, nSubjects);

if ~exist('eeglab','var'); eeglab; end

% initialize the cell array of RVs of all components in condition 
allRVs = {}; 
for conditionIndex = 1:nConditions
    allRVs{conditionIndex} = []; 
end

% load files 
for subjectIndex = 1:nSubjects
    
    % subject ID to string
    subjectString   = num2str(subjects(subjectIndex));
    disp(['Evaluating subject ' subjectString ' decomposition quality.']);
    
    for conditionIndex = 1:nConditions 

        % input file path
        studyFolder     = paths{conditionIndex};  
        eegFilePath     = [studyFolder '\4_single-subject-analysis\' subjectString '\'];
        eegFileName     = [subjectString '_interp_avRef_ICA.set'];
        EEG             = pop_loadset('filename', eegFileName, 'filepath', eegFilePath);

        % extract some measures 
        [numBrainICs(conditionIndex, subjectIndex), meanProbMax(conditionIndex, subjectIndex), meanProbAll(conditionIndex, subjectIndex), meanRV(conditionIndex, subjectIndex), RVs] = AMICA_results_quickcheck(EEG);
        
        allRVs{conditionIndex}       = [allRVs{conditionIndex} RVs]; 
        
    end
    
end

% plot results  
figure 
subplot(2,2,1)
bar(numBrainICs')
title('Number of brain ICs')
subplot(2,2,2)
bar(meanRV')
title('Mean residual variance')
subplot(2,2,3)
bar(meanProbMax')
title('Number of brain ICs')
subplot(2,2,4)
bar(meanProbAll')
title('Number of brain ICs')
legend(conditionNames)


figure

for conditionIndex = 1:nConditions
    
    sorted = sort(allRVs{conditionIndex});
    
    x = unique(sorted);
    y =[]; 
    
    for i = 1:numel(x)
        y(i) = numel(find(sorted <= x(i)));
    end
    
    plot(x,y, 'LineWidth', 2);
    
    hold on
    
end

legend(conditionNames)
xlabel('RV','FontSize',16)
ylabel('Number of components','FontSize',16)


% mutual information reduction