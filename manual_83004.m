% for 83004, first four blocks are VR and last 6 blocks are desktop
EEG         = pop_loadset('P:\Sein_Jeung\Project_Watermaze\WM_EEG_Data\6_cleaned\sub-83004\sub-83004_cleaned.set'); 
events      = EEG.event; 
blockMarkers = find(contains({EEG.event(:).type}, 'origin_angle') & ~contains({EEG.event(:).type}, 'index:99'));  

% display this line to see markers
EEG.event(blockMarkers).type; 

% the markers are base 0 indexed in the markers 
conditionsMOBI = [3, 1, 0, 2] + 1; 
conditionsSTAT = [4, 2, 3, 5, 1, 0] + 1; 
otherTrials = load('P:\Sein_Jeung\Project_Watermaze\WM_EEG_Results\BEH_output\sub-81001_beh_trials.mat'); 

TrialLearnM = []; 
TrialProbeM = []; 
TrialLearnS = [];
TrialProbeS = [];

% match trials and target pos
for MBi = 1:4
    trialsInBlockL      = find([otherTrials.TrialLearnM(:).conditionNo] == conditionsMOBI(MBi),1,'first');
    trialsInBlockP      = find([otherTrials.TrialProbeM(:).conditionNo] == conditionsMOBI(MBi),1,'first');
    for Li = 1:3
        TrialLearnM(end+1).targetPos_x = otherTrials.TrialLearnM(trialsInBlockL).targetPos_x;
        TrialLearnM(end).targetPos_z = otherTrials.TrialLearnM(trialsInBlockL).targetPos_z;
    end
    for Pi = 1:4
        TrialProbeM(end+1).targetPos_x = otherTrials.TrialProbeM(trialsInBlockP).targetPos_x;
        TrialProbeM(end).targetPos_z = otherTrials.TrialProbeM(trialsInBlockP).targetPos_z;
    end
end


% match trials and target pos
for SBi = 1:6
    trialsInBlockL      = find([otherTrials.TrialLearnS(:).conditionNo] == conditionsSTAT(SBi),1,'first');
    trialsInBlockP      = find([otherTrials.TrialProbeS(:).conditionNo] == conditionsSTAT(SBi),1,'first');
    for Li = 1:3
        TrialLearnS(end+1).targetPos_x = otherTrials.TrialLearnS(trialsInBlockL).targetPos_x;
        TrialLearnS(end).targetPos_z = otherTrials.TrialLearnS(trialsInBlockL).targetPos_z;
    end
    for Pi = 1:4
        TrialProbeS(end+1).targetPos_x = otherTrials.TrialProbeS(trialsInBlockP).targetPos_x;
        TrialProbeS(end).targetPos_z = otherTrials.TrialProbeS(trialsInBlockP).targetPos_z;
    end
end

save('P:\Sein_Jeung\Project_Watermaze\WM_EEG_Results\BEH_output\sub-83004_beh_trials.mat', 'TrialLearnS', 'TrialLearnM', 'TrialProbeS', 'TrialProbeM');