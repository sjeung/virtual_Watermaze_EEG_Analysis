% extract metrics in a reportable form and save a table 
%--------------------------------------------------------------------------

WM_config; 


%% Methods
%--------------------------------------------------------------------------
% number of epoches per condition 
% mean number of epoches per condition per participant with SEM 

%% Results
%--------------------------------------------------------------------------
% rows 1-30 contain stat data
% first 10 rows MTLR, last 20 rows CTRL 
% rows 31-60 contain mobi data
% first 10 rows MTLR, last 20 rows CTRL
%--------------------------------------------------------------------------
tasks  = {'walk_', 'stand_', 'probe_Start', 'probe_Mid', 'probe_End'};

summary_means  = table([], [], [], [],[], [], [], [], ...
    'VariableNames', {'measure', 'task', 'session', 'group', 'chan', 'freq', 'mean', 'se'});

measures = {'p-episodes', 'power'}; 

for Ti = 1:numel(tasks)
    for Gi = 1:numel(config_param.chanGroups)
        
        load(fullfile(['P:\Sein_Jeung\Project_Watermaze\WM_EEG_Results\BOSC\BOSC-comp_' tasks{Ti} '_' config_param.chanGroups(Gi).key '.mat']))
        
        for Fi = 1:5
            
            for Mi = 1:2
                
                if Mi == 1
                    metricVec = pEpisodesVec; metricName = 'p-episodes'; 
                else
                    metricVec = bandpowerVec; metricName = 'powers'; 
                end
                
                statMTLRMean    = mean(metricVec(1:10,Fi));
                statCTRLMean    = mean(metricVec(11:30,Fi));
                mobiMTLRMean    = mean(metricVec(31:40,Fi));
                mobiCTRLMean    = mean(metricVec(41:60,Fi));
                statMTLRSE      = std(metricVec(1:10, Fi)) / sqrt(10);
                statCTRLSE      = std(metricVec(11:30, Fi)) / sqrt(20);
                mobiMTLRSE      = std(metricVec(31:40, Fi)) / sqrt(10);
                mobiCTRLSE      = std(metricVec(41:60, Fi)) / sqrt(20);
                
                newRows         = { metricName, tasks{Ti}, 'stat', 'mtlr', config_param.chanGroups(Gi).key, config_param.band_names{Fi}, statMTLRMean, statMTLRSE;...
                                    metricName, tasks{Ti}, 'stat', 'ctrl', config_param.chanGroups(Gi).key, config_param.band_names{Fi}, statCTRLMean, statCTRLSE;...
                                    metricName, tasks{Ti}, 'mobi', 'mtlr', config_param.chanGroups(Gi).key, config_param.band_names{Fi}, mobiMTLRMean, mobiMTLRSE;...
                                    metricName, tasks{Ti}, 'mobi', 'ctlr', config_param.chanGroups(Gi).key, config_param.band_names{Fi}, mobiCTRLMean, mobiCTRLSE};
                
                % concatenate
                summary_means = [summary_means; newRows];
            end
        end
        
    end
end

% save a table
%--------------------------------------------------------------------------
save('P:\Sein_Jeung\Project_Watermaze\WM_EEG_Results\summary_BoSC-means.mat', 'summary_means')
summary_means.mean = round(summary_means.mean, 3);  % Round mean to 3 decimal places
summary_means.se = round(summary_means.se, 3);  % Round se to 3 decimal places
writetable(summary_means, 'P:\Sein_Jeung\Project_Watermaze\WM_EEG_Results\summary_BoSC-means.xlsx');


% compute means for main effects
%--------------------------------------------------------------------------
load(fullfile(['P:\Sein_Jeung\Project_Watermaze\WM_EEG_Results\BOSC\BOSC-comp_stand__RT.mat'])); 

% Patients: Rows for conditions a and b
patientsStat = bandpowerVec(1:10, 1);      
patientsMobi = bandpowerVec(31:40, 1);     
patientsMeanPerSubject = mean([patientsStat, patientsMobi], 2);
patientsGroupMean = mean(patientsMeanPerSubject);
patientsSE = std(patientsMeanPerSubject) / sqrt(10);

% Controls: Rows for conditions a and b
controlsStat = bandpowerVec(11:30, 1);     
controlsMobi = bandpowerVec(41:60, 1);   
controlsData = [controlsStat; controlsMobi];
controlsGroupMean = mean(controlsData);
controlsSE = std(controlsData) / sqrt(20);

% Display results
fprintf('Patients Group Mean: %.4f, SE: %.4f\n', patientsGroupMean, patientsSE);
fprintf('Controls Group Mean: %.4f, SE: %.4f\n', controlsGroupMean, controlsSE);


% p-values table
%--------------------------------------------------------------------------
load('P:\Sein_Jeung\Project_Watermaze\WM_EEG_Results\summary_BoSC-bands.mat')
writetable(results_bosc, 'P:\Sein_Jeung\Project_Watermaze\WM_EEG_Results\summary_BoSC-bands.xlsx');
