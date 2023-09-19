
function  WM_09b_power_spatial_overlay_target(ERSP, motion, trials, condText, Pi, fBand, chanGroupName, resultsDir, figureDir)
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

% extract frequency inds
freqInds    = find(ERSP.freq >= fBand(1) & ERSP.freq <= fBand(2));

% create motion grid for spatial overlay
xBound2      = [-7, 7];  
yBound2      = [-7, 7]; 
xBinEdges2   = xBound2(1):0.2:xBound2(2); 
yBinEdges2   = yBound2(1):0.2:yBound2(2);

% initialize matrices  
ERSPMatTarget   = nan(numel(xBinEdges2)-1,numel(yBinEdges2)-1);   
ERSPCellTarget  = cell(numel(xBinEdges2)-1,numel(yBinEdges2)-1);            % store spatially structured ERSP data

% search for elements in motion data that fits
for Ti = trialInds

    xVec        = motion.trial{Ti}(xChanInd,1:end-sRate*bufferSec);         % cut off the 1 second offset buffer here
    yVec        = motion.trial{Ti}(yChanInd,1:end-sRate*bufferSec);
    xTarget     = trials(Ti).targetPos_x; 
    yTarget     = trials(Ti).targetPos_z; 
   
    % spatial overlay of powers, centred at target location
    xVecTarg = xVec - xTarget; 
    yVecTarg = yVec - yTarget; 
    
    for Xi = 1:numel(xBinEdges2)-1
        xInBin  = find(xVecTarg >= xBinEdges2(Xi) & xVecTarg < xBinEdges2(Xi+1));     % indices of all samples that fall into X bin
        for Yi = 1:numel(yBinEdges2)-1
            yInBin = find(yVecTarg >= yBinEdges2(Yi) & yVecTarg < yBinEdges2(Yi+1));  % indices of all samples that fall into Y bin
            inds  = intersect(xInBin,yInBin);
            inds  = inds(inds > sRate*bufferSec);                           % cut off the 1 second onset buffer here;
            if ~isempty(inds)
                
                % index ERSP by spatial bins
                powers = squeeze(ERSP.powspctrm(Ti,:,freqInds,inds));
                powers = squeeze(mean(powers,[1,2],'omitnan'))';              % average over electrodes and frequencies
                ERSPCellTarget{Xi, Yi} = [ERSPCellTarget{Xi, Yi} powers(~isnan(powers))]; % concatenate samples to normalize later
                
            end
        end
    end
end

% normalization
for Xi = 1:numel(xBinEdges2)-1
    for Yi = 1:numel(yBinEdges2)-1
        if ~isempty(ERSPCellTarget{Xi,Yi})
            ERSPMatTarget(Xi,Yi) = median(ERSPCellTarget{Xi,Yi});
        end
    end
end

% visualize spatial overlay centered at target
f = figure; imagesc(flipud(ERSPMatTarget), [0,cLimUpper]); hold on; colorbar; 

title([num2str(Pi) ', power in space, ' condText], 'Interpreter', 'none')
xticklabels = -7:1:7;
xticks = linspace(1, size(ERSPMatTarget, 2), numel(xticklabels));
set(gca, 'XTick', xticks, 'XTickLabel', xticklabels)
set(gca, 'YTick', xticks, 'YTickLabel', xticklabels)

% save data and figure, then close figure
save(fullfile(resultsDir, ['sub-' num2str(Pi) '_' condText '_spatial_power_target_' num2str(fBand(1)) 'to' num2str(fBand(2)) '_Hz_' chanGroupName '.mat']), 'ERSPMatTarget')
saveas(f,fullfile(figureDir, ['sub-' num2str(Pi) '_' condText '_spatial_power_target_' num2str(fBand(1)) 'to' num2str(fBand(2)) '_Hz_' chanGroupName '.png']))
close(f)


end