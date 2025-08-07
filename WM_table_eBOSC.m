function WM_table_eBOSC(trial, timeWindow)

% measure : 'pepisode' or 'power'
%--------------------------------------------------------------------------
WM_config;
addpath(genpath('P:\Sein_Jeung\Tools\FDR'))

% this needs to match WM_stat_ERSP
patientIDs      = 81001:81011; 
controlIDs      = [82001:82011, 83001:83011, 84009];
excludedIDs     = [81005, 82005, 83005 ...      % 81005 and matched controls excluded due to psychosis
                   82009 ];                     % 82009 nausea              
controlIDs      = setdiff(controlIDs, excludedIDs); 
patientIDs      = setdiff(patientIDs, excludedIDs); 
               
% Read in the behavioural data
data        = readtable('P:\Sein_Jeung\Project_Watermaze\WM_EEG_Data\BEHdata_OSF.xlsx');

% Preallocate vectors for demographics
ids         = [patientIDs controlIDs]; 
numIds      = length([patientIDs controlIDs]);
group       = zeros(numIds, 1);
sex         = group; age = group; education = group; sessionOrder = group;
MS          = group; idPhis = group; DTWs = group; 

% Loop through each unique ID and extract demographics
for i = 1:numIds
    id              = ids(i);
    
    % Find the first row where the ID matches
    firstRowIdx     = find(data.id == id, 1, 'first');
    
    % Extract the demographic information
    group(i)        = data.group(firstRowIdx);                              % Extract group
    sex(i)          = data.sex(firstRowIdx);                                % Extract sex
    age(i)          = data.age(firstRowIdx);                                % Extract age
    education(i)    = data.education_years(firstRowIdx);                    % Extract education years
    sessionOrder(i) = data.session(firstRowIdx);                            % Extract session order    
    
    for Si = 1:2 %1 for stat, 2 for mobi
        allRowIdx       = find(data.id == id & data.setup == Si);
        MSmean          = mean(data.memory_score(allRowIdx));
        if Si ==1
            newi        = i*2-1;
        else 
            newi        = i*2; 
        end
        MS(newi)           = log(MSmean./(1-MSmean)); % logit transform memory score
        idPhis(newi)       = mean(data.avg_idPhi_angular_velocity_5_sec(allRowIdx));
        DTWs(newi)         = mean(data.learning_probe_avg_dTW_square(allRowIdx), 'omitnan');
    end
end

% Repeat each value 24*2 times
repeated_ids            = repelem(ids', 2);
repeated_group          = repelem(group, 2);
repeated_sex            = repelem(sex, 2);
repeated_age            = repelem(age, 2);
repeated_education      = repelem(education, 2);
repeated_sessionOrder   = repelem(sessionOrder, 2);
repeated_setup          = repmat([1,2]',[numel(ids), 1]); % 1 for stat, 2 for mobi

% Combine demographics into a table
demographicsTable = table(repeated_ids, repeated_group, repeated_setup, repeated_sex, repeated_age, repeated_education, repeated_sessionOrder, MS, idPhis, DTWs, ...
    'VariableNames', {'ID', 'Group', 'Setup', 'Sex', 'Age', 'Education', 'SessionOrder', 'MemoryScore', 'HeadRotation', 'DTW'});

% Convert categorical variables if needed
demographicsTable.Group         = categorical(demographicsTable.Group);
demographicsTable.Sex           = categorical(demographicsTable.Sex);
demographicsTable.Setup         = categorical(demographicsTable.Setup);
demographicsTable.SessionOrder  = categorical(demographicsTable.SessionOrder);
demographicsTable.ID            = categorical(demographicsTable.ID);
resultsTable_power              = demographicsTable; 
resultsTable_pep                = demographicsTable; 
 
% write a data table for statistical analysis in R 
%--------------------------------------------------------------------------
for Gi = 1:numel(config_param.chanGroups)
    
    load(fullfile('P:\Sein_Jeung\Project_Watermaze\WM_EEG_Results\BOSC', ['BOSC-comp_' trial '_' timeWindow '_' config_param.chanGroups(Gi).key '.mat']), 'pEpisodesVec', 'bandpowerVec', 'freqAxis');
    
    for Fi = 1:numel(config_param.band_names)
         
        fieldName = [config_param.chanGroups(Gi).key, config_param.band_names{Fi}];
        
        reorderedPower  = NaN(60,1);
        reorderedPep    = NaN(60,1);

        % reorder the power and p-episodes for the matrix 
        for Pi = 1:30
            reorderedPower(Pi*2-1)      = bandpowerVec(Pi,Fi);              % stat
            reorderedPower(Pi*2)        = bandpowerVec(Pi+30,Fi);           % mobi
            reorderedPep(Pi*2-1)        = pEpisodesVec(Pi,Fi); 
            reorderedPep(Pi*2)          = pEpisodesVec(Pi+30, Fi); 
        end
        
        resultsTable_power.(fieldName)  = reorderedPower;                       % Add the response variable to demographicsTable
        resultsTable_pep.(fieldName)    = log(reorderedPep./(1-reorderedPep));  % Add the response variable to demographicsTable
    end
    
end

writetable(resultsTable_power, fullfile(config_folder.results_folder, ['resultsTable_power_' trial '_' timeWindow '.xlsx']));
writetable(resultsTable_pep, fullfile(config_folder.results_folder, ['resultsTable_pep_' trial '_' timeWindow '.xlsx']));


end