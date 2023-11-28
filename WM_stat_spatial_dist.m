function WM_stat_spatial_dist(trialType, channelGroup)

% trialType = 'learn' or 'probe'
%--------------------------------------------------------------------------

% aggregate and run statistics on difference
missedPatients      = []; 
missedControls      = []; 
% centerDistP         = zeros(58,40); 
% centerDistC         = zeros(58,40);
% targetDistP         = zeros(58,40); 
% targetDistC         = zeros(58,40);
centerDistP         = nan(58,40,11); 
centerDistC         = nan(58,40,22); 
targetDistP         = nan(58,40,11); 
targetDistC         = nan(58,40,22); 

pCount              = 0; 
cCount              = 0;

% load ERSP output to get frequency vector
ERSPDummy = load('P:\Sein_Jeung\Project_Watermaze\WM_EEG_Results\ERSP_pruned\sub-82002\sub-82002_learn_stat_PM_Start_ERSP_pruned.mat'); 
freqs = ERSPDummy.ERSPLS.freq; 
times = 1:40; % ERSPDummy.ERSPLS.time;

%% Iterate over patients
%--------------------------------------------------------------------------
nanCountC       = zeros(58,40);
nanCountT       = zeros(58,40);

for Pi = 81001:81011
    try
        % parse out patient numerical ID 
        nP = rem(Pi,20); 
        
        this =  load(['P:\Sein_Jeung\Project_Watermaze\WM_EEG_Results\spatial_dist\sub-' num2str(Pi) '\sub-' num2str(Pi) '_' trialType '_spatial_center_dist_' channelGroup.key '.mat']);
        centerDist      = this.cdMat; 
        that =  load(['P:\Sein_Jeung\Project_Watermaze\WM_EEG_Results\spatial_dist\sub-' num2str(Pi) '\sub-' num2str(Pi) '_' trialType '_spatial_target_dist_' channelGroup.key '.mat']);
        targetDist      = that.tdMat;
        
        centerDistP(:,:,nP) = centerDist; 
        targetDistP(:,:,nP) = targetDist; 
        
%         nanCountC(isnan(centerDist)) = nanCountC(isnan(centerDist)) + 1;  
%         centerDist(isnan(centerDist)) = 0;
%         centerDistP        = centerDistP + centerDist;
%         
%         nanCountT(isnan(targetDist)) = nanCountT(isnan(targetDist)) + 1;  
%         targetDist(isnan(targetDist)) = 0;
%         targetDistP        = targetDistP + targetDist;
        
        pCount          = pCount + 1; 
        
    catch
       missedPatients(end+1) = Pi; 
   end
end

% take median
centerDistPN = nanmedian(centerDistP, 3); 
targetDistPN = nanmedian(targetDistP, 3); 


% % Normalization by number of data points in the cell
% pCountMatC      = ones(58,40)*pCount - nanCountC; % populate a matrix with pCount and subtract nanCounts  
% centerDistPN    = centerDistP./pCountMatC; 
% 
% pCountMatT      = ones(58,40)*pCount - nanCountT; % populate a matrix with pCount and subtract nanCounts  
% targetDistPN    = targetDistP./pCountMatT; 

%% Iterate over controls
%--------------------------------------------------------------------------
nanCountC       = zeros(58,40);
nanCountT       = zeros(58,40);

for Pi = [82001:82011, 83001:83011, 84009]
    try
        
        this =  load(['P:\Sein_Jeung\Project_Watermaze\WM_EEG_Results\spatial_dist\sub-' num2str(Pi) '\sub-' num2str(Pi) '_' trialType '_spatial_center_dist_' channelGroup.key '.mat']);
        centerDist      = this.cdMat; 
        that =  load(['P:\Sein_Jeung\Project_Watermaze\WM_EEG_Results\spatial_dist\sub-' num2str(Pi) '\sub-' num2str(Pi) '_' trialType '_spatial_target_dist_' channelGroup.key '.mat']);
        targetDist      = that.tdMat;
                
        % parse out control numerical ID
        nC = rem(Pi,20);
        if Pi > 82000
            nC = nC + 11; 
        end
        
        if Pi == 84009
            nC = 9; 
        end
        
