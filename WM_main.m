% WM_main
%--------------------------------------------------------------------------
WM_config;
eeglab;

% participants 
% excluded due to technical error
% excluded due to strong nausea
allParticipants = [81001:81011, 82001:82011, 83001:83011, 84009]; %[81001:81011, 82001:82011, 83001:83011];
excluded        = [81005, 82005, 83005]; % patient 81005 excluded due to psychosis   
allParticipants = setdiff(allParticipants,excluded);

%% 01.Import files 
%WM_01_import

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
      WM_05_IC_clean(Pi)
    
       %% 06. epoch 
       WM_06_epoch(Pi)
    
 %% 07-09. channel level TFR and temporal/spatial analyiss
 try
     for Gi = 1:numel(config_param.chanGroups)
         WM_07_ERSP_channel(Pi,config_param.chanGroups(Gi))
         WM_08_ERSP_temporal(Pi,config_param.chanGroups(Gi)) 
         WM_09_ERSP_spatial(Pi,config_param.chanGroups(Gi))
     end
 catch
     errorParticipants(end+1) = Pi;
 end
 
end


%% Aggregate temporal ERSP results
%--------------------------------------------------------------------------
sessionTypes        = {'stat', 'mobi'}; 
trialTypes          = {'learn', 'probe'}; 
windowTypes         = {'Start', 'End'}; 

for Gi = 1%:numel(config_param.chanGroups)
    for Si = 1:2
        
        WM_stat_outlier_removal(sessionTypes{Si}, config_param.chanGroups(Gi));
        
        for Wi = 1:2
            for Ti = 1:2
                
                condType = [trialTypes{Ti} '_' sessionTypes{Si}];
                  
                [pval] = WM_stat_ERSP(condType, windowTypes{Wi}, config_param.chanGroups(Gi));
                disp([config_param.chanGroups(Gi).key, ', ' condType ' ' windowTypes{Wi} ', p = ' num2str(pval(1))])
                
            end
        end
    end
end

%--------------------------------------------------------------------------
trialTypes = {'stat_learn', 'mobi_learn', 'stat_probe', 'mobi_probe'}; 

for Ti = 1:4
    
    trialType = trialTypes{Ti}; 
    
    for Gi = 1%:numel(config_param.chanGroups)
        
        WM_stat_spatial_ERSP(trialType, config_param.chanGroups(Gi), '8to12_Hz');
        
    end
    
    %save(fullfile(config_folder.results_folder, config_folder.ersp_folder, ['stats_' trialType '.mat']), 'statArray');
end

%% Aggregate spatial ERSP results
%--------------------------------------------------------------------------
for Ti = 1:4
    
    trialType = trialTypes{Ti};
    statArray = {};
    
    for Gi = 1:numel(config_param.chanGroups)
        if Gi == 1
            WM_stat_bandpower(trialType, config_param.chanGroups(Gi), 1);
        else
            WM_stat_bandpower(trialType, config_param.chanGroups(Gi), 0);
        end
    end
    
end