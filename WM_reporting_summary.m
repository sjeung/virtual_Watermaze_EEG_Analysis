% extract metrics in a reportable form and save a table 
%--------------------------------------------------------------------------
WM_config; 

%% Methods
%--------------------------------------------------------------------------
% number of epoches per condition 
% mean number of epoches per condition per participant with SEM 

% participants 
allParticipants = [81001:81011, 82001:82011, 83001:83011, 84009];
excluded        = [81005, 82005, 83005 ...                                  % 81005 and matched controls excluded due to psychosis
                   82009 ];                                                 % 82009 excluded due to nausea in mobile session   

allParticipants = setdiff(allParticipants,excluded);

eeglab;
nRemovedComponents      = [];
nRemovedChannels        = [];
nMidTrialsMobi          = []; 
nMidTrialsStat          = []; 

for Pi = 1:numel(allParticipants)

    [mobiFileName,epochedFileDir]       = assemble_file(config_folder.data_folder, config_folder.epoched_folder, '_probe_mobi_epoched_mid.mat', allParticipants(Pi));
    [statFileName,~]                    = assemble_file(config_folder.data_folder, config_folder.epoched_folder, '_probe_stat_epoched_mid.mat', allParticipants(Pi));
    [cleanedFileName,cleanedFileDir]    = assemble_file(config_folder.data_folder, config_folder.cleaned_folder, config_folder.cleanedFileName, allParticipants(Pi));

    % Load preprocessed data
    EEG                     = pop_loadset('filepath', cleanedFileDir, 'filename', cleanedFileName);
    
    % Count number of removed channels
    nRemovedChannels(end+1) = numel(EEG.etc.interpolated_channels); 
    
    % Count number of removed IC components
    nRemovedComponents(end+1) = EEG.etc.nICrej(1); 
    
    % Load epoched data
    mobiEEGMID              = load(fullfile(epochedFileDir,mobiFileName));
    statEEGMID              = load(fullfile(epochedFileDir,statFileName));
    
    % Count number of epochs in MID trials
    nMidTrialsMobi(end+1)   = numel(mobiEEGMID.ftEEG.trial);
    nMidTrialsStat(end+1)   = numel(statEEGMID.ftEEG.trial);
    
end
clearvars EEG mobiEEGMID statEEGMID; 

% Print output
meanVal = mean(nRemovedChannels); semVal = std(nRemovedChannels) / sqrt(length(nRemovedChannels));
fprintf('Number of removed channels: %.4f ± %.4f\n', meanVal, semVal);
meanVal = mean(nRemovedComponents); semVal = std(nRemovedComponents) / sqrt(length(nRemovedComponents));
fprintf('Number of removed components: %.4f ± %.4f\n', meanVal, semVal);

meanVal = mean(nMidTrialsMobi); semVal = std(nMidTrialsMobi) / sqrt(length(nMidTrialsMobi));
fprintf('Number of MID segments in mobi: %.4f ± %.4f\n', meanVal, semVal);
meanVal = mean(nMidTrialsStat); semVal = std(nMidTrialsStat) / sqrt(length(nMidTrialsStat));
fprintf('Number of MID segments in stat: %.4f ± %.4f\n', meanVal, semVal);


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
                    %pEpisodesVec = log(pEpisodesVec./(1-pEpisodesVec)); %
                    %for reporting it's probably best not to logit
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

% p-values table for latex
%--------------------------------------------------------------------------
load('P:\Sein_Jeung\Project_Watermaze\WM_EEG_Results\summary_BoSC-bands.mat')
writetable(results_bosc, 'P:\Sein_Jeung\Project_Watermaze\WM_EEG_Results\summary_BoSC-bands.xlsx');

task = 'probe_End'; % 'probe_Mid'; %'walk_'; % 'stand_'
tasktype = 'probe'; %'stand'; 'probe' % 
twindow = 'End'; % 'n/a'; %
this = readtable(['P:\Sein_Jeung\Project_Watermaze\WM_EEG_Results\statistics_pep_' tasktype '_' twindow '.xlsx']); 

