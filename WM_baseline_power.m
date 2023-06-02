function [ERSPAllMOBI, ERSPAllSTAT, times, freqs] = WM_baseline_power(Pi, elecNames, freqRange)

baseMOBISet     = pop_loadset('filepath', ['P:\Sein_Jeung\Project_Watermaze\WM_EEG_Data\7_epoched\sub-' num2str(Pi)], 'filename', ['sub-' num2str(Pi) '_mobi_walk.set']); 
baseSTATSet     = pop_loadset('filepath', ['P:\Sein_Jeung\Project_Watermaze\WM_EEG_Data\7_epoched\sub-' num2str(Pi)], 'filename', ['sub-' num2str(Pi) '_stat_walk.set']);
baseMOBIEpoch   = eeglab2fieldtrip(baseMOBISet, 'raw'); 
baseSTATEpoch   = eeglab2fieldtrip(baseSTATSet, 'raw'); 

ERSPAllMOBI = {};
ERSPAllSTAT = {};

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
    mobifreq                = ft_freqanalysis(cfg, baseMOBIEpoch);
    statfreq                = ft_freqanalysis(cfg, baseSTATEpoch);
    
    ERSPAllMOBI{end+1}      = mobifreq.powspctrm;
    ERSPAllSTAT{end+1}      = statfreq.powspctrm;
end

times = mobifreq.time;
freqs = mobifreq.freq; 

end