function WM_eBOSC(allParticipants, session, trial, timeWindow, chanGroup)

if strcmp(trial, 'stand') ||  strcmp(trial, 'walk')
    isBaseline = 1; 
else
    isBaseline = 0; 
end

condString  = [trial '_' session];

WM_config;

%% add eBOSC toolbox with subdirectories
eBOSCDir = 'P:\Sein_Jeung\Tools\eBOSC';
addpath('P:\Sein_Jeung\Tools\eBOSC\internal') % add eBOSC functions
addpath('P:\Sein_Jeung\Tools\eBOSC\external\BOSC') % add BOSC functions


%% eBOSC parameters
% general setup
cfg.eBOSC.F             = 2.^[1:.125:6.7];              % frequency sampling
cfg.eBOSC.wavenumber	= 6;                            % wavelet family parameter (time-frequency tradeoff)
cfg.eBOSC.fsample       = 250;                          % current sampling frequency of EEG data

% padding
cfg.eBOSC.pad.tfr_s         = 0.5;           % padding following wavelet transform to avoid edge artifacts in seconds (bi-lateral)
cfg.eBOSC.pad.detection_s   = 0.5;           % padding following rhythm detection in seconds (bi-lateral); 'shoulder' for BOSC eBOSC.detected matrix to account for duration threshold
cfg.eBOSC.pad.background_s  = 0.5;           % padding of segments for BG (only avoiding edge artifacts)

% threshold settings
cfg.eBOSC.threshold.excludePeak = [];                                       % lower and upperedit bound of frequencies to be excluded during background fit (Hz) (previously: LowFreqExcludeBG HighFreqExcludeBG)
cfg.eBOSC.threshold.duration	= repmat(2, 1, numel(cfg.eBOSC.F));         % vector of duration thresholds at each frequency (previously: ncyc)
cfg.eBOSC.threshold.percentile  = .95;                                      % percentile of background fit for power threshold

% episode post-processing
cfg.eBOSC.postproc.use      = 'no';         % Post-processing of rhythmic eBOSC.episodes, i.e., wavelet 'deconvolution' (default = 'no')
cfg.eBOSC.postproc.method   = 'MaxBias';	% Deconvolution method (default = 'MaxBias', FWHM: 'FWHM')
cfg.eBOSC.postproc.edgeOnly = 'yes';        % Deconvolution only at on- and offsets of eBOSC.episodes? (default = 'yes')
cfg.eBOSC.postproc.effSignal= 'PT';         % Power deconvolution on whole signal or signal above power threshold? (default = 'PT')

% general processing settings
cfg.eBOSC.channel   = chanGroup.chan_inds;  % select channels (default: all)
cfg.eBOSC.trial     = [];                   % select trials (default: all)
cfg.eBOSC.trial_background = [];            % select trials for background (default: all)

boscOutputs = {};
for Pi = allParticipants
    
    %% load data
    if isBaseline
        fileDir         = fullfile(['P:\Sein_Jeung\Project_Watermaze\WM_EEG_Data\7_epoched\sub-' num2str(Pi) '\sub-' num2str(Pi) '_' condString '_epoched.mat']);
    else
        fileDir         = fullfile(['P:\Sein_Jeung\Project_Watermaze\WM_EEG_Data\7_epoched\sub-' num2str(Pi) '\sub-' num2str(Pi) '_' condString '_epoched_' timeWindow '.mat']);
    end
    load(fullfile(fileDir), 'ftEEG');
    
    %% run eBOSC
    [eBOSC, outConfig, TFR]  = eBOSC_wrapper(cfg, ftEEG);
    eBOSC.config        = outConfig;
    boscOutputs{end+1}  = eBOSC;
end
save(fullfile('P:\Sein_Jeung\Project_Watermaze\WM_EEG_Results\BOSC', ['BOSC_' condString '_' timeWindow '_' chanGroup.key '.mat']), 'boscOutputs', '-v7.3')

end