text_desc = []; 
text_lme  = []; 
for Gi = 1:4
    text_desc   = [text_desc, '\midrule ', config_param.chanGroups(Gi).key];
    text_lme    = [text_lme, '\midrule ', config_param.chanGroups(Gi).key];
    
    for Fi = 1:5
        idSM = find(strcmp(summary_means.measure, 'p-episodes') & ...
            strcmp(summary_means.task, task) & ...
            strcmp(summary_means.session, 'stat') & ...
            strcmp(summary_means.group, 'mtlr') & ...
            strcmp(summary_means.chan, config_param.chanGroups(Gi).key) & ...
            strcmp(summary_means.freq, config_param.band_names{Fi}));
        idSC    = idSM + 1;
        idMM    = idSM + 2; 
        idMC    = idSM + 3; 
        
        idStat  = find(strcmp(this.Channel_Band, [config_param.chanGroups(Gi).key, config_param.band_names{Fi}]));   

        if strcmp(config_param.band_names{Fi}, 'high gamma')
            bandname = 'gamma''';
        else
            bandname = config_param.band_names{Fi}; 
        end
        
        text1 = [' & \(\' bandname '\) & ' ,...
            num2str(summary_means.mean(idMM),'%.3f') ' ± ' num2str(summary_means.se(idMM),'%.3f') ' & ',...
            num2str(summary_means.mean(idMC),'%.3f') ' ± ' num2str(summary_means.se(idMC),'%.3f') ' & ',...
            num2str(summary_means.mean(idSM),'%.3f') ' ± ' num2str(summary_means.se(idSM),'%.3f') ' & ',...
            num2str(summary_means.mean(idSC),'%.3f') ' ± ' num2str(summary_means.se(idSC),'%.3f') ' \\ '];
        
        text2 = [' & \(\' bandname '\) & ' ,...
            num2str(this.Group_p(idStat),'%.3f') ' & ' num2str(this.Group_Adjusted_p(idStat),'%.3f') ' & ',...
            num2str(this.Omega2_Group(idStat),'%.3f') ' & ' num2str(this.Group_F(idStat),'%.3f') ' & ',...
            num2str(this.Setup_p(idStat),'%.3f') ' & ' num2str(this.Setup_Adjusted_p(idStat),'%.3f') ' & ',...
            num2str(this.Omega2_Setup(idStat),'%.3f') ' & ' num2str(this.Setup_F(idStat),'%.3f') ' & ',...
            num2str(this.Interaction_p(idStat),'%.3f') ' & ' num2str(this.Interaction_Adjusted_p(idStat),'%.3f') ' & ',...
            num2str(this.Omega2_Interaction(idStat),'%.3f') ' & ' num2str(this.Interaction_F(idStat),'%.3f') ' \\ '];
        
        text_desc = [text_desc, text1]; 
        text_lme = [text_lme, text2]; 
    end
    
end

text_desc
text_lme

% make behavioural-EEG analysis latex table
%--------------------------------------------------------------------------
tasktype = 'probe'; %'stand'; 'probe' %
behMeasure = 'HeadRotation'; %
tWindows = {'Start', 'Mid', 'End'};

for Wi = 1:3
    
        that        = readtable(['P:\Sein_Jeung\Project_Watermaze\WM_EEG_Results\statistics_beh_pep_' behMeasure '_' tasktype '_' twindow '.xlsx']);for c = 2:width(that)
        text_beh  = [];
        
        for Gi = 1:4
            text_beh    = [text_beh, '\midrule ', config_param.chanGroups(Gi).key];
            twindow     = tWindows{Wi};
            
            for Fi = 1:5
                
                idStat  = find(strcmp(this.Channel_Band, [config_param.chanGroups(Gi).key, config_param.band_names{Fi}]));
                
                if strcmp(config_param.band_names{Fi}, 'high gamma')
                    bandname = 'gamma''';
                else
                    bandname = config_param.band_names{Fi};
                end
                
                text = [' & \(\' bandname '\) & ' ,...
                    num2str(that.EEG_Beta(idStat),'%.3f') ' & ' num2str(that.EEG_SE(idStat),'%.3f') ' & ',...
                    num2str(that.EEG_p(idStat),'%.3f') ' & ' num2str(that.Adjusted_p_EEG(idStat),'%.3f') ' & ',...
                    num2str(that.Group_Beta(idStat),'%.3f') ' & ' num2str(that.Group_SE(idStat),'%.3f') ' & ',...
                    num2str(that.Group_p(idStat),'%.3f') ' & ' num2str(that.Adjusted_p_Group(idStat),'%.3f') ' & ',...
                    num2str(that.Setup_Beta(idStat),'%.3f') ' & ' num2str(that.Setup_SE(idStat),'%.3f') ' & ',...
                    num2str(that.Setup_p(idStat),'%.3f') ' & ' num2str(that.Adjusted_p_Setup(idStat),'%.3f') ' & ',...
                    num2str(that.Interaction_Beta(idStat),'%.3f') ' & ' num2str(that.Interaction_SE(idStat),'%.3f') ' & ',...
                    num2str(that.Interaction_p(idStat),'%.3f') ' & ' num2str(that.Adjusted_p_THREEWAY(idStat),'%.3f') ' \\ '];
                
                text_beh = [text_beh, text];
            end
        end
    end
    text_beh
end
