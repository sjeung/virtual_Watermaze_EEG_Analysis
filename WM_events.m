function [searchEvents, guessEvents] = WM_events(events, ID, sessions)
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
%   events      
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
addpath('P:\Sein_Jeung\Project_Watermaze\WM_EEG_Data\source-data')
eval(['Subject', num2str(ID)])
nBlocks         = 6; 
nSearchTrials   = 3; 
nGuessTrials    = 4; 

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
% indices of all trials in the event stream 
searchStartMarkers      = find(contains({events(:).type},'searchtrial:start'));
searchEndMarkers        = find(contains({events(:).type},'searchtrial:end'));
guessStartMarkers       = find(contains({events(:).type},'guesstrial:start'));
guessEndMarkers         = find(contains({events(:).type},'guesstrial:end'));

searchEvents            = events(guessStartMarkers);
guessEvents             = events(searchStartMarkers); 

end