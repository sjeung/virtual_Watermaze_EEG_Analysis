function WM_stat_spatial_overlay_target(trialType, channelGroup, fBandText)

% trialType = 'learn' or 'probe'
%--------------------------------------------------------------------------


this = load(['P:\Sein_Jeung\Project_Watermaze\WM_EEG_Results\spatial_overlay\sub-81001\sub-81001_' trialType '_spatial_power_' fBandText '_' channelGroup.key '.mat']);

% aggregate and run statistics on difference
missedPatients  = []; 
missedControls  = []; 
overlayP            = nan(70,70,11);
overlayC            = nan(70,70,22);

pCount          = 0; 
cCount          = 0;


%% Iterate over patients
%--------------------------------------------------------------------------
nanCount        = zeros(70,70); % keep track of how many times each bin had nan entries for normalization later  

for Pi = 81001:81011
    try
        this =  load(['P:\Sein_Jeung\Project_Watermaze\WM_EEG_Results\spatial_overlay_target\sub-' num2str(Pi) '\sub-' num2str(Pi) '_' trialType '_spatial_power_target_' fBandText '_' channelGroup.key '.mat']);
        ERSP            = this.ERSPMatTarget;
        
        % parse out patient numerical ID
        nP = rem(Pi,20);
        
        overlayP(:,:,nP)    = ERSP; 

        pCount          = pCount + 1; 
        
    catch
       missedPatients(end+1) = Pi; 
   end
end


ERSPpn          = nanmedian(overlayP,3); 

%% Iterate over controls
%--------------------------------------------------------------------------
nanCount        = zeros(40,40); 

for Pi = [82001:82011, 83001:83011, 84009]
    try
        this =  load(['P:\Sein_Jeung\Project_Watermaze\WM_EEG_Results\spatial_overlay_target\sub-' num2str(Pi) '\sub-' num2str(Pi) '_' trialType '_spatial_power_target_' fBandText '_' channelGroup.key '.mat']);
        ERSP            = this.ERSPMatTarget;
        
        % parse out control numerical ID
        nC = rem(Pi,20);
        if Pi > 82000
            nC = nC + 11;
        end
        
        if Pi == 84009
            nC = 9;
        end
        
        overlayC(:,:,nC) = ERSP; 
        
        cCount          = cCount + 1;
        
    catch
       missedControls(end+1) = Pi; 
   end
end
 
ERSPcn  = nanmedian(overlayC, 3); 

%% Visualize and save
%--------------------------------------------------------------------------

if contains(trialType, 'stat')
    climUpper               = 1;
else
    climUpper               = 8;
end

figure; subplot(1,2,1); 
imagesc(ERSPpn, [0 climUpper])
title(['MTL ' trialType, ', ' channelGroup.key ', ' fBandText], 'Interpreter', 'none')
colorbar; 
subplot(1,2,2); imagesc(ERSPcn, [0 climUpper])
colorbar; 
title(['CTRL ' trialType, ', ' channelGroup.key ', ' fBandText], 'Interpreter', 'none')


end