% WM_main
%--------------------------------------------------------------------------
addpath('P:\Sein_Jeung\Project_Watermaze\WM_EEG_Analysis\util_WM')
WM_config;
eeglab;
ft_defaults;

% participants 
allParticipants = [81001:81011, 82001:82011, 83001:83011, 84009];
excluded        = [81005, 82005, 83005 ...      % 81005 and matched controls excluded due to psychosis
                   81008, 82008, 83008 ...      % 81008 and matched controls excluded due to extensive spectral artefacts in data
                   82009 ];                     % 82009 nausea   
allParticipants = setdiff(allParticipants,excluded);

%% 01.Import files & convert beh data to trial info matrices 
% WM_01_import
% WM_read_beh_trials % the output file was generated in beh analyses

errorParticipants = [];
for Pi = allParticipants
    
%     %% 02. process events and trim files
%     WM_02_trim(Pi)
%     
%     %% 03. preprocess
%     WM_03_preprocess(Pi)
%     
%     %% 04. run AMICA
%     WM_04_amica(Pi)
%     
%     % 05. IC based cleaning
%     WM_05_IC_clean(Pi)
%     
%     %% 06. epoch
%     WM_06_epoch(Pi)
%     
    %% 07-09. channel level TFR and temporal/spatial analyiss
    try
        for Gi = 1:2 % 1%:numel(config_param.chanGroups)
             % WM_07_ERSP_channel(Pi,config_param.chanGroups(Gi))
             WM_08_ERSP_temporal(Pi,config_param.chanGroups(Gi))
             % WM_09_ERSP_spatial(Pi,config_param.chanGroups(Gi))
         end
    catch
        errorParticipants(end+1) = Pi;
    end
    
end


%% Aggregate temporal ERSP results
%--------------------------------------------------------------------------
sessionTypes        = {'stat', 'mobi'};
trialTypes          = {'learn', 'probe'};
windowTypes         = {'Start', 'End', 'Mid'};

for Gi = 1:2
    for Si = 1:2
          
        WM_stat_outlier_removal(sessionTypes{Si}, config_param.chanGroups(Gi));
        
        for Wi = 1:3 %1:2
            for Ti = 1:2
              
                condType = [trialTypes{Ti} '_' sessionTypes{Si}];
                
                WM_stat_ERSP(condType, windowTypes{Wi}, config_param.chanGroups(Gi), true);
                
            end
        end
    end
end

%--------------------------------------------------------------------------
trialTypes = {'stat_learn', 'mobi_learn', 'stat_probe', 'mobi_probe'}; 

for Ti = 3:4
    
    trialType = trialTypes{Ti}; 
    
    for Gi = 1%:numel(config_param.chanGroups)
        WM_stat_spatial_dist(trialType, config_param.chanGroups(Gi));
        for Fi = [1,4]
            %WM_stat_spatial_overlay(trialType, config_param.chanGroups(Gi), [num2str(config_param.FOI_lower(Fi)), 'to', num2str(config_param.FOI_upper(Fi)), '_Hz']);
            WM_stat_spatial_overlay_target(trialType, config_param.chanGroups(Gi), [num2str(config_param.FOI_lower(Fi)), 'to', num2str(config_param.FOI_upper(Fi)), '_Hz']);
        end
    end
    
    %save(fullfile(config_folder.results_folder, config_folder.ersp_folder, ['stats_' trialType '.mat']), 'statArray');
end
