function [trialInfo] = util_WM_tInfo(cond, trialFileName)

% match ERSP data with trial information 
allInfo = load(trialFileName);

switch cond
    
    case 'learn_stat'
        trialInfo   = allInfo.TrialLearnS; 
    case 'learn_mobi'
        trialInfo   = allInfo.TrialLearnM; 
    case 'probe_stat'
        trialInfo   = allInfo.TrialProbeS; 
    case 'probe_mobi'
        trialInfo   = allInfo.TrialProbeM; 
end

end