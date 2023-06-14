
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
ERSPMat         = zeros(numel(xBinEdges)-1,numel(yBinEdges)-1);             % store spatially structured ERSP data
centerDistMat   = ERSPMat;                                                  % store indices           
targetDistMat   = ERSPMat;                                                  % store indices 

% search for elements in motion data that fits
for Ti = 1:numel(motion.trial)
    xVec    = motion.trial{Ti}(xChanInd,:);
    yVec    = motion.trial{Ti}(yChanInd,:);
    for Xi = 1:numel(xBinEdges)-1
        xInBin  = find(xVec >= xBinEdges(Xi) & xVec < xBinEdges(Xi+1));     % indices of all samples that fall into X bin
        for Yi = 1:numel(yBinEdges)-1
            yInBin = find(yVec >= yBinEdges(Yi) & yVec < yBinEdges(Yi+1));  % indices of all samples that fall into Y bin 
            inds  = intersect(xInBin,yInBin);
            if ~isempty(inds)
              % index ERSP by spatial bins
              this = squeeze(ERSP.powspctrm(Ti,:,freqInds,inds));
              ERSPMat(Xi, Yi) = mean([ERSPMat(Xi, Yi), squeeze(mean(this, 'all', 'omitnan'))], 'omitnan');
            end
        end
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