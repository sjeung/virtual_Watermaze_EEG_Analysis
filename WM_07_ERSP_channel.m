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
[ERSPStandBaseMOBI]     = util_WM_ERSP(elecGroup.chan_names, 'stand', 'stat', Pi, freqRange);
[ERSPStandBaseSTAT]     = util_WM_ERSP(elecGroup.chan_names, 'stand', 'mobi', Pi, freqRange);
[ERSPWalkBaseMOBI]      = util_WM_ERSP(elecGroup.chan_names, 'walk', 'stat', Pi, freqRange);
[ERSPWalkBaseSTAT]      = util_WM_ERSP(elecGroup.chan_names, 'walk', 'mobi', Pi, freqRange);

% compare walking baseline activity against standing baseline
util_WM_basecorrect(ERSPWalkBaseSTAT, ERSPStandBaseSTAT, Pi, ['walk_versus_stand_stat_', elecGroup.key]);
util_WM_basecorrect(ERSPWalkBaseMOBI, ERSPStandBaseMOBI, Pi, ['walk_versus_stand_mobi_', elecGroup.key]);

% correct trial data using common baseline
util_WM_basecorrect(ERSPLearnSRaw, ERSPWalkBaseSTAT, Pi, ['learn_stat_', elecGroup.key]);
util_WM_basecorrect(ERSPLearnMRaw, ERSPWalkBaseMOBI, Pi, ['learn_mobi_', elecGroup.key]);
util_WM_basecorrect(ERSPProbeSRaw, ERSPWalkBaseSTAT, Pi, ['probe_stat_', elecGroup.key]);
util_WM_basecorrect(ERSPProbeMRaw, ERSPWalkBaseMOBI, Pi, ['probe_mobi_', elecGroup.key]);


end
