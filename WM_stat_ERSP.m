function [p_values, excludedIDsStr] = WM_stat_ERSP(trialType, trialSection, channelGroup, doERSPStat)

% trialType = 'learn_stat', 'learn_mobi', 'probe_stat', *probe_mobi'
% contrast participants versus controls
% contrast first to last learning trials 
% contrast rotated versus unrotated trials 
%--------------------------------------------------------------------------

% Parameters
%--------------------------------------------------------------------------
WM_config; 
pThreshold      = 0.025; 
nPermutations   = 5000; 

% Load data
%--------------------------------------------------------------------------
ERSPvar = load(['P:\Sein_Jeung\Project_Watermaze\WM_EEG_Results\ERSP\sub-81001\sub-81001_' trialType '_' channelGroup.key '_' trialSection '_ERSP.mat']);
fn = fieldnames(ERSPvar); vn = fn{1}; ERSP = ERSPvar.(vn); % highly annoying to work with this variable name - update later

timePoints = ERSP.time; 
freqPoints = ERSP.freq;

% Main loop 
%--------------------------------------------------------------------------
% participants to include or exclude
patientIDs      = 81001:81011; 
controlIDs      = [82001:82011, 83001:83011, 84009];
excludedIDs     = [81005, 82005, 83005 ...      % 81005 and matched controls excluded due to psychosis
                   82009];                     % 82009 nausea              

controlIDs      = setdiff(controlIDs, excludedIDs); 
patientIDs      = setdiff(patientIDs, excludedIDs); 

% aggregate and run statistics on difference
missedPatients  = []; 
missedControls  = []; 
ERSPp           = {};
ERSPc           = {};
bandpowersp     = []; % matrix, number of patients X number of frequency bands
bandpowersc     = [];

for Pi = patientIDs
    try
        ERSPvar         = load(['P:\Sein_Jeung\Project_Watermaze\WM_EEG_Results\ERSP_pruned\sub-' num2str(Pi) '\sub-' num2str(Pi) '_' trialType '_' channelGroup.key '_' trialSection '_ERSP_pruned.mat']);    
        fn              = fieldnames(ERSPvar);
        vn              = fn{1};
        ERSP            = ERSPvar.(vn);
        ERSPp{end+1}    = squeeze(mean(ERSP.powspctrm,[1,2],'omitnan'));
        
        % compute band power
        trialBandPowers     = []; % trial-by-trial powers  
        meanBandPowers      = []; % trials are averaged
        
        for Bi = 1:numel(config_param.band_names) 

            % find indices of closed point to upper and lower bounds
            [~,lowInd]                  = min(abs(freqPoints - config_param.band_bounds(Bi,1)));
            [~,upInd]                   = min(abs(freqPoints - config_param.band_bounds(Bi,2)));
            
            if strcmp(trialSection, 'Start')
                timeInds = find(ERSP.time > 0);
            elseif strcmp(trialSection, 'End')
                timeInds = find(ERSP.time < 0);
            elseif strcmp(trialSection, 'Mid')
                timeInds = find(ERSP.time);
            end
            
            trialBandPowers(:,end+1)    = mean(ERSP.powspctrm(:,:,lowInd:upInd,timeInds),[2,3,4]);
            meanBandPowers(Bi)          = squeeze(mean(ERSP.powspctrm(:,:,lowInd:upInd,timeInds),[1,2,3,4]));
            
        end
        
        bandpowersp(end+1,:)            = meanBandPowers;
        
        % save trial-by-trial powers 
        [bandFileName, bandFileDir]     = assemble_file(config_folder.results_folder, config_folder.band_powers_folder, ['_' trialType '_' trialSection '_' channelGroup.key config_folder.bandPowerFileName], Pi);
        
        if ~exist(bandFileDir, 'dir')
            mkdir(bandFileDir)
        end
        
        save(fullfile(bandFileDir, bandFileName), 'trialBandPowers')

    catch
        warning(['Could not process participant ' num2str(Pi)])
        missedPatients(end+1) = Pi;
    end
end

