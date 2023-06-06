function [ERSPcorr] = util_WM_basecorrect(ERSPdata, ERSPbase)
% divide (or subtract) baseline ERSP from data
%--------------------------------------------------------------------------

% issue warning if freq points differ too much
timeDiff        = abs(ERSPbase.freq - ERSPdata.freq); 
assert(~any(timeDiff > 0.3));                                               % difference frequencies should be under 0.3 Hz

% average baseilne data over trials and samples 
baseMean    = mean(mean(ERSPbase.powspctrm, 4, 'omitnan'),1,'omitnan');
baseMat     = repmat(baseMean, size(ERSPdata.powspctrm,1),1,1,size(ERSPdata.powspctrm,4));

ERSPcorr                        = ERSPdata;                                 % copy data structure of the input                              
ERSPcorr.powspctrm              = ERSPdata.powspctrm ./ baseMat;

% Plot the ERSP using FieldTrip functions
cfg             = [];
cfg.colorbar    = 'yes';  % Display colorbar
cfg.xlim        = [-0.7,10];
cfg.zlim        = [0,4];
f = figure;
ft_singleplotTFR(cfg, ERSPcorr);


end