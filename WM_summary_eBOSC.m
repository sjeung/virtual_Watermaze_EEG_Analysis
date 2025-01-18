WM_config; 

% https://www.learnui.design/tools/data-color-picker.html
% https://blog.datawrapper.de/beautifulcolors/#:~:text=makes%20them%20work.-,Use%20warm%20colors%20%26%20blue,%2Forange%2Fred%20and%20blue.

% conditions
sessionTypes        = {'stat', 'mobi'};
taskTypes           = {'learn', 'probe'};
windowTypes         = {'Start', 'End', 'Mid'};
measures            = {'powers', 'pepisodes'};

addpath('P:\Sein_Jeung\Tools\FDR')
effectTexts = {'groupXsetup interaction', 'group', 'setup'};  

%%
%--------------------------------------------------------------------------
% POWER & P-EPISODES 
%--------------------------------------------------------------------------
% intialize tables 
results_bosc       = table([], [], [], [], [], [], [], [], [], [], ...
                     'VariableNames', {'measure', 'task', 'twindow', 'changroup', 'frequency', 'contrast', 'p', 'omegasquared', 'F', 'corrected_p'});

newRows         = {};
for measureInd = 1:2
    
    % pVals(1,:) : interaction
    % pVals(2,:) : group
    % pVals(3,:) : setup
    
    %% 1. Standing baseline
    %----------------------------------------------------------------------
    for Gi = 1:4
        [pVals, omegasq, Fs] = WM_stat_eBOSC('stand', '', config_param.chanGroups(Gi), measures{measureInd});
        for effectInd = 1:3
            for fInd = 1:5
                newRow =  {measures{measureInd}, 'stand', 'n/a', config_param.chanGroups(Gi).key, config_param.band_names{fInd}, effectTexts{effectInd}, pVals(effectInd,fInd), omegasq(effectInd,fInd), Fs(effectInd,fInd), NaN};
                newRows =  [newRows; newRow]; 
            end
        end
    end
    
    %% 2. Walking baseline
    %----------------------------------------------------------------------
    for Gi = 1:4
        [pVals, omegasq, Fs] = WM_stat_eBOSC('walk', '', config_param.chanGroups(Gi), measures{measureInd});
        for effectInd = 1:3
            for fInd = 1:5
                newRow =  {measures{measureInd}, 'walk', 'n/a', config_param.chanGroups(Gi).key, config_param.band_names{fInd}, effectTexts{effectInd}, pVals(effectInd,fInd), omegasq(effectInd,fInd), Fs(effectInd,fInd), NaN};
                newRows =  [newRows; newRow];
            end
        end
    end
    
    
    %% Main task stats on powers
    %----------------------------------------------------------------------
    for Wi = 1:3
        for Gi = 1:4
            [pVals, omegasq, Fs] = WM_stat_eBOSC('probe', windowTypes{Wi}, config_param.chanGroups(Gi), measures{measureInd});
            for effectInd = 1:3
                for fInd = 1:5
                    newRow =  {measures{measureInd}, 'probe', windowTypes{Wi}, config_param.chanGroups(Gi).key, config_param.band_names{fInd}, effectTexts{effectInd}, pVals(effectInd,fInd), omegasq(effectInd,fInd), Fs(effectInd,fInd), NaN};
                    newRows =  [newRows; newRow];
                end
            end
        end
    end
end

results_bosc    = [results_bosc; newRows];

effectTexts = {'groupXsetup interaction', 'group', 'setup'};  
tasks           = {'stand', 'walk', 'probe'};
for measureInd = 1:2
    
    % baseline tasks
    for taskInd = 1:2
        for effectInd = 1:3
            results_temp            = results_bosc(find(strcmp(results_bosc.measure, measures{measureInd}) & strcmp(results_bosc.task, tasks{taskInd}) & strcmp(results_bosc.contrast, effectTexts{effectInd})),:);
            pVals                   = results_temp.p;
            [h,~,~,corrPs]          = fdr_bh(pVals);
            inds = find(h)'; 
            for index = inds
                disp([results_temp.task{index} ', ' results_temp.changroup{index} ', ' results_temp.frequency{index} ' ' results_temp.measure{index} ', ' results_temp.contrast{index} ': p = ' num2str(corrPs(index))]);
            end
            
            % replace p value with corrected values
            results_bosc(find(strcmp(results_bosc.measure, measures{measureInd}) & strcmp(results_bosc.task, tasks{taskInd}) & strcmp(results_bosc.contrast, effectTexts{effectInd})),:).corrected_p = corrPs;
        end
    end
    
    % main task
    taskInd = 3;
    for windowInd = 1:3
        for effectInd = 1:3
            results_temp =  results_bosc(find(strcmp(results_bosc.measure, measures{measureInd}) & strcmp(results_bosc.twindow, windowTypes{windowInd}) & strcmp(results_bosc.task, tasks{taskInd}) & strcmp(results_bosc.contrast, effectTexts{effectInd})),:);
            pVals = results_temp.p;
            [h,~,~,corrPs]       = fdr_bh(pVals);
            inds = find(h)';
            for index = inds
                disp([results_temp.task{index} '-' results_temp.twindow{index} ', ' results_temp.changroup{index} ', ' results_temp.frequency{index} ' ' results_temp.measure{index} ', ' results_temp.contrast{index} ': p = ' num2str(corrPs(index))]);
            end
            
            % replace p value with corrected values
            results_bosc(find(strcmp(results_bosc.measure, measures{measureInd}) & strcmp(results_bosc.twindow, windowTypes{windowInd}) & strcmp(results_bosc.task, tasks{taskInd}) & strcmp(results_bosc.contrast, effectTexts{effectInd})),:).corrected_p = corrPs;
            
        end
    end