%         nanCountC(isnan(centerDist)) = nanCountC(isnan(centerDist)) + 1;
%         centerDist(isnan(centerDist)) = 0;
%         centerDistC        = centerDistC + centerDist;
%         
%         nanCountT(isnan(targetDist)) = nanCountT(isnan(targetDist)) + 1;
%         targetDist(isnan(targetDist)) = 0;
%         targetDistC        = targetDistC + targetDist;

        centerDistC(:,:,nC) = centerDist; 
        targetDistC(:,:,nC) = targetDist; 
        
        cCount          = cCount + 1;
        
    catch
       missedControls(end+1) = Pi; 
   end
end

% cCountMatC      = ones(58,40)*cCount - nanCountC; % populate a matrix with pCount and subtract nanCounts  
% centerDistCN    = centerDistC./cCountMatC; 
% 
% cCountMatT      = ones(58,40)*cCount - nanCountT; % populate a matrix with pCount and subtract nanCounts  
% targetDistCN    = targetDistC./cCountMatT; 


% take median
centerDistCN = nanmedian(centerDistC, 3); 
targetDistCN = nanmedian(targetDistC, 3); 


%% Visualize and save
%--------------------------------------------------------------------------

if contains(trialType, 'stat')
    climUpper               = 1;
else
    climUpper               = 10;
end

% visualize distance ERSP
figure; 
%yticklabels     = fliplr(round(min(ERSP.freq)):4:round(max(ERSP.freq)));     % set axis properties
%yticks          = linspace(1, size(targetDistCN, 1), numel(yticklabels));    

subplot(2,2,1)
imagesclogy(times, freqs, centerDistPN, [0,climUpper]); hold on; colorbar; 
title(['Center distance, MTLR, ' trialType], 'Interpreter', 'none')
xticklabels = 0:4; 
xticks      = linspace(1, size(centerDistPN, 2), numel(xticklabels));
set(gca, 'XTick', xticks, 'XTickLabel', xticklabels)
set(gca,'YDir','normal')
%set(gca, 'YTick', yticks, 'YTickLabel', yticklabels)
xlabel('Distance')
ylabel('Hz')

subplot(2,2,2)
imagesclogy(times, freqs, targetDistPN, [0,climUpper]); hold on; colorbar; 
title(['Target distance, MTLR, ' trialType], 'Interpreter', 'none')
xticklabels = 0:8; 
xticks      = linspace(1, size(targetDistPN, 2), numel(xticklabels));
set(gca, 'XTick', xticks, 'XTickLabel', xticklabels)
set(gca,'YDir','normal')
%set(gca, 'YTick', yticks, 'YTickLabel', yticklabels)
xlabel('Distance')
ylabel('Hz')

subplot(2,2,3)
imagesclogy(times, freqs, centerDistCN, [0,climUpper]); hold on; colorbar; 
title(['Center distance, CTRL, ' trialType], 'Interpreter', 'none')
xticklabels = 0:4; 
xticks      = linspace(1, size(centerDistCN, 2), numel(xticklabels));
set(gca, 'XTick', xticks, 'XTickLabel', xticklabels)
%set(gca, 'YTick', yticks, 'YTickLabel', yticklabels)
set(gca,'YDir','normal')
xlabel('Distance')
ylabel('Hz')

subplot(2,2,4)
imagesclogy(times, freqs, targetDistCN, [0,climUpper]); hold on; colorbar; 
title(['Target distance, CTRL, ' trialType], 'Interpreter', 'none')
xticklabels = 0:8; 
xticks      = linspace(1, size(targetDistCN, 2), numel(xticklabels));
set(gca, 'XTick', xticks, 'XTickLabel', xticklabels)
set(gca,'YDir','normal')
%set(gca, 'YTick', yticks, 'YTickLabel', yticklabels)
xlabel('Distance')
ylabel('Hz')