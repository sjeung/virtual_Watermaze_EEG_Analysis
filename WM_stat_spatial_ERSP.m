function WM_stat_spatial_ERSP(trialType, channelGroup)

% trialType = 'learn' or 'probe'
%--------------------------------------------------------------------------

pThreshold      = 0.01; 
nPermutations   = 1024; 

this = load(['P:\Sein_Jeung\Project_Watermaze\WM_EEG_Results\spatial_power\sub-81001\sub-81001_' trialType '_spatial_power.mat']);

% highly annoying to work with this variable name - update later
fn = fieldnames(this);
vn = fn{1};
ERSP = this.(vn);


% aggregate and run statistics on difference
missedPatients  = []; 
missedControls  = []; 
ERSPp           = zeros(40,40);
ERSPc           = zeros(40,40);
pCount          = 0; 
cCount          = 0;
nanCount        = zeros(40,40); % keep track of how many times each bin had nan entries for normalization later  

for Pi = 81001:81011
    try
        this =  load(['P:\Sein_Jeung\Project_Watermaze\WM_EEG_Results\spatial_power\sub-' num2str(Pi) '\sub-' num2str(Pi) '_' trialType '_spatial_power.mat']);
        fn              = fieldnames(this);
        vn              = fn{1};
        ERSP            = this.(vn);
        ERSP(isnan(ERSP))= 0;
        nanCount(isnan(ERSP)) = nanCount(isnan(ERSP)) + 1;  
        ERSPp           = ERSPp + ERSP;
        pCount          = pCount + 1; 
    catch
       missedPatients(end+1) = Pi; 
   end
end

for Pi = [82001:82011, 83001:83011, 84004]
    try
        this =  load(['P:\Sein_Jeung\Project_Watermaze\WM_EEG_Results\spatial_power\sub-' num2str(Pi) '\sub-' num2str(Pi) '_' trialType '_spatial_power.mat']);
        fn              = fieldnames(this);
        vn              = fn{1};
        ERSP            = this.(vn);
        ERSP(isnan(ERSP))= 0;
        ERSPc           = ERSPc + ERSP;
        cCount          = cCount + 1;
    catch
       missedControls(end+1) = Pi; 
   end
end
 
ERSPpn = ERSPp./pCount; 
ERSPcn = ERSPc./cCount; 


figure; imagesc(ERSPpn, [0 5])
title(['MTL ' trialType], 'Interpreter', 'none')
colorbar; 
figure; imagesc(ERSPcn, [0 5])
colorbar; 
title(['CTRL ' trialType], 'Interpreter', 'none')
% 
% pMat    = cat(3,ERSPp{:});
% cMat    = cat(3,ERSPc{1:numel(ERSPp)});
% [clusters, p_values, t_sums, permutation_distribution ] = permutest(pMat,cMat, 'true', pThreshold, nPermutations, 'true');
% 
% util_WM_plot_ERSP(ERSPp, timePoints, freqPoints, ['ERSP_MTL_' channelGroup.key], ['P:\Sein_Jeung\Project_Watermaze\WM_EEG_Results\ERSP\aggregated_ERSP_mtl_' trialType '_' channelGroup.key '_' trialSection '.png'], [])
% util_WM_plot_ERSP(ERSPc, timePoints, freqPoints, ['ERSP_CTRL_' channelGroup.key], ['P:\Sein_Jeung\Project_Watermaze\WM_EEG_Results\ERSP\aggregated_ERSP_ctrl_' trialType '_' channelGroup.key '_' trialSection '.png'], [])
% 

end