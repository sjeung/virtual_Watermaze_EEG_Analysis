
function util_WM_ERSP_spatial_map(ERSP, motion, trials, condText, Pi, fBand, chanGroupName, resultsDir, figureDir)
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
    disp([num2str(Pi) ', cond ' condText ', mobi channels selected'])
else
    xChanInd   = 11;
    yChanInd   = 13;
    cLimUpper  = 1; 
    disp([num2str(Pi) ', cond ' condText ', stat channels selected'])
end

disp([motion.label{xChanInd}, ', ' motion.label{yChanInd}])

% extract frequency inds
freqInds    = find(ERSP.freq >= fBand(1) & ERSP.freq <= fBand(2));

% create motion grid for spatial overlay
xBound      = [-4, 4];  
yBound      = [-4, 4]; 
xBinEdges   = xBound(1):0.2:xBound(2); 
yBinEdges   = yBound(1):0.2:yBound(2);
xBound2      = [-7, 7];  
yBound2      = [-7, 7]; 
xBinEdges2   = xBound2(1):0.2:xBound2(2); 
yBinEdges2   = yBound2(1):0.2:yBound2(2);

% create bins for targe/center distance plot
tBinEdges   = 0:0.2:8;                                                      % target distance can go up to twice the radius
cBinEdges   = 0:0.1:4;                                                      % center distance can go up to the radius

% initialize matrices  
ERSPMat         = nan(numel(xBinEdges)-1,numel(yBinEdges)-1);   
ERSPCell        = cell(numel(xBinEdges)-1,numel(yBinEdges)-1);              % store spatially structured ERSP data
ERSPMatTarget   = nan(numel(xBinEdges2)-1,numel(yBinEdges2)-1);   
ERSPCellTarget  = cell(numel(xBinEdges2)-1,numel(yBinEdges2)-1);            % store spatially structured ERSP data
cdMat           = nan(numel(ERSP.freq),numel(tBinEdges)-1);                   
cdCell          = cell(1,numel(tBinEdges)-1);                   
tdMat           = nan(numel(ERSP.freq),numel(cBinEdges)-1);                     
tdCell          = cell(1,numel(tBinEdges)-1);                   

% search for elements in motion data that fits
for Ti = 1:numel(motion.trial)

    xVec        = motion.trial{Ti}(xChanInd,1:end-sRate*bufferSec);         % cut off the 1 second offset buffer here
    yVec        = motion.trial{Ti}(yChanInd,1:end-sRate*bufferSec);
    xTarget     = trials(Ti).targetPos_x; 
    yTarget     = trials(Ti).targetPos_z; 
    cdVec       = sqrt(xVec.^2 + yVec.^2);                                  % center distance vector
    tdVec       = sqrt((xVec-xTarget).^2 + (yVec-yTarget).^2);              % target distance vector 

    % spatial overlay of powers
    for Xi = 1:numel(xBinEdges)-1
        xInBin  = find(xVec >= xBinEdges(Xi) & xVec < xBinEdges(Xi+1));     % indices of all samples that fall into X bin
        for Yi = 1:numel(yBinEdges)-1
            yInBin = find(yVec >= yBinEdges(Yi) & yVec < yBinEdges(Yi+1));  % indices of all samples that fall into Y bin 
            inds  = intersect(xInBin,yInBin);
            inds  = inds(inds > sRate*bufferSec);                           % cut off the 1 second onset buffer here; 
            if ~isempty(inds)
                
              % index ERSP by spatial bins
              powers = squeeze(ERSP.powspctrm(Ti,:,freqInds,inds));
              powers = squeeze(mean(powers,[1,2],'omitnan'))';              % average over electrodes and frequencies
              ERSPCell{Xi, Yi} = [ERSPCell{Xi, Yi} powers(~isnan(powers))]; % concatenate samples to normalize later
              
            end
        end
    end
    
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
for Xi = 1:numel(xBinEdges)-1
    for Yi = 1:numel(yBinEdges)-1
        if ~isempty(ERSPCell{Xi,Yi})
            ERSPMat(Xi,Yi) = median(ERSPCell{Xi,Yi});
        end
    end
end

for Xi = 1:numel(xBinEdges2)-1
    for Yi = 1:numel(yBinEdges2)-1
        if ~isempty(ERSPCellTarget{Xi,Yi})
            ERSPMatTarget(Xi,Yi) = median(ERSPCellTarget{Xi,Yi});
        end
    end
end

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

save(fullfile(spatialFileDir, ['sub-' num2str(Pi) '_' condText '_spatial_power_' num2str(fBand(1)) 'to' num2str(fBand(2)) '_Hz_' chanGroupName '.mat']), 'cdMat','tdMat', 'ERSPMat', 'ERSPMatTarget')

% visualize spatial overlay
f = figure; imagesc(flipud(ERSPMat), [0,cLimUpper]); hold on; colorbar; 

title([num2str(Pi) ', power in space, ' condText], 'Interpreter', 'none')
xticklabels = -4:1:4;
xticks = linspace(1, size(ERSPMat, 2), numel(xticklabels));
set(gca, 'XTick', xticks, 'XTickLabel', xticklabels)
set(gca, 'YTick', xticks, 'YTickLabel', xticklabels)
saveas(f,fullfile(spatialFileDir, ['sub-' num2str(Pi) '_' condText '_overlay.png']))
close(f)

% visualize spatial overlay centered at target
f = figure; imagesc(flipud(ERSPMatTarget), [0,cLimUpper]); hold on; colorbar; 

title([num2str(Pi) ', power in space, ' condText], 'Interpreter', 'none')
xticklabels = -7:1:7;
xticks = linspace(1, size(ERSPMatTarget, 2), numel(xticklabels));
set(gca, 'XTick', xticks, 'XTickLabel', xticklabels)
set(gca, 'YTick', xticks, 'YTickLabel', xticklabels)
saveas(f,fullfile(spatialFileDir, ['sub-' num2str(Pi) '_' condText '_overlay_target.png']))
close(f)

% visualize distance ERSP
f = figure; 
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

subplot(1,2,2)
imagesc(flipud(tdMat), [0,cLimUpper]); hold on; colorbar; 
title([num2str(Pi) ',Target distance, ' condText], 'Interpreter', 'none')
xticklabels = 0:8; 
xticks      = linspace(1, size(cdMat, 2), numel(xticklabels));
set(gca, 'XTick', xticks, 'XTickLabel', xticklabels)
set(gca, 'YTick', yticks, 'YTickLabel', yticklabels)
xlabel('Distance')
ylabel('Hz')

saveas(f, fullfile(spatialFileDir, ['sub-' num2str(Pi) '_' condText '_distance.png']))
close(f)

end