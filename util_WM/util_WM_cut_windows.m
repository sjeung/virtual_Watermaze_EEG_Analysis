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
ERSPMid         = ERSP; 
sizeVec                 = size(ERSP.powspctrm);
numSamples              = sRate*winWidth; 

% onset window 
%--------------------------------------------------------------------------
onsetStartIndex         = find(-1 < ERSP.time, 1, 'first'); 
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

% middle section 
%--------------------------------------------------------------------------
ERSPMid.powspctrm       = NaN(sizeVec(1), sizeVec(2), sizeVec(3) ,numSamples);

for Ti = 1:size(ERSP.powspctrm, 1)
    
    % find out how many epochs can be generated 
    nWinds = round((tLengths(Ti)/250 - 2*winWidth)/winWidth); 
    
    % a trial can have multiple windows
    if nWinds ==  0 % if a trial is too short, just use the center window even if it spans a bit on start and end time windows
        ERSPMid.powspctrm(Ti,:,:,:)     = ERSP.powspctrm(Ti,:,:,round((tLengths(Ti)- numSamples)/2):round((tLengths(Ti) - numSamples)/2) + numSamples - 1);
    else 
        ERSPsInTrial = NaN([nWinds,size(ERSP.powspctrm,2),size(ERSP.powspctrm,3),numSamples]);
        for Wi = 1:nWinds
            winStartInd = round((tLengths(Ti) - numSamples*nWinds)/2) + numSamples*(Wi-1);
            winEndInd   = round((tLengths(Ti) - numSamples*nWinds)/2) + numSamples*Wi-1; 
            ERSPsInTrial(Wi,:,:,:) = ERSP.powspctrm(Ti,:,:,winStartInd:winEndInd);
        end
        ERSPMid.powspctrm(Ti,:,:,:)     = mean(ERSPsInTrial,1, 'omitnan');
    end
    
end
ERSPMid.time            = linspace(0,winWidth, numSamples);


% save data
%--------------------------------------------------------------------------
save(fullfile(erspFileDir, [erspFileName, '_Start_ERSP.mat']), 'ERSPStart'); 
save(fullfile(erspFileDir, [erspFileName, '_End_ERSP.mat']), 'ERSPEnd'); 
save(fullfile(erspFileDir, [erspFileName, '_Mid_ERSP.mat']), 'ERSPMid'); 

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
title('Onset', 'FontSize', 15)

subplot(1,2,2)
ft_singleplotTFR(cfg, ERSPEnd);
title('Offset', 'FontSize', 15)
set(gcf,'Position',[100 100 2500 500])

saveas(f, fullfile(erspFileDir, ['sub-' num2str(Pi) '_' condText '_ERSP.png']))
close(f);


f = figure; 
cfg.trials      = 'all';
ft_singleplotTFR(cfg, ERSPMid);
title('Mid Trial', 'FontSize', 15)
saveas(f, fullfile(erspFileDir, ['sub-' num2str(Pi) '_' condText '_ERSP_Mid.png']))
close(f);


end