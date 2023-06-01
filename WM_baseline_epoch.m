function WM_baseline_epoch(Pi)

epochWidth = 5; % in seconds
EEG = pop_loadset(['P:\Sein_Jeung\Project_Watermaze\WM_EEG_Data\5_post-AMICA\sub-' num2str(Pi), '\sub-' num2str(Pi) '_cleaned_with_ICA.set']); 

standingStarts  = find(contains({EEG.event(:).type},'standing:start'));
standingEnds    = find(contains({EEG.event(:).type},'standing:end'));
walkingStarts   = standingEnds;
walkingEnds     = find(contains({EEG.event(:).type},'baseline:end'));

% generate continuous epochs

% import event markers and latency to EEG.event
newEvent = struct('type', {}, 'latency',{}, 'urevent',{});

for Bi = 1:3
    ssLat = EEG.event(standingStarts(Bi)).latency; 
    seLat = EEG.event(standingEnds(Bi)).latency; 
    wsLat = EEG.event(walkingStarts(Bi)).latency; 
    weLat = EEG.event(walkingEnds(Bi)).latency; 
    
    % convert seconds to number of samples 
    latencies       = ssLat:EEG.srate*epochWidth:seLat; 
    latenciesWalk   = wsLat:EEG.srate*epochWidth:weLat; 
    
    for Ei = 1:numel(latencies)
        newEvent(end+1).type = 'standing_mobi'; 
        newEvent(end).latency = latencies(Ei);  
        newEvent(end).urevent = numel(newEvent);  
    end

    for Ei = 1:numel(latenciesWalk)
        newEvent(end+1).type = 'walking_mobi'; 
        newEvent(end).latency = latenciesWalk(Ei);  
        newEvent(end).urevent = numel(newEvent);  
    end
end

for Bi = 4:6
    ssLat = EEG.event(standingStarts(Bi)).latency; 
    seLat = EEG.event(standingEnds(Bi)).latency; 
    wsLat = EEG.event(walkingStarts(Bi)).latency; 
    weLat = EEG.event(walkingEnds(Bi)).latency; 
    
    % convert seconds to number of samples 
    latencies       = ssLat:EEG.srate*epochWidth:seLat; 
    latenciesWalk   = wsLat:EEG.srate*epochWidth:weLat; 
    
    for Ei = 1:numel(latencies)
        newEvent(end+1).type = 'standing_stat'; 
        newEvent(end).latency = latencies(Ei);  
        newEvent(end).urevent = numel(newEvent);  
    end

    for Ei = 1:numel(latenciesWalk)
        newEvent(end+1).type = 'walking_stat'; 
        newEvent(end).latency = latenciesWalk(Ei);  
        newEvent(end).urevent = numel(newEvent);  
    end
end

EEG.event = newEvent; 

baseMOBIEpoch = pop_epoch(EEG, {'standing_mobi'}, [-1 4], 'epochinfo', 'yes');
baseSTATEpoch = pop_epoch(EEG, {'standing_stat'}, [-1 4], 'epochinfo', 'yes');
walkMOBIEpoch = pop_epoch(EEG, {'walking_mobi'}, [-1 4], 'epochinfo', 'yes');
walkSTATEpoch = pop_epoch(EEG, {'walking_stat'}, [-1 4], 'epochinfo', 'yes');

pop_saveset(baseMOBIEpoch, 'filepath', ['P:\Sein_Jeung\Project_Watermaze\WM_EEG_Data\7_epoched\sub-' num2str(Pi)], 'filename', ['sub-' num2str(Pi) '_mobi_stand.set']); 
pop_saveset(baseSTATEpoch, 'filepath', ['P:\Sein_Jeung\Project_Watermaze\WM_EEG_Data\7_epoched\sub-' num2str(Pi)], 'filename', ['sub-' num2str(Pi) '_stat_stand.set']);
pop_saveset(walkMOBIEpoch, 'filepath', ['P:\Sein_Jeung\Project_Watermaze\WM_EEG_Data\7_epoched\sub-' num2str(Pi)], 'filename', ['sub-' num2str(Pi) '_mobi_walk.set']); 
pop_saveset(walkSTATEpoch, 'filepath', ['P:\Sein_Jeung\Project_Watermaze\WM_EEG_Data\7_epoched\sub-' num2str(Pi)], 'filename', ['sub-' num2str(Pi) '_stat_walk.set']);

end