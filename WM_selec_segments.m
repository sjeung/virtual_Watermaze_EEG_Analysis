function segment_indices  = WM_selec_segments(EEG_AMICA_no_eyes)

WM_config
addpath(subjectInfoPath)

% finds event 'boundary' that marks the separation between desktop and MoBI
% sessions in Watermaze experiment
segment_indices = NaN(2,2); 

[firstIndex, lastIndex] = size(EEG_AMICA_no_eyes.data); 
boundaryEventIndex      = find(strcmp({EEG_AMICA_no_eyes.event.type}, 'boundary'));


% find participant ID to look for an appropriate index for each participant
if numel(boundaryEventIndex) == 1   
    disp(['Found boundary event, index ' num2str(boundaryEventIndex)])
else
  
    subjectString = EEG_AMICA_no_eyes.filename(1:5); 
    eval(['Subject' subjectString]); 
    
    % sanity check 
    if numel(subjectData.filesDesktop)+ numel(subjectData.filesVR) - 1 == numel(boundaryEventIndex)
        nAllBoundaryEvents  = numel(boundaryEventIndex); 
        boundaryEventIndex  = boundaryEventIndex(numel(subjectData.filesDesktop));
        disp(['Participant ' subjectString ' : ' num2str(nAllBoundaryEvents) 'boundaries found. using ' num2str(boundaryEventIndex) 'th boundary event index to select segments'])
    else
       error('Invalid number of boundary events') 
    end 
    
end

boundaryIndex           = EEG_AMICA_no_eyes.event(boundaryEventIndex).latency; 

% desktop session 
segment_indices(1,1) = firstIndex; 
segment_indices(1,2) = boundaryIndex - 1; 

% MoBI session 
segment_indices(2,1) = boundaryIndex; 
segment_indices(2,2) = lastIndex; 


end


