function [ERSPAll] = util_WM_ERSP(elecNames, trialType, session, Pi, freqRange)

WM_config

% load data
[epochedFileName,epochedFileDir] = assemble_file(config_folder.data_folder, config_folder.epoched_folder, ['_' trialType '_' session '_epoched.mat'], Pi);
load(fullfile(epochedFileDir, epochedFileName), 'ftEEG');
EEG = ftEEG;

timeBuffer = 1; % buffer time pre- and post- epoch

ERSPAll = {};

for Ei = 1:numel(elecNames)
    cfg                     = [];
    cfg.output              = 'pow';
    cfg.method              = 'mtmconvol';
    cfg.channel             = elecNames{Ei};
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
    
    ERSPAll{Ei} = ERSP;
end


% Select the index of the electrode of interest
electrodeIndex = 1;  % Change this according to your electrode index of interest

% Extract the ERSP data for the selected electrode
ERSP = ERSPAll{electrodeIndex};

% % Plot the ERSP using FieldTrip functions
% figure;
% cfg             = [];
% cfg.colorbar    = 'yes';  % Display colorbar
% cfg.xlim        = [10,15];
% ft_singleplotTFR(cfg, ERSP);

end