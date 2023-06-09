function WM_02_trim(Pi)
% trimming out irrelevant portions of the continuous data 
% specify properties of markers that define windows of interest
%--------------------------------------------------------------------------
WM_config; 

[rawEEGFileName, rawEEGFileDir] = assemble_file(config_folder.data_folder, config_folder.set_folder, config_folder.rawFileNameEEG, Pi); 
[rawMOTIONFileName, rawMOTIONFileDir] = assemble_file(config_folder.data_folder, config_folder.set_folder, config_folder.rawFileNameMotion, Pi); 
[trimmedEEGFileName, trimmedEEGFileDir] = assemble_file(config_folder.data_folder, config_folder.trimmed_folder, config_folder.trimmedFileNameEEG, Pi); 
[trimmedMOTIONFileName, trimmedMOTIONFileDir] = assemble_file(config_folder.data_folder, config_folder.trimmed_folder, config_folder.trimmedFileNameMotion, Pi); 


rawEEG      = pop_loadset(fullfile(rawEEGFileDir, rawEEGFileName));
rawMOTION   = pop_loadset(fullfile(rawMOTIONFileDir, rawMOTIONFileName));

% baseline 
numBaseline         = 6; 
baselineStartMarker = 'baseline:start'; 
baselineEndMarker   = 'baseline:end';

% all blocks   
numBlocks           = 12;
blockStartMarker    = 'block:start';
blockEndMarker      = 'block:end';

% Load Data
markers = {rawEEG.event.type};


% remove practice blocks 
for mi = 1:numel(markers)
    if contains(markers{mi},'block_index:99') || contains(markers{mi},'blockIndex:99') 
        markers{mi} = 'ignore';
    end
end

%--------------------------------------------------------------------------
% Process Markers 
%--------------------------------------------------------------------------

% Find all baseline windows
%--------------------------------------------------------------------------
[baselineStartIndices, baselineEndIndices] = markerwindows(markers, baselineStartMarker, baselineEndMarker);

% Sanity check : Do the numbers of indices match?
if numel(baselineStartIndices) ~= numBaseline
    error('Invalid number of baseline tasks found')
end

% Find all blocks
%--------------------------------------------------------------------------
[blockStartIndices, blockEndIndices] = markerwindows(markers, blockStartMarker, blockEndMarker);

% Sanity check : Do the numbers of indices match?
if numel(blockStartIndices) ~= numBlocks
    error('Invalid number of baseline tasks found')
end


% Construct regions specified as latencies 
%--------------------------------------------------------------------------
regionsToKeep = []; 

for bi = 1:numBaseline 
    regionsToKeep = [regionsToKeep; [rawEEG.event(baselineStartIndices(bi)).latency, rawEEG.event(baselineEndIndices(bi)).latency]];
end

for bi = 1:numBlocks 
    regionsToKeep = [regionsToKeep; [rawEEG.event(blockStartIndices(bi)).latency, rawEEG.event(blockEndIndices(bi)).latency]];
end

% sort the rows from early to late
regionsToKeep = sortrows(regionsToKeep); 

% iterate over the number of included regions to define regions to exclude
regionsToExclude = NaN(size(regionsToKeep,1) + 1,2);
regionsToExclude(1,1)       = 1;
regionsToExclude(1,2)       = regionsToKeep(1,1) - 1;

for ri = 2:size(regionsToKeep,1) 
    
    regionsToExclude(ri,1) = regionsToKeep(ri - 1,2) + 1; 
    regionsToExclude(ri,2) = regionsToKeep(ri,1) - 1;

end 

regionsToExclude(end,1)     = regionsToKeep(end,2) + 1;
regionsToExclude(end,2)     = rawEEG.pnts;


% reject all irrelevant parts and write a new data set
trimmedEEG          = eeg_eegrej(rawEEG, regionsToExclude);
trimmedMOTION       = eeg_eegrej(rawMOTION, regionsToExclude);

if ~isfolder(trimmedEEGFileDir)
    mkdir(trimmedEEGFileDir)
end

% save
pop_saveset(trimmedEEG, 'filename',  trimmedEEGFileName, 'filepath', trimmedEEGFileDir);
pop_saveset(trimmedMOTION, 'filename', trimmedMOTIONFileName, 'filepath', trimmedMOTIONFileDir);

end


function [startIndices, endIndices] = markerwindows(markers, startMarker, endMarker)

startIndices = []; 
endIndices   = [];

% find all start events
allStarts   = find(contains(markers, startMarker));
allEnds     = find(contains(markers, endMarker));

 % iterate and find matching pairs
for Ei = 1:numel(allStarts)
    
    % find the first end marker after the start marker 
    endmarker = find(allEnds(:) > allStarts(Ei),1,'first'); 
    
    % if there is a start marker that comes earlier than the end marker,
    % discard this one
    nextstart = find(allStarts(:) > allStarts(Ei) & allStarts(:) < allEnds(endmarker), 1, 'first'); 
    
    if isempty(nextstart) && ~isempty(endmarker)
        startIndices    = [startIndices allStarts(Ei)]; 
        endIndices      = [endIndices allEnds(endmarker)]; 
    end
     
end

end