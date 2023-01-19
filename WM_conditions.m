% This script compares condition-specific EEG measures
if ~exist('eeglab','var'); eeglab; end
%pop_editoptions( 'option_storedisk', 0, 'option_savetwofiles', 1, 'option_saveversion6', 0, 'option_single', 0, 'option_memmapdata', 0, 'option_eegobject', 0, 'option_computeica', 1, 'option_scaleicarms', 1, 'option_rememberfolder', 1, 'option_donotusetoolboxes', 0, 'option_checkversion', 1);

% load configurations for WM data
WM_config; 

% EEGlab study folder
studyPath           = [studyFolder '6_clustered']; 

% clustering output path 
clusterPath         = [studyFolder '6_clustered']; 

% pre/clustered file names 
preclusteredFile    = 'preclustered_MWM.study';                        
clusteredFile       = 'clustered_MWM.study';

% epoching parameters
epochWindow         = [-1 2];
overwriteEpochs     = 1; 

%% Epoch the EEG data by conditions 
%--------------------------------------------------------------------------
for subject = subjects
    
    % subject ID to string
    subjectString   = num2str(subject);
    disp(['Epoching for Subject #' subjectString]);
    
    % input file path
    eegFilePath     = [studyFolder '\4_single-subject-analysis\' subjectString '\'];

    % input file name
    eegFileName     = [subjectString '_interp_avRef_ICA.set'];
    
    % output file path
    epochedPath     = [studyFolder '7_conditions\' subjectString '\'];
    
    if ~exist(epochedPath, 'dir')
        mkdir(epochedPath);
    end
    
    epoched = [epochedPath subjectString '_guess_unrotated.set'];
    
    if overwriteEpochs || ~exist(epoched,'file')
        
        disp(['Epoching for subject ' subjectString ' EEG data.'])
        
        % load the eeg data
        EEG         = pop_loadset('filename', eegFileName, 'filepath', eegFilePath);
        
        % parse markers and add appropriate fields to events
        processedEvents = WM_events(EEG.event, subject, {'desktop', 'VR'});
        
        EEG.event           = processedEvents;
        EEG_new             = eeg_checkset(EEG, 'eventconsistency');

        % find indices of events of interest 
        guessUnrotatedIndices            = find(strcmp({EEG_new.event(:).task},'guess') & strcmp({EEG_new.event(:).status},'onset') & cellfun(@(x)isequal(x,0),{EEG_new.event(:).rotation}));  
        guessRotatedIndices              = find(strcmp({EEG_new.event(:).task},'guess') & strcmp({EEG_new.event(:).status},'onset') & cellfun(@(x)~isequal(x,0),{EEG_new.event(:).rotation}));  
     
        % epoch
        epochedEEG = pop_epoch(EEG_new, {}, epochWindow, 'epochinfo', 'yes', 'eventindices', guessUnrotatedIndices);
        
        % output file name
        epochedFile     = [subjectString '_unrotated.set'];
        
        % save on disk
        epochedEEG = pop_saveset( epochedEEG, 'filename',epochedFile,'filepath', epochedPath);
        
        % epoch
        epochedEEG = pop_epoch(EEG_new, {}, epochWindow, 'epochinfo', 'yes', 'eventindices', guessRotatedIndices);
 
        % output file name
        epochedFile     = [subjectString '_rotated.set'];
        
        % save on disk
        epochedEEG = pop_saveset( epochedEEG, 'filename',epochedFile,'filepath', epochedPath);
        
        
    else
        
        disp(['Skip epoching for subject ' num2str(subject)])
        
    end
    
    
end

% create STUDY structure 
%--------------------------------------------------------------------------

% create commands to be given as an input to the function
command         = {};
commandCount    = 1;


% iterate over all subjects to locate the data file and enter subject info
for subject = subjects(1:5)
    
    % subject ID to string
    subjectString   = num2str(subject);
    epochedPath     = [studyFolder '7_conditions\' subjectString '\'];
    
    epochedFile     = [subjectString '_unrotated.set'];
    filePath        = [epochedPath  epochedFile];
    command{commandCount}      = {'index', commandCount, 'load', filePath, 'subject', subjectString, 'condition', 'guess_unrotated'};
    commandCount = commandCount + 1;
    
    
    epochedFile     = [subjectString '_rotated.set'];
    filePath        = [epochedPath  epochedFile];
    command{commandCount}      = {'index', commandCount, 'load', filePath, 'subject', subjectString, 'condition', 'guess_rotated'};
        commandCount = commandCount + 1;
        
        
end

command{commandCount}   = {'dipselect', .4 };

STUDY = []; 
% This part does not work because of some bug in makedesign.m
[STUDY, ALLEEG] = std_editset(STUDY, [], 'name','Watermaze',...
    'task', 'MWM',...
    'filename', 'MWM.study','filepath',[studyFolder '8_test'], ...
    'commands', command); 
    
% check consistency
CURRENTSTUDY = 1; EEG = ALLEEG;

[STUDY, ALLEEG] = std_checkset(STUDY, ALLEEG);


[STUDY, ALLEEG]         = pop_loadstudy('filename', 'clustered_MWM.study', 'filepath',[studyFolder '6_clustered']);
cluster                 = STUDY.cluster; 
STUDY                   = [];
ALLEEG                  = []; 

[STUDY, ALLEEG]         = pop_loadstudy('filename', 'MWM.study', 'filepath',[studyFolder '8_test']);
STUDY.cluster           = cluster; 

[STUDY, EEG] = pop_savestudy(STUDY, EEG, 'filename','MWM_clustered.study','filepath', [studyFolder '8_test']);
disp('...clustered study saved');
% find clustering results (components for each participant)


% Search 1, 2, and 3


% Search 3 patient versus control


% Guess unrotated vs. rotated

% Guess patient vs. control 

% Guess rotation X participant group 

% Guess ego vs. allo 

