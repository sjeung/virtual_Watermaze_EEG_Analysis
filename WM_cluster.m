% Create a study with watermaze data and cluster 
%

%% Directory Management and Specifications 
%--------------------------------------------------------------------------
if ~exist('eeglab','var'); eeglab; end
pop_editoptions( 'option_storedisk', 0, 'option_savetwofiles', 1, 'option_saveversion6', 0, 'option_single', 0, 'option_memmapdata', 0, 'option_eegobject', 0, 'option_computeica', 1, 'option_scaleicarms', 1, 'option_rememberfolder', 1, 'option_donotusetoolboxes', 0, 'option_checkversion', 1);

% load configurations for WM data
WM_config; 

% EEGlab study folder
studyPath           = [studyFolder '6_clustered']; 

% clustering output path 
clusterPath         = [studyFolder '6_clustered']; 

% pre/clustered file names 
preclusteredFile    = 'preclustered_MWM.study';                        
clusteredFile       = 'clustered_MWM.study';

% parameters for continuous cleaning 
cleaning_epoch_length       = 1; 
cleaning_epoch_overlap      = 0.5; 
cleaning_epoch_buffer       = 0.25; 
cleaning_fixed_threshold    = 0.1; 
cleaning_weights            = [1 1 1 1]; 
cleaning_use_kneepoint      = 0; 
cleaning_kneepoint_offset   = 0; 
cleaning_highpass_cutoff    = 10; 
cleaning_plot               = 1; 

% epoching parameters  
overwriteEpochs     = 0;
newStudy            = 0;
precompute          = 'off'; 
precluster          = 0; 

epochWindow         = [-1 2];
epochLength         = epochWindow(2) - epochWindow(1);

% for ERSP and spectra used for preclustering
timewindow          = [0 1000];

% weights for preclustering
clustering_weights.dipoles              = 6;
clustering_weights.scalp_topographies   = 1;
clustering_weights.spectra              = 3;
clustering_weights.ERSPs                = 1;
clustering_weights.ERPs                 = 1;

% residual variance threshold for clustering
thresholdRV                             = 0.4;

% minimum proportion of subjects in the cluster 
minProportionSubjects                   = .5; 
 
% fft parameters
% fft_cycles = [3 0.5];
% fft_freqrange = [3 100];
% fft_padratio = 2;
% fft_freqscale = 'linear';
%                                          
% fft_alpha = NaN;
% fft_powbase = NaN;
% fft_c_type = 'ersp';
% n_freqs = 98;

% clustering parameters
freqRange               = [2 80]; 
n_clust                 = 50;
n_iterations            = 20;
outlier_sigma           = 3; 
ROIName                 = 'RSC';
ROI.x                   = 0;
ROI.y                   = -55;
ROI.z                   = 10;
cluster_ROI_talairach   =  ROI; 


%% Epoch the EEG data (continous epoching of all phases in the experiment)
%--------------------------------------------------------------------------

