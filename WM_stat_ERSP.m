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
                   82009 ];                     % 82009 nausea              
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

% save summary of all patients data 
save(fullfile(config_folder.results_folder, config_folder.band_powers_folder, ['MTLR_average_' trialType '_' trialSection '_' channelGroup.key config_folder.bandPowerFileName]), 'bandpowersp')
       


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

% save summary of all patients data 
save(fullfile(config_folder.results_folder, config_folder.band_powers_folder, ['CTRL_average_' trialType '_' trialSection '_' channelGroup.key config_folder.bandPowerFileName]), 'bandpowersc')
      

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
    
    util_WM_plot_ERSP(ERSPp, timePoints, freqPoints, ['ERSP_MTL_' trialType '_' channelGroup.key '_' trialSection], ['P:\Sein_Jeung\Project_Watermaze\WM_EEG_Figures\ERSP\aggregated_ERSP_mtl_' trialType '_' channelGroup.key '_' trialSection '.png'], [], lims)
    util_WM_plot_ERSP(ERSPc, timePoints, freqPoints, ['ERSP_CTRL_' trialType '_' channelGroup.key '_' trialSection], ['P:\Sein_Jeung\Project_Watermaze\WM_EEG_Figures\ERSP\aggregated_ERSP_ctrl_' trialType '_' channelGroup.key '_' trialSection '.png'], [], lims)
    
    sigClusters = find(p_values < 0.05);
    
    for Ci = sigClusters
        
        disp([num2str(Ci) ' out of ' num2str(numel(sigClusters)) ' significant cluster found'])
        mask = clusters{Ci};
        util_WM_plot_ERSP({ERSPp, ERSPc}, timePoints, freqPoints, ['MTLR-CTRL_' channelGroup.key], ['P:\Sein_Jeung\Project_Watermaze\WM_EEG_Figures\ERSP\aggregated_ERSP_diff_' trialType '_' channelGroup.key '_' trialSection '.png'], mask, lims)
        
    end
    
    disp(['ERSP sig cluster p = ' num2str(p_values(1))])
end

% Participant versus control spectra 
%--------------------------------------------------------------------------
f = figure; 
%subplot(1,2,1)
this = mean(pMat, 2); pSpectra = squeeze(this);
this2 = mean(pMat, [2,3]); pSpectraMean = squeeze(this2);
that = mean(cMat, 2); cSpectra = squeeze(that);
that2 = mean(cMat, [2,3]); cSpectraMean = squeeze(that2);

% Assuming you have pSpectra and cSpectra matrices
% Calculate the mean and standard error for each frequency
mean_pSpectra   = pSpectraMean';
std_pSpectra    = nanstd(pSpectra', 1);
mean_cSpectra   = cSpectraMean';
std_cSpectra    = nanstd(cSpectra', 1);

% Define the x-axis (frequencies)
frequencies = 1:size(pSpectra, 1); % You may need to adjust this based on your data

% Plot the mean lines
plot(frequencies, mean_pSpectra, 'LineWidth', 3, 'Color', config_visual.pColor);
hold on;
plot(frequencies, mean_cSpectra, 'LineWidth', 3, 'Color', config_visual.cColor);

% Plot the confidence intervals as filled areas
x = [frequencies, fliplr(frequencies)]; % x values for filling
y_p = [mean_pSpectra + std_pSpectra, fliplr(mean_pSpectra - std_pSpectra)]; % y values for filling
fill(x, y_p, config_visual.pColor, 'FaceAlpha', 0.2, 'EdgeColor', 'none'); % Fill confidence interval area for pSpectra

y_c = [mean_cSpectra + std_cSpectra, fliplr(mean_cSpectra - std_cSpectra)]; % y values for filling
fill(x, y_c, config_visual.cColor, 'FaceAlpha', 0.2, 'EdgeColor', 'none'); % Fill confidence interval area for cSpectra

% %grid on; 

%xlabel('frequencies in Hz')
%ylabel('trial power / baseline')
%title(['Power ratio ' trialType ', ' channelGroup.key ', ' trialSection], 'Interpreter', 'none')
if contains(trialType, 'mobi')
    ylim([0 20])
else
    ylim([-0.5 3])
end

set(gcf,'Position',[300 300 500 800])
set(gca,'fontsize',20)
set(gca,'Xscale','log')

xticks([1 6 10 18 28 58])
xticklabelsCell = arrayfun(@num2str, [3 8 12 20 30 60], 'UniformOutput', false);
xticklabels(xticklabelsCell);

if ~strcmp(trialSection,'Start')
    set(gca, 'YColor','none')
end
saveas(f, fullfile(config_folder.figures_folder, [trialType '_' channelGroup.key '_' trialSection '_narrow.png']))
saveas(f, fullfile(config_folder.figures_folder, [trialType '_' channelGroup.key '_' trialSection '_narrow.svg']))


 
% % Band power 
% %--------------------------------------------------------------------------
% subplot(1,2,2) 
% dataBoxPlot                             = nan(numel(config_param.band_names),2,30);
% dataBoxPlot(:,1,1:size(bandpowersp,1))  = bandpowersp';
% dataBoxPlot(:,2,1:size(bandpowersc,1))  = bandpowersc';
% boxplot2(dataBoxPlot); 
% 
% h =  findobj(gca,'Tag','Box');
% 
% for j=1:length(h)
% 
%     if mod(j,2) == 1
%         color = config_visual.cColor;
%     else
%         color = config_visual.pColor;
%     end
%     
%     patch(get(h(j),'XData'),get(h(j),'YData'),color,'FaceAlpha',.8, 'EdgeColor','w');
%     
% end
% 
% xticks([1,2,3,4])
% xticklabels({'theta','alpha','beta','gamma'})
% set(gcf,'Position',[300 300 1500 800])
% set(gca,'fontsize',15)
% 
% if contains(trialType, 'mobi')
%     ylim([0 20])
% else
%     ylim([-0.5 3])
% end
% 
% saveas(f, fullfile(config_folder.figures_folder, [trialType '_' channelGroup.key '_' trialSection '.png']))
% 
% for Bi = 1:numel(config_param.band_names)
%     [~, pval] = ttest2(bandpowersp(:,Bi), bandpowersc(:,Bi)); 
%     disp([config_param.band_names{Bi} ', ' trialType ', ' trialSection ', ' channelGroup.key ' band powers, p = ' num2str(pval)])
% end


end