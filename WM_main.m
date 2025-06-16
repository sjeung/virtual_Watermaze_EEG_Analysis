% WM_main
%--------------------------------------------------------------------------
addpath('P:\Sein_Jeung\Project_Watermaze\WM_EEG_Analysis\util_WM')
WM_config;
eeglab;
ft_defaults;

% conditions
sessionTypes        = {'stat', 'mobi'};
taskTypes           = {'learn', 'probe'};
windowTypes         = {'Start', 'End', 'Mid'};

% participants 
allParticipants = [81001:81011, 82001:82011, 83001:83011, 84009];
excluded        = [81005, 82005, 83005 ...                                  % 81005 and matched controls excluded due to psychosis
                   82009 ];                                                 % 82009 excluded due to nausea in mobile session   

allParticipants = setdiff(allParticipants,excluded);

%% 01.Import files & convert beh data to trial info matrices 
% WM_01_import
% WM_read_beh_trials % the output file was generated in beh analyses

for Pi = allParticipants
    
        %     %% 02. process events and trim files
        %     WM_02_trim(Pi)
        %
        %     %% 03. preprocess
        %     WM_03_preprocess(Pi)
        %
        %     %% 04. run AMICA
%             WM_04_amica(Pi)
%             WM_05_IC_clean(Pi)
%        
% %     % 05. epoch
%      WM_05_epoch(Pi)                                                         % this version cuts data to individual trial lengths
%      WM_05_epoch_truncated(Pi)                                               % this version cuts data to start, mid, end sections
% 
%     % 07-09. Channel level TFR and temporal/spatial analyiss
%     for Gi = 1:numel(config_param.chanGroups)
%         WM_06_baseline(Pi,config_param.chanGroups(Gi))
%         WM_07_ERSP_channel(Pi,config_param.chanGroups(Gi))                  % channel level ERSP computation + baseline correction (whole trials)
%         WM_08_ERSP_temporal(Pi,config_param.chanGroups(Gi))                 % cut output from above by time (start, mid, end windows) - current version excludes learn trials
%         WM_09_ERSP_spatial(Pi,config_param.chanGroups(Gi))
%     end
% 
%     % 10. Remove first learning trials, outlier trials and store indices
%     for Gi = 1:numel(config_param.chanGroups)
%         for Si = 1:2
%             WM_10_reject_outlier_trials(Pi, sessionTypes{Si}, config_param.chanGroups(Gi))
%         end
%     end
    
end

% %--------------------------------------------------------------------------
% %% Aggregate baseline spectral analysis results
% %--------------------------------------------------------------------------
% for Gi = 1:4
%     WM_stat_baseline(config_param.chanGroups(Gi), 'stand');
%     WM_stat_baseline(config_param.chanGroups(Gi), 'walk');
% end
% 
% %--------------------------------------------------------------------------
% %% Aggregate temporal ERSP results
% %--------------------------------------------------------------------------
% for Si = 1:2
%     for Gi = 1:4
%         for Wi = 1:3
%             for Ti = 2
%                 
%                 condType = [taskTypes{Ti} '_' sessionTypes{Si}];
%                 [pval] = WM_stat_ERSP(condType, windowTypes{Wi}, config_param.chanGroups(Gi),0);
%                 
%             end
%         end
%     end
% end
% 
% 
% %--------------------------------------------------------------------------
% %% Aggregate spatial analysis results
% %--------------------------------------------------------------------------
% for Ti = 2
%     for Si = 1:2
%         
%         condType = [ sessionTypes{Si} '_' taskTypes{Ti} ];
%         for Gi = 1%:numel(config_param.chanGroups)
%             %WM_stat_spatial_dist(condType, config_param.chanGroups(Gi));
%            % WM_stat_angvel(condType, config_param.chanGroups(Gi));
%             
%             for Fi = 1
%                 %WM_stat_spatial_overlay(condType, config_param.chanGroups(Gi), [num2str(config_param.FOI_lower(Fi)), 'to', num2str(config_param.FOI_upper(Fi)), '_Hz']);
%                WM_stat_spatial_overlay_target(condType, config_param.chanGroups(Gi), [num2str(config_param.FOI_lower(Fi)), 'to', num2str(config_param.FOI_upper(Fi)), '_Hz']);
%             end
%         end
%         
%         %save(fullfile(config_folder.results_folder, config_folder.ersp_folder, ['stats_' trialType '.mat']), 'statArray');
%     end
% end
% 
% 
% %--------------------------------------------------------------------------
% %% Correlate with behavioral metrics
% %--------------------------------------------------------------------------
% for Ti = 2
%     for Si = 1:2
%         for Gi = 1:4 
%             for Wi = 1:3
%                 WM_stat_beh_eeg(sessionTypes{Si}, taskTypes{Ti}, windowTypes{Wi}, config_param.chanGroups(Gi),'MS')
%                 WM_stat_beh_eeg(sessionTypes{Si}, taskTypes{Ti}, windowTypes{Wi}, config_param.chanGroups(Gi),'idPhis')
%                 WM_stat_beh_eeg(sessionTypes{Si}, taskTypes{Ti}, windowTypes{Wi}, config_param.chanGroups(Gi),'DTWs')
%             end
%         end
%     end
% end
% 
% %--------------------------------------------------------------------------
% %% Summary matrix
% %--------------------------------------------------------------------------
% WM_stat_corr_matrix

% eBOSC
%--------------------------------------------------------------------------
for Si = 1:2
    for Gi = 1:4
        WM_eBOSC(allParticipants, sessionTypes{Si}, 'stand', '', config_param.chanGroups(Gi))
        WM_eBOSC(allParticipants, sessionTypes{Si}, 'walk', '', config_param.chanGroups(Gi))
        
        for Wi = 1:3
            WM_eBOSC(allParticipants, sessionTypes{Si}, 'probe', windowTypes{Wi}, config_param.chanGroups(Gi))
        end
    end
end

% eBOSC all channels for topography
%--------------------------------------------------------------------------
for Si = 1:2
    WM_eBOSC_allchan(allParticipants, sessionTypes{Si}, 'stand', '')
    WM_eBOSC_allchan(allParticipants, sessionTypes{Si}, 'walk', '')
    for Wi = 1:3
        WM_eBOSC_allchan(allParticipants, sessionTypes{Si}, 'probe', windowTypes{Wi})
    end
end

params = {'power', 'pepisode'};
for iParam = 1:2
    param = params{iParam};
    for Si = 1:2
        WM_stat_topo(['probe_'  sessionTypes{Si} '_Start'], allParticipants, param)
        WM_stat_topo(['probe_'  sessionTypes{Si} '_Mid'], allParticipants, param)
        WM_stat_topo(['probe_'  sessionTypes{Si} '_End'], allParticipants, param)
        WM_stat_topo(['stand_' sessionTypes{Si} '_'], allParticipants, param)
        WM_stat_topo(['walk_' sessionTypes{Si} '_'], allParticipants, param)
    end
end