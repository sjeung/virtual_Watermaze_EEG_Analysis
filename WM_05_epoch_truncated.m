function WM_05_epoch_truncated(Pi)
% epoch data
% save data in fieldtrip style structure
%
% authors : Sein Jeung
%--------------------------------------------------------------------------

WM_config;                                                                  % load configs

trialTypes                          = {'learn', 'probe'};
sessions                            = {'mobi', 'stat'};
epochWidth                          = 3; % in seconds
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

% extract trials
lStarts         = find(contains({EEG.event.type}, 'searchtrial:start'));
lEnds           = find(contains({EEG.event.type}, 'searchtrial:found'));
pStarts         = find(contains({EEG.event.type}, 'guesstrial:start'));
pEnds           = find(contains({EEG.event.type}, 'guesstrial:keypress'));

assert(numel(lStarts) == numel(lEnds));
assert(numel(pStarts) == numel(pEnds));

if Pi ~= 83004
    assert(numel(lStarts) == 36);
    assert(numel(pStarts) == 48);
else
    disp(['Participant 83004 has ' num2str(numel(lStarts)) ' learn and ' num2str(numel(pStarts)) ' probe trials'])
end

learnTrials = [EEG.event(lStarts).latency; EEG.event(lEnds).latency];       % 2 x N vector consisting of start and end indices
probeTrials = [EEG.event(pStarts).latency; EEG.event(pEnds).latency];       % 2 x N vector consisting of start and end indices

% construct fieldtrip header information
hdr             = ft_read_header(fullfile(cleanedFileDir, cleanedFileName));
hdr.chanunit    = repmat({'uV'}, 1, hdr.nChans);
motionhdr       = ft_read_header(fullfile(motionFileDir, motionFileName));

for iSession    = 1:2
    
    session     = sessions{iSession};
    
    %% Epoch trials (variable lengths)
    for iType       = 1:numel(trialTypes)
        
        trialType   = trialTypes{iType};
        
        % define learn versus probe trials
        if strcmp(trialType, 'learn')
            trials = learnTrials;
        elseif strcmp(trialType, 'probe')
            trials = probeTrials;
        end
        
        % define stat versus mobi trials: VR comes first and then desktop
        if strcmp(session, 'mobi') % (83004 VR ends at marker 359, latency 380985)
            if Pi == 83004 && strcmp(trialType, 'learn')
                trials = trials(:,1:12);
            else
                trials = trials(:,1:size(trials,2)/2);                              % extract first half (mobi setup)
            end
        elseif strcmp(session, 'stat')
            if Pi == 83004 && strcmp(trialType, 'learn')
                trials = trials(:,13:end);
            else
                trials = trials(:,size(trials,2)/2+1:end);                          % extract second half (stationary setup)
            end
        end
        
        %% Trial start
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
            tWindow = trials(1,Ti) - timeBuffer*EEG.srate:trials(1,Ti) + (epochWidth + timeBuffer)*EEG.srate; % in latency, for indexing data point
            
            ftEEG.trial{end + 1} = EEG.data(:,tWindow);
            ftEEG.time{end + 1} = (tWindow - tWindow(1))/EEG.srate - timeBuffer; % convert to seconds
            
            ftMotion.trial{end + 1} = MOTION.data(:,tWindow);
            ftMotion.time{end + 1} = (tWindow - tWindow(1))/MOTION.srate - timeBuffer; % convert to seconds
        end
        
        [epochedFileName,epochedFileDir]    = assemble_file(config_folder.data_folder, config_folder.epoched_folder, ['_' trialType '_' session '_epoched_start.mat'], Pi);
        [epochedMotionFileName,~]    = assemble_file(config_folder.data_folder, config_folder.epoched_folder, ['_' trialType '_' session '_motion_epoched_start.mat'], Pi);        
        save(fullfile(epochedFileDir, epochedFileName), 'ftEEG');
        save(fullfile(epochedFileDir, epochedMotionFileName), 'ftMotion');
        
        %% Trial mid
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
            
            winStart =  trials(1,Ti) + epochWidth*EEG.srate; % increment windows from right after the start segment within a trial
            
            while winStart < trials(2,Ti) - epochWidth*EEG.srate                
                tWindow = winStart - timeBuffer*EEG.srate:winStart + (timeBuffer+epochWidth)*EEG.srate; % in latency, for indexing data point
                
                ftEEG.trial{end + 1} = EEG.data(:,tWindow);
                ftEEG.time{end + 1} =  (tWindow - tWindow(1))/EEG.srate - timeBuffer; % convert to seconds
                
                ftMotion.trial{end + 1} = MOTION.data(:,tWindow);
                ftMotion.time{end + 1} = (tWindow - tWindow(1))/EEG.srate - timeBuffer; % convert to seconds
                
                winStart = winStart + epochWidth*EEG.srate; % increment windows from right after the start segment within a trial
            end
        end
        
        [epochedFileName,epochedFileDir]    = assemble_file(config_folder.data_folder, config_folder.epoched_folder, ['_' trialType '_' session '_epoched_mid.mat'], Pi);
        [epochedMotionFileName,~]    = assemble_file(config_folder.data_folder, config_folder.epoched_folder, ['_' trialType '_' session '_motion_epoched_mid.mat'], Pi);
        save(fullfile(epochedFileDir, epochedFileName), 'ftEEG');
        save(fullfile(epochedFileDir, epochedMotionFileName), 'ftMotion');
        
        
        %% Trial end
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

            tWindow = trials(2,Ti) - (timeBuffer+epochWidth)*EEG.srate:trials(2,Ti) + (timeBuffer)*EEG.srate; % in latency, for indexing data point
            
            ftEEG.trial{end + 1} = EEG.data(:,tWindow);
            ftEEG.time{end + 1} = (tWindow - tWindow(end))/EEG.srate + timeBuffer; % convert to seconds
            
            ftMotion.trial{end + 1} = MOTION.data(:,tWindow);
            ftMotion.time{end + 1} = (tWindow - tWindow(end))/MOTION.srate + timeBuffer; % convert to seconds
        end
        
        [epochedFileName,epochedFileDir]    = assemble_file(config_folder.data_folder, config_folder.epoched_folder, ['_' trialType '_' session '_epoched_end.mat'], Pi);
        [epochedMotionFileName,~]    = assemble_file(config_folder.data_folder, config_folder.epoched_folder, ['_' trialType '_' session '_motion_epoched_end.mat'], Pi);        
        save(fullfile(epochedFileDir, epochedFileName), 'ftEEG');
        save(fullfile(epochedFileDir, epochedMotionFileName), 'ftMotion');
        
    end
end


end
