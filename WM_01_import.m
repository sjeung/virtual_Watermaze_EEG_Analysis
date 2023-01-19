% WM_01_import reads in .xdf data, saves it in BIDS, and imports to .set
% to prepare the data for the next preprocessing steps
%
% Both EEG and motion data streams are resampled to 250Hz 
%
% author Sein Jeung, 2022.11.05
%--------------------------------------------------------------------------

% toolboxes
eeglab; % start eeglab to add bemobil pipeline to matlab path
rmpath(fileparts(which('ft_defaults'))) % remove the fieldtrip version that is in the pipeline
addpath('C:\Users\seinjeung\Documents\GitHub\fieldtrip') % add the modded fieldtrip

% data directory
addpath(fullfile(config_folder.dataFolder, 'source-data'))
numericalIDs                        = []; % go over all participants

% general metadata shared across all modalities
%--------------------------------------------------------------------------
%--------------------------------------------------------------------------
generalInfo = [];

% required for dataset_description.json
generalInfo.dataset_description.Name                = 'EEG and virtual transform data set for a keyboard desktop navigation task';
generalInfo.dataset_description.BIDSVersion         = 'unofficial extension';

% optional for dataset_description.json
generalInfo.dataset_description.License             = 'n/a';
generalInfo.dataset_description.Authors             = {"Jeung, S.", "Iggena, D.", "Maier, P.", "Ploner, C.", "Finke, C.", "Gramann, K."};
generalInfo.dataset_description.Acknowledgements    = 'n/a';
generalInfo.dataset_description.Funding             = {"n/a"};
generalInfo.dataset_description.ReferencesAndLinks  = {"n/a"};
generalInfo.dataset_description.DatasetDOI          = 'n/a';

% general information shared across modality specific json files
generalInfo.InstitutionName                         = 'Technische Universitaet zu Berlin';
generalInfo.InstitutionalDepartmentName             = 'Biological Psychology and Neuroergonomics';
generalInfo.InstitutionAddress                      = 'Strasse des 17. Juni 135, 10623, Berlin, Germany';
generalInfo.TaskDescription                         = 'MTL patients and double-matched controles performed a human-scale virtual Morris Watermaze task in desktop and mobile immersive VR setups.';

% information about the eeg recording system
%--------------------------------------------------------------------------
%--------------------------------------------------------------------------
eegInfo     = [];
eegInfo.coordsystem.EEGCoordinateSystem = 'Other';
eegInfo.coordsystem.EEGCoordinateUnits = 'mm';
eegInfo.coordsystem.EEGCoordinateSystemDescription = 'ALS with origin between ears, measured with Xensor.';


% information about the motion recording system
%--------------------------------------------------------------------------
%--------------------------------------------------------------------------
motionInfo  = [];

tracking_systems                                    = {'Unity'};

% motion specific fields in json
motionInfo.motion = [];
motionInfo.motion.RecordingType                     = 'continuous';

% system 1 information
motionInfo.motion.TrackingSystems(1).TrackingSystemName             = 'Unity';
motionInfo.motion.TrackingSystems(1).Manufacturer                   = 'Unity3D';
motionInfo.motion.TrackingSystems(1).ManufacturersModelName         = 'VirtualTransform';
motionInfo.motion.TrackingSystems(1).SamplingFrequencyNominal       = 60; %  If no nominal Fs exists, n/a entry returns 'n/a'. If it exists, n/a entry returns nominal Fs from motion stream.
motionInfo.motion.TrackingSystems(1).SpatialAxes                    = 'RUF';
motionInfo.motion.TrackingSystems(1).RotationRule                   = 'left-hand';
motionInfo.motion.TrackingSystems(1).RotationOrder                  = 'ZXY';

% system 2 information
motionInfo.motion.TrackingSystems(1).TrackingSystemName             = 'HTCVive';
motionInfo.motion.TrackingSystems(1).Manufacturer                   = 'HTC';
motionInfo.motion.TrackingSystems(1).ManufacturersModelName         = 'Vive Pro';
motionInfo.motion.TrackingSystems(1).SamplingFrequencyNominal       = 90; %  If no nominal Fs exists, n/a entry returns 'n/a'. If it exists, n/a entry returns nominal Fs from motion stream.
motionInfo.motion.TrackingSystems(1).SpatialAxes                    = 'RUF';
motionInfo.motion.TrackingSystems(1).RotationRule                   = 'left-hand';
motionInfo.motion.TrackingSystems(1).RotationOrder                  = 'ZXY';


% participant information 
%--------------------------------------------------------------------------
%--------------------------------------------------------------------------
% here describe the fields in the participant file
% for numerical values  : 
%       subjectData.fields.[insert your field name here].Description    = 'describe what the field contains';
%       subjectData.fields.[insert your field name here].Unit           = 'write the unit of the quantity';
% for values with discrete levels :
%       subjectData.fields.[insert your field name here].Description    = 'describe what the field contains';
%       subjectData.fields.[insert your field name here].Levels.[insert the name of the first level] = 'describe what the level means';
%       subjectData.fields.[insert your field name here].Levels.[insert the name of the Nth level]   = 'describe what the level means';
%--------------------------------------------------------------------------
subjectInfo = [];

subjectInfo.fields.nr.Description      = 'age of the participant'; 

subjectInfo.fields.age.Description      = 'age of the participant'; 
subjectInfo.fields.age.Unit             = 'years'; 

subjectInfo.fields.sex.Description      = 'sex of the participant'; 
subjectInfo.fields.sex.Levels.M         = 'male'; 
subjectInfo.fields.sex.Levels.F         = 'female'; 

subjectInfo.fields.rfpt.Description     = 'reference frame proclivity';
subjectInfo.fields.rfpt.Levels.turner   = 'participant was classified as turner';
subjectInfo.fields.rfpt.Levels.nonturner     = 'participnat was classified as nonturner'; 

subjectInfo.fields.language.Description     = 'native language of the participant';

% 1: none, 2: secondary school (haupt/volk), 3: secondary school (real/poly) 4: highschool (fachabi) 5: uni (hochschulabschluss)
subjectInfo.fields.education.Description            = 'highest acieved education level of the participant';
subjectInfo.fields.education.Levels.none            = 'no formal education';
subjectInfo.fields.education.Levels.secondaryHV     = 'secondary school (Haupt, Volkschule)';
subjectInfo.fields.education.Levels.secondaryRP     = 'secondary school (Real, Poly)';
subjectInfo.fields.education.Levels.highschool      = 'highschool (Fachabi)';
subjectInfo.fields.education.Levels.university      = 'university (Hochschulabschluss)';

% 1: school student, 2: college/uni, 3: employed, 4: other 
subjectInfo.fields.occupation.Description           = 'current occupation of the participant';
subjectInfo.fields.occupation.Levels.school         = 'school student';
subjectInfo.fields.occupation.Levels.collegeuni     = 'college or university student';
subjectInfo.fields.occupation.Levels.employed       = 'employed';
subjectInfo.fields.occupation.Levels.other          = 'other';

% subject information
%--------------------------------------------------------------------------
% names of the columns - 'nr' column is just the numerical IDs of subjects
%                         do not change the name of this column
subjectInfo.cols = {'nr',   'age',  'sex',  'rfpt', 'language', 'education','occupation' };
subjectInfo.data = cell(numel(numericalIDs),numel(subjectInfo.cols));
addpath(fullfile(studyFolder, '0_source-data')) 

for Si = 1:numel(numericalIDs)
    eval(['sub' num2str(numericalIDs(Si)) '_info']);
    subjectInfo.data{Si,1} = numericalIDs(Si);
    for Ci = 2:numel(subjectInfo.cols)
        if strcmp(subjectInfo.cols{Ci}, 'education')
            switch subjectdata.education
                case 1
                    subjectInfo.data{Si,Ci} = 'none'; 
                case 2
                    subjectInfo.data{Si,Ci} = 'secondaryHV'; 
                case 3
                    subjectInfo.data{Si,Ci} = 'secondaryRP'; 
                case 4
                    subjectInfo.data{Si,Ci} = 'highschool'; 
                case 5 
                    subjectInfo.data{Si,Ci} = 'university'; 
                otherwise 
                    subjectInfo.data{Si,Ci} = 'n/a'; 
            end
        elseif strcmp(subjectInfo.cols{Ci}, 'occupation')
            switch subjectdata.occupation
                case 1 
                    subjectInfo.data{Si,Ci} = 'school'; 
                case 2
                    subjectInfo.data{Si,Ci} = 'collegeuni'; 
                case 3
                    subjectInfo.data{Si,Ci} = 'employed'; 
                case 4
                    subjectInfo.data{Si,Ci} = 'other'; 
                otherwise
                    subjectInfo.data{Si,Ci} = 'n/a';
            end
        else
            subjectInfo.data{Si,Ci} = subjectdata.(subjectInfo.cols{Ci});
        end
    end
end

% loop over participants
for subject = numericalIDs
    
    config                        = [];                                     % reset for each loop
    config.bids_target_folder     = fullfile(studyFolder, '\1_BIDS-data'); % required 
    config.eeg.chanloc            = fullfile([studyFolder, '\source-data\sub' num2str(subject) '\sub' num2str(subject) '_VN_E1_eloc.elc']); % optional
    config.task                   = 'VirtualNavigation';                    % optional
    config.subject                = subject;                                % required
    
    config.eeg.stream_name        = 'BrainVision';                          % required
    
    config.motion.streams{1}.xdfname            = 'PlayerTransform';
    config.motion.streams{1}.bidsname           = 'Unity';
    config.motion.streams{1}.tracking_system    = 'Unity';
    config.motion.streams{1}.tracked_points     = {'PlayerTransform'};
    config.motion.streams{1}.positions.channel_names = {'PlayerTransform_rigid_x';'PlayerTransform_rigid_y';'PlayerTransform_rigid_z'};
    config.motion.streams{1}.quaternions.channel_names = {'PlayerTransform_quat_w';'PlayerTransform_quat_x';'PlayerTransform_quat_y';'PlayerTransform_quat_z'};
    config.motion.POS.unit                      = 'vm';
    
    % load subject information to check for multiple recording files  
    eval(['sub' num2str(subject) '_info']);
  
    for Fi = 1:numel(subjectdata.files)
        config.filename                 = fullfile([studyFolder, '\source-data\sub' num2str(subject) '\sub' num2str(subject) '_' subjectdata.files{Fi} '.xdf']); % required
        if numel(subjectdata.files) > 1
            config.run                      = Fi;
        end
        bemobil_xdf2bids(config, ...
            'general_metadata', generalInfo,...
            'participant_metadata', subjectInfo,...
            'motion_metadata', motionInfo, ...
            'eeg_metadata', eegInfo);
    end
    
    % configuration for bemobil bids2set
    %----------------------------------------------------------------------
    config.study_folder             = studyFolder;
    config.session_names            = 'VirtualNavigation';
    config.set_folder               = fullfile([config_folder.dataFolder, '\1_basic-data\sub' num2str(subject) '\sub' num2str(subject) '_' subjectdata.files{Fi} '.xdf']); % required
    config.resample_freq            = 500; 
    config.overwrite                = 'on'; 
    % match labels in electrodes.tsv and channels.tsv
    matchlocs = {};
    letters = {'g', 'y', 'r', 'w'};
    for Li = 1:numel(letters)
        letter = letters{Li};
        for Ni = 1:32
            matchlocs{Ni + (Li-1)*32,1} = [letter num2str(Ni)]; % channel name in electrodes.tsv
            matchlocs{Ni + (Li-1)*32,2} = ['BrainVision RDA_' upper(letter) num2str(Ni, '%02.f')]; % channel name in channels.tsv
        end
    end
    
   config.match_electrodes_channels = matchlocs;
   if subject == 29
       config.match_electrodes_channels{128,1} = ''; % subject 29 missing W32 location 
   end
    
   bemobil_bids2set(config);
    
end