for Pi = controlIDs
    try
        ERSPvar         = load(['P:\Sein_Jeung\Project_Watermaze\WM_EEG_Results\ERSP_pruned\sub-' num2str(Pi) '\sub-' num2str(Pi) '_' trialType '_' channelGroup.key '_' trialSection '_ERSP_pruned.mat']);    
        fn              = fieldnames(ERSPvar);
        vn              = fn{1};
        ERSP            = ERSPvar.(vn);
        ERSPc{end+1}    = squeeze(mean(ERSP.powspctrm,[1,2],'omitnan'));
        
        % compute band power
        trialBandPowers     = []; % trial-by-trial powers  
        meanBandPowers      = []; % trials are averaged
        
        for Bi = 1:numel(config_param.band_names) 

            % find indices of closed point to upper and lower bounds
            [~,lowInd]                  = min(abs(freqPoints - config_param.band_bounds(Bi,1)));
            [~,upInd]                   = min(abs(freqPoints - config_param.band_bounds(Bi,2)));
            
            if strcmp(trialSection, 'Start')
                timeInds = find(ERSP.time > 0);
            elseif strcmp(trialSection, 'End')
                timeInds = find(ERSP.time < 0);
            elseif strcmp(trialSection, 'Mid')
                timeInds = find(ERSP.time);
            end
            
            trialBandPowers(:,end+1)        = mean(ERSP.powspctrm(:,:,lowInd:upInd,timeInds),[2,3,4]);
            meanBandPowers(Bi)              = squeeze(mean(ERSP.powspctrm(:,:,lowInd:upInd,timeInds),[1,2,3,4]));
            
        end
        
        bandpowersc(end+1,:)            = meanBandPowers;
        
        % save trial-by-trial powers 
        [bandFileName, bandFileDir]     = assemble_file(config_folder.results_folder, config_folder.band_powers_folder, ['_' trialType '_' trialSection '_' channelGroup.key config_folder.bandPowerFileName], Pi);
        
        if ~exist(bandFileDir, 'dir')
            mkdir(bandFileDir)
        end
        
        save(fullfile(bandFileDir, bandFileName), 'trialBandPowers')

    catch
        warning(['Could not process participant ' num2str(Pi)])
        missedControls(end+1) = Pi;
    end
end


mergedpowers    = [bandpowersp; bandpowersc]; 
mergedIDs       = [patientIDs, controlIDs];
ind = util_WM_IQR(log(mean(mergedpowers,2)));
figure; 
subplot(1,2,1)
imagesc(mergedpowers); colorbar; 
title([trialType '_' trialSection '_' channelGroup.key ' all'], 'Interpreter', 'none')
subplot(1,2,2)
exc                = mergedpowers; 
exc(ind,:)         =  []; 
imagesc(exc); colorbar; 
excIDs = mergedIDs(ind);  % Get the IDs of excluded participants
excludedIDsStr = num2str(excIDs, '%d ');
title([trialType '_' trialSection '_' channelGroup.key ' excluding ' excludedIDsStr], 'Interpreter', 'none')

[~, indexp] = ismember(excIDs, patientIDs); 
indexp(indexp == 0) = [];
bandpowersp(indexp,:)       = NaN;
[~, indexc] = ismember(excIDs, controlIDs); 
indexc(indexc == 0) = [];
bandpowersc(indexc,:)       = NaN;

% save summary of all patients data 
save(fullfile(config_folder.results_folder, config_folder.band_powers_folder, ['MTLR_average_' trialType '_' trialSection '_' channelGroup.key config_folder.bandPowerFileName]), 'bandpowersp')
save(fullfile(config_folder.results_folder, config_folder.band_powers_folder, ['CTRL_average_' trialType '_' trialSection '_' channelGroup.key config_folder.bandPowerFileName]), 'bandpowersc')

if numel(indexp) > 0 
   ERSPp(indexp) = [];  
end

if numel(indexc) > 0 
   ERSPc(indexc) = [];  
end

pMat    = cat(3,ERSPp{:});
cMat    = cat(3,ERSPc{1:numel(ERSPc)});

% Participants versus controls contrast
%--------------------------------------------------------------------------
if doERSPStat
    [clusters, p_values, t_sums, permutation_distribution] = permutest(pMat,cMat, false, pThreshold, nPermutations, true);
    
    if contains(trialType, 'mobi')
        lims = [0,4];
    else
        lims = [0,1.2];
    end
    
%     util_WM_plot_ERSP(ERSPp, timePoints, freqPoints, ['ERSP_MTL_' trialType '_' channelGroup.key '_' trialSection], ['P:\Sein_Jeung\Project_Watermaze\WM_EEG_Figures\ERSP\aggregated_ERSP_mtl_' trialType '_' channelGroup.key '_' trialSection '.png'], [], lims)
%     util_WM_plot_ERSP(ERSPc, timePoints, freqPoints, ['ERSP_CTRL_' trialType '_' channelGroup.key '_' trialSection], ['P:\Sein_Jeung\Project_Watermaze\WM_EEG_Figures\ERSP\aggregated_ERSP_ctrl_' trialType '_' channelGroup.key '_' trialSection '.png'], [], lims)
     
    sigClusters = find(p_values < 0.05);
    
    for Ci = sigClusters
        
        disp([num2str(Ci) ' out of ' num2str(numel(sigClusters)) ' significant cluster found'])
        mask = clusters{Ci};
        util_WM_plot_ERSP({ERSPp, ERSPc}, timePoints, freqPoints, ['MTLR-CTRL_' channelGroup.key], ['P:\Sein_Jeung\Project_Watermaze\WM_EEG_Figures\ERSP\aggregated_ERSP_diff_' trialType '_' channelGroup.key '_' trialSection '.png'], mask, lims)
        
    end
    
    disp(['ERSP sig cluster p = ' num2str(p_values(1)) ', ERSP_' trialType '_' channelGroup.key '_' trialSection])
end


end