function util_WM_basecorrect(ERSPdata, ERSPbase, Pi, condText)
% divide (or subtract) baseline ERSP from data
%--------------------------------------------------------------------------
WM_config;

% issue warning if freq points differ too much
timeDiff        = abs(ERSPbase.freq - ERSPdata.freq);
if any(timeDiff > 0.3)
    error('baseline and data frequency points differ too much');            % difference frequencies should be under 0.3 Hz
end

% remove outliers from baseline trials 
baseTrials  = mean(ERSPbase.powspctrm, [2,3,4], 'omitnan'); 
[~,outInds] = rmoutliers(baseTrials);                                       % extract outlier indices
 
% average baseline data over trials and samples 
powerTrials                = mean(ERSPbase.powspctrm, 4, 'omitnan');        % trials X channels X freqs
powerTrials(outInds,:,:)   = [];                                            % take out outlier trials
baseMean    = mean(powerTrials,1,'omitnan');                                % average over trials
baseMat     = repmat(baseMean, size(ERSPdata.powspctrm,1),1,1,size(ERSPdata.powspctrm,4));

ERSPcorr                        = ERSPdata;                                 % copy data structure of the input                              
ERSPcorr.powspctrm              = ERSPdata.powspctrm ./ baseMat;
ERSPcorr.numoutliers            = numel(find(outInds));  

% save data
[erspFileName,erspFileDir] = assemble_file(config_folder.results_folder, config_folder.ersp_folder, ['_' condText '_ERSP.mat'], Pi);

if ~isfolder(erspFileDir)
    mkdir(erspFileDir)
end

save(fullfile(erspFileDir, erspFileName), 'ERSPcorr'); 

% plot the ERSP using FieldTrip functions
f = figure;
cfg             = [];
cfg.colorbar    = 'yes';  % Display colorbar
cfg.zlim        = [0,4];
cfg.figure      = 'gcf';
set(gcf,'Position',[100 100 2500 500])

subplot(1,3,1)
hold on; 
cfg.xlim        = [-0.5,3];
ft_singleplotTFR(cfg, ERSPdata);
title('Uncorrected ERSP', 'FontSize', 15)

subplot(1,3,2)
cfg.xlim        = [0.2,3.7];
cfg.trials      = find(~outInds); 
ft_singleplotTFR(cfg, ERSPbase);
title('Baseline ERSP', 'FontSize', 15)

subplot(1,3,3)
cfg.xlim        = [-0.5,3];
cfg.trials      = 'all'; 
ft_singleplotTFR(cfg, ERSPcorr);
title('Corrected ERSP', 'FontSize', 15)
    
saveas(f, fullfile(erspFileDir, ['sub-' num2str(Pi) '_' condText '_baseline.png']))
close(f)

end