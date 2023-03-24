function [pMTL, pCTRL, statStruct] = WM_stat_ERSP(trialType, trialSection, channelGroup)

% trialType = 'learn' or 'probe'
%--------------------------------------------------------------------------

pThreshold      = 0.01; 
nPermutations   = 1024; 

statStruct = [];
loadedVar   =  load(['P:\Sein_Jeung\Project_Watermaze\WM_EEG_Results\ERSP\sub-81001\sub-81001_ERSP_' channelGroup.key '.mat'], 'times', 'freqs');
timePoints = loadedVar.times; 
freqPoints = loadedVar.freqs;

% aggregate and run statistics on difference
missedPatients  = [];
diffPatients    = {}; 
mobiP           = {};
deskP           = {};

for Pi = 81001:81011
    try
        load(['P:\Sein_Jeung\Project_Watermaze\WM_EEG_Results\ERSP\sub-' num2str(Pi) '\sub-' num2str(Pi) '_ERSP_' channelGroup.key '.mat']);
        mobiERSP        = mean(cat(3,eval(['ERSP_' trialType '_' trialSection '_mobi{:}'])),3);
        desktopERSP     = mean(cat(3,eval(['ERSP_' trialType '_' trialSection '_desktop{:}'])),3);
        diffPatients{end+1} = mobiERSP - desktopERSP;
        mobiP{end+1}    = mobiERSP; 
        deskP{end+1}    = desktopERSP; 
    catch
       missedPatients(end+1) = Pi; 
   end
end

mobiPMat    = cat(3,mobiP{:});
deskPMat    = cat(3,deskP{:});
[clusters, p_values, t_sums, permutation_distribution ] = permutest(mobiPMat,deskPMat, 'true', pThreshold, nPermutations, 'true');
util_WM_plot_ERSP(diffPatients, timePoints, freqPoints, ['ERSP_MTL_' channelGroup.key], ['P:\Sein_Jeung\Project_Watermaze\WM_EEG_Results\ERSP\aggregated_ERSP_mtl_' trialType '_' channelGroup.key '.png'], clusters)

pMTL = p_values(p_values < 0.05);
statStruct.mtl.clusters = clusters; 
statStruct.mtl.p_values = p_values; 
statStruct.mtl.t_sums = t_sums; 
statStruct.mtl.permutation_distribution = permutation_distribution; 

missedControls  = [];
diffControls    = {};
mobiC           = {};
deskC           = {};
for Pi = [82001:82011, 83001:83011, 84009]
    try
        load(['P:\Sein_Jeung\Project_Watermaze\WM_EEG_Results\ERSP\sub-' num2str(Pi) '\sub-' num2str(Pi) '_ERSP_' channelGroup.key '.mat']);
        mobiERSP        = mean(cat(3,eval(['ERSP_' trialType '_' trialSection '_mobi{:}'])),3);
        desktopERSP     = mean(cat(3,eval(['ERSP_' trialType '_' trialSection '_desktop{:}'])),3);
        diffControls{end+1} = mobiERSP - desktopERSP;
        mobiC{end+1}    = mobiERSP; 
        deskC{end+1}    = desktopERSP; 
    catch
        missedControls(end+1) = Pi;
    end
end
mobiCMat    = cat(3,mobiC{:});
deskCMat    = cat(3,deskC{:});
[clusters, p_values, t_sums, permutation_distribution ] = permutest(mobiCMat,deskCMat, 'true', pThreshold, nPermutations, 'true');
util_WM_plot_ERSP(diffControls, timePoints, freqPoints, ['ERSP_Controls_' channelGroup.key], ['P:\Sein_Jeung\Project_Watermaze\WM_EEG_Results\ERSP\aggregated_ERSP_control_' trialType '_' channelGroup.key '.png'], clusters)
pCTRL = p_values(p_values < 0.05);
statStruct.ctrl.clusters = clusters; 
statStruct.ctrl.p_values = p_values; 
statStruct.ctrl.t_sums = t_sums; 
statStruct.ctrl.permutation_distribution = permutation_distribution;

% for Pi = 1:numel(missedPatients)
%    %warning(['Data from ' num2str(missedPatients(Pi)) ' could not be processed'])
% end
% 
% for Ci = 1:numel(missedControls)
%    %warning(['Data from ' num2str(missedControls(Ci)) ' could not be processed'])
% end


end