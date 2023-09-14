function WM_stat_ERSP(trialType, trialSection, channelGroup, doERSPStat)

% trialType = 'learn_stat', 'learn_mobi', 'probe_stat', *probe_mobi'
% contrast participants versus controls
% contrast first to last learning trials 
% contrast rotated versus unrotated trials 
%--------------------------------------------------------------------------

% Parameters
%--------------------------------------------------------------------------
WM_config; 
pThreshold      = 0.025; 
nPermutations   = 2000; 

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
                   81008, 82008, 83008 ...      % 81008 and matched controls excluded due to extensive spectral artefacts in data
                   82009 ];                     % 82009 nausea   patientIDs      = setdiff(patientIDs, excludedIDs); 
controlIDs      = setdiff(controlIDs, excludedIDs); 
patientIDs      = setdiff(patientIDs, excludedIDs); 

% aggregate and run statistics on difference
missedPatients  = []; 
missedControls  = []; 
ERSPp           = {};
ERSPc           = {};
bandpowersp     = [];   % matrix, number of patients X number of frequency bands
bandpowersc     = [];
    
for Pi = patientIDs
    try
        ERSPvar         = load(['P:\Sein_Jeung\Project_Watermaze\WM_EEG_Results\ERSP\sub-' num2str(Pi) '\sub-' num2str(Pi) '_' trialType '_' channelGroup.key '_' trialSection '_ERSP.mat']);    
        fn              = fieldnames(ERSPvar);
        vn              = fn{1};
        ERSP            = ERSPvar.(vn);
        ERSPp{end+1}    = squeeze(median(ERSP.powspctrm,[1,2],'omitnan'));
        
        % compute band power
        bandPowers      = []; % participant specific, trial-by-trial powers  
        meanBandPowers  = []; % trials are averaged
        
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
            
            bandPowers(:,end+1)         = median(ERSP.powspctrm(:,:,lowInd:upInd,timeInds),[2,3,4]);
            meanBandPowers(Bi)          = squeeze(median(ERSP.powspctrm(:,:,lowInd:upInd,timeInds),[1,2,3,4]));
            
        end
        
        bandpowersp(end+1,:)       = meanBandPowers;
        
        [bandFileName, bandFileDir]     = assemble_file(config_folder.results_folder, config_folder.band_powers_folder, ['_' trialType '_' trialSection '_' channelGroup.key '_' config_folder.bandPowerFileName], Pi);
        save(fullfile(bandFileDir, bandFileName), 'bandpowers')

    catch
        missedPatients(end+1) = Pi;
    end
end

for Pi = controlIDs 
    try
        
        ERSPvar =  load(['P:\Sein_Jeung\Project_Watermaze\WM_EEG_Results\ERSP\sub-' num2str(Pi) '\sub-' num2str(Pi) '_' trialType '_' channelGroup.key '_' trialSection '_ERSP.mat']);
        fn              = fieldnames(ERSPvar);
        vn              = fn{1};
        ERSP            = ERSPvar.(vn);
        ERSPc{end+1}    = squeeze(median(ERSP.powspctrm,[1,2], 'omitnan'));
        
        % compute band power
        bandPowers      = []; % participant specific, trial-by-trial powers
        meanBandPowers  = []; % trials are averaged
        
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
            
            bandPowers(:,end+1)         = median(ERSP.powspctrm(:,:,lowInd:upInd,timeInds),[2,3,4]);
            meanBandPowers(Bi)          = squeeze(median(ERSP.powspctrm(:,:,lowInd:upInd,:),[1,2,3,4]));
            
        end
        
        bandpowersc(end+1,:)            = meanBandPowers;
        
        [bandFileName, bandFileDir]     = assemble_file(config_folder.results_folder, config_folder.band_powers_folder, ['_' trialType '_' trialSection '_' channelGroup.key '_' config_folder.bandPowerFileName], Pi);
        save(fullfile(bandFileDir, bandFileName), 'bandpowers')
        
    catch
       missedControls(end+1) = Pi; 
    end
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
    
    util_WM_plot_ERSP(ERSPp, timePoints, freqPoints, ['ERSP_MTL_' channelGroup.key], ['P:\Sein_Jeung\Project_Watermaze\WM_EEG_Figures\aggregated_ERSP_mtl_' trialType '_' channelGroup.key '_' trialSection '.png'], [], lims)
    util_WM_plot_ERSP(ERSPc, timePoints, freqPoints, ['ERSP_CTRL_' channelGroup.key], ['P:\Sein_Jeung\Project_Watermaze\WM_EEG_Figures\aggregated_ERSP_ctrl_' trialType '_' channelGroup.key '_' trialSection '.png'], [], lims)
    
    sigClusters = find(p_values < 0.05);
    
    for Ci = sigClusters
        
        disp([num2str(Ci) ' out of ' num2str(numel(sigClusters)) ' significant cluster found'])
        mask = clusters{Ci};
        util_WM_plot_ERSP({ERSPp, ERSPc}, timePoints, freqPoints, ['MTLR-CTRL_' channelGroup.key], ['P:\Sein_Jeung\Project_Watermaze\WM_EEG_Results\ERSP\aggregated_ERSP_diff_' trialType '_' channelGroup.key '_' trialSection '.png'], mask, lims)
        
    end
    
    disp(['ERSP sig cluster p = ' num2str(p_values(1))])
