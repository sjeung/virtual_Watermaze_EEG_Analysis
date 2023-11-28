function WM_stat_beh_eeg(sessionType, trialType, windowType, channelGroup)

% EEG features 
%   FM/PM theta, alpha, beta, gamma
% Behavioral features
%   Memory score
%   idPhi
%   DTW distances
%--------------------------------------------------------------------------

WM_config

% session code (1 = desktop, 2 = VR)
if strcmp(sessionType, 'stat')
    sessionCode     = 1;
elseif strcmp(sessionType, 'mobi')
    sessionCode     = 2;
end

% participants to include or exclude
patientIDs      = 81001:81011; 
controlIDs      = [82001:82011, 83001:83011, 84009];
excludedIDs     = [81005, 82005, 83005 ...              % 81005 and matched controls excluded due to psychosis
                   81008, 82008, 83008 ...              % 81008 and matched controls excluded due to extensive spectral artefacts in data
                   82009, 83004 ];                      % 82009 nausea   
controlIDs      = setdiff(controlIDs, excludedIDs); 
patientIDs      = setdiff(patientIDs, excludedIDs); 

% patients
loadedVar                       = load(fullfile(config_folder.results_folder, config_folder.band_powers_folder, ['MTLR_average_' trialType '_' sessionType '_' windowType  '_' channelGroup.key config_folder.bandPowerFileName])); % , 'bandpowersp'); 
patientsPower                   = loadedVar.bandpowersp; 

% controls 
loadedVar                       = load(fullfile(config_folder.results_folder, config_folder.band_powers_folder, ['CTRL_average_' trialType '_' sessionType '_' windowType  '_' channelGroup.key config_folder.bandPowerFileName])); % , 'bandpowersp'); 
controlsPower                   = loadedVar.bandpowersc; 

% Behavioral measures 
tableData   = readtable('P:\Sein_Jeung\Project_Watermaze\WM_EEG_Data\BEHdata_OSF.xlsx'); 
IDs         = tableData.id;
LP          = tableData.learning_or_probeTrial; 
SU          = tableData.setup;
MS          = tableData.memory_score;
idPhis      = tableData.avg_idPhi_angular_velocity_5_sec; 
DTWs        = tableData.learning_probe_avg_dTW_square; 

pMeans      = []; 
pSlopes     = NaN(numel(patientIDs), 3, 4); % number of participants X beh measures X frequency bands 
pInd        = 1; 
for Pi = patientIDs
    
    % average performance per participant 
    tInds               = find(IDs == Pi);          % participant ID 
    pInds               = find(LP == 2);            % probe only
    sInds               = find(SU == sessionCode);  % stat or mobi 
    fullInds            = intersect(intersect(tInds,pInds),sInds); % trial inds without outlier removal
    pMeans(1,end+1)     = mean(MS(fullInds)); 
    pMeans(2,end)       = mean(idPhis(fullInds)); 
    pMeans(3,end)       = mean(DTWs(fullInds)); 
    
    % correlate measures trial-by-trial 
    [ERSPFileName, ERSPFileDir]    = assemble_file(config_folder.results_folder, 'ERSP_pruned', ['_' trialType '_' sessionType '_' channelGroup.key '_' windowType '_ERSP_pruned.mat'], Pi);
    [bandFileName, bandFileDir]    = assemble_file(config_folder.results_folder, 'Band_powers', ['_' trialType '_' sessionType '_' windowType, '_' channelGroup.key '_band_powers.mat'], Pi);
    ERSPFile    = load(fullfile(ERSPFileDir, ERSPFileName)); 
    ERSPCell    = struct2cell(ERSPFile); ERSP = ERSPCell{1}; 
    bandFile    = load(fullfile(bandFileDir, bandFileName)); 
    bandPowers  = bandFile.trialBandPowers; 
    behData     = [MS(fullInds), idPhis(fullInds), DTWs(fullInds)];
    behData(ERSP.outliers,:) = [];% remove power outlier rows to match matrix size
    
    
    try
        [slopes]    = WM_correlate_EEG_beh(behData, bandPowers);
        pSlopes(pInd,:,:)   = slopes;
        pInd = pInd +1;
    catch
    end
    
