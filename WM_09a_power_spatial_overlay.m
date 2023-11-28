
function WM_09a_power_spatial_overlay(ERSP, motion, trials, condText, Pi, fBand, chanGroupName, resultsDir, figureDir)
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

% temporary : add these variables to the trial file instead
tempWM      = load('P:\Sein_Jeung\Project_Watermaze\WM_EEG_Results\WP8_WM_table.mat'); 

if contains(condText, 'stat')
    setupInd = 1; 
else
    setupInd = 2; 
end 
charID      = num2str(Pi-80000); 
groupInd    = str2double(charID(1)); 
numInd      = str2double(charID(end-1:end)); 

blocks = tempWM.wm.setup{setupInd}.group{groupInd}.sub{numInd}.blocks;
if contains(condText, 'probe')
    ogAngles    = []; 
    responses   = nan(2,24); 
    for Bi = 1:numel(blocks)
        PBi                 = blocks{Bi}.presented_order; 
        responses(:,(PBi-1)*4 + 1:(PBi-1)*4 + 4)  	= blocks{Bi}.guess.responses;  
    end
end

%--------------------------------------------------------------------------

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

disp(['Spatial overlay for ' num2str(Pi) ',' motion.label{xChanInd}, ', ' motion.label{yChanInd} ', ' condText])

% extract frequency inds
freqInds    = find(ERSP.freq >= fBand(1) & ERSP.freq <= fBand(2));

% create motion grid for spatial overlay
xBound      = [-4, 4];  
yBound      = [-4, 4]; 
xBinEdges   = xBound(1):0.2:xBound(2); 
yBinEdges   = yBound(1):0.2:yBound(2);


% initialize matrices  
ERSPMat         = nan(numel(xBinEdges)-1,numel(yBinEdges)-1);   
ERSPCell        = cell(numel(xBinEdges)-1,numel(yBinEdges)-1);              % store spatially structured ERSP data
               

% search for elements in motion data that fits
for Ti = trialInds
    
    xVec        = motion.trial{Ti}(xChanInd,1:end); %-sRate*bufferSec);     % cut off the 1 second offset buffer here
    yVec        = motion.trial{Ti}(yChanInd,1:end); %-sRate*bufferSec);
    
    %......................................................................
    % temporary - rotate the data points
    xVec        = xVec*cos(deg2rad(trials(Ti).rotations)) - yVec*sin(deg2rad(trials(Ti).rotations));         % cut off the 1 second offset buffer here
    yVec        = yVec*cos(deg2rad(trials(Ti).rotations)) + xVec*sin(deg2rad(trials(Ti).rotations));
    %......................................................................
    
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
    
end

% normalization
for Xi = 1:numel(xBinEdges)-1
    for Yi = 1:numel(yBinEdges)-1
        if ~isempty(ERSPCell{Xi,Yi})
            ERSPMat(Xi,Yi) = median(ERSPCell{Xi,Yi});
        end
    end
end

% visualize spatial overlay
f = figure; imagesc(flipud(ERSPMat), [0,cLimUpper]); hold on; colorbar; 

title([num2str(Pi) ', power in space, ' condText], 'Interpreter', 'none')
xticklabels = -4:1:4;
xticks = linspace(1, size(ERSPMat, 2), numel(xticklabels));
set(gca, 'XTick', xticks, 'XTickLabel', xticklabels)
set(gca, 'YTick', xticks, 'YTickLabel', xticklabels)


% save data and figure, then close figure
save(fullfile(resultsDir, ['sub-' num2str(Pi) '_' condText '_spatial_power_' num2str(fBand(1)) 'to' num2str(fBand(2)) '_Hz_' chanGroupName '.mat']), 'ERSPMat')
saveas(f,fullfile(figureDir, ['sub-' num2str(Pi) '_' condText '_spatial_power_' num2str(fBand(1)) 'to' num2str(fBand(2)) '_Hz_' chanGroupName '.png']))
close(f)


end