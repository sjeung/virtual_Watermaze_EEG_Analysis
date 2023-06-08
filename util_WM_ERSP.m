function [ERSP] = util_WM_ERSP(elecNames, trialType, session, Pi, freqRange)
WM_config; 
[epochedFileName,epochedFileDir] = assemble_file(config_folder.data_folder, config_folder.epoched_folder, ['_' trialType '_' session '_epoched.mat'], Pi);

% load data
load(fullfile(epochedFileDir, epochedFileName), 'ftEEG');
EEG = ftEEG;

cfg                     = [];
cfg.output              = 'pow';
cfg.method              = 'mtmconvol';
cfg.channel             = elecNames;
cfg.taper               = 'hanning';
cfg.foi                 = freqRange(1):1:freqRange(2);
cfg.t_ftimwin           = ones(length(cfg.foi),1).*0.3;
cfg.toi                 = 'all';
cfg.pad                 = 'nextpow2';
cfg.padratio            = 4;
cfg.baseline            = NaN;
cfg.datatype            = 'raw';
cfg.keeptrials          = 'yes';
ERSP                    = ft_freqanalysis(cfg, EEG);

end