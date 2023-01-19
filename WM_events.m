function events = WM_events(events, ID, sessions)
% This function processes events so that only the relevant parts are
% inlcuded for further event-related processing.
% It deals with incomplete blocks and
% trials due to broken recording by trimming them out.
%
% Inputs
%   events      :  
%   ID          :
%                   8100X
%                   8200X
%
%   sessions    :
%                   {"desktop", "VR"}
%
% Outputs
%   events      : 
%
% author : Sein Jeung
%--------------------------------------------------------------------------

%--------------------------------------------------------------------------
%                           Parameters
%--------------------------------------------------------------------------

% load experiment parameters from config file
% (number of blocks in a session, number of trials, path to subject info)
WM_config;

% load participant-specific parameters from subject info files
addpath(subjectInfoPath)
eval(['Subject', num2str(ID)])

%--------------------------------------------------------------------------
%                Participant and Session Information
%--------------------------------------------------------------------------

% convert numerical ID to string
participantIDString     = num2str(ID);

% participant group, either patient or control 
if participantIDString(2) == '1'
    group    = 'patient';
elseif participantIDString(2) == '2'
    group    = 'control';
else
    error('Invalid participant ID');
end

% index of the matched pair of patient and control 
pair_index      = str2double(participantIDString(4:5));

% RFPT results 
rfpt            = subjectdata.rfpt; 

% number of sessions included in the events input 
nSessions       = numel(sessions);

% check if there is any event to be ignored
if isfield(subjectdata,'eventstoignore') && ~isempty(subjectdata.eventstoignore)
    disp([num2str(numel(subjectdata.eventstoignore)) ' event(s) from participant ' num2str(participantIDString) ' ignored.'])
    events(subjectdata.eventstoignore)          = []; 
end

%--------------------------------------------------------------------------
%            Identify Relevant Blocks and Trials 
%--------------------------------------------------------------------------

% initialize empty arrays 
sessionStartIndices     = NaN(1,nSessions);
sessionEndIndices       = NaN(1,nSessions); 
blockStartIndices       = NaN(1,nBlocks*nSessions);
blockEndIndices         = NaN(1,nBlocks*nSessions); 
searchStartIndices      = NaN(nSearchTrials,nBlocks*nSessions);
searchEndIndices        = NaN(nSearchTrials,nBlocks*nSessions);
guessStartIndices       = NaN(nGuessTrials,nBlocks*nSessions);
guessEndIndices         = NaN(nGuessTrials,nBlocks*nSessions);

% indices of all trials in the event stream 
searchStartMarkers      = find(contains({events(:).type},'searchtrial:start'));
searchEndMarkers        = find(contains({events(:).type},'searchtrial:end'));
guessStartMarkers       = find(contains({events(:).type},'guesstrial:start'));
guessEndMarkers         = find(contains({events(:).type},'guesstrial:end'));

% check the boundary between sessions 
boundary = find(contains({events(:).type},'boundary'));

if  numel(boundary) == nSessions -1
    disp([num2str(nSessions) ' sessions and ' num2str(numel(boundary)) ' boundary events found.'])
else
    error('Boundary events and session number mismatch')
end

% iterate over sessions to fill the array of block indices
%--------------------------------------------------------------------------
for session = 1:nSessions
    
    % fill out the array of session indices
    %----------------------------------------------------------------------
    if session == 1
        sessionStartIndices(session)    = 1;
    else
        % boundary is indexed by session - 1 because there are 
        % N - 1 boundary events for N sessions
        sessionStartIndices(session)    = boundary(session-1) + 1; 
    end
    
    if session == nSessions 
        sessionEndIndices(session)      = numel(events); 
    else
        sessionEndIndices(session)      = boundary(session) - 1; 
    end 
    
    % iterate over blocks in all sessions
    %----------------------------------------------------------------------
    for block = 1:nBlocks
        
        blockStartMarkers   = find(contains({events(:).type},['block:start;block_index:' num2str(block) ';']));
        blockEndMarkers     = find(contains({events(:).type},['block:end;block_index:' num2str(block) 'c']) | ...
            contains({events(:).type},['block:end;block_index:' num2str(block) ';']));
        
        % fill out the array of block indices
        blockStartIndices(nBlocks*(session-1) + block)  = blockStartMarkers(session);
        blockEndIndices(nBlocks*(session-1) + block)    = blockEndMarkers(session);
        
        % find trial markers in each block
        searchStartsInBlock     = searchStartMarkers(blockStartMarkers(session) < searchStartMarkers & ...
            searchStartMarkers < blockEndMarkers(session));
        searchEndsInBlock       = searchEndMarkers(blockStartMarkers(session) < searchEndMarkers & ...
            searchEndMarkers <= blockEndMarkers(session) + 1);
        guessStartsInBlock      = guessStartMarkers(blockStartMarkers(session) < guessStartMarkers & ...
            guessStartMarkers < blockEndMarkers(session));
        guessEndsInBlock        = guessEndMarkers(blockStartMarkers(session) < guessEndMarkers & ...
            guessEndMarkers <= blockEndMarkers(session) + 1);
        
        % fill out the array of trial indices
        searchStartIndices(:,nBlocks*(session-1) + block)   = searchStartsInBlock;
        searchEndIndices(:,nBlocks*(session-1) + block)     = searchEndsInBlock;
        guessStartIndices(:,nBlocks*(session-1) + block)    = guessStartsInBlock;
        guessEndIndices(:,nBlocks*(session-1) + block)      = guessEndsInBlock;
        
    end
    
