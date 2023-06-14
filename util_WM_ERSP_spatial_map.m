
function util_WM_ERSP_spatial_map(ERSP, motion, trials, condText, fBand)

% assgin channel indices depending on the session
if contains(condText, 'mobi')
    xChanInd   = 4;
    yChanInd   = 6;
    disp(['Cond ' condText ', mobi channels selected'])
else
    xChanInd   = 11;
    yChanInd   = 13;
    disp(['Cond ' condText ', stat channels selected'])
end

% extract frequency inds
freqInds    = find(ERSP.freq >= fBand(1) & ERSP.freq <= fBand(2));

% create motion grid 
xBound      = [-4, 4];  
yBound      = [-4, 4]; 
xBinEdges   = xBound(1):0.2:xBound(2); 
yBinEdges   = yBound(1):0.2:yBound(2);

% initialize matrices  
ERSPCell        = cell(numel(xBinEdges)-1,numel(yBinEdges)-1);             % store spatially structured ERSP data
centerDistMat   = nan(numel(ERSP.freq),numel(tBinEdges)-1);                   
targetDistMat   = nan(numel(ERSP.freq),numel(cBinEdges)-1);                     

% search for elements in motion data that fits
for Ti = 1:numel(motion.trial)

    xVec        = motion.trial{Ti}(xChanInd,1:end-sRate*bufferSec);         % cut off the 1 second offset buffer here
    yVec        = motion.trial{Ti}(yChanInd,1:end-sRate*bufferSec);
    xTarget     = trials(Ti).targetPos_x; 
    yTarget     = trials(Ti).targetPos_z; 
    cdVec       = sqrt(xVec.^2 + yVec.^2);                                  % center distance vector
    tdVec       = sqrt((xVec-xTarget).^2 + (yVec-yTarget).^2);              % target distance vector 

    for Xi = 1:numel(xBinEdges)-1
        xInBin  = find(xVec >= xBinEdges(Xi) & xVec < xBinEdges(Xi+1));     % indices of all samples that fall into X bin
        for Yi = 1:numel(yBinEdges)-1
            yInBin = find(yVec >= yBinEdges(Yi) & yVec < yBinEdges(Yi+1));  % indices of all samples that fall into Y bin 
            inds  = intersect(xInBin,yInBin);
            inds  = inds(inds > sRate*bufferSec);                           % cut off the 1 second onset buffer here; 
            if ~isempty(inds)
                
              % index ERSP by spatial bins
              powers = squeeze(ERSP.powspctrm(Ti,:,freqInds,inds));
              ERSPCell{Xi, Yi} = [ERSPCell{Xi, Yi} powers(~isnan(powers))];
              
            end
        end
    end
end

% normalization
for Xi = 1:numel(xBinEdges)-1
    for Yi = 1:numel(yBinEdges)-1
        ERSPCell{Xi, Yi} = mean(ERSPCell);
    end
end


% save output 
centerDistERSP      = [];
targetDistERSP      = [];

% visualize the outcome 
f = figure; imagesc(ERSPMat, [0,4]); hold on; colorbar; 
title(['ERSP in space, ' condText], 'Interpreter', 'none')
saveas(f,'png')
close(f)


end