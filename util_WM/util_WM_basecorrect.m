function util_WM_basecorrect(ERSPdata, ERSPbase, Pi, condText)
% divide (or subtract) baseline ERSP from data
%--------------------------------------------------------------------------
WM_config;

[erspFileName,erspFileDir] = assemble_file(config_folder.results_folder, config_folder.ersp_folder, ['_' condText '_ERSP.mat'], Pi);

if ~isfolder(erspFileDir)
    mkdir(erspFileDir)
end

% check if the ERSPs have trials
if ndims(ERSPbase.powspctrm) == 3
    trialOn = 0;
else
    trialOn = 1;
end

% issue warning if freq points differ too much
timeDiff        = abs(ERSPbase.freq - ERSPdata.freq);
if any(timeDiff > 0.3)
    error('baseline and data frequency points differ too much');            % difference frequencies should be under 0.3 Hz
end

if trialOn
    % remove outliers from baseline trials
    baseTrials  = mean(ERSPbase.powspctrm, [2,3,4], 'omitnan');
    [outInds,~] = util_WM_IQR(baseTrials);                                  % use IQR methods due to non-normal distribution
    
    % average baseline data over trials and samples
    powerTrials                 = mean(ERSPbase.powspctrm, 4, 'omitnan');   % trials X channels X freqs
    powerTrials(outInds,:,:)    = [];                                       % take out outlier trials
    baseMean                    = mean(powerTrials,1,'omitnan');            % average over trials
    baseMat                     = repmat(baseMean, size(ERSPdata.powspctrm,1),1,1,size(ERSPdata.powspctrm,4));
else
    % average baseline data over trials and samples
    powerTrials                 = mean(ERSPbase.powspctrm, [2,3], 'omitnan');        % trials X channels X freqs
    baseMat                     = repmat(powerTrials,1,1,size(ERSPdata.powspctrm,3));    
end

% corrected ERSP
ERSPcorr                        = ERSPdata;                                 % copy data structure of the input
ERSPcorr.powspctrm              = mean(ERSPdata.powspctrm,2) ./ baseMat;

if ~trialOn % topoplot
    cfg             = [];
    cfg.layout      = ['P:\Sein_Jeung\Project_Watermaze\WM_EEG_Data\source-data\' num2str(Pi) '\' num2str(Pi) '_eloc.elc'];
    ERSPcorr.freq   = mean(ERSPcorr.freq); 
    f = figure('visible', 'off'); ft_topoplotTFR(cfg,ERSPcorr); colorbar
    figureName = [fullfile(erspFileDir, erspFileName(1:end-4)), '.png']; 
    saveas(f, figureName)
end

% save data
save(fullfile(erspFileDir, erspFileName), 'ERSPcorr',  '-v7.3');

end