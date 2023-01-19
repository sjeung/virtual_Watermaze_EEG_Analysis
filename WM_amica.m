% This script executes batch processing of participant EEG data

% directory management 
if ~exist('eeglab','var'); eeglab; end
if ~exist('mobilab','var'); runmobilab; end
addpath(genpath('P:\Sein_Jeung\NoiseTools'))
pop_editoptions( 'option_storedisk', 0, 'option_savetwofiles', 1, 'option_saveversion6', 0, 'option_single', 0, 'option_memmapdata', 0, 'option_eegobject', 0, 'option_computeica', 1, 'option_scaleicarms', 1, 'option_rememberfolder', 1, 'option_donotusetoolboxes', 0, 'option_checkversion', 1);

% load data 
WM_config
addpath(subjectInfoPath);

% edit elocs
elocPaths     = cell(1,numel(subjects)); 
elocIDIndex = 1; 

for subject = subjects
    elocPaths{elocIDIndex} = [subjectInfoPath '\' num2str(subject) '\' num2str(subject) '_eloc.elc']; 
    elocIDIndex = elocIDIndex + 1; 
end

eloc_edit(elocPaths, elocNewSuffix, fiducials)


%% processing loop

for subject = subjects
   
  disp(['Subject #' num2str(subject)]);

  STUDY = []; CURRENTSTUDY = 0; ALLEEG = []; EEG=[]; CURRENTSET=[];
  force_recompute = 0;
  
  % load recording notes for processing participant data 
  eval(['Subject' num2str(subject)])
  bemobil_config.filenames = [subjectdata.filesDesktop subjectdata.filesVR];  
  
  for namei = 1:numel(bemobil_config.filenames)
      
      nameString                            = bemobil_config.filenames{namei};
      bemobil_config.filenames{namei}       = nameString(7:end-4);
 
  end
  
  % import data and preprocess (no filtering)
  [ALLEEG, EEG_interp_avRef, CURRENTSET] = bemobil_process_all_mobilab(subject, bemobil_config, ALLEEG, CURRENTSET, mobilab, force_recompute);
  
  
  % AMICA on the merged data
  [ALLEEG, EEG_AMICA_final, CURRENTSET] = bemobil_process_all_AMICA_selective_cleaning(ALLEEG, EEG_interp_avRef, CURRENTSET, subject, bemobil_config);


 end