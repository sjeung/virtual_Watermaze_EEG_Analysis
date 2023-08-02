function [p_values] = WM_stat_ERSP(trialType, trialSection, channelGroup)

% trialType = 'learn_stat', 'learn_mobi', 'probe_stat', *probe_mobi'
% contrast participants versus controls
% contrast first to last learning trials 
% contrast rotated versus unrotated trials 
%--------------------------------------------------------------------------

% Parameters
%--------------------------------------------------------------------------
pThreshold      = 0.05; 
nPermutations   = 2048; 
frequencyBands  = [];


ERSPvar = load(['P:\Sein_Jeung\Project_Watermaze\WM_EEG_Results\ERSP\sub-81001\sub-81001_' trialType '_' channelGroup.key '_' trialSection '_ERSP.mat'], ['ERSP' trialSection]);
fn = fieldnames(ERSPvar); vn = fn{1}; ERSP = ERSPvar.(vn); % highly annoying to work with this variable name - update later

timePoints = ERSP.time; 
freqPoints = ERSP.freq;

% participants to include or exclude
patientIDs      = 81001:81011; 
controlIDs      = [82001:82011, 83001:83011, 84009];
excludedIDs     = [81005, 82005, 83005, 81008]; % participant group 5 excluded due to psychosis. participant 81008 excluded due to massive spectral artefact
patientIDs      = setdiff(patientIDs, excludedIDs); 
controlIDs      = setdiff(controlIDs, excludedIDs); 

% aggregate and run statistics on difference
missedPatients  = []; 
missedControls  = []; 
ERSPp           = {};
ERSPc           = {};
 
for Pi = patientIDs
    try
        ERSPvar         = load(['P:\Sein_Jeung\Project_Watermaze\WM_EEG_Results\ERSP_pruned\sub-' num2str(Pi) '\sub-' num2str(Pi) '_' trialType '_' channelGroup.key '_' trialSection '_ERSP_pruned.mat']);
       
        fn              = fieldnames(ERSPvar);
        vn              = fn{1};
        ERSP            = ERSPvar.(vn);
        ERSPp{end+1}    = squeeze(mean(ERSP.powspctrm,[1,2],'omitnan'));
        
    catch
        missedPatients(end+1) = Pi;
    end
end

for Pi = controlIDs 
    try
        
        ERSPvar =  load(['P:\Sein_Jeung\Project_Watermaze\WM_EEG_Results\ERSP_pruned\sub-' num2str(Pi) '\sub-' num2str(Pi) '_' trialType '_' channelGroup.key '_' trialSection '_ERSP_pruned.mat']);
        fn              = fieldnames(ERSPvar);
        vn              = fn{1};
        ERSP            = ERSPvar.(vn);
        ERSPc{end+1}    = squeeze(mean(ERSP.powspctrm,[1,2], 'omitnan'));
        
    catch
       missedControls(end+1) = Pi; 
   end
end


pMat    = cat(3,ERSPp{:});
cMat    = cat(3,ERSPc{1:numel(ERSPc)});


% Participants versus controls contrast
%--------------------------------------------------------------------------

[clusters, p_values, t_sums, permutation_distribution] = permutest(pMat,cMat, false, pThreshold, nPermutations, true);

util_WM_plot_ERSP(ERSPp, timePoints, freqPoints, ['ERSP_MTL_' channelGroup.key], ['P:\Sein_Jeung\Project_Watermaze\WM_EEG_Results\ERSP\aggregated_ERSP_mtl_' trialType '_' channelGroup.key '_' trialSection '.png'], [])
util_WM_plot_ERSP(ERSPc, timePoints, freqPoints, ['ERSP_CTRL_' channelGroup.key], ['P:\Sein_Jeung\Project_Watermaze\WM_EEG_Results\ERSP\aggregated_ERSP_ctrl_' trialType '_' channelGroup.key '_' trialSection '.png'], [])


% Baseline versus navigation spectra 
%--------------------------------------------------------------------------

figure; 
plot()
pMat



% Band power 
%--------------------------------------------------------------------------




% Regresssion 
%--------------------------------------------------------------------------



% Save and summarize results 
%--------------------------------------------------------------------------