end

pColor = [22, 137, 128]/225; 
cColor = [100, 100, 100]/225; 
% Participant versus control spectra 
%--------------------------------------------------------------------------
f = figure; 
subplot(1,2,1)
this = median(pMat, 2); this = squeeze(this);
this2 = median(pMat, [2,3]); this2 = squeeze(this2);
plot(this, 'LineWidth', 1, 'Color', [pColor, 0.5]);
hold on; 
plot(this2, 'LineWidth', 3, 'Color', pColor);

that = median(cMat, 2); that = squeeze(that);
that2 = median(cMat, [2,3]); that2 = squeeze(that2);
plot(that, 'LineWidth', 1, 'Color', [cColor, 0.5])
plot(that2, 'LineWidth', 3, 'Color', cColor);

% SEM = std(that,0,2)/sqrt(size(that,2)); % standard error
% ts = tinv([0.025  0.975],length(that)-1); % t score
% confplot(1:size(that,1), that2, median(that,2) - ts(2)*SEM, median(that,2) + ts(2)*SEM, 'Color', [pColor, 0.5] ); 

xticks(1:5:size(cMat,1))
xticklabelsCell = arrayfun(@num2str, round(freqPoints(1:5:size(cMat,1))), 'UniformOutput', false);
xticklabels(xticklabelsCell);
xlabel('frequencies in Hz')
ylabel('trial power / baseline')
title(['Spectra ' trialType ', ' channelGroup.key ', ' trialSection], 'Interpreter', 'none')

% Band power 
%--------------------------------------------------------------------------
subplot(1,2,2) 
dataBoxPlot                             = nan(numel(config_param.band_names),2,30);
dataBoxPlot(:,1,1:size(bandpowersp,1))  = bandpowersp';
dataBoxPlot(:,2,1:size(bandpowersc,1))  = bandpowersc';
boxplot2(dataBoxPlot); 

h =  findobj(gca,'Tag','Box');

for j=1:length(h)

    if mod(j,2) == 1
        color = cColor;
    else
        color = pColor;
    end
    
    patch(get(h(j),'XData'),get(h(j),'YData'),color,'FaceAlpha',.3, 'EdgeColor','w');
    
end

xticks([1,2,3,4])
xticklabels({'theta','alpha','beta','gamma'})
set(gcf,'Position',[300 300 1500 800])
saveas(f, fullfile(config_folder.figures_folder, [trialType '_' channelGroup.key '_' trialSection '.png']))

for Bi = 1:numel(config_param.band_names)
    [~, pval] = ttest2(bandpowersp(:,Bi), bandpowersc(:,Bi)); 
    disp([config_param.band_names{Bi} ', ' trialType ', ' trialSection ', ' channelGroup.key ' band powers, p = ' num2str(pval)])
end

% Temporal band power  
%--------------------------------------------------------------------------
for Bi = 1:numel(config_param.band_names)
    
    
end











end