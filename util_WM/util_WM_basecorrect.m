function util_WM_basecorrect(ERSPdata, sessionType, Pi, condText)
% divide (or subtract) baseline ERSP from data
%--------------------------------------------------------------------------
WM_config;

[erspFileName,erspFileDir] = assemble_file(config_folder.results_folder, config_folder.ersp_folder, ['_' condText '_ERSP.mat'], Pi);
[baseFileName,baseFileDir] = assemble_file(config_folder.results_folder, 'baseline_powers', ['_walk_' sessionType '_' condText(end-1:end) '_baseline-power.mat'], Pi);

if ~isfolder(erspFileDir)
    mkdir(erspFileDir)
end

% load baseline file 
load(fullfile(baseFileDir, baseFileName), 'ERSPIQR');
ERSPbase   = ERSPIQR; 

allChans = 0; 

% check if the ERSPs have trials
if ndims(ERSPbase.powspctrm) == 3
    trialOn = 0; 
    if numel(ERSPbase.label) > 60
       allChans = 1;  % this is for topoplot
    end
else
    trialOn = 1;
end

% issue warning if freq points differ too much
timeDiff        = abs(ERSPbase.freq - ERSPdata.freq);
if any(timeDiff > 0.3)
    error('baseline and data frequency points differ too much');            % difference frequencies should be under 0.3 Hz
end

if ~allChans  
    % average baseline data over trials and samples
    powerTrials                 = mean(ERSPbase.powspctrm, 3, 'omitnan');   % trials X channels X freqs 
    baseMean                    = mean(powerTrials,1,'omitnan');            % average over trials
    baseMat                     = repmat(baseMean, size(ERSPdata.powspctrm,1),1,1,size(ERSPdata.powspctrm,4));
else
    % average baseline data over trials and samples
    powerTrials                 = mean(ERSPbase.powspctrm, [2,3], 'omitnan');        % trials X channels X freqs
    baseMat                     = repmat(powerTrials,1,1,size(ERSPdata.powspctrm,3));    
end
clear ERSPbase

% corrected ERSP
ERSPcorr                        = ERSPdata;                                 % copy data structure of the input
clear ERSPdata powerTrials


if allChans % this means the data is for topoplot
    ERSPcorr.powspctrm              = ERSPcorr.powspctrm ./ baseMat;
    cfg             = [];
    cfg.layout      = ['P:\Sein_Jeung\Project_Watermaze\WM_EEG_Data\source-data\' num2str(Pi) '\' num2str(Pi) '_eloc.elc'];
    ERSPcorr.freq   = mean(ERSPcorr.freq);
    f = figure('visible', 'off'); ft_topoplotTFR(cfg,ERSPcorr); colorbar
    figureName = [fullfile(erspFileDir, erspFileName(1:end-4)), '.png'];
    saveas(f, figureName)
else
    ERSPcorr.powspctrm              = squeeze(mean(ERSPcorr.powspctrm,2));
    ERSPcorr.powspctrm              = ERSPcorr.powspctrm ./ squeeze(baseMat);
    ERSPcorr.dimord                 = 'rpt_freq_time';
end

% save data
save(fullfile(erspFileDir, erspFileName), 'ERSPcorr',  '-v7.3');

end