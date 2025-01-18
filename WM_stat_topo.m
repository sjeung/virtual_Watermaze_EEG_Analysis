function WM_stat_topo(condText, allParticipants)
WM_config;

if contains(condText, 'start')
    timeWindow = [0 1]; 
elseif contains(condText, 'mid')
    timeWindow = [0 3]; 
else
    timeWindow = [-2 0]; 
end

if contains(condText, 'stat_all_theta')   
    zLims       = [-1.5 1.5]; 
else
    zLims       = [0 5]; 
end

% Initialize variables to store accumulated electrode positions
total_elec_pos = zeros(132, 3);

% Iterate over all participants
for Pi = allParticipants
    % Read electrode positions for current participant
    elec = ft_read_sens(['P:\Sein_Jeung\Project_Watermaze\WM_EEG_Data\source-data\' num2str(Pi) '\' num2str(Pi) '_eloc.elc']); 
    
    % Accumulate electrode positions
    total_elec_pos = total_elec_pos + elec.chanpos;
end

% Calculate average electrode positions and rotate
average_elec_pos = total_elec_pos / numel(allParticipants);
average_elec = elec; 
average_elec.chanpos = [average_elec_pos(:,2),average_elec_pos(:,1), average_elec_pos(:,3)]; 
average_elec.elecpos = average_elec.chanpos; 

[erspFileName,erspFileDir] = assemble_file(config_folder.results_folder, config_folder.ersp_folder, ['_' condText '_ERSP.mat'], 81001);
load(fullfile(erspFileDir, erspFileName), 'ERSPcorr');

timeIndices = find(ERSPcorr.time >= timeWindow(1), 1,'first'):find(ERSPcorr.time <= timeWindow(2), 1,'last');

pCell    = {}; 
cCell    = {}; 

for Pi = allParticipants
   
    [erspFileName,erspFileDir] = assemble_file(config_folder.results_folder, config_folder.ersp_folder, ['_' condText '_ERSP.mat'], Pi);
    load(fullfile(erspFileDir, erspFileName), 'ERSPcorr'); 
    [outInds, ~] = util_WM_IQR(mean(ERSPcorr.powspctrm, [2,3], 'omitnan'));     % removing outlier electrodes 
    ERSPcorr.powspctrm(outInds,:,:) = NaN; 
    
    if floor((Pi-80000)/1000) == 1
        pCell{end+1} = ERSPcorr.powspctrm;
    else
        cCell{end+1} = ERSPcorr.powspctrm;
    end
end

pConcat             = cat(4, pCell{:}); 
cConcat             = cat(4, cCell{:}); 
sigVals             = nan(1,129);  
meanTs              = sigVals; 

for Ei = 1:129 % last electrode is ref
    pMat        = nanmean(squeeze(pConcat(Ei,1,timeIndices,:)),1);
    cMat        = nanmean(squeeze(cConcat(Ei,1,timeIndices,:)),1);
    [~,p,~,stats] = ttest2(pMat, cMat);
    sigVals(Ei)  = p;
    meanTs(Ei)   = stats.tstat;
end

% Step 1: Find significant p-values
sigEs = find(sigVals < 0.05);

% Step 2: Perform Benjamini-Hochberg FDR correction
sorted_pvals = sort(sigVals(sigEs), 'ascend');
m               = length(sorted_pvals);
threshold       = (1:m) * 0.05 / m;
FDRcorrected    = [];

% Step 3: Display p-values surviving FDR correction
for i = 1:length(sigEs)
    sigEi = sigEs(i);
    if sigVals(sigEi) <= threshold(i)
        disp(['p = ' num2str(sigVals(sigEi)) ' for channel ' ERSPcorr.label{sigEi} ', FDR corrected'])
        FDRcorrected(end+1) = sigEi; 
    end
end

average_pCell   = nanmean(cat(4, pCell{:}), 4);
average_cCell   = nanmean(cat(4, cCell{:}), 4);
ERSPp           = ERSPcorr; 
ERSPc           = ERSPcorr; 
ERSPd           = ERSPcorr; 

ERSPp.powspctrm = average_pCell;
ERSPc.powspctrm = average_cCell;
ERSPd.powspctrm = repmat(meanTs',1,1,numel(ERSPp.time)); % average_pCell - average_cCell;

% cfg = []; 
% cfg.elec = average_elec;
% cfg.projection  = 'orthographic';
% layout = ft_prepare_layout(cfg);

%--------------------------------------------------------------------------
makeFigs = 0; 

if makeFigs
    cfg                     = [];
    cfg.figure              = 'gcf';
    cfg.elec                = average_elec;
    cfg.xlim                = timeWindow;
    cfg.highlightsize       = 10;
    cfg.comment             = 'no';
    cfg.zlim                = zLims;
    
    f1 = figure('visible', 'off');
    ft_topoplotTFR(cfg,ERSPp); colorbar;
    
    f2 = figure('visible', 'off');
    ft_topoplotTFR(cfg,ERSPc); colorbar;
    
    cfg.highlight           = 'on';
    cfg.highlightchannel    = {ERSPcorr.label{FDRcorrected}};
    cfg.highlightsymbol     = '*';
    cfg.highlightcolor      = repelem({[1,1,1]},1,numel(FDRcorrected));
    cfg.zlim                = [];
    
    f3 = figure('visible', 'off');
    ft_topoplotTFR(cfg,ERSPd); colorbar;
    
    
    figureFileDir = fullfile(config_folder.figures_folder, 'topoplots');
    if ~isfolder(figureFileDir)
        mkdir(figureFileDir)
    end
    
    saveas(f1, fullfile(figureFileDir,[condText '_patients.png']))
    saveas(f2, fullfile(figureFileDir,[condText '_controls.png']))
    saveas(f3, fullfile(figureFileDir,[condText '_diffs.png']))
    
    close([f1, f2, f3]);
end

end