
function WM_09c_power_spatial_dist(ERSP, motion, trials, condText, Pi, chanGroupName, resultsDir, figureDir)
% plot ERSP data onto spatial map 
% compute distance to target and boundary
% 
%--------------------------------------------------------------------------

% sampling frequency 
sRate           = 250; 
bufferSec       = 1; % buffer at trial end 

% assign channel indices depending on the session
if contains(condText, 'mobi')
    xChanInd   = 4;
    yChanInd   = 6;
    cLimUpper  = 8; 
else
    xChanInd   = 11;
    yChanInd   = 13;
    cLimUpper  = 1; 
end


% remove first learning trial
assert(numel(motion.trial) == size(ERSP.powspctrm,1))

if contains(condText, 'learn')
    assert(numel(motion.trial) == 18); 
    triadsVec = 1:6; 
    trialInds = sort([triadsVec*3, triadsVec*3-1]);                         % this operation is performed in order to pick out first learn trials - beware it assumes all trials are present in data  
else
    assert(numel(motion.trial) == 24); 
    trialInds   = 1:numel(motion.trial); 
end


disp([motion.label{xChanInd}, ', ' motion.label{yChanInd}])

% create bins for targe/center distance plot
tBinEdges   = 0:0.2:8;                                                      % target distance can go up to twice the radius
cBinEdges   = 0:0.1:4;                                                      % center distance can go up to the radius

% initialize matrices  
cdMat           = nan(numel(ERSP.freq),numel(tBinEdges)-1);                   
cdCell          = cell(1,numel(tBinEdges)-1);                   
tdMat           = nan(numel(ERSP.freq),numel(cBinEdges)-1);                     
tdCell          = cell(1,numel(tBinEdges)-1);                   

% search for elements in motion data that fits
for Ti = trialInds

    xVec        = motion.trial{Ti}(xChanInd,1:end-sRate*bufferSec);         % cut off the 1 second offset buffer here
    yVec        = motion.trial{Ti}(yChanInd,1:end-sRate*bufferSec);
    xTarget     = trials(Ti).targetPos_x; 
    yTarget     = trials(Ti).targetPos_z; 
    cdVec       = sqrt(xVec.^2 + yVec.^2);                                  % center distance vector
    tdVec       = sqrt((xVec-xTarget).^2 + (yVec-yTarget).^2);              % target distance vector 

    % power ordered by distance to target
    for tdBin = 1:numel(tBinEdges)-1
        inds    = find(tdVec >= tBinEdges(tdBin) & tdVec < tBinEdges(tdBin+1));
        inds    = inds(inds > sRate*bufferSec);                             % cut off the 1 second onset buffer here;
        if ~isempty(inds)
            powers  = squeeze(ERSP.powspctrm(Ti,:,:,inds));
            powers  = squeeze(mean(powers, 1));                             % average over electrodes
            
            if numel(inds) == 1
                powers = powers';                                           % this prevents autotranspose in case only one sample is in bin
            end
            
            tdCell{tdBin} = [tdCell{:, tdBin} powers];                      % concatenate samples to normalize later
        end
    end
    
    % power ordered by distance to center
    for cdBin = 1:numel(cBinEdges)-1
        inds    = find(cdVec >= cBinEdges(cdBin) & cdVec < cBinEdges(cdBin+1));
        inds    = inds(inds > sRate*bufferSec);                             % cut off the 1 second onset buffer here;
        if ~isempty(inds)
            powers  = squeeze(ERSP.powspctrm(Ti,:,:,inds));
            powers  = squeeze(mean(powers, 1));

            if numel(inds) == 1
                powers = powers';               
            end
            
            % average over electrodes
            cdCell{cdBin} = [cdCell{:, cdBin} powers];                      % concatenate samples to normalize later
        end
    end

end

% normalization
for tdBin = 1:numel(tBinEdges)-1
    if ~isempty(tdCell{tdBin})
        tdMat(:,tdBin) = squeeze(median(tdCell{tdBin}, 2));
    end
end

for cdBin = 1:numel(cBinEdges)-1
    if ~isempty(cdCell{cdBin})
        cdMat(:,cdBin) = squeeze(median(cdCell{cdBin}, 2));
    end
end

% visualize distance ERSP
f1 = figure; 
set(gcf,'Position',[100 100 2500 500])
yticklabels     = fliplr(round(min(ERSP.freq)):4:round(max(ERSP.freq))); 
yticks          = linspace(1, size(cdMat, 1), numel(yticklabels));

subplot(1,2,1)
imagesc(flipud(cdMat), [0,cLimUpper]); hold on; colorbar; 
title([num2str(Pi) ', Center distance, ' condText], 'Interpreter', 'none')
xticklabels = 0:4; 
xticks      = linspace(1, size(cdMat, 2), numel(xticklabels));
set(gca, 'XTick', xticks, 'XTickLabel', xticklabels)
set(gca, 'YTick', yticks, 'YTickLabel', yticklabels)
xlabel('Distance')
ylabel('Hz')

f2 = figure; 
imagesc(flipud(tdMat), [0,cLimUpper]); hold on; colorbar; 
title([num2str(Pi) ',Target distance, ' condText], 'Interpreter', 'none')
xticklabels = 0:8; 
xticks      = linspace(1, size(cdMat, 2), numel(xticklabels));
set(gca, 'XTick', xticks, 'XTickLabel', xticklabels)
set(gca, 'YTick', yticks, 'YTickLabel', yticklabels)
xlabel('Distance')
ylabel('Hz')

% save data and figure, then close figure
save(fullfile(resultsDir, ['sub-' num2str(Pi) '_' condText '_spatial_center_dist_' chanGroupName '.mat']), 'cdMat')
save(fullfile(resultsDir, ['sub-' num2str(Pi) '_' condText '_spatial_target_dist_' chanGroupName '.mat']), 'tdMat')
saveas(f1,fullfile(figureDir, ['sub-' num2str(Pi) '_' condText '_spatial_center_dist_' chanGroupName '.png']))
saveas(f2,fullfile(figureDir, ['sub-' num2str(Pi) '_' condText '_spatial_target_dist_' chanGroupName '.png']))
close(f1); close(f2); 


end