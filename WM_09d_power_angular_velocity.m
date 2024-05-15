
function WM_09c_power_spatial_dist(ERSP, motion, trials, condText, Pi, chanGroupName, resultsDir, figureDir)
% plot ERSP data onto spatial map 
% compute distance to target and boundary
% 
%--------------------------------------------------------------------------

% sampling frequency 
sRate           = 250; 
bufferSec       = 1; % buffer at trial end 


% load baseline spectra 
baseline = load('P:\Sein_Jeung\Project_Watermaze\WM_EEG_Results\baseline_spectra\FM_walk_mobi_baseline.mat');

% assign channel indices depending on the session
if contains(condText, 'mobi')
    yawInd     = 1; 
    xChanInd   = 4;
    yChanInd   = 6;
    cLimUpper  = 15; 
    maxAngVel   = 1.5; 
    baselinePower = baseline.pSpectra{2}(1,:); 

else
    yawInd     = 8; 
    xChanInd   = 11;
    yChanInd   = 13;
    cLimUpper  = 8; 
    maxAngVel   = 1; 
    baselinePower = baseline.pSpectra{1}(1,:); 
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

disp(['Angular velocity analysis for ' num2str(Pi) ',' motion.label{xChanInd}, ', ' motion.label{yChanInd} ', ' condText])

% create bins for plot
avBinEdges   = 0:0.1:maxAngVel;                                                   % target distance can go up to twice the radius

% initialize matrices                  
avMat           = nan(numel(ERSP.freq),numel(avBinEdges)-1);                     
avCell          = cell(1,numel(avBinEdges)-1);                   

% search for elements in motion data that fits
for Ti = trialInds

    yawVec          = unwrap(motion.trial{Ti}(yawInd,1:end-sRate*bufferSec));     % cut off the 1 second offset buffer here
    
    % Calculate angular velocity using numerical differentiation
    dt = 1 / 250;
    angularVelocity = abs(diff(yawVec) / dt);
    desiredSmoothingTime = 1; % in seconds
    windowSize = round(250 * desiredSmoothingTime);
    
    % Apply moving average filter for smoothing
    smoothedAngularVelocity = movmean(angularVelocity, windowSize);
    avVec   = smoothedAngularVelocity; 
    
    % Plot the results
    time = (0:length(yawVec)-2) * dt; % Adjust the time vector for angular velocity
    
%     figure;
%     subplot(2,1,1);
%     plot(time, angularVelocity);
%     title('Angular Velocity (Numerical Differentiation)');
%     xlabel('Time (seconds)');
%     ylabel('Angular Velocity');
%     
%     subplot(2,1,2);
%     plot(time, smoothedAngularVelocity);
%     title('Smoothed Angular Velocity');
%     xlabel('Time (seconds)');
%     ylabel('Smoothed Angular Velocity');

    % power ordered by angular velocity 
    for avBin = 1:numel(avBinEdges)-1
        inds    = find(avVec >= avBinEdges(avBin) & avVec < avBinEdges(avBin+1));
        inds    = inds(inds > sRate*bufferSec);                             % cut off the 1 second onset buffer here;
       
        if ~isempty(inds)
            powers  = squeeze(ERSP.powspctrm(Ti,:,:,inds));
            powers  = squeeze(mean(powers, 1));                             % average over electrodes
            
            if numel(inds) == 1
                powers = powers';                                           % this prevents autotranspose in case only one sample is in bin
            end
            
            avCell{avBin} = [avCell{:, avBin} powers];                      % concatenate samples to normalize later
        end
    end
    
end

% normalization & baseline correction
for avBin = 1:numel(avBinEdges)-1
    if ~isempty(avCell{avBin})
        avMat(:,avBin) = squeeze(median(avCell{avBin}, 2));
    end
end
this = avMat./baselinePower'; 
avMat  = this; 

% visualize distance ERSP
f1 = figure; 
yticklabels     = fliplr(round(min(ERSP.freq)):4:round(max(ERSP.freq))); 
yticks          = linspace(1, size(avMat, 1), numel(yticklabels));

imagesc(flipud(avMat), [0,cLimUpper]); hold on; colorbar; 
xticklabels = 0:0.5:1.5; 
xticks      = linspace(1, size(avMat, 2), numel(xticklabels));
set(gca, 'XTick', xticks, 'XTickLabel', xticklabels)
set(gca, 'YTick', yticks, 'YTickLabel', yticklabels)
xlabel('Angular velocity')
ylabel('Hz')

title([num2str(Pi) ', by idPhi, ' condText], 'Interpreter', 'none')

% save data and figure, then close figure
save(fullfile(resultsDir, ['sub-' num2str(Pi) '_' condText '_angvel_' chanGroupName '.mat']), 'avMat')
saveas(f1,fullfile(figureDir, ['sub-' num2str(Pi) '_' condText '_angvel_' chanGroupName '.png']))
%close(f1);


end