end


%--------------------------------------------------------------------------
%                      Filling out Event Fields
%--------------------------------------------------------------------------

% assign values to participant-specific fields 
%--------------------------------------------------------------------------
[events(:).participant_group]   = deal(group);
[events(:).pair_index]          = deal(pair_index);
[events(:).rfpt]                = deal(rfpt);        

% iterate over sessions 
%--------------------------------------------------------------------------
for session = 1:nSessions
    
    % assign values to session-specific fields
    %----------------------------------------------------------------------  
    eventsInSession = sessionStartIndices(session):sessionEndIndices(session); 

    % setup presentation order
    if strcmpi(subjectdata.setuporder(1:2),'vr')
        if strcmpi(sessions(session),'vr')
            session_order = 1; 
        else
            session_order = 2; 
        end
    else
        if strcmpi(sessions(session),'desktop')
            session_order = 1;
        else
            session_order = 2;
        end
    end 
    
    % scene presentation order
    scene = subjectdata.sceneorder(session_order); 
    
    [events(eventsInSession).setup]             = deal(sessions(session));
    [events(eventsInSession).session_order]     = deal(num2str(session_order));
    [events(eventsInSession).scene]             = deal(scene);
    
    % iterate over blocks
    %----------------------------------------------------------------------
    for block = 1:nBlocks
        
        % assign values to block-specific fields
        %------------------------------------------------------------------
        eventsInBlock           = blockStartIndices(nBlocks*(session-1) + block):blockEndIndices(nBlocks*(session-1) + block); 
        blockInfo               = events(blockStartIndices(nBlocks*(session-1) + block)).type;
        
        block_order             = block; 
        spatial_configuration   = extractBetween(blockInfo,'condition_index:',';');
        target_model            = extractBetween(blockInfo,'model_name:',';'); 
        
        [events(eventsInBlock).block_order]             = deal(num2str(block_order)); 
        [events(eventsInBlock).spatial_configuration]   = deal(spatial_configuration); 
        [events(eventsInBlock).target_model]            = deal(target_model); 

        
        % iterate over search trials
        %------------------------------------------------------------------
        for search = 1:nSearchTrials
            
            
            % assign values to trial-specific fields
            %--------------------------------------------------------------
            trialStart          = searchStartIndices(search,nBlocks*(session-1) + block);
            trialEnd            = searchEndIndices(search,nBlocks*(session-1) + block);
            eventsInTrial       = trialStart:trialEnd;
            
            [events(eventsInTrial).task]                = deal('search');
            [events(eventsInTrial).search_trial_order]  = deal(search);
            
            [events(trialStart).status]                 = deal('onset');
            [events(trialEnd-1).status]                 = deal('feedback');
            [events(trialEnd).status]                   = deal('offset');
            
            
        end
        
        % iterate over guess trials
        %------------------------------------------------------------------
        for guess = 1:nGuessTrials
            
            
            % assign values to trial-specific fields
            %--------------------------------------------------------------
            trialStart          = guessStartIndices(guess,nBlocks*(session-1) + block);
            trialEnd            = guessEndIndices(guess,nBlocks*(session-1) + block);
            eventsInTrial       = trialStart:trialEnd;
            
            trialInfo           = events(trialStart).type;
            rotation            = str2double(extractBetween(trialInfo, 'starting_angle:',';'))...
                                  - str2double(extractBetween(blockInfo,'origin_angle:',';')); 
            rotation            = mod(rotation,360);
            
            performanceInfo     = events(trialEnd-1).type; 
            response_x          = extractBetween(performanceInfo,'response_x:',';');
            response_y          = extractBetween(performanceInfo,'response_y:',';');
            
            [events(eventsInTrial).task]                = deal('guess');
            [events(eventsInTrial).guess_trial_order]   = deal(guess);
            [events(eventsInTrial).rotation]            = deal(rotation);
            [events(eventsInTrial).response_x]          = deal(response_x);
            [events(eventsInTrial).response_y]          = deal(response_y);
            
            [events(trialStart).status]                 = deal('onset');
            [events(trialEnd).status]                   = deal('offset');
            
            
        end
        
    end
    
    
end
        


end