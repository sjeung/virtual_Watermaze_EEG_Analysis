function WM_10_reject_outlier_trials(Pi, sessionType, channelGroup)

WM_config;

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

% multiple channel data have been averaged together 
% insert a dimension just for getting downstream functions to work 
ERSPLS.label    = {channelGroup.key}; 
ERSPLM.label    = {channelGroup.key}; 
ERSPLE.label    = {channelGroup.key}; 
ERSPPS.label    = {channelGroup.key}; 
ERSPPM.label    = {channelGroup.key}; 
ERSPPE.label    = {channelGroup.key}; 

ERSPLS.dimord   = 'rpt_chan_freq_time'; 
ERSPLM.dimord   = 'rpt_chan_freq_time';  
ERSPLE.dimord   = 'rpt_chan_freq_time';  
ERSPPS.dimord   = 'rpt_chan_freq_time';  
ERSPPM.dimord   = 'rpt_chan_freq_time'; 
ERSPPE.dimord   = 'rpt_chan_freq_time'; 

% Add a new dimension to powspctrm for channel
% Add a new dimension to powspctrm for ERSPStart
ERSPLS.powspctrm = reshape(ERSPLS.powspctrm, [size(ERSPLS.powspctrm, 1), 1, size(ERSPLS.powspctrm, 2), size(ERSPLS.powspctrm, 3)]);
ERSPLM.powspctrm = reshape(ERSPLM.powspctrm, [size(ERSPLM.powspctrm, 1), 1, size(ERSPLM.powspctrm, 2), size(ERSPLM.powspctrm, 3)]);
ERSPLE.powspctrm = reshape(ERSPLE.powspctrm, [size(ERSPLE.powspctrm, 1), 1, size(ERSPLE.powspctrm, 2), size(ERSPLE.powspctrm, 3)]);
ERSPPS.powspctrm = reshape(ERSPPS.powspctrm, [size(ERSPPS.powspctrm, 1), 1, size(ERSPPS.powspctrm, 2), size(ERSPPS.powspctrm, 3)]);
ERSPPM.powspctrm = reshape(ERSPPM.powspctrm, [size(ERSPPM.powspctrm, 1), 1, size(ERSPPM.powspctrm, 2), size(ERSPPM.powspctrm, 3)]);
ERSPPE.powspctrm = reshape(ERSPPE.powspctrm, [size(ERSPPE.powspctrm, 1), 1, size(ERSPPE.powspctrm, 2), size(ERSPPE.powspctrm, 3)]);


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

outCell          = {};
for cInd = 1:6
    
    outCell{cInd}    = matchVec(outInds == 1 & matchVec(:,1) == cInd,2);     
    
    % for LS, LM, LE conditions, remove first learning trials
    if cInd < 4
        if Pi == 83004 && strcmp(sessionType, 'mobi')
            outCell{cInd} = union(outCell{cInd}, [1,4,7,10]);
        else
            outCell{cInd} = union(outCell{cInd}, [1,4,7,10,13,16]);
        end
    end
    
end
 
% remove outliers from ERSP fields
ERSPLS.powspctrm(outCell{1},:,:,:)  = [];
ERSPLM.powspctrm(outCell{2},:,:,:)  = [];
ERSPLE.powspctrm(outCell{3},:,:,:)  = [];
ERSPPS.powspctrm(outCell{4},:,:,:)  = [];
ERSPPM.powspctrm(outCell{5},:,:,:)  = [];
ERSPPE.powspctrm(outCell{6},:,:,:)  = [];

ERSPLS.cumtapcnt(outCell{1},:)      = [];
ERSPLM.cumtapcnt(outCell{2},:)      = [];
ERSPLE.cumtapcnt(outCell{3},:)      = [];
ERSPPS.cumtapcnt(outCell{4},:)      = [];
ERSPPM.cumtapcnt(outCell{5},:)      = [];
ERSPPE.cumtapcnt(outCell{6},:)      = [];

ERSPLS.trialinfo(outCell{1})        = [];
ERSPLM.trialinfo(outCell{2})        = [];
ERSPLE.trialinfo(outCell{3})        = [];
ERSPPS.trialinfo(outCell{4})        = [];
ERSPPM.trialinfo(outCell{5})        = [];
ERSPPE.trialinfo(outCell{6})        = [];

ERSPLS.outliers                     = outCell{1};
ERSPLM.outliers                     = outCell{2};
ERSPLE.outliers                     = outCell{3};
ERSPPS.outliers                     = outCell{4};
ERSPPM.outliers                     = outCell{5};
ERSPPE.outliers                     = outCell{6};

disp(['Removed ' num2str(numel(find(outInds))) ' out of ' num2str(numel(outInds)) ' outlier trial(s) for participant ' num2str(Pi) ' in ' sessionType ' session'])

if ~isfolder(prunedFileDir)
    mkdir(prunedFileDir)
end

% save data
save([prunedFileDir '\sub-' num2str(Pi) '_learn_' sessionType '_' channelGroup.key '_Start_ERSP_pruned.mat'],   'ERSPLS');
save([prunedFileDir '\sub-' num2str(Pi) '_learn_' sessionType '_' channelGroup.key '_Mid_ERSP_pruned.mat'],     'ERSPLM');
save([prunedFileDir '\sub-' num2str(Pi) '_learn_' sessionType '_' channelGroup.key '_End_ERSP_pruned.mat'],     'ERSPLE');
save([prunedFileDir '\sub-' num2str(Pi) '_probe_' sessionType '_' channelGroup.key '_Start_ERSP_pruned.mat'],   'ERSPPS');
save([prunedFileDir '\sub-' num2str(Pi) '_probe_' sessionType '_' channelGroup.key '_Mid_ERSP_pruned.mat'],     'ERSPPM');
save([prunedFileDir '\sub-' num2str(Pi) '_probe_' sessionType '_' channelGroup.key '_End_ERSP_pruned.mat'],     'ERSPPE');

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

end