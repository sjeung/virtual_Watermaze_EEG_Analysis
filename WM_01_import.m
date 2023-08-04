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

% check streams 
addpath('C:\Users\seinjeung\Documents\GitHub\fieldtrip\external\xdf')
streams = load_xdf('P:\Sein_Jeung\Project_Watermaze\WM_EEG_Data\source-data\81001\81001_VR.xdf'); 
cellfun(@(x) x.info.name,streams,'UniformOutput', false)
%cellfun(@(x) x.label, motionStream.info.desc.channels.channel, 'UniformOutput', false)'

WM_config

% data directory
addpath(fullfile(config_folder.data_folder, 'source-data'))
numericalIDs                        = [82010, 82011, 83001:83011]; % go over all participants


% import issues
% 82002 : run index issue
% 82009 : excluded due to nausea, missing motion stream in VR
% 82010 : desktop session issue (no motion stream found?)
% 83004 : broken recording 
% 83006 : eloc file name issue suspected - solved
% 84009 : eloc file name issue, forgot to import - solved


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
generalInfo.dataset_description.Acknowledgements    = 'We acknowledge support from Timo Berg for data collection';
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
eegInfo                                     = [];
eegInfo.coordsystem.EEGCoordinateSystem     = 'Other';
eegInfo.coordsystem.EEGCoordinateUnits      = 'mm';
eegInfo.coordsystem.EEGCoordinateSystemDescription = 'ALS with origin between ears, measured with Xensor.';

% information about the motion recording system
%--------------------------------------------------------------------------
%--------------------------------------------------------------------------
motionInfo  = [];

tracking_systems                                                    = {'Unity'};

% motion specific fields in json
motionInfo.motion = [];
motionInfo.motion.RecordingType                                     = 'continuous';

% system 1 information
motionInfo.motion.TrackingSystems(1).TrackingSystemName             = 'Unity';
motionInfo.motion.TrackingSystems(1).Manufacturer                   = 'Unity3D';
motionInfo.motion.TrackingSystems(1).ManufacturersModelName         = 'VirtualTransform';
motionInfo.motion.TrackingSystems(1).SamplingFrequencyNominal       = 60; %  If no nominal Fs exists, n/a entry returns 'n/a'. If it exists, n/a entry returns nominal Fs from motion stream.
motionInfo.motion.TrackingSystems(1).SpatialAxes                    = 'RUF';
motionInfo.motion.TrackingSystems(1).RotationRule                   = 'left-hand';
motionInfo.motion.TrackingSystems(1).RotationOrder                  = 'ZXY';

% system 2 information
motionInfo.motion.TrackingSystems(2).TrackingSystemName             = 'HTCVive';
motionInfo.motion.TrackingSystems(2).Manufacturer                   = 'HTC';
motionInfo.motion.TrackingSystems(2).ManufacturersModelName         = 'Vive Pro';
motionInfo.motion.TrackingSystems(2).SamplingFrequencyNominal       = 90; %  If no nominal Fs exists, n/a entry returns 'n/a'. If it exists, n/a entry returns nominal Fs from motion stream.
motionInfo.motion.TrackingSystems(2).SpatialAxes                    = 'RUF';
motionInfo.motion.TrackingSystems(2).RotationRule                   = 'left-hand';
motionInfo.motion.TrackingSystems(2).RotationOrder                  = 'ZXY';

% doubled because of stream name typo
motionInfo.motion.TrackingSystems(3)                                = motionInfo.motion.TrackingSystems(1); 
motionInfo.motion.TrackingSystems(2).TrackingSystemName             = 'Unity2';
motionInfo.motion.TrackingSystems(4)                                = motionInfo.motion.TrackingSystems(2); 
motionInfo.motion.TrackingSystems(2).TrackingSystemName             = 'HTCVive2';

% system 3 information : HTC Vive trackers 
motionInfo.motion.TrackingSystems(5)                                = motionInfo.motion.TrackingSystems(2); 
motionInfo.motion.TrackingSystems(6)                                = motionInfo.motion.TrackingSystems(2); 
motionInfo.motion.TrackingSystems(7)                                = motionInfo.motion.TrackingSystems(2); 
motionInfo.motion.TrackingSystems(5).TrackingSystemName             = 'Torso';
motionInfo.motion.TrackingSystems(6).TrackingSystemName             = 'LeftFoot';
motionInfo.motion.TrackingSystems(7).TrackingSystemName             = 'RightFoot';



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

subjectInfo.fields.nr.Description       = 'participant ID'; 

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
% subjectInfo.cols = {'nr',   'age',  'sex',  'rfpt', 'language', 'education','occupation' };
% subjectInfo.data = cell(numel(numericalIDs),numel(subjectInfo.cols));
% addpath(fullfile(config_folder.dataFolder, 'source-data'))

