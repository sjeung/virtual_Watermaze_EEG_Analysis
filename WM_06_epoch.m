function WM_06_epoch(Pi)
% epoch data 
% authors : Berrak Hosgoren, Sein Jeung
%--------------------------------------------------------------------------
%% load data 
%--------------------------------------------------------------------------
% load configs
WM_config;

% !! update with the commented out line after doing custom IC cleaning
% [cleanedFileName,cleanedFileDir]    = assemble_file(config_folder.data_folder, config_folder.cleaned_folder, config_folder.cleanedFileName, Pi);
[cleanedFileName,cleanedFileDir]    = assemble_file(config_folder.data_folder, '5_post-AMICA', '_cleaned_with_ICA.set', Pi);
[epochedFileName,epochedFileDir]    = assemble_file(config_folder.data_folder, config_folder.epoched_folder, '_epoched', Pi);

EEG = pop_loadset('filepath', cleanedFileDir, 'filename', cleanedFileName);

% find trial start and end indices
searchTrialStarts   = find(contains({EEG.event(:).type},'searchtrial:start'));
searchTrialEnds     = find(contains({EEG.event(:).type},'searchtrial:end'));
searchTrialFounds   = find(contains({EEG.event(:).type},'searchtrial:found'));
guessTrialStarts    = find(contains({EEG.event(:).type},'guesstrial:start'));
guessTrialEnds      = find(contains({EEG.event(:).type},'guesstrial:end'));

nSearch = 3;
nGuess  = 4;


% First: check whether block and trial numbers are correct
%-----------------------------------------------------------------------

% seperate the data into VR and Desktop sessions
for session_idx = 1:2
    
    % iterate over blocks
    for block_idx = 1:6 % there are 6 blocks in each session
        
        % find events by their block indices
        blockStartIndices   = find(contains({EEG.event(:).type},['block:start;block_index:' num2str(block_idx) ';']));
        blockEndIndices     = find(contains({EEG.event(:).type},['block:end;block_index:' num2str(block_idx)]));
        
        % choose the block that is in the session
        blockStart_idx = blockStartIndices(session_idx);
        blockEnd_idx   = blockEndIndices(session_idx);
        
        % check the order of block indices
        if blockEnd_idx <= blockStart_idx
            error(['Events marking block ' num2str(b) ' are invalid'])
        end
        
        % choose search trials in the block
        searchStartsInBlock  = find(searchTrialStarts(:) > blockStart_idx & searchTrialStarts(:) < blockEnd_idx);
        searchEndsInBlock    = find(searchTrialEnds(:) < blockEnd_idx & searchTrialEnds(:) > blockStart_idx);
        
        % choose guess trials in the block
        guessStartsInBlock  = find(guessTrialStarts(:) > blockStart_idx & guessTrialStarts(:) < blockEnd_idx);
        guessEndsInBlock    = find(guessTrialEnds(:) < blockEnd_idx & guessTrialEnds(:) > blockStart_idx);
        
        % check if the order and number of trials are correct
        if numel(searchStartsInBlock) ~= nSearch || numel(searchStartsInBlock) ~= numel(searchEndsInBlock)
            error(['Invalid number of search trials in block ' num2str(block_idx)])
        elseif numel(guessStartsInBlock) ~= nGuess || numel(guessStartsInBlock) ~= numel(guessEndsInBlock)
            error(['Invalid number of guess trials in block ' num2str(block_idx)])
        end
        
    end
end


