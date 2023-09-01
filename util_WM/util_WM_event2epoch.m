function epochInds = util_WM_event2epoch(EEG,eventInds)
% convert event indices to epoch indices

epochInds       = [];
for Ei = 1:numel(EEG.epoch)
    if any(ismember(eventInds, EEG.epoch(Ei).event))
        epochInds(end+1) = Ei; 
    end
end

end