
% 1.Overview of which channels have been removed
config_param.chanGroups(1).key           = 'FM';
config_param.chanGroups(1).full_name     = 'Frontal-midline';
config_param.chanGroups(1).chan_names    = {'y1','y2','y3','y25','y32'};

config_param.chanGroups(2).key           = 'PM';
config_param.chanGroups(2).full_name     = 'Parietal-midline';
config_param.chanGroups(2).chan_names    = {'r9', 'r10', 'r11', 'r27', 'r32'};

config_param.chanGroups(3).key           = 'LT';
config_param.chanGroups(3).full_name     = 'Left-temporal';
config_param.chanGroups(3).chan_names    = {'g1', 'y16', 'r15', 'r13'};

config_param.chanGroups(4).key           = 'RT';
config_param.chanGroups(4).full_name     = 'Right-temporal';
config_param.chanGroups(4).chan_names    = {'g24','y20', 'r18', 'r20'};


numParticipants = length(allParticipants); % Replace allParticipants with actual participant list if needed
numGroups = length(config_param.chanGroups); % Number of channel groups
removedChannels = zeros(numParticipants, numGroups); % To store number of removed channels per group for each participant


for pIdx = 1:numParticipants
    Pi = allParticipants(pIdx); % Current participant
    
    [preprocessedFileName,preprocessedFileDir]      = assemble_file(config_folder.data_folder, config_folder.preprocessed_folder, ['_' bemobil_config.preprocessed_filename], Pi);
    EEG                                             = pop_loadset('filename', preprocessedFileName, 'filepath', preprocessedFileDir);
    interpChans                                     = EEG.etc.interpolated_channels;
    
    
    % Loop through each channel group
    for gIdx = 1:numGroups
        groupChans = config_param.chanGroups(gIdx).chan_names; % Get the group channel names
        totalRemoved = 0;
        
        % Check which channels in this group were removed (interpolated)
        for i = 1:length(groupChans)
            chanName = groupChans{i};
            
            % Find index of this channel in EEG.chanlocs
            chanIdx = find(strcmp({EEG.chanlocs.labels}, chanName));
            
            if ~isempty(chanIdx) && ismember(chanIdx, interpChans) % If channel is found and interpolated
                totalRemoved = totalRemoved + 1; % Increment the count for removed channels
            end
        end
        
        % Store the count of removed channels for this group and participant
        removedChannels(pIdx, gIdx) = totalRemoved;
    end
end


% Plot the heatmap
figure;
heatmapData = removedChannels;
h = heatmap(heatmapData',1:numGroups, 1:numParticipants, 'Colormap', parula, ...
    'ColorbarVisible', 'on', 'GridVisible', 'off');

% Customize heatmap labels
h.XLabel = 'Channel Groups';
h.YLabel = 'Participants';

% Set X and Y labels for heatmap
groupKeys = {config_param.chanGroups.key}; % Use group keys as labels
participantLabels = arrayfun(@(x) ['P' num2str(x)], allParticipants, 'UniformOutput', false); % Label participants
h.XDisplayLabels = groupKeys;
h.YDisplayLabels = participantLabels;

title('Number of Interpolated Channels Per Participant and Channel Group');


% 2. How much does AMICA help


% 3. Median instead of mean