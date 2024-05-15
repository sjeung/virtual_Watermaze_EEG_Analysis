function WM_topo(foiL, foiU, fBandName, Pi, timeWindow)
WM_config; 

freqRange                = [foiL, foiU]; 


%% Time-frequency analysis of entire trials 
[ERSPLearnSRaw] = util_WM_ERSP('all', 'learn', 'stat', Pi, freqRange, timeWindow);
[ERSPLearnMRaw] = util_WM_ERSP('all', 'learn', 'mobi', Pi, freqRange, timeWindow);
[ERSPProbeSRaw] = util_WM_ERSP('all', 'probe', 'stat', Pi, freqRange, timeWindow);
[ERSPProbeMRaw] = util_WM_ERSP('all', 'probe', 'mobi', Pi, freqRange, timeWindow);


%% Baseline correction 
[ERSPWalkBaseMOBI]      = util_WM_ERSP('all', 'walk', 'stat', Pi, freqRange);
[ERSPWalkBaseSTAT]      = util_WM_ERSP('all', 'walk', 'mobi', Pi, freqRange);

[baseFileName,baseFileDir] = assemble_file(config_folder.results_folder, [config_folder.ersp_folder '_base'], ['_allchan_' fBandName '_.mat'], Pi);

if ~isfolder(baseFileDir)
    mkdir(baseFileDir)
end

% save data from baseline 
save(fullfile(baseFileDir, baseFileName), 'ERSPWalkBaseMOBI', 'ERSPWalkBaseSTAT',  '-v7.3'); 

% correct trial data using common baseline
util_WM_basecorrect(ERSPLearnSRaw, ERSPWalkBaseSTAT, Pi, ['learn_stat_all_' fBandName '_' timeWindow]);
util_WM_basecorrect(ERSPLearnMRaw, ERSPWalkBaseMOBI, Pi, ['learn_mobi_all_' fBandName '_' timeWindow]);
util_WM_basecorrect(ERSPProbeSRaw, ERSPWalkBaseSTAT, Pi, ['probe_stat_all_' fBandName '_' timeWindow]);
util_WM_basecorrect(ERSPProbeMRaw, ERSPWalkBaseMOBI, Pi, ['probe_mobi_all_' fBandName '_' timeWindow]);


end
