function [ERSPStart, ERSPEnd] = util_WM_cut_windows(ERSP, winWidth, Pi, condText)
%
% inputs 
% ERSP : ERSP struct
%           ERSP{n}.times : vector of time in miliseconds
% winWidth : time window in seconds

% Parameters
%--------------------------------------------------------------------------
WM_config;
sRate                   = 250;
[erspFileName,erspFileDir] = assemble_file(config_folder.results_folder, config_folder.ersp_folder, ['_' condText], Pi);

if ~isfolder(fullfile(erspFileDir, 'trial_ERSPs'))
    mkdir(fullfile(erspFileDir, 'trial_ERSPs'))
end

% copy structs
ERSPStart       = ERSP; 
ERSPEnd         = ERSP; 
sizeVec                 = size(ERSP.powspctrm);
numSamples              = sRate*winWidth; 

% onset window 
%--------------------------------------------------------------------------
onsetStartIndex         = find(~isnan(squeeze(ERSP.powspctrm(1,1,1,:))), 1, 'first'); 
ERSPStart.powspctrm     = ERSP.powspctrm(:,:,:,onsetStartIndex:onsetStartIndex + numSamples -1);
ERSPStart.time          = ERSP.time(onsetStartIndex:onsetStartIndex + numSamples -1);

% offset window
%--------------------------------------------------------------------------
tLengths                = [];
ERSPEnd.powspctrm       = NaN(sizeVec(1), sizeVec(2), sizeVec(3) ,numSamples);

for Ti = 1:size(ERSP.powspctrm, 1)
    dataRow                         = ERSP.powspctrm(Ti,1,1,:);
    dataRow                         = squeeze(dataRow);
    tLengths(end+1)                 = find(~isnan(dataRow),1,'last');
    offsetEndIndex                  = tLengths(end);
    ERSPEnd.powspctrm(Ti,:,:,:)     = ERSP.powspctrm(Ti,:,:,offsetEndIndex-numSamples+1:offsetEndIndex);
end
ERSPEnd.time            = ERSP.time(offsetEndIndex-numSamples+1:offsetEndIndex)- ERSP.time(offsetEndIndex) +1; 

% save data
%--------------------------------------------------------------------------
save(fullfile(erspFileDir, [erspFileName, '_Start_ERSP.mat']), 'ERSPStart'); 
save(fullfile(erspFileDir, [erspFileName, '_End_ERSP.mat']), 'ERSPEnd'); 

% visualize
%--------------------------------------------------------------------------
cfg             = []; 
cfg.colorbar    = 'yes';  % Display colorbar
cfg.zlim        = [0,4];
cfg.figure      = 'gcf';

% for Ti = 1:size(ERSP.powspctrm, 1)
%     f = figure;
%     cfg.trials = Ti; 
% 
%     subplot(1,2,1)
%     ft_singleplotTFR(cfg, ERSPStart); 
%     title('first 5 sec', 'FontSize', 15)
% 
%     subplot(1,2,2)
%     ft_singleplotTFR(cfg, ERSPEnd);
%     title('last 5 sec', 'FontSize', 15)
%     set(gcf,'Position',[100 100 2500 500])
%     
%     saveas(f, fullfile(erspFileDir, 'trial_ERSPs', ['sub-' num2str(Pi) '_' condText '_trial-' num2str(Ti) '_ERSP.png']))
%     close(f);
% end

f = figure; 
cfg.trials      = 'all';

subplot(1,2,1)
ft_singleplotTFR(cfg, ERSPStart);
title('first 5 sec', 'FontSize', 15)

subplot(1,2,2)
ft_singleplotTFR(cfg, ERSPEnd);
title('last 5 sec', 'FontSize', 15)
set(gcf,'Position',[100 100 2500 500])

saveas(f, fullfile(erspFileDir, ['sub-' num2str(Pi) '_' condText '_ERSP.png']))
close(f);

end