for subject = subjects
    
    EEG = []; EEG_new = []; epochedEEG = []; ALLEEG = [];
   
    % subject ID to string
    subjectString   = num2str(subject);
    disp(['Epoching for Subject #' subjectString]);
    
    % input file path
    eegFilePath     = [studyFolder '\4_single-subject-analysis\' subjectString '\'];

    % input file name
    eegFileName     = [subjectString '_interp_avRef_ICA.set'];
    
    % output file path
    epochedPath     = [studyFolder '5_epoched\' subjectString '\'];
    
    if ~exist(epochedPath, 'dir')
        mkdir(epochedPath);
    end
  
    epoched = [epochedPath subjectString '_continuous.set'];
   
    if overwriteEpochs || ~exist(epoched,'file')
        
        disp(['Epoching for subject ' subjectString ' EEG data.'])
        
        % load the eeg data
        EEG         = pop_loadset('filename', eegFileName, 'filepath', eegFilePath);
        

        % parse markers and add appropriate fields to events 
        processedEvents = WM_events(EEG.event, subject, {'desktop', 'VR'});
        
        EEG.event       = processedEvents;
        EEG             = eeg_checkset(EEG);
        
        % find the first and the last markers in each session in the experiment 
        %------------------------------------------------------------------
        % find the boundary marker first 
        boundaryEventIndex  = find(strcmp({EEG.event(:).type},'boundary')); 
        
        % throw an error if there is more or fewer boundary events than 1 
        if numel(boundaryEventIndex) ~= 1
            error(['Invalid number of boundary events for participant ' num2str(subject)])
        end 
        
        % find the first and last markers in each session 
        sessionStartIndex(1)        = 1; 
        sessionEndIndex(1)           = boundaryEventIndex - 1; 
        sessionStartIndex(2)        = boundaryEventIndex + 1; 
        sessionEndIndex(2)          = numel(EEG.event);
        
        % initialize a variable storing events to be added
        newEvents              = [];
       
        % iterate over sessions and generate continous epochs  
        %------------------------------------------------------------------
        for session = 1:2
        
            sessionStartLatency     = EEG.event(sessionStartIndex(session)).latency; 
            sessionEndLatency       = EEG.event(sessionEndIndex(session)).latency; 
 
            % session duration in seconds
            duration                = (sessionEndLatency - sessionStartLatency)/EEG.srate;
            
            % count the number of sessions that can fit in the session 
            nEpochsInTrial          = floor(duration/epochLength);
            
            % iterate over the number of epochs in a session 
            for epochIndex          = 1:nEpochsInTrial
                newEvents(end+1).type       = 'continuous';
                newEvents(end).latency      = sessionStartLatency + epochLength*(epochIndex-1)*EEG.srate - epochWindow(1)*EEG.srate;
            end
         
        end
        
        % assign additional field values to the newly generated epochs
        [newEvents.task]          = deal('undefined');
        [newEvents.status]        = deal('undefined');
        
        % add new events with modified types, latencies, and status fields
        taskFieldValues     = {newEvents(:).task};
        statusFieldValues   = {newEvents(:).status};
        EEG                 = eeg_addnewevents(EEG, {[newEvents(:).latency]}, {'continuous'}, {'task' 'status'}, {char(taskFieldValues), char(statusFieldValues)});
        EEG                 = eeg_checkset(EEG, 'eventconsistency');
        
        % Continuous cleaning by means of automatic detection of bad epochs
        [ ALLEEG EEG CURRENTSET ] = bemobil_reject_continuous(ALLEEG, EEG, CURRENTSET,...
            cleaning_epoch_length, cleaning_epoch_overlap, cleaning_epoch_buffer, cleaning_fixed_threshold, cleaning_weights,...
            cleaning_use_kneepoint, cleaning_kneepoint_offset, cleaning_highpass_cutoff, cleaning_plot);
        
        % epoch
        epochedEEG = pop_epoch(EEG, {'continuous'}, epochWindow, 'epochinfo', 'yes');
        
        % output file name
        epochedFile     = [subjectString '_continuous.set'];
        
        % save on disk
        epochedEEG = pop_saveset( epochedEEG, 'filename',epochedFile,'filepath', epochedPath);
        
    else
        
        disp(['Skip epoching for subject ' num2str(subject)])
        
    end
    
    
end


epochedEEG = []; 
EEG = []; 
ALLEEG  = [];

%% STUDY creation
%--------------------------------------------------------------------------
if newStudy
    
    % create commands to be given as an input to the function
    command         = {};
    commandCount    = 1;
   
    
    % iterate over all subjects to locate the data file and enter subject info
    for subject = subjects
        
        % subject ID to string
        subjectString   = num2str(subject);
        epochedPath     = [studyFolder '5_epoched\' subjectString '\'];
        
        epochedFile     = [subjectString '_continuous.set'];
        filePath        = [epochedPath  epochedFile];
        command{commandCount}      = {'index', commandCount, 'load', filePath, 'subject', subjectString, 'condition', 'continuous'};
        commandCount = commandCount + 1;
        
    end
    
    command{commandCount}   = {'dipselect', thresholdRV };
    
    % This part does not work because of some bug in makedesign.m
    [STUDY, ALLEEG] = std_editset(STUDY, [], 'name','MWM',...
        'task', 'VirtualMWM',...
        'filename', 'Watermaze.study','filepath',[studyFolder '5_epoched'], ...
        'commands', command);
    
    % check consistency
    CURRENTSTUDY = 1; EEG = ALLEEG; 
    
    [STUDY, ALLEEG] = std_checkset(STUDY, ALLEEG);
    

else
    
    [STUDY, ALLEEG]      = pop_loadstudy('filename', 'Watermaze.study', 'filepath',[studyFolder '5_epoched']);
    EEG = ALLEEG;
    
end


%% Preclustering
%--------------------------------------------------------------------------
% precomputing
[STUDY, ALLEEG]      = std_precomp(STUDY, ALLEEG,'components','recompute',precompute,'spec','on', 'specparams',{}, 'ersp', 'on', 'erspparams',{'cycles',[3 0.5] , 'nfreqs',100, 'freqs',[3 70] ,'alpha',0.01},'scalp','on','erp','on','itc','on');


if precluster
    
    % preclustering
    [STUDY, ALLEEG, EEG] = bemobil_precluster(STUDY, ALLEEG, EEG, clustering_weights, freqRange, timewindow, preclusteredFile, clusterPath);
    
else
    
    [STUDY, ALLEEG]      = pop_loadstudy('filename', preclusteredFile, 'filepath',clusterPath);
    EEG = ALLEEG;

end


%% Clustering
%--------------------------------------------------------------------------
preclustparams          = STUDY.bemobil.clustering.preclustparams;

clustering_solutions    = bemobil_repeated_clustering(STUDY, ALLEEG, n_iterations, n_clust, outlier_sigma, preclustparams);

[cluster_multivariate_data, data_plot] = bemobil_create_multivariate_data_from_cluster_solutions(STUDY,ALLEEG,clustering_solutions,cluster_ROI_talairach);

% store the multivariate data (saves the best fitting cluster for each solution)
STUDY.cluster_multivariate_data = cluster_multivariate_data;

% choose a solution 
cluster_multivariate_data       = STUDY.cluster_multivariate_data;
candidates                      = find(cluster_multivariate_data.data(:,1) > numel(subjects)*minProportionSubjects);
[minValue, minIndex]            = min(cluster_multivariate_data.data(candidates,9)); 
bestSolutionIndex               = candidates(minIndex);  
bestClusterIndex                = cluster_multivariate_data.best_fitting_cluster(bestSolutionIndex); 
STUDY.cluster                   = clustering_solutions.(['solution_' num2str(bestSolutionIndex)]);

% multivariate_data(:,1) = best_fitting_cluster_n_subjects;
% multivariate_data(:,2) = best_fitting_cluster_n_ICs;
% multivariate_data(:,3) = best_fitting_cluster_n_ICs./best_fitting_cluster_n_subjects;
% multivariate_data(:,4) = best_fitting_cluster_normalized_spread;
% multivariate_data(:,5) = best_fitting_cluster_mean_rv;
% multivariate_data(:,6) = best_fitting_cluster_x;
% multivariate_data(:,7) = best_fitting_cluster_y;
% multivariate_data(:,8) = best_fitting_cluster_z;
% multivariate_data(:,9) = best_fitting_cluster_distance;


% Compute dipole centroids 
STUDY = bemobil_dipoles(STUDY,ALLEEG);

% save study 
[STUDY, EEG] = pop_savestudy(STUDY, EEG, 'filename',clusteredFile,'filepath',clusterPath);
disp('...clustered study saved');

%--------------------------------------------------------------------------
% 2.2. Plot the best fitting cluster
%--------------------------------------------------------------------------
STUDY   = [];
EEG     = [];
ALLEEG  = []; 

% load study 
[STUDY, ALLEEG] = pop_loadstudy('filename',clusteredFile,'filepath',clusterPath);
disp('...clustered study loaded');

% choose a solution 
cluster_multivariate_data       = STUDY.cluster_multivariate_data;
candidates                      = find(cluster_multivariate_data.data(:,1) > numel(subjects)*minProportionSubjects);
[minValue, minIndex]            = min(cluster_multivariate_data.data(candidates,9)); 
bestSolutionIndex               = candidates(minIndex);  
bestClusterIndex                = cluster_multivariate_data.best_fitting_cluster(bestSolutionIndex); 

% Cluster visualization
%--------------------------------------------------------------------------
clusters = 3:length(STUDY.cluster); % clusters to plot
title = "Cluster Dipoles"; % figure title
plot_params = [2,2,1]; % [nrows,ncols,subplot]
views = [1,2,3,4]; % 1=top,2=side,3=rear,4=oblique
cols = hsv(length(clusters));

% std_dipoleclusters function call:
std_dipoleclusters(STUDY,ALLEEG,"clusters",clusters,...
    "title",title,"viewnum",views,...
    "centroid","off","colors",cols);

% saveas(gcf,['Params_' ...
%     'dip_' num2str(clustering_weights.dipoles) ',' ...
%     'scalp_' num2str(clustering_weights.scalp_topographies) ',' ...
%     'spec_' num2str(clustering_weights.spectra) ',' ...
%     'ERSP_' num2str(clustering_weights.ERSPs) ...
%     '.png']);

% std_dipoleclusters function call:
std_dipoleclusters(STUDY,ALLEEG,"clusters",bestClusterIndex,...
    "title",title,"viewnum",views,...
    "centroid","off","colors",cols(bestClusterIndex,:));







