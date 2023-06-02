function WM_06_epoch(Pi)
% epoch data 
% save data in fieldtrip style structure 
% 
% authors : Berrak Hosgoren, Sein Jeung
%--------------------------------------------------------------------------
%% load data 
%--------------------------------------------------------------------------
WM_config;                                                                  % load configs

trialTypes                          = {'learn', 'probe'}; 
sessions                            = {'mobi', 'stat'};
timeBuffer                          = 1;                                    % in seconds

[cleanedFileName,cleanedFileDir]    = assemble_file(config_folder.data_folder, config_folder.cleaned_folder, config_folder.cleanedFileName, Pi);

EEG = pop_loadset('filepath', cleanedFileDir, 'filename', cleanedFileName);

% extract trials
lStarts     = find(contains({EEG.event.type}, 'searchtrial:start')); 
lEnds       = find(contains({EEG.event.type}, 'searchtrial:found')); 
pStarts     = find(contains({EEG.event.type}, 'guesstrial:start')); 
pEnds       = find(contains({EEG.event.type}, 'guesstrial:keypress'));

assert(numel(lStarts) == numel(lEnds)); 
assert(numel(pStarts) == numel(pEnds)); 
assert(numel(lStarts) == 36); 
assert(numel(pStarts) == 48); 

learnTrials = [EEG.event(lStarts).latency; EEG.event(lEnds).latency];       % 2 x N vector consisting of start and end indices
probeTrials = [EEG.event(pStarts).latency; EEG.event(pEnds).latency];       % 2 x N vector consisting of start and end indices

for iType       = 1:numel(trialTypes)
    
    for iSession    = 1:2
      
        trialType   = trialTypes{iType};
        session     = sessions{iSession}; 
        
        % define learn versus probe trials
        if strcmp(trialType, 'learn')
            trials = learnTrials;
        elseif strcmp(trialType, 'probe')
            trials = probeTrials;
        end
        
        % define stat versus mobi trials: VR comes first and then desktop
        if strcmp(session, 'mobi')
            trials = trials(:,1:size(trials,2)/2);                              % extract first half (mobi setup)
        elseif strcmp(session, 'stat')
            trials = trials(:,size(trials,2)/2+1:end);                          % extract second half (stationary setup)
        end
        
        % construct fieldtrip header information
        hdr             = ft_read_header(fullfile(cleanedFileDir, cleanedFileName), 'filename', cleanedFileName);
        hdr.chanunit    = repmat({'uV'}, 1, hdr.nChans);
        hdr.nTrials     = size(trials, 2);
        
        ftEEG           = [];
        ftEEG.hdr       = hdr;
        ftEEG.label     = hdr.label;
        ftEEG.trial     = {};
        ftEEG.time      = {}; % unit is seconds
        
        % extract data
        for Ti = 1:size(trials, 2)
            tWindow = trials(1,Ti) - timeBuffer*EEG.srate:trials(2,Ti)+timeBuffer*EEG.srate; % in latency, for indexing data point
            ftEEG.trial{end + 1} = EEG.data(:,tWindow);
            ftEEG.time{end + 1} = (tWindow - tWindow(1))/EEG.srate - timeBuffer; % convert to seconds
        end
        
        [epochedFileName,epochedFileDir]    = assemble_file(config_folder.data_folder, config_folder.epoched_folder, ['_' trialType '_' session '_epoched.mat'], Pi);
        
        if ~isfolder(epochedFileDir)
            mkdir(epochedFileDir)
        end        

        save(fullfile(epochedFileDir, epochedFileName), 'ftEEG');
    end
end
