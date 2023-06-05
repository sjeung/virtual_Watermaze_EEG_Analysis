function [ERSPcorr] = util_WM_basecorrect(ERSPdata, ERSPbase)

basePower       = mean(ERSPbase,3, 'omitnan');                              % baseline power nChan X freqs 
ERSPcorr        = ERSPdata;                                                 % copy data structure of input

for Ti = 1:size(ERSPdata.powspctrm,1) % iterate over trials
    data                            = ERSPdata.powspctrm(Ti,:,:,:);
    baselineMat                     = repmat(basePower, [1,1,1,size(data,4)]);
    baselineMat                     = permute(baselineMat, [3,1,2,4]);
    corrData                        = data./baselineMat;
    ERSPcorr.powspctrm(Ti,:,:,:)    = corrData;
end

% Plot the ERSP using FieldTrip functions
figure;
cfg             = [];
cfg.colorbar    = 'yes';  % Display colorbar
cfg.xlim        = [-1,5];
ft_singleplotTFR(cfg, ERSPdata);


% Plot the ERSP using FieldTrip functions
figure;
cfg             = [];
cfg.channel     = {'y32'};
%cfg.baseline = [-0.7 -0.1];
%cfg.baselinetype = 'absolute';
cfg.colorbar    = 'yes';  % Display colorbar
cfg.xlim        = [-0.5,3];
cfg.zlim        = [0, 10]
ft_singleplotTFR(cfg, ERSPcorr);



ERSPcorr = ERSPdata; 

end