end

cMeans      = []; 
cSlopes     = NaN(numel(controlIDs), 3, 4); % number of participants X beh measures X frequency bands 
cInd        = 1; 
for Pi = controlIDs
    
    % average performance per participant 
    tInds               = find(IDs == Pi);          % participant ID 
    pInds               = find(LP == 2);            % probe only
    sInds               = find(SU == sessionCode);  % stat or mobi 
    fullInds            = intersect(intersect(tInds,pInds),sInds); % trial inds without outlier removal
    cMeans(1,end+1)     = mean(MS(fullInds)); 
    cMeans(2,end)       = mean(idPhis(fullInds)); 
    cMeans(3,end)       = mean(DTWs(fullInds)); 
    
    % correlate measures trial-by-trial 
    [ERSPFileName, ERSPFileDir]    = assemble_file(config_folder.results_folder, 'ERSP_pruned', ['_' trialType '_' sessionType '_' channelGroup.key '_' windowType '_ERSP_pruned.mat'], Pi);
    [bandFileName, bandFileDir]    = assemble_file(config_folder.results_folder, 'Band_powers', ['_' trialType '_' sessionType '_' windowType, '_' channelGroup.key '_band_powers.mat'], Pi);
    ERSPFile    = load(fullfile(ERSPFileDir, ERSPFileName)); 
    ERSPCell    = struct2cell(ERSPFile); ERSP = ERSPCell{1}; 
    bandFile    = load(fullfile(bandFileDir, bandFileName)); 
    bandPowers  = bandFile.trialBandPowers; 
    behData     = [MS(fullInds), idPhis(fullInds), DTWs(fullInds)];
    behData(ERSP.outliers,:) = [];% remove power outlier rows to match matrix size
    
%     if Pi == 82004
%         bandPowers(13,:) = []; % strange drops in beh data
%     elseif Pi == 83009
%         bandPowers(16,:) = []; % strange drops in beh data
%     elseif Pi == 84009
%         bandPowers(end,:) = [];
%     end
%     

try 
    [slopes]    = WM_correlate_EEG_beh(behData, bandPowers); 
    cSlopes(cInd,:,:)   = slopes; 
    cInd = cInd +1; 
catch
end
    
    
end

pMeans = pMeans';
cMeans = cMeans'; 

bandNames = {'theta', 'alpha', 'beta', 'gamma'};
f1 = figure;
sig = 0; 
for iBand = 1
    
    memoryScore = pMeans(:,1); power = patientsPower(:,iBand);
    mdl = fitlm(memoryScore, power);
    hlm = plot(mdl, 'MarkerEdge', 'none', 'MarkerFace', config_visual.pColor, 'MarkerSize', 10);
    hlm(1).Marker       = 'o';
    hlm(2).LineWidth    = 3;
    hlm(2).Color        = config_visual.pColor;
    hlm(3).Color        = 'none'; hlm(4).Color        = 'none';
    % title(['MTLR, ' sessionType, ',' trialType, ',' windowType,',' channelGroup.key '-' bandNames{iBand}]); legend('off'); xlabel('memory score'); ylabel('power')
    if mdl.Coefficients.pValue(2) < 0.05
        disp(['MTLR, ' sessionType, ',' trialType, ',' sessionType, ', ' windowType,',' channelGroup.key '-' bandNames{iBand} ', p = ' num2str(mdl.Coefficients.pValue(2))])
        sig = 1;
    end
    
    hold on;
    
    memoryScore = cMeans(:,1); power = controlsPower(:,iBand);
    mdl = fitlm(memoryScore,power);
    hlm = plot(mdl, 'MarkerEdge', 'none', 'MarkerFace', config_visual.cColor, 'MarkerSize', 10);
    hlm(1).Marker       = 'o';
    hlm(2).LineWidth    = 3;
    hlm(2).Color        = config_visual.cColor;
    hlm(3).Color        = 'none'; hlm(4).Color        = 'none';
    
    % title(['CTRL, ' sessionType, ',' trialType, ',' windowType,',' channelGroup.key '-' bandNames{iBand}]); legend('off'); xlabel('memory score'); ylabel('power')
    title(''); xlabel(''); ylabel('');
    if mdl.Coefficients.pValue(2) < 0.05
        disp(['CTRL, ' sessionType, ',' trialType, ',' sessionType ', ' windowType,',' channelGroup.key '-' bandNames{iBand} ', p = ' num2str(mdl.Coefficients.pValue(2))])
        sig = 1;
    end
    set(gca,'fontsize',20)
    legend(gca,'off')
