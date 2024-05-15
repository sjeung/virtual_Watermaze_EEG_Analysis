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
                   81008, 82008, 83008 ...                                  % 81008 and matched controls excluded due to extensive spectral artefacts in data
                   82009 ];                                                 % 82009 excluded due to nausea in mobile session   

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
    %     % 06. epoch
    %     WM_06_epoch(Pi) % this version cuts data to individual trial lengths
        WM_06_epoch_truncated(Pi) % this version cuts data to start, mid, end sections 
    
%     % 07-09. Channel level TFR and temporal/spatial analyiss
%     for Gi = 1:numel(config_param.chanGroups)
% %         WM_07_ERSP_channel(Pi,config_param.chanGroups(Gi))              % channel level ERSP computation + baseline correction
% %         WM_08_ERSP_temporal(Pi,config_param.chanGroups(Gi))
%          WM_09_ERSP_spatial(Pi,config_param.chanGroups(Gi))
%     end
%     
%     % 10. Remove first learning trials, outlier trials and store indices
%     for Gi = 1:4
%         for Si = 1:2
%             WM_10_reject_outlier_trials(Pi, sessionTypes{Si}, config_param.chanGroups(Gi))
%         end
%     end
end

%--------------------------------------------------------------------------
%% Visualize topography of different frequency bands
%--------------------------------------------------------------------------
for Fi = 1:4

    for Pi = allParticipants
        WM_topo(config_param.FOI_lower(Fi),config_param.FOI_upper(Fi),config_param.band_names{Fi},Pi, 'start');
        WM_topo(config_param.FOI_lower(Fi),config_param.FOI_upper(Fi),config_param.band_names{Fi},Pi, 'mid');
        WM_topo(config_param.FOI_lower(Fi),config_param.FOI_upper(Fi),config_param.band_names{Fi},Pi, 'end');
    end
    
end

fName = 'theta'

%--------------------------------------------------------------------------
WM_stat_topo(['probe_stat_all_' fName '_start'], allParticipants);
WM_stat_topo(['probe_stat_all_' fName '_mid'], allParticipants);
WM_stat_topo(['probe_stat_all_' fName '_end'], allParticipants);

WM_stat_topo(['probe_mobi_all_' fName '_start'], allParticipants);
WM_stat_topo(['probe_mobi_all_' fName '_mid'], allParticipants);
WM_stat_topo(['probe_mobi_all_' fName '_end'], allParticipants);


%--------------------------------------------------------------------------
%% Aggregate baseline spectral analysis results
%--------------------------------------------------------------------------
for Gi = 1:4
    WM_stat_baseline(config_param.chanGroups(Gi), 'stand');
    WM_stat_baseline(config_param.chanGroups(Gi), 'walk');
end

%--------------------------------------------------------------------------
%% Aggregate temporal ERSP results
%--------------------------------------------------------------------------
for Gi = 1:4
    for Si = 1:2
        for Wi = 1:3 
            for Ti = 2
              
                condType = [taskTypes{Ti} '_' sessionTypes{Si}];
                WM_stat_ERSP(condType, windowTypes{Wi}, config_param.chanGroups(Gi), true);
                
            end
        end
    end
end

%--------------------------------------------------------------------------
%% Aggregate spatial analysis results
%--------------------------------------------------------------------------
for Ti = 2
    for Si = 1:2
        
        condType = [ sessionTypes{Si} '_' taskTypes{Ti} ];
        for Gi = 1%:numel(config_param.chanGroups)
            %WM_stat_spatial_dist(condType, config_param.chanGroups(Gi));
            for Fi = [1,4]
                WM_stat_spatial_overlay(condType, config_param.chanGroups(Gi), [num2str(config_param.FOI_lower(Fi)), 'to', num2str(config_param.FOI_upper(Fi)), '_Hz']);
               % WM_stat_spatial_overlay_target(condType, config_param.chanGroups(Gi), [num2str(config_param.FOI_lower(Fi)), 'to', num2str(config_param.FOI_upper(Fi)), '_Hz']);
            end
        end
        
        %save(fullfile(config_folder.results_folder, config_folder.ersp_folder, ['stats_' trialType '.mat']), 'statArray');
    end
end


%--------------------------------------------------------------------------
%% Correlate with behavioral metrics
%--------------------------------------------------------------------------
for Ti = 2
    for Si = 1:2
        for Gi = 1:numel(config_param.chanGroups)
            for Wi = 1:3
                WM_stat_beh_eeg(sessionTypes{Si}, taskTypes{Ti}, windowTypes{Wi}, config_param.chanGroups(Gi))
            end
        end
    end
end

%--------------------------------------------------------------------------
%% Summary matrix
%--------------------------------------------------------------------------
WM_stat_corr_matrix