% loop over sessions - VR comes first and then desktop
for session_idx = 1:2 
    
    % iterate over blocks
    for block_idx = 1:6 % there are 6 blocks in each session
        
        %---------------------------------------------------------
        % add new information to the event codes: search/guess_index,
        % block_index, session_index etc.
        
        % find events by their block indices
        blockStartIndices   = find(contains({EEG.event(:).type},['block:start;block_index:' num2str(block_idx) ';']));
        blockEndIndices     = find(contains({EEG.event(:).type},['block:end;block_index:' num2str(block_idx)]));
        
        % choose the block that is in the session
        blockStart_idx = blockStartIndices(session_idx);
        blockEnd_idx   = blockEndIndices(session_idx);
        
        % find the origin angle of the block
        block_angle = str2double(extractBetween(EEG.event(blockStart_idx).type,'origin_angle:',';target_angle'));
        
        % choose search trial found in the block
        searchFoundInBlock = [];
        sF_count = 1;
        
        for searchFnumber = 1:36
            if searchTrialFounds(searchFnumber) > blockStart_idx && searchTrialFounds(searchFnumber) < blockEnd_idx
                searchFoundInBlock(sF_count) = searchTrialFounds(searchFnumber);
                sF_count = sF_count + 1;
            end
        end
        
        for search_idx = 1:3
            % add new event information
            EEG.event(searchFoundInBlock(search_idx)).order = search_idx;
            EEG.event(searchFoundInBlock(search_idx)).block = block_idx;
            EEG.event(searchFoundInBlock(search_idx)).rotation = 0;
            EEG.event(searchFoundInBlock(search_idx)).session = session_idx;
        end
        
        % choose search trial start in the block
        searchStartInBlock = [];
        sS_count = 1;
        
        for searchSnumber = 1:36
            if searchTrialStarts(searchSnumber) > blockStart_idx && searchTrialStarts(searchSnumber) < blockEnd_idx
                searchStartInBlock(sS_count) = searchTrialStarts(searchSnumber);
                sS_count = sS_count + 1;
            end
        end
        
        for search_idx = 1:3
            % add new event information
            EEG.event(searchStartInBlock(search_idx)).order = search_idx;
            EEG.event(searchStartInBlock(search_idx)).block = block_idx;
            EEG.event(searchStartInBlock(search_idx)).rotation = 0;
            EEG.event(searchStartInBlock(search_idx)).session = session_idx;
            
        end
        
        
        % choose guess trials in the block
        guessStartInBlock = [];
        g_count = 1;
        
        for guessnumber = 1:48
            if guessTrialStarts(guessnumber) > blockStart_idx && guessTrialStarts(guessnumber) < blockEnd_idx
                guessStartInBlock(g_count) = guessTrialStarts(guessnumber);
                g_count = g_count + 1;
            end
        end
        
        for guess_idx = 1:4
            % add new event information
            EEG.event(guessStartInBlock(guess_idx)).order = guess_idx;
            EEG.event(guessStartInBlock(guess_idx)).block = block_idx;
            EEG.event(guessStartInBlock(guess_idx)).session = session_idx;
            
            % find the angle of the guess trial
            guess_angle = str2double(extractBetween(EEG.event(guessStartInBlock(guess_idx)).type,'starting_angle:',';'));
            rotation = block_angle - guess_angle;
            EEG.event(guessStartInBlock(guess_idx)).rotation = mod(rotation,360);
            
        end
        
    end
end

% Third: extract epochs from trials
%-----------------------------------------------------------------------------
% guess_epochs include all the events that start with guesstrial:start
learn_starts    = []; 
learn_ends     = [];
probe_starts    = [];
probe_ends      = [];
learn.count     = 1;
probe.count    = 1;

for event_idx = 1:length(EEG.event)
    
    if startsWith(EEG.event(event_idx).type, 'searchtrial:start')
        learn_starts{learn.count} = EEG.event(event_idx).type;
    end
    
    if startsWith(EEG.event(event_idx).type, 'searchtrial:found') 
        learn_ends{learn.count} = EEG.event(event_idx).type;
        learn.count = learn.count + 1;
    end
    
    if startsWith(EEG.event(event_idx).type, 'guesstrial:start')
        probe_starts{probe.count} = EEG.event(event_idx).type;
    end
    
    if startsWith(EEG.event(event_idx).type, 'guesstrial:keypress')
        probe_ends{probe.count} = EEG.event(event_idx).type;
        probe.count = probe.count + 1;
    end
    
end

assert(numel(learn_ends) == numel(learn_starts)); 
assert(numel(probe_ends) == numel(probe_starts)); 

% segments data into epochs (searchtrial:found, guesstrial:start)
epochedEEGStart     = pop_epoch(EEG, [learn_starts, probe_starts], [-1 4], 'epochinfo', 'yes');
epochedEEGEnd       = pop_epoch(EEG, [learn_ends, probe_ends], [-4 1], 'epochinfo', 'yes');

if ~isfolder(epochedFileDir)
    mkdir(epochedFileDir)
end

pop_saveset(epochedEEGStart, 'filepath', epochedFileDir, 'filename', [epochedFileName '_start.set']);
pop_saveset(epochedEEGEnd, 'filepath', epochedFileDir, 'filename', [epochedFileName '_end.set']);

end
