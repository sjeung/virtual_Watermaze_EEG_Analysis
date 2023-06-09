function WM_06_epoch(Pi)
% epoch data
% save data in fieldtrip style structure
%
% authors : Berrak Hosgoren, Sein Jeung
%--------------------------------------------------------------------------

WM_config;                                                                  % load configs

trialTypes                          = {'learn', 'probe'};
baselineTrialTypes                  = {'stand', 'walk'};
sessions                            = {'mobi', 'stat'};
epochWidth                          = 5; % in seconds
timeBuffer                          = 1;                                    % in seconds (trials will be cut with -buffer, +buffer around the edge events)

[cleanedFileName,cleanedFileDir]    = assemble_file(config_folder.data_folder, config_folder.cleaned_folder, config_folder.cleanedFileName, Pi);
[motionFileName,motionFileDir]      = assemble_file(config_folder.data_folder, config_folder.trimmed_folder, config_folder.trimmedFileNameMotion, Pi);
[~,epochedFileDir]                  = assemble_file(config_folder.data_folder, config_folder.epoched_folder, '', Pi);

if ~isfolder(epochedFileDir)
    mkdir(epochedFileDir)
end

%% load data
%--------------------------------------------------------------------------
EEG             = pop_loadset('filepath', cleanedFileDir, 'filename', cleanedFileName);
MOTION          = pop_loadset('filepath', motionFileDir, 'filename', motionFileName); 
 
% extract standing and walking baselines
standingStarts  = find(contains({EEG.event.type},'standing:start'));
standingEnds    = find(contains({EEG.event.type},'standing:end'));
walkingStarts   = standingEnds;
walkingEnds     = find(contains({EEG.event.type},'baseline:end'));

assert(numel(standingStarts) == numel(standingEnds));
assert(numel(walkingStarts) == numel(walkingEnds));
assert(numel(standingStarts) == 6);
assert(numel(walkingStarts) == 6);

standingTrials  = [EEG.event(standingStarts).latency; EEG.event(standingEnds).latency];     % 2 x N vector consisting of start and end indices
walkingTrials   = [EEG.event(walkingStarts).latency; EEG.event(walkingEnds).latency];       % 2 x N vector consisting of start and end indices

% extract trials
lStarts         = find(contains({EEG.event.type}, 'searchtrial:start'));
lEnds           = find(contains({EEG.event.type}, 'searchtrial:found'));
pStarts         = find(contains({EEG.event.type}, 'guesstrial:start'));
pEnds           = find(contains({EEG.event.type}, 'guesstrial:keypress'));

assert(numel(lStarts) == numel(lEnds));
assert(numel(pStarts) == numel(pEnds));
assert(numel(lStarts) == 36);
assert(numel(pStarts) == 48);

learnTrials = [EEG.event(lStarts).latency; EEG.event(lEnds).latency];       % 2 x N vector consisting of start and end indices
probeTrials = [EEG.event(pStarts).latency; EEG.event(pEnds).latency];       % 2 x N vector consisting of start and end indices

% construct fieldtrip header information
hdr             = ft_read_header(fullfile(cleanedFileDir, cleanedFileName));
hdr.chanunit    = repmat({'uV'}, 1, hdr.nChans);
motionhdr       = ft_read_header(fullfile(motionFileDir, motionFileName));

for iSession    = 1:2
    
    session     = sessions{iSession};
    
    %% Epoch baselines
    for iBaseType = 1:2
        
        baselineTrialType = baselineTrialTypes{iBaseType};
        
        % fill out header information
        ftEEG           = [];
        ftEEG.hdr       = hdr;
        ftEEG.label     = hdr.label;
        ftEEG.trial     = {};
        ftEEG.time      = {}; % unit is seconds
        
        ftMotion        = [];
        ftMotion.hdr    = motionhdr; 
        ftMotion.label  = motionhdr.label; 
        ftMotion.trial  = {};
        ftMotion.time   = {}; 

        % define learn versus probe trials
        if strcmp(baselineTrialType, 'stand')
            baseTrials  = standingTrials;
        else
            baseTrials  = walkingTrials;
        end
        
        % extract data
        for Bi = (iSession-1)*3+1:(iSession-1)*3 + 3                        % blocks 1-3 are mobi, 4-6 are stationary
            
            blockStart  = baseTrials(1,Bi);
            blockEnd    = baseTrials(2,Bi);
            
            % convert seconds to number of samples
            latencies    = blockStart:EEG.srate*epochWidth:blockEnd;
            
            for Li = 1:numel(latencies) - 1
                ftEEG.trial{end + 1} = EEG.data(:,latencies(Li):latencies(Li+1));
                ftEEG.time{end + 1} = linspace(0,epochWidth, size(ftEEG.trial{end},2)); % convert to seconds
                
                ftMotion.trial{end + 1} = MOTION.data(:,latencies(Li):latencies(Li+1));
                ftMotion.time{end + 1} = linspace(0,epochWidth, size(ftMotion.trial{end},2)); % convert to seconds
            end
            
        end
        
        ftEEG.hdr.nTrials       = numel(latencies) - 1;
        ftMotion.hdr.nTrials    = numel(latencies) - 1;
        
        [baselineFileName,epochedFileDir]    = assemble_file(config_folder.data_folder, config_folder.epoched_folder, ['_' baselineTrialType '_' session '_epoched.mat'], Pi);
        [baselineMotionFileName,~]    = assemble_file(config_folder.data_folder, config_folder.epoched_folder, ['_' baselineTrialType '_' session '_motion_epoched.mat'], Pi);
        
        save(fullfile(epochedFileDir, baselineFileName), 'ftEEG');
        save(fullfile(epochedFileDir, baselineMotionFileName), 'ftMotion');
        
    end
    
    %% Epoch trials (various lengths)
    for iType       = 1:numel(trialTypes)
        
        trialType   = trialTypes{iType};
        
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
        
        % fill out header information
        hdr.nTrials     = size(trials, 2);
        ftEEG           = [];
        ftEEG.hdr       = hdr;
        ftEEG.label     = hdr.label;
        ftEEG.trial     = {};
        ftEEG.time      = {}; % unit is seconds

        ftMotion        = [];
        ftMotion.hdr    = motionhdr; 
        ftMotion.label  = motionhdr.label;
        ftMotion.trial  = {};
        ftMotion.time   = {};
        
        % extract data
        for Ti = 1:size(trials, 2)
            tWindow = trials(1,Ti) - timeBuffer*EEG.srate:trials(2,Ti)+timeBuffer*EEG.srate; % in latency, for indexing data point
            
            ftEEG.trial{end + 1} = EEG.data(:,tWindow);
            ftEEG.time{end + 1} = (tWindow - tWindow(1))/EEG.srate - timeBuffer; % convert to seconds
            
            ftMotion.trial{end + 1} = MOTION.data(:,tWindow);
            ftMotion.time{end + 1} = (tWindow - tWindow(1))/MOTION.srate - timeBuffer; % convert to seconds
        end
        
        [epochedFileName,epochedFileDir]    = assemble_file(config_folder.data_folder, config_folder.epoched_folder, ['_' trialType '_' session '_epoched.mat'], Pi);
        [epochedMotionFileName,~]    = assemble_file(config_folder.data_folder, config_folder.epoched_folder, ['_' trialType '_' session '_motion_epoched.mat'], Pi);
        
        save(fullfile(epochedFileDir, epochedFileName), 'ftEEG');
        save(fullfile(epochedFileDir, epochedMotionFileName), 'ftMotion');
    end
end

end
