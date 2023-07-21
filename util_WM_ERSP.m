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
cfg.t_ftimwin           = ones(length(cfg.foi),1).*0.7;
cfg.toi                 = 'all';
cfg.pad                 = 'nextpow2';
cfg.padratio            = 4;
cfg.baseline            = NaN;
cfg.datatype            = 'raw';
cfg.keeptrials          = 'yes';
ERSP                    = ft_freqanalysis(cfg, EEG);


% % plot the ERSP using FieldTrip functions
% f = figure;
% cfg             = [];
% cfg.colorbar    = 'yes';  % Display colorbar
% cfg.zlim        = [0,4];
% cfg.figure      = 'gcf';
% set(gcf,'Position',[100 100 2500 500])
% 
% hold on; 
% cfg.xlim        = [-0.5,3];
% ft_singleplotTFR(cfg, ERSP);
% title('Uncorrected ERSP', 'FontSize', 15)
end