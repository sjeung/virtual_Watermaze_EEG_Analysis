function WM_07_ERSP_channel(Pi, elecGroup)
% time-frequency analysis channel level 
%
% Inputs 
%   Pi          : participant ID
%   elecInds    : 'none' or channel indices
%
% Outputs 
%   none, writes data to disk 
%
%--------------------------------------------------------------------------
%% configuration
%--------------------------------------------------------------------------
WM_config;                                                                  % load configs
freqRange                   = config_param.ERSP_freq_range; 

%% Time-frequency analysis of entire trials 

[ERSPLearnSRaw] = util_WM_ERSP(elecGroup.chan_names, 'learn', 'stat', Pi, freqRange);
[ERSPLearnMRaw] = util_WM_ERSP(elecGroup.chan_names, 'learn', 'mobi', Pi, freqRange);
[ERSPProbeSRaw] = util_WM_ERSP(elecGroup.chan_names, 'probe', 'stat', Pi, freqRange);
[ERSPProbeMRaw] = util_WM_ERSP(elecGroup.chan_names, 'probe', 'mobi', Pi, freqRange);

% visualize trial lengths
util_WM_plot_trial_lengths(ERSPLearnSRaw, ERSPLearnMRaw, ERSPProbeSRaw, ERSPProbeMRaw, Pi); 

%% Baseline correction 

% compute baseline 
[ERSPBaseMOBI]   = util_WM_ERSP(elecGroup.chan_names, 'walk', 'stat', Pi, freqRange);
[ERSPBaseSTAT]   = util_WM_ERSP(elecGroup.chan_names, 'walk', 'mobi', Pi, freqRange);

% correct trial data using common baseline
util_WM_basecorrect(ERSPLearnSRaw, ERSPBaseSTAT, Pi, ['learn_stat_', elecGroup.key]);
util_WM_basecorrect(ERSPLearnMRaw, ERSPBaseMOBI, Pi, ['learn_mobi_', elecGroup.key]);
util_WM_basecorrect(ERSPProbeSRaw, ERSPBaseSTAT, Pi, ['probe_stat_', elecGroup.key]);
util_WM_basecorrect(ERSPProbeMRaw, ERSPBaseMOBI, Pi, ['probe_mobi_', elecGroup.key]);


end
