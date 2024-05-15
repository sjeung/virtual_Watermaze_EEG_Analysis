function [ERSP] = util_WM_ERSP(elecNames, trialType, session, Pi, freqRange, varargin)

WM_config; 

if nargin == 6 
    [epochedFileName,epochedFileDir] = assemble_file(config_folder.data_folder, config_folder.epoched_folder, ['_' trialType '_' session '_epoched_' varargin{1} '.mat'], Pi);
else
    [epochedFileName,epochedFileDir] = assemble_file(config_folder.data_folder, config_folder.epoched_folder, ['_' trialType '_' session '_epoched.mat'], Pi);
end

% load data
load(fullfile(epochedFileDir, epochedFileName), 'ftEEG');
EEG = ftEEG;

cfg                     = [];
cfg.output              = 'pow';
cfg.method              = 'mtmconvol';
cfg.channel             = elecNames;
cfg.taper               = 'hanning';
cfg.foi                 = freqRange(1):1:freqRange(2);
cfg.t_ftimwin           = ones(length(cfg.foi),1).*0.7;
cfg.toi                 = 'all';
cfg.pad                 = 'nextpow2';
cfg.padratio            = 4;
cfg.baseline            = NaN;
cfg.datatype            = 'raw';

if iscell(elecNames)
    cfg.keeptrials      = 'yes';
else
    cfg.keeptrials      = 'no'; 
end

ERSP                    = ft_freqanalysis(cfg, EEG);


end