% Attempted use of fieldtrip built-in statistics - not working due to
% imbalanced design 
%--------------------------------------------------------------------------
% cfg = [];
% cfg.keepindividual = 'yes'; 
% avC = ft_freqgrandaverage(cfg, ERSPc{1:10}); 
% avP = ft_freqgrandaverage(cfg, ERSPp{:}); 
% 
% cfg = [];
% cfg.latency          = [0 1.8];
% cfg.frequency        = 6;
% cfg.method           = 'montecarlo';
% cfg.statistic        = 'ft_statfun_depsamplesT';
% % cfg.correctm         = 'cluster';
% % cfg.clusteralpha     = 0.05;
% % cfg.clusterstatistic = 'maxsum';
% % cfg.minnbchan        = 2;
% % cfg.tail             = 0;
% % cfg.clustertail      = 0;
%  cfg.alpha            = 0.025;
%  cfg.numrandomization = 500;
% 
% % specifies with which sensors other sensors can form clusters
% cfg_neighb.method    = 'distance';
% cfg_neighb.elec             = 'P:\Sein_Jeung\Project_Watermaze\WM_EEG_Data\source-data\Eloc and impedances\81010_xensor.elc'; 
% 
% cfg.neighbours       = ft_prepare_neighbours(cfg_neighb, avC);
% 
% subj = 10;
% design = zeros(2,subj);
% 
% for i = 1:subj
%   design(1,i) = i;
% end
% 
% design(2,1:subj)        = 1;
% 
% secondgroup = [1:10]; 
% for i = 1:10
%   design(1,end+1) = secondgroup(i);
% end
% 
% % thirdgroup = [2,3,6,7,8,9,10,11]; 
% % for i = 1:8
% %   design(1,end+1) = thirdgroup(i);
% % end
% 
% design(2,11:20) = 2;
% % design(2,18:25) = 2;
% 
% cfg.design   = design;
% cfg.uvar     = 1;
% cfg.ivar     = 2;
% 
% [stat] = ft_freqstatistics(cfg, avP, avC)
% 
% 
% mobiPMat    = cat(3,mobiP{:});
% [clusters, p_values, t_sums, permutation_distribution ] = permutest(mobiPMat,deskPMat, 'true', pThreshold, nPermutations, 'true');
% util_WM_plot_ERSP(diffPatients, timePoints, freqPoints, ['ERSP_MTL_' channelGroup.key], ['P:\Sein_Jeung\Project_Watermaze\WM_EEG_Results\ERSP\aggregated_ERSP_mtl_' trialType '_' channelGroup.key '_diff.png'], clusters)
% util_WM_plot_ERSP(mobiP, timePoints, freqPoints, ['ERSP_MTL_' channelGroup.key '_MOBI'], ['P:\Sein_Jeung\Project_Watermaze\WM_EEG_Results\ERSP\aggregated_ERSP_mtl_' trialType '_' channelGroup.key '_mobi.png'],[])
% util_WM_plot_ERSP(deskP, timePoints, freqPoints, ['ERSP_MTL_' channelGroup.key '_STAT'], ['P:\Sein_Jeung\Project_Watermaze\WM_EEG_Results\ERSP\aggregated_ERSP_mtl_' trialType '_' channelGroup.key '_stat.png'],[])
% 
% pMTL = p_values(p_values < pThreshold);
% statStruct.mtl.clusters = clusters; 
% statStruct.mtl.p_values = p_values; 
% statStruct.mtl.t_sums = t_sums; 
% statStruct.mtl.permutation_distribution = permutation_distribution; 
% 
% missedControls  = [];
% diffControls    = {};
% mobiC           = {};
% deskC           = {};
% for Pi = [82001:82011, 83001:83011, 84009]
%     try
%         load(['P:\Sein_Jeung\Project_Watermaze\WM_EEG_Results\ERSP\sub-' num2str(Pi) '\sub-' num2str(Pi) '_ERSP_' channelGroup.key '.mat']);
%         mobiERSP        = mean(cat(3,eval(['ERSP_' trialType '_' trialSection '_mobi{:}'])),3);
%         desktopERSP     = mean(cat(3,eval(['ERSP_' trialType '_' trialSection '_desktop{:}'])),3);
%         diffControls{end+1} = mobiERSP - desktopERSP;
%         mobiC{end+1}    = mobiERSP; 
%         deskC{end+1}    = desktopERSP; 
%     catch
%         missedControls(end+1) = Pi;
%     end
% end
% mobiCMat    = cat(3,mobiC{:});
% deskCMat    = cat(3,deskC{:});
% [clusters, p_values, t_sums, permutation_distribution ] = permutest(mobiCMat,deskCMat, 'true', pThreshold, nPermutations, 'true');
% util_WM_plot_ERSP(diffControls, timePoints, freqPoints, ['ERSP_Controls_' channelGroup.key], ['P:\Sein_Jeung\Project_Watermaze\WM_EEG_Results\ERSP\aggregated_ERSP_control_' trialType '_' channelGroup.key '_diff.png'], clusters)
% util_WM_plot_ERSP(mobiC, timePoints, freqPoints, ['ERSP_Controls_' channelGroup.key '_MOBI'], ['P:\Sein_Jeung\Project_Watermaze\WM_EEG_Results\ERSP\aggregated_ERSP_control_' trialType '_' channelGroup.key '_mobi.png'], [])
% util_WM_plot_ERSP(deskC, timePoints, freqPoints, ['ERSP_Controls_' channelGroup.key '_STAT'], ['P:\Sein_Jeung\Project_Watermaze\WM_EEG_Results\ERSP\aggregated_ERSP_control_' trialType '_' channelGroup.key '_stat.png'], [])
% 
% pCTRL = p_values(p_values < pThreshold);
% statStruct.ctrl.clusters = clusters; 
% statStruct.ctrl.p_values = p_values; 
% statStruct.ctrl.t_sums = t_sums; 
% statStruct.ctrl.permutation_distribution = permutation_distribution;
% 
% missingParticipants = [missedPatients, missedControls];

end