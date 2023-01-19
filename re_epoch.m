% Epoch
%--------------------------------------------------------------------------
for subject = subjects
    
    % Directory
    %----------------------------------------------------------------------
    % subject ID to string
    subjectString   = num2str(subject);
    disp(['Epoching for Subject #' subjectString]);
    
    % input file path
    eegFilePath     = [studyFolder '\4_single-subject-analysis\' subjectString '\'];
    
    % input file name
    eegFileName     = [subjectString '_interp_avRef_ICA.set'];
    
    % output file name
    epochedFileName = [subjectString '_searchOrder_' num2str(1) '.set'];
    
    % output file path
    epochedPath     = [studyFolder '\5_epoched\' subjectString '\'];
    
    if ~exist(epochedPath, 'dir')
        mkdir(epochedPath);
    end
    
    % Parameters
    %----------------------------------------------------------------------
    % epoch window around the event
    epochWindow     = [-1 2];
    
    % length of epochs
    epochLength     = max(epochWindow) - min(epochWindow);
    
    % cell array of event names to be added(as many as conditions);
    eventNames      = {'navigation'};
    
    % number of conditions
    nConditions     = numel(eventNames);
    
    % number of blocks
    nBlocks         = 6;
    
    % number of search trials
    nSearch         = 3;
    
    % number of guess trials
    nGuess          = 4;
    
    
    % Epoching
    %----------------------------------------------------------------------
    if overwriteEpochs || ~exist(epochedFileName,'file')
        
        disp(['Epoching for subject ' subjectString ' EEG data.'])
        
        % load the eeg data
        EEG         = pop_loadset('filename', eegFileName, 'filepath', eegFilePath);
        
        % remove events that mess with marker parsing
        if subject == 81002
            EEG.event(785)  = [];
        elseif subject == 81003
            % to do : check the boundary event - recording was broken 
        end
        
        % find boundary events to segment data into desktop and MoBI
        % sessions
        boundaryIndices     = [EEG.event(1) find(contains({EEG.event(:).type},'sessionBoundary')) EEG.event(end)];
        
        % check the number of boundary events
        if numel(boundaryIndices) ~= 3
            error('Invalid number of boundary events for separating desktop and VR session')
        end
        
        % find trial start and end indices
        searchTrialStarts   = find(contains({EEG.event(:).type},'searchtrial:start'));
        searchTrialEnds     = find(contains({EEG.event(:).type},'searchtrial:end'));
        guessTrialStarts    = find(contains({EEG.event(:).type},'guesstrial:start'));
        guessTrialEnds      = find(contains({EEG.event(:).type},'guesstrial:end'));
        
        % initialize an empty array of events to add
        eventLatenciesToAdd         = [];
        eventNamesToAdd             = [];
        
        % iterate over sessions (1 for desktop 2 for MoBI)
        for sessionIndex = 1:2
            
            sessionStartIndex   = boundaryIndices(sessionIndex);
            sessionEndIndex     = boundaryIndices(sessionIndex + 1);
            
            % iterate over blocks
            for b = 1:nBlocks
                
                % find events by their block indices
                blockStartIndices   = find(contains({EEG.event(:).type},['block:start;block_index:' num2str(b) ';']));
                blockEndIndices     = find(contains({EEG.event(:).type},['block:end;block_index:' num2str(b) 'c']) | ...
                    contains({EEG.event(:).type},['block:end;block_index:' num2str(b) ';']));
                
                % choose the block that is in the session
                blockStartIndex     = find(blockStartIndices >= sessionStartIndex && blockStartIndices <= sessionStartIndex);
                blockEndIndex       = find(blockEndIndices >= sessionStartIndex && blockEndIndices <= sessionStartIndex);
                
                % check the order of block indices
                if blockEndIndex <= blockStartIndex
                    error(['Events marking block ' num2str(b) ' are invalid'])
                end
                
                % choose search trials in the block
                searchStartsInBlock  = find(blockStartIndex < searchTrialStarts(:) && searchTrialStarts(:)< blockStartIndex);
                searchEndsInBlock    = find(blockEndIndex < searchTrialEnds(:) && searchTrialEnds(:)< blockEndIndex);
                
                % check if the order and number of trials are correct
                if numel(searchStartsInBlock) ~= nSearch || numel(searchStartsInBlock) ~= numel(searchEndsInBlock)
                    error(['Invalid number of search trials in block ' num2str(b)])
                elseif numel(guessStartsInBlock) ~= nGuess || numel(guessStartsInBlock) ~= numel(guessEndsInBlock)
                    error(['Invalid number of guess trials in block ' num2str(b)])
                end
                
            end
            
        end
        
        
        % segment continous data into epochs of 3 seconds
        for trialIndex = 1:nTrials
            
            trialStartLatency   = eventLatencies(trialIndex);
            trialEndLatency     = eventLatencies(trialIndex);
            trialLength         = trialEndLatency - trialStartLatency;
            nEpochsInTrial      = floor(trialLength/epochLength);
            
            for epochIndex  = 1:nEpochsInTrial
                
                epochStart          = epochStart + epochLength;
                epochZeroPoint      = epochStart + 1000;
                remainingLength     = remainingLength - epochLength;
                eventLatenciesInTrial = [eventLatenciesInTrial ];
                
            end
            
            eventLatencies = [eventLatencies eventLatenciesInTrial];
        end
        
        
        for cond = 1:nConditions
            
            
            % add new events
            EEG_new = eeg_addnewevents(EEG, {[EEG.event(searchInBlock(:,cond)').latency]}, {['searchOrder_' num2str(cond)]});
            EEG_new = eeg_checkset(EEG_new);
            
            % epoch
            epochedEEG = pop_epoch(EEG_new, {['searchOrder_' num2str(cond)]}, [-1 2], 'epochinfo', 'yes');
            
            % output file name
            epochedFile     = [subjectString '_searchOrder_' num2str(cond) '.set'];
            
            % save on disk
            epochedEEG = pop_saveset( epochedEEG, 'filename',epochedFile,'filepath', epochedPath);
            
        end
        
        
    else
        
        disp(['Skip epoching for subject ' num2str(subject)])
        
    end
    
    
end
