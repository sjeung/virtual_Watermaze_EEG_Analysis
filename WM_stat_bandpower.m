function [stat] = WM_stat_bandpower(trialType, chanGroup, doPlot)
WM_config; 
% trialType = 'learn' or 'probe'
%--------------------------------------------------------------------------
trialSection    = 'start';
chanInds        = chanGroup.chan_inds; 

% aggregate and run statistics on difference
mobiP           = [];
deskP           = [];
mobiPTopo       = [];
deskPTopo       = [];

for Pi = 81001:81011
    try
        load(['P:\Sein_Jeung\Project_Watermaze\WM_EEG_Results\bandpower\sub-' num2str(Pi) '\sub-' num2str(Pi) '_band.mat']);
        mobiPower        = mean(eval(['band_' trialType '_' trialSection '_mobi(chanInds)']));
        desktopPower     = mean(eval(['band_' trialType '_' trialSection '_desktop(chanInds)']));
        mobiP(end+1)     = mobiPower; 
        deskP(end+1)     = desktopPower;
        if isempty(mobiPTopo) && isempty(deskPTopo)
            mobiPTopo = eval(['band_' trialType '_' trialSection '_mobi']);
            deskPTopo = eval(['band_' trialType '_' trialSection '_desktop']);
            matCount = 1; 
        else
            mobiPTopo = mobiPTopo + eval(['band_' trialType '_' trialSection '_mobi']);
            deskPTopo = deskPTopo + eval(['band_' trialType '_' trialSection '_desktop']); 
            matCount = matcount + 1; 
        end
    catch
   end
end

if doPlot
    mobiPTopoMean = mobiPTopo./matCount;
    deskPTopoMean = deskPTopo./matCount;
    
    EEG        = pop_loadset('P:\Sein_Jeung\Project_Watermaze\WM_EEG_Data\7_epoched\sub-81001\sub-81001_epoched.set');
    
    bandFileDir     = 'P:\Sein_Jeung\Project_Watermaze\WM_EEG_Results\bandpower';
    util_WM_plot_topo(mobiPTopoMean, EEG.chanlocs, ['MTL_topo_MOBI_', trialType],fullfile(bandFileDir, ['\' trialType, '_MTL_topo_mobi.png']))
    util_WM_plot_topo(deskPTopoMean, EEG.chanlocs, ['MTL_topo_STAT_', trialType],fullfile(bandFileDir, ['\' trialType, '_MTL_topo_stat.png']))
end

mobiC           = [];
deskC           = [];
mobiCTopo       = [];
deskCTopo       = [];

for Pi = [82001:82011, 83001:83011, 84009]
    try
        load(['P:\Sein_Jeung\Project_Watermaze\WM_EEG_Results\bandpower\sub-' num2str(Pi) '\sub-' num2str(Pi) '_band.mat']);
        mobiPower        = mean(eval(['band_' trialType '_' trialSection '_mobi(chanInds)']));
        desktopPower     = mean(eval(['band_' trialType '_' trialSection '_desktop(chanInds)']));
        mobiC(end+1)     = mobiPower; 
        deskC(end+1)     = desktopPower; 

        if isempty(mobiCTopo) && isempty(deskCTopo)
            mobiCTopo = eval(['band_' trialType '_' trialSection '_mobi']);
            deskCTopo = eval(['band_' trialType '_' trialSection '_desktop']);
            matCount = 1; 
        else
            mobiCTopo = mobiCTopo + eval(['band_' trialType '_' trialSection '_mobi']);
            deskCTopo = deskCTopo + eval(['band_' trialType '_' trialSection '_desktop']); 
            matCount = matcount + 1; 
        end
    catch
   end
end

if doPlot
    mobiCTopoMean = mobiCTopo./matCount;
    deskCTopoMean = deskCTopo./matCount;
    
    bandFileDir     = 'P:\Sein_Jeung\Project_Watermaze\WM_EEG_Results\bandpower';
    util_WM_plot_topo(mobiCTopoMean, EEG.chanlocs, ['CTRL_topo_MOBI_', trialType],fullfile(bandFileDir, ['\' trialType, '_CTRL_topo_mobi.png']))
    util_WM_plot_topo(deskCTopoMean, EEG.chanlocs, ['CTRL_topo_STAT_', trialType],fullfile(bandFileDir, ['\' trialType, '_CTRL_topo_stat.png']))
end

% concatenate data for anova
dataMat = NaN(max(size(mobiC)),4);
dataMat(1:10,1) = mobiP; 
dataMat(1:10,2) = deskP; 
dataMat(:,3) = mobiC; 
dataMat(:,4) = deskC; 
util_WM_anova(dataMat, trialType, chanGroup.full_name)

end