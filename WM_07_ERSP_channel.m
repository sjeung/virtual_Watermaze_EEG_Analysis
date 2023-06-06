function WM_07_ERSP_channel(Pi, elecGroup)
% time-frequency analysis channel level 
%
% Inputs 
%   Pi          : participant ID
%   setup       : 1-'MoBI', 2-'Desktop'
%   elecInds    : 'none' or channel indices
%
% Outputs 
%   none, writes data to disk 
%   saved variable 'TFR'
%       TFR.learn_start 
%       TFR.learn_end
%       TFR.probe_start
%       TFP.probe_end
%
%--------------------------------------------------------------------------

%% load data 
%--------------------------------------------------------------------------
% load configs
WM_config;
freqRange   = config_param.ERSP_freq_range; 
[erspFileName,erspFileDir]                  = assemble_file(config_folder.results_folder, config_folder.ersp_folder, ['_ERSP_' elecGroup.key '.mat'], Pi);


%% 1. Compute baseline
%[ERSPAllMOBI, ERSPAllSTAT] = WM_baseline_power(Pi,elecGroup.chan_names, freqRange); 
[ERSPBaseMOBI]   = util_WM_ERSP(elecGroup.chan_names, 'walk', 'stat', Pi, freqRange);
[ERSPBaseSTAT]   = util_WM_ERSP(elecGroup.chan_names, 'walk', 'mobi', Pi, freqRange);

%% 2. Time-frequency analysis of entire trials for timewarping later 
[ERSPLearnSRaw] = util_WM_ERSP(elecGroup.chan_names, 'learn', 'stat', Pi, freqRange);
[ERSPLearnMRaw] = util_WM_ERSP(elecGroup.chan_names, 'learn', 'mobi', Pi, freqRange);
[ERSPProbeSRaw] = util_WM_ERSP(elecGroup.chan_names, 'probe', 'stat', Pi, freqRange);
[ERSPProbeMRaw] = util_WM_ERSP(elecGroup.chan_names, 'probe', 'mobi', Pi, freqRange);

% visualize trial lengths
util_WM_plot_trial_lengths(ERSPLearnSRaw, ERSPLearnMRaw, ERSPProbeSRaw, ERSPProbeMRaw, Pi, WM_config); 

[ERSPLearnS] = util_WM_basecorrect(ERSPLearnSRaw, ERSPBaseSTAT);
[ERSPLearnM] = util_WM_basecorrect(ERSPLearnMRaw, ERSPBaseMOBI);
[ERSPProbeS] = util_WM_basecorrect(ERSPProbeSRaw, ERSPBaseSTAT);
[ERSPProbeM] = util_WM_basecorrect(ERSPProbeMRaw, ERSPBaseMOBI);

%% 3. Analysis of the start and end of trials
[ERSPLearnMobiStart, ERSPLearnMobiEnd, times, freqs]  = util_WM_cut_windows(ERSPLearnM, freqs, 5);
[ERSPProbeStatStart, ERSPProbeStatEnd, times, freqs]  = util_WM_cut_windows(ERSPProbeS, freqs, 5);
[ERSPProbeMobiStart, ERSPProbeMobiEnd, times, freqs]  = util_WM_cut_windows(ERSPProbeM, freqs, 5);


figTitle        = [num2str(Pi) ', Learn Start, MoBI']; 
figFilename     = [num2str(Pi) '_ERSP_L_S_M_' elecGroup.key '.png'];

util_WM_plot_ERSP(ERSPLearnMobiStart, times, freqs, figTitle, fullfile(erspFileDir, figFilename), [])
util_WM_plot_ERSP(ERSPLearnStatStart, times, freqs, figTitle, fullfile(erspFileDir, figFilename), [])

%% 4. Time-warped analysis
[ERSPLearnStart, times, freqs]  = util_WM_cut_windows(ERSPLearnS, 'start', 5,1);

%% 5. Space-based analysis 
% order samples by its distance to center

% order samples by its distance to target

%% 6. Save data 
if ~isfolder(erspFileDir)
    mkdir(erspFileDir)
end

% save results
save(fullfile(erspFileDir, erspFileName),...
    'ERSP_learn_start_mobi',...
    'ERSP_learn_start_desktop',...
    'ERSP_probe_start_mobi',...
    'ERSP_probe_start_desktop');


% %% learn trials start
% eventInds       = find(strcmp('searchtrial:start', {EEG.event.type}) & [EEG.event.session] == 1); 
% epochInds       = util_WM_event2epoch(EEG, eventInds);
% [ERSP_learn_start_mobi, times, freqs] = util_WM_ERSP(EEG, elecInds, epochInds);
% [ERSP_learn_start_mobi] = util_WM_basecorrect(ERSP_learn_start_mobi, ERSPAllMOBI);
% figTitle        = [num2str(Pi) ', Learn Start, MoBI']; 
% figFilename     = [num2str(Pi) '_ERSP_L_S_M_' elecGroup.key '.png'];
% util_WM_plot_ERSP(ERSP_learn_start_mobi, times, freqs, figTitle, fullfile(erspFileDir, figFilename), [])
% 
% eventInds       = find(strcmp('searchtrial:start', {EEG.event.type}) & [EEG.event.session] == 2); 
% epochInds       = util_WM_event2epoch(EEG, eventInds);
% [ERSP_learn_start_desktop] = util_WM_ERSP(EEG, elecInds, epochInds); 
% [ERSP_learn_start_desktop] = util_WM_basecorrect(ERSP_learn_start_desktop, ERSPAllSTAT);
% figTitle        = [num2str(Pi) ', Learn Start, Desktop']; 
% figFilename     = [num2str(Pi) '_ERSP_L_S_D_' elecGroup.key '.png'];
% util_WM_plot_ERSP(ERSP_learn_start_desktop, times, freqs, figTitle, fullfile(erspFileDir, figFilename), [])
% 
% %% learn trials end
% eventInds       = find(strcmp('searchtrial:found', {EEG.event.type}) & [EEG.event.session] == 1); 
% epochInds       = util_WM_event2epoch(EEG, eventInds);
% [ERSP_learn_start_mobi, times, freqs] = util_WM_ERSP(EEG, elecInds, epochInds);
% [ERSP_learn_start_mobi] = util_WM_basecorrect(ERSP_learn_start_mobi, ERSPAllMOBI);
% figTitle        = [num2str(Pi) ', Learn Start, MoBI']; 
% figFilename     = [num2str(Pi) '_ERSP_L_S_M_' elecGroup.key '.png'];
% util_WM_plot_ERSP(ERSP_learn_start_mobi, times, freqs, figTitle, fullfile(erspFileDir, figFilename), [])
% 
% eventInds       = find(strcmp('searchtrial:start', {EEG.event.type}) & [EEG.event.session] == 2); 
% epochInds       = util_WM_event2epoch(EEG, eventInds);
% [ERSP_learn_start_desktop] = util_WM_ERSP(EEG, elecInds, epochInds); 
% [ERSP_learn_start_desktop] = util_WM_basecorrect(ERSP_learn_start_desktop, ERSPAllSTAT);
% figTitle        = [num2str(Pi) ', Learn Start, Desktop']; 
% figFilename     = [num2str(Pi) '_ERSP_L_S_D_' elecGroup.key '.png'];
% util_WM_plot_ERSP(ERSP_learn_start_desktop, times, freqs, figTitle, fullfile(erspFileDir, figFilename), [])
% 
% 
% %% probe trials start
% eventInds       = find(contains({EEG.event.type},'guesstrial:start') & [EEG.event.session] == 1); 
% epochInds       = util_WM_event2epoch(EEG, eventInds);
% [ERSP_probe_start_mobi] = util_WM_ERSP(EEG, elecInds, epochInds); 
% [ERSP_probe_start_mobi] = util_WM_basecorrect(ERSP_probe_start_mobi, ERSPAllMOBI);
% figTitle        = [num2str(Pi) ', Probe Start, MoBI']; 
% figFilename     = [num2str(Pi) '_ERSP_P_S_M_' elecGroup.key '.png'];
% util_WM_plot_ERSP(ERSP_probe_start_mobi, times, freqs, figTitle, fullfile(erspFileDir, figFilename), [])
% 
% eventInds       = find(contains({EEG.event.type},'guesstrial:start') & [EEG.event.session] == 2); 
% epochInds       = util_WM_event2epoch(EEG, eventInds);
% [ERSP_probe_start_desktop] = util_WM_ERSP(EEG, elecInds, epochInds);
% [ERSP_probe_start_desktop] = util_WM_basecorrect(ERSP_probe_start_desktop, ERSPAllSTAT);
% figTitle        = [num2str(Pi) ', Probe Start, Desktop']; 
% figFilename     = [num2str(Pi) '_ERSP_P_S_D_' elecGroup.key '.png'];
% util_WM_plot_ERSP(ERSP_probe_start_desktop, times, freqs, figTitle, fullfile(erspFileDir, figFilename), [])
% 
% 
% %% probe trials end 
% if ~isfolder(erspFileDir)
%     mkdir(erspFileDir)
% end
% 
% % save results
% save(fullfile(erspFileDir, erspFileName),...
%     'ERSP_learn_start_mobi',...
%     'ERSP_learn_start_desktop',...
%     'ERSP_probe_start_mobi',...
%     'ERSP_probe_start_desktop',...
%     'times',...
%     'freqs');

end