end

%save('P:\Sein_Jeung\Project_Watermaze\WM_EEG_Results\summary_BoSC-bands.mat', "results_bosc"); 

results_bosc.p = round(results_bosc.p, 3);  % Round values to 3 decimal places
results_bosc.omegasquared = round(results_bosc.omegasquared, 3);
results_bosc.F = round(results_bosc.F, 3);
results_bosc.corrected_p = round(results_bosc.corrected_p, 3);
writetable(results_bosc, 'P:\Sein_Jeung\Project_Watermaze\WM_EEG_Results\summary_BoSC-bands.xlsx');
%load("P:\Sein_Jeung\Project_Watermaze\WM_EEG_Results\summary_BoSC-bands.mat"); 


% Post-hoc tests on interactions
%--------------------------------------------------------------------------


%%
%--------------------------------------------------------------------------
% Correlation with behavior 
%--------------------------------------------------------------------------
effectTexts     = {'threeway interaction', 'groupXpower interaction', 'setupXpower interaction', 'power'};  
behVars         = {'MS', 'DTWs', 'idPhis'};  

% intialize tables 
results_eeg_beh = table([], [], [], [], [], [], [], [], [], [], [], ...
                     'VariableNames', {'measure', 'behvar', 'task', 'twindow', 'changroup', 'frequency', 'contrast', 'p', 'omegasquared', 'F', 'corrected_p'});

newRows         = {};
for measureInd = 1:2
    for behInd = 1:3
        
        % pVals(1,:) : interaction
        % pVals(2,:) : group
        % pVals(3,:) : setup
        
        %% Main task stats on powers
        %------------------------------------------------------------------
        for Wi = 1:3
            for Gi = 3%1:4
                [pVals, omegasq, Fs] = WM_stat_beh_eeg_BOSC('probe', windowTypes{Wi}, config_param.chanGroups(Gi), behVars{behInd}, measures{measureInd});
                for effectInd = 1:4
                    for fInd = 1:5
                        newRow      =  {measures{measureInd}, behVars{behInd} 'probe', windowTypes{Wi}, config_param.chanGroups(Gi).key, config_param.band_names{fInd}, effectTexts{effectInd}, pVals(effectInd,fInd), omegasq(effectInd,fInd), Fs(effectInd,fInd), NaN};
                        newRows     =  [newRows; newRow];
                    end
                end
            end
        end
    end
end

results_eeg_beh   = [results_eeg_beh; newRows];

%-------------------------------------------------------------------------
tasks           = {'stand', 'walk', 'probe'};
taskInd = 3;
for measureInd = 1:2
    for behInd = 1:2
        for windowInd = 1:3
            for effectInd = 1:4
                results_temp    = results_eeg_beh(find(strcmp(results_eeg_beh.measure, measures{measureInd}) & strcmp(results_eeg_beh.behvar, behVars{behInd}) & strcmp(results_eeg_beh.twindow, windowTypes{windowInd}) & strcmp(results_eeg_beh.task, tasks{taskInd}) & strcmp(results_eeg_beh.contrast, effectTexts{effectInd})),:);
                pVals           = results_temp.p;
                [h,~,~,corrPs]            = fdr_bh(pVals);
                inds            = find(h)';
                for index = inds
                    disp([results_temp.task{index} '-' results_temp.twindow{index} ', '  behVars{behInd} ', ' results_temp.changroup{index} ', ' results_temp.frequency{index} ' ' results_temp.measure{index} ', ' results_temp.contrast{index} ': p = ' num2str(corrPs(index))]);
                end
                results_eeg_beh(find(strcmp(results_eeg_beh.measure, measures{measureInd}) & strcmp(results_eeg_beh.behvar, behVars{behInd}) & strcmp(results_eeg_beh.twindow, windowTypes{windowInd}) & strcmp(results_eeg_beh.task, tasks{taskInd}) & strcmp(results_eeg_beh.contrast, effectTexts{effectInd})),:).corrected_p = corrPs;
            end
        end
    end
end

save('P:\Sein_Jeung\Project_Watermaze\WM_EEG_Results\summary_BoSC-beh.mat', "results_eeg_beh");
results_eeg_beh.p = round(results_eeg_beh.p, 3);  % Round values to 3 decimal places
results_eeg_beh.omegasquared = round(results_eeg_beh.omegasquared, 3);
results_eeg_beh.F = round(results_eeg_beh.F, 3);
results_eeg_beh.corrected_p = round(results_eeg_beh.corrected_p, 3);
writetable(results_eeg_beh, 'P:\Sein_Jeung\Project_Watermaze\WM_EEG_Results\summary_BoSC-beh.xlsx');

%% Visualizations
%--------------------------------------------------------------------------
% 1. Baseline
%--------------------------------------------------------------------------
for Gi = 1:4
    WM_vis_eBOSC('stand', '', config_param.chanGroups(Gi));
    WM_vis_eBOSC('walk', '', config_param.chanGroups(Gi));
end


% 2. Main task stats on powers
%--------------------------------------------------------------------------
for Wi = 1:3
    for Gi = 1:4
        WM_vis_eBOSC('probe', windowTypes{Wi}, config_param.chanGroups(Gi));
    end
end
