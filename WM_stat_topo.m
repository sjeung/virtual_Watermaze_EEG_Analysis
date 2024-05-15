function WM_stat_topo(condText, allParticipants)
WM_config;

if contains(condText, 'start')
    timeWindow = [0 1]; 
elseif contains(condText, 'mid')
    timeWindow = [0 3]; 
else
    timeWindow = [-2 0]; 
end

if contains(condText, 'stat')   
    zLims       = [0 1.5]; 
    diffLims    = [-1 1]; 
else
    zLims       = [0 8]; 
    diffLims    = [-3 3]; 
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

pCell    = {}; 
cCell    = {}; 

for Pi = allParticipants
   
    [erspFileName,erspFileDir] = assemble_file(config_folder.results_folder, config_folder.ersp_folder, ['_' condText '_ERSP.mat'], Pi);
    load(fullfile(erspFileDir, erspFileName), 'ERSPcorr'); 
    [outInds, ~] = util_WM_IQR(mean(ERSPcorr.powspctrm, 3, 'omitnan'));
    ERSPcorr.powspctrm(outInds,:,:) = NaN; 
    
    if floor((Pi-80000)/1000) == 1
        pCell{end+1} = ERSPcorr.powspctrm;
    else
        cCell{end+1} = ERSPcorr.powspctrm;
    end
end

average_pCell = nanmean(cat(4, pCell{:}), 4);
average_cCell = nanmean(cat(4, cCell{:}), 4);
ERSPp           = ERSPcorr; 
ERSPc           = ERSPcorr; 
ERSPd           = ERSPcorr; 

ERSPp.powspctrm = average_pCell;
ERSPc.powspctrm = average_cCell;
ERSPd.powspctrm = average_pCell - average_cCell;

cfg                     = [];
cfg.figure              = 'gcf';
cfg.elec                = average_elec;
cfg.xlim                = timeWindow;
cfg.zlim                = zLims;
cfg.colormap            = 'jet';
cfg.highlight           = 'on';
cfg.highlightchannel    = [config_param.chanGroups(1).chan_names, config_param.chanGroups(2).chan_names, config_param.chanGroups(3).chan_names,config_param.chanGroups(4).chan_names];
cfg.highlightsize       = 10; 


f1 = figure('visible', 'off'); 
ft_topoplotTFR(cfg,ERSPp); colorbar; 
f2 = figure('visible', 'off'); 
ft_topoplotTFR(cfg,ERSPc); colorbar; 
cfg.zlim     = diffLims;
f3 = figure('visible', 'off'); ft_topoplotTFR(cfg,ERSPd); colorbar; 

figureFileDir = fullfile(config_folder.figures_folder, 'topoplots');

if ~isfolder(figureFileDir)
    mkdir(figureFileDir)
end

saveas(f1, fullfile(figureFileDir,[condText '_patients.png']))
saveas(f2, fullfile(figureFileDir,[condText '_controls.png']))
saveas(f3, fullfile(figureFileDir,[condText '_diffs.png']))


% permutation test  
% [clusters, p_values, t_sums, permutation_distribution ] = permutest(pCell, cCell, false)
end