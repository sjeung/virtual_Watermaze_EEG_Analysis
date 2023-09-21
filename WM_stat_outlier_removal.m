function WM_stat_outlier_removal(sessionType, channelGroup)
%--------------------------------------------------------------------------
% output : nothing. writes .mat file on disk, a struct 
%          with indices of trials that got removed (presentation order)
%--------------------------------------------------------------------------
WM_config;

% participants to include or exclude
patientIDs      = 81001:81011; 
controlIDs      = [82001:82011, 83001:83011, 84009];
excludedIDs     = [81005, 82005, 83005, 81008]; % participant group 5 excluded due to psychosis. participant 81008 excluded due to massive spectral artefact
patientIDs      = setdiff(patientIDs, excludedIDs); 
controlIDs      = setdiff(controlIDs, excludedIDs); 
participantIDs  = union(patientIDs, controlIDs); 

missedParticipants  = []; 

for Pi = participantIDs
    try
        [~, prunedFileDir]    = assemble_file(config_folder.results_folder, config_folder.pruned_ERSP_folder, '', Pi);
        
        ERSPLearnS       = load(['P:\Sein_Jeung\Project_Watermaze\WM_EEG_Results\ERSP\sub-' num2str(Pi) '\sub-' num2str(Pi) '_learn_' sessionType '_' channelGroup.key '_Start_ERSP.mat']);
        ERSPLearnM       = load(['P:\Sein_Jeung\Project_Watermaze\WM_EEG_Results\ERSP\sub-' num2str(Pi) '\sub-' num2str(Pi) '_learn_' sessionType '_' channelGroup.key '_Mid_ERSP.mat']);
        ERSPLearnE       = load(['P:\Sein_Jeung\Project_Watermaze\WM_EEG_Results\ERSP\sub-' num2str(Pi) '\sub-' num2str(Pi) '_learn_' sessionType '_' channelGroup.key '_End_ERSP.mat']);
        ERSPProbeS       = load(['P:\Sein_Jeung\Project_Watermaze\WM_EEG_Results\ERSP\sub-' num2str(Pi) '\sub-' num2str(Pi) '_probe_' sessionType '_' channelGroup.key '_Start_ERSP.mat']);
        ERSPProbeM       = load(['P:\Sein_Jeung\Project_Watermaze\WM_EEG_Results\ERSP\sub-' num2str(Pi) '\sub-' num2str(Pi) '_probe_' sessionType '_' channelGroup.key '_Mid_ERSP.mat']);
        ERSPProbeE       = load(['P:\Sein_Jeung\Project_Watermaze\WM_EEG_Results\ERSP\sub-' num2str(Pi) '\sub-' num2str(Pi) '_probe_' sessionType '_' channelGroup.key '_End_ERSP.mat']);
        
        trialInfoLearn  = util_WM_tInfo(['learn_' sessionType], ['P:\Sein_Jeung\Project_Watermaze\WM_EEG_Results\BEH_output\sub-' num2str(Pi) '_beh_trials.mat']); 
        trialInfoProbe  = util_WM_tInfo(['probe_' sessionType], ['P:\Sein_Jeung\Project_Watermaze\WM_EEG_Results\BEH_output\sub-' num2str(Pi) '_beh_trials.mat']); 
       
        % annoying operation ... need to update the data struct later
        fn              = fieldnames(ERSPLearnS);  vn = fn{1};
        ERSPLS          = ERSPLearnS.(vn);
        fn              = fieldnames(ERSPLearnM);  vn = fn{1};
        ERSPLM          = ERSPLearnM.(vn);
        fn              = fieldnames(ERSPLearnE);  vn = fn{1};
        ERSPLE          = ERSPLearnE.(vn);
        fn              = fieldnames(ERSPProbeS);  vn = fn{1};
        ERSPPS          = ERSPProbeS.(vn);
        fn              = fieldnames(ERSPProbeM);  vn = fn{1};
        ERSPPM          = ERSPProbeM.(vn);
        fn              = fieldnames(ERSPProbeE);  vn = fn{1};
        ERSPPE          = ERSPProbeE.(vn);

        % attach trial info to ERSP for later
        ERSPLS.trialinfo  = trialInfoLearn; 
        ERSPLM.trialinfo  = trialInfoLearn; 
        ERSPLE.trialinfo  = trialInfoLearn; 
        ERSPPS.trialinfo  = trialInfoProbe; 
        ERSPPM.trialinfo  = trialInfoProbe; 
        ERSPPE.trialinfo  = trialInfoProbe; 
        
        % compute trial means to remove outlier on
        meansLS         = mean(ERSPLS.powspctrm, [2,3,4], 'omitnan');
        meansLM         = mean(ERSPLS.powspctrm, [2,3,4], 'omitnan');
        meansLE         = mean(ERSPLE.powspctrm, [2,3,4], 'omitnan');
        meansPS         = mean(ERSPPS.powspctrm, [2,3,4], 'omitnan');
        meansPM         = mean(ERSPPS.powspctrm, [2,3,4], 'omitnan');
        meansPE         = mean(ERSPPE.powspctrm, [2,3,4], 'omitnan');
        
        matchVec        = [ones(1,numel(meansLS)),   ones(1,numel(meansLM))*2   ones(1,numel(meansLE))*3,  ones(1,numel(meansPS))*4,  ones(1,numel(meansPM))*5, ones(1,numel(meansPE))*6; ...
                           1:numel(meansLS),         1:numel(meansLM),          1:numel(meansLE),          1:numel(meansPS),          1:numel(meansPM),         1:numel(meansPE)]';  
        
        % concatenate learn and probe trials so that outlier removal can be performed over all trials in one session (stat or desktop)
        outInds         = util_WM_IQR([meansLS; meansLM; meansLE; meansPS; meansPM; meansPE;]); % reject outlier trials using IQR method
        
        % remvoe outliers from ERSP fields
        ERSPLS.powspctrm(matchVec(outInds == 1 & matchVec(:,1) == 1,2),:,:,:) = [];
        ERSPLM.powspctrm(matchVec(outInds == 1 & matchVec(:,1) == 2,2),:,:,:) = [];
        ERSPLE.powspctrm(matchVec(outInds == 1 & matchVec(:,1) == 3,2),:,:,:) = [];
        ERSPPS.powspctrm(matchVec(outInds == 1 & matchVec(:,1) == 4,2),:,:,:) = [];
        ERSPPM.powspctrm(matchVec(outInds == 1 & matchVec(:,1) == 5,2),:,:,:) = [];
        ERSPPE.powspctrm(matchVec(outInds == 1 & matchVec(:,1) == 6,2),:,:,:) = [];
        
        ERSPLS.cumtapcnt(matchVec(outInds == 1 & matchVec(:,1) == 1,2),:) = [];
        ERSPLM.cumtapcnt(matchVec(outInds == 1 & matchVec(:,1) == 2,2),:) = [];
        ERSPLE.cumtapcnt(matchVec(outInds == 1 & matchVec(:,1) == 3,2),:) = [];
        ERSPPS.cumtapcnt(matchVec(outInds == 1 & matchVec(:,1) == 4,2),:) = [];
        ERSPPM.cumtapcnt(matchVec(outInds == 1 & matchVec(:,1) == 5,2),:) = [];
        ERSPPE.cumtapcnt(matchVec(outInds == 1 & matchVec(:,1) == 6,2),:) = [];
        
        ERSPLS.trialinfo(matchVec(outInds == 1 & matchVec(:,1) == 1,2)) = [];
        ERSPLM.trialinfo(matchVec(outInds == 1 & matchVec(:,1) == 2,2)) = [];
        ERSPLE.trialinfo(matchVec(outInds == 1 & matchVec(:,1) == 3,2)) = [];
        ERSPPS.trialinfo(matchVec(outInds == 1 & matchVec(:,1) == 4,2)) = [];
        ERSPPM.trialinfo(matchVec(outInds == 1 & matchVec(:,1) == 5,2)) = [];
        ERSPPE.trialinfo(matchVec(outInds == 1 & matchVec(:,1) == 6,2)) = [];
        
        disp(['Removed ' num2str(numel(find(outInds))) ' outlier(s) for participant ' num2str(Pi) ' in ' sessionType ' session'])
        
        if ~isfolder(prunedFileDir)
            mkdir(prunedFileDir)
        end
        
        % save data
        save([prunedFileDir '\sub-' num2str(Pi) '_learn_' sessionType '_' channelGroup.key '_Start_ERSP_pruned.mat'], 'ERSPLS');
        save([prunedFileDir '\sub-' num2str(Pi) '_learn_' sessionType '_' channelGroup.key '_Mid_ERSP_pruned.mat'], 'ERSPLM');
        save([prunedFileDir '\sub-' num2str(Pi) '_learn_' sessionType '_' channelGroup.key '_End_ERSP_pruned.mat'], 'ERSPLE');
        save([prunedFileDir '\sub-' num2str(Pi) '_probe_' sessionType '_' channelGroup.key '_Start_ERSP_pruned.mat'], 'ERSPPS');
        save([prunedFileDir '\sub-' num2str(Pi) '_probe_' sessionType '_' channelGroup.key '_Mid_ERSP_pruned.mat'], 'ERSPPM');
        save([prunedFileDir '\sub-' num2str(Pi) '_probe_' sessionType '_' channelGroup.key '_End_ERSP_pruned.mat'], 'ERSPPE');
        
        % outlier summary file 
        save(fullfile(prunedFileDir, ['sub-' num2str(Pi) '_outliers_' sessionType '_' channelGroup.key '.mat']), 'outInds', 'matchVec')
      
        f = figure;
        cfg             = [];
        cfg.colorbar    = 'yes';  % Display colorbar
        cfg.zlim        = [0,2.5];
        if strcmp(sessionType, 'mobi')
            cfg.zlim        = [0,5];
        end
        cfg.xlim        = [-0.5,3];
        cfg.figure      = 'gcf';
        set(gcf,'Position',[100 100 1500 800])
        
        subplot(2,2,1);
        ft_singleplotTFR(cfg, ERSPLS);
        title('ERSPLS')
        subplot(2,2,2);
        ft_singleplotTFR(cfg, ERSPLE);
        title('ERSPLE')
        subplot(2,2,3);
        ft_singleplotTFR(cfg, ERSPPS);
        title('ERSPPS')
        subplot(2,2,4);
        ft_singleplotTFR(cfg, ERSPPE);
        title('ERSPPE')
        
        saveas(f, fullfile(prunedFileDir, ['sub-' num2str(Pi) '_outliers_' sessionType '_' channelGroup.key '.png']))
        close(f);
        
        
    catch
        missedParticipants(end+1) = Pi;
    end
end


end