% loop over participants
for subject = numericalIDs
    
    % load subject information to check for multiple recording files
    eval(['Subject' num2str(subject)]);

    config                        = [];                                     % reset for each loop
    config.bids_target_folder     = fullfile(config_folder.data_folder, config_folder.bids_folder); % required 
    config.eeg.chanloc            = fullfile([config_folder.data_folder, '\source-data\' num2str(subject) '\' num2str(subject) '_eloc.elc']); % optional
    config.task                   = 'MorrisWaterMaze';                      % optional
    config.subject                = subject;                                % required
    
    config.eeg.stream_name        = 'BrainVision';                          % required
    
    
    for session = {'VR'} % , 'Desktop'}
        
        if strcmp(session{1}, 'VR')
            config.motion.POS.unit                      = 'm';
             
            config.motion.streams{1}.xdfname            = 'PlayerTransform';
            config.motion.streams{1}.bidsname           = 'HTCVive';
            config.motion.streams{1}.tracked_points     = {'PlayerTransform'};
            config.motion.streams{1}.positions.channel_names = {'PlayerTransform_rigid_x';'PlayerTransform_rigid_y';'PlayerTransform_rigid_z'};
            config.motion.streams{1}.quaternions.channel_names = {'PlayerTransform_quat_w';'PlayerTransform_quat_x';'PlayerTransform_quat_z';'PlayerTransform_quat_y'};
            
            config.motion.streams{2} = config.motion.streams{1};
            config.motion.streams{2}.xdfname            = 'PlayerTransfom';
            config.motion.streams{2}.bidsname           = 'HTCVive2';
            config.motion.streams{2}.tracked_points     = {'PlayerTransfom'};
            config.motion.streams{2}.positions.channel_names = {'PlayerTransfom_rigid_x';'PlayerTransfom_rigid_y';'PlayerTransfom_rigid_z'};
            config.motion.streams{2}.quaternions.channel_names = {'PlayerTransfom_quat_w';'PlayerTransfom_quat_x';'PlayerTransfom_quat_z';'PlayerTransfom_quat_y'};
            
            config.motion.streams{3} = config.motion.streams{1};
            config.motion.streams{3}.xdfname            = 'Torso';
            config.motion.streams{3}.bidsname           = 'Torso';
            config.motion.streams{3}.tracked_points     = {'Torso'};
            config.motion.streams{3}.positions.channel_names = {'Torso_rigid_x';'Torso_rigid_y';'Torso_rigid_z'};
            config.motion.streams{3}.quaternions.channel_names = {'Torso_quat_w';'Torso_quat_x';'Torso_quat_z';'Torso_quat_y'};
            
            config.motion.streams{4} = config.motion.streams{1};
            config.motion.streams{4}.xdfname            = 'LeftFoot';
            config.motion.streams{4}.bidsname           = 'LeftFoot';
            config.motion.streams{4}.tracked_points     = {'LeftFoot'};
            config.motion.streams{4}.positions.channel_names = {'LeftFoot_rigid_x';'LeftFoot_rigid_y';'LeftFoot_rigid_z'};
            config.motion.streams{4}.quaternions.channel_names = {'LeftFoot_quat_w';'LeftFoot_quat_x';'LeftFoot_quat_z';'LeftFoot_quat_y'};
            
            config.motion.streams{5} = config.motion.streams{1};
            config.motion.streams{5}.xdfname            = 'RightFoot';
            config.motion.streams{5}.bidsname           = 'RightFoot';
            config.motion.streams{5}.tracked_points     = {'RightFoot'};
            config.motion.streams{5}.positions.channel_names = {'RightFoot_rigid_x';'RightFoot_rigid_y';'RightFoot_rigid_z'};
            config.motion.streams{5}.quaternions.channel_names = {'RightFoot_quat_w';'RightFoot_quat_x';'RightFoot_quat_z';'RightFoot_quat_y'};
       
        else
            config.motion.POS.unit                      = 'vm';           
        
            config.motion.streams{1}.xdfname            = 'PlayerTransform';
            config.motion.streams{1}.bidsname           = 'Unity';
            config.motion.streams{1}.tracked_points     = {'PlayerTransform'};
            config.motion.streams{1}.positions.channel_names = {'PlayerTransform_rigid_x';'PlayerTransform_rigid_y';'PlayerTransform_rigid_z'};
            config.motion.streams{1}.quaternions.channel_names = {'PlayerTransform_quat_w';'PlayerTransform_quat_x';'PlayerTransform_quat_z';'PlayerTransform_quat_y'};
            
            config.motion.streams{2} = config.motion.streams{1};
            config.motion.streams{2}.xdfname            = 'PlayerTransfom';
            config.motion.streams{2}.bidsname           = 'Unity2';
            config.motion.streams{2}.tracked_points     = {'PlayerTransfom'};
            config.motion.streams{2}.positions.channel_names = {'PlayerTransfom_rigid_x';'PlayerTransfom_rigid_y';'PlayerTransfom_rigid_z'};
            config.motion.streams{2}.quaternions.channel_names = {'PlayerTransfom_quat_w';'PlayerTransfom_quat_x';'PlayerTransfom_quat_z';'PlayerTransfom_quat_y'};
            
        end

        for Fi = 1:numel(subjectdata.(['files', session{1}]))
            config.filename                 = fullfile(config_folder.data_folder,['\source-data\' num2str(subject) '\' subjectdata.(['files', session{1}]){Fi}]); % required
            config.session                  = session{1}; 
            if numel(subjectdata.(['files', session{1}])) > 1
                config.run                      = Fi;
            else
                if isfield(config, 'run')
                    config = rmfield(config, 'run');
                end
            end
            
            bemobil_xdf2bids(config, ...
                'general_metadata', generalInfo,...
                'motion_metadata', motionInfo, ...
                'eeg_metadata', eegInfo);
        end
    end
    
    % configuration for bemobil bids2set
    %----------------------------------------------------------------------
    config.study_folder             = config_folder.data_folder;
    config.session_names            = {'VR', 'Desktop'};
    config.set_folder               = fullfile(config_folder.data_folder, config_folder.set_folder); % required
    config.resample_freq            = 250; 
    
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
    
   config.match_electrodes_channels     = matchlocs;
   config.other_data_types              = {'motion'};
   bemobil_bids2set(config);
    
end