end

if sig == 0
    close(f1); %close(f2); 
end

% % visualize
% % Create a heatmap of the correlation coefficients
% disp(['Correlation matrices for ' trialType '_' windowType, '_' sessionType '_' channelGroup.key '.png'])
% 
% f = figure('Position', [100 100 1800 600]);
% subplot(1,2,1)
% for rowI = 1:3
%     for colI = 1:4
%         [~,pval] = ttest(pSlopes(:,rowI,colI));
%         if pval < 0.05
%             disp(['MTLR' ', ' trialType ', ' windowType, ', ' sessionType ', ' channelGroup.key ', row ' num2str(rowI), ', col ' num2str(colI), 'p = ' num2str(pval)])
%         end
%     end
% end
% 
% imagesc(squeeze(mean(pSlopes, 'omitnan'))); % 'none' color method for custom colormap
% 
% colorbar; 
% caxis([-0.2,0.2])
% % Set the labels for rows (behavioral measures) and columns (EEG power bands)
% rowLabels = {'MS', 'idPhi', 'DTW'}; % Replace with your labels
% colLabels = {'theta', 'alpha', 'beta', 'gamma'}; % Replace with your labels
% set(gca, 'YTick', 1:numel(rowLabels), 'YTickLabel', rowLabels);
% set(gca, 'XTick', 1:numel(colLabels), 'XTickLabel', colLabels);
% 
% % Set the title and labels for the heatmap
% title(['MTLR' ', ' trialType ', ' windowType, ', ' sessionType ', ' channelGroup.key]);
% xlabel('EEG Power Bands');
% ylabel('Behavioral Measures');
% 
% subplot(1,2,2)
% imagesc(squeeze(mean(cSlopes, 'omitnan'))); % 'none' color method for custom colormap
% for rowI = 1:3
%     for colI = 1:4
%         [~,pval] = ttest(cSlopes(:,rowI,colI));
%         if pval < 0.05
%             disp(['CTRL' ', ' trialType ', ' windowType, ', ' sessionType ', ' channelGroup.key ', row ' num2str(rowI), ', col ' num2str(colI), 'p = ' num2str(pval)])
%         end
%     end
% end
% colorbar; 
% caxis([-0.2,0.2])
% % Set the labels for rows (behavioral measures) and columns (EEG power bands)
% rowLabels = {'MS', 'idPhi', 'DTW'}; % Replace with your labels
% colLabels = {'theta', 'alpha', 'beta', 'gamma'}; % Replace with your labels
% set(gca, 'YTick', 1:numel(rowLabels), 'YTickLabel', rowLabels);
% set(gca, 'XTick', 1:numel(colLabels), 'XTickLabel', colLabels);
% 
% % Set the title and labels for the heatmap
% title(['CTLR' ', ' trialType ', ' windowType, ', ' sessionType ', ' channelGroup.key]);
% xlabel('EEG Power Bands');
% ylabel('Behavioral Measures');
% 
% 
% %--------------------------------------------------------------------------
% for rowI = 1:3
%     for colI = 1:4
%         [~,pval] = ttest2(pSlopes(:,rowI,colI), cSlopes(:,rowI,colI));
%         if pval < 0.05
%             disp(['Diff' ', ' trialType ', ' windowType, ', ' sessionType ', ' channelGroup.key ', row ' num2str(rowI), ', col ' num2str(colI), 'p = ' num2str(pval)])
%         end
%     end
% end
% 
% if ~isfolder(fullfile(config_folder.figures_folder, 'Correlation_matrices'))
%     mkdir(fullfile(config_folder.figures_folder, 'Correlation_matrices'))
% end
% saveas(f,fullfile(config_folder.figures_folder, 'Correlation_matrices', [trialType '_' windowType, '_' sessionType '_' channelGroup.key '.png']))
% close(f); 

end

