# Project virtual Morris Water Maze - EEG analysis (work in progress)

This repository contains analysis and visualization scripts for virtual Morris Watermaze data set
collected 2019-2020 at the Berlin Mobile Brain-Body Imaging Lab, 
in collaboration between TU Berlin department of Biopsychology and Neuroergonomics and Charite department of Neurology.
The batch of Matlab script performs preprocessing of the EEG data and ERS/ERDS analysis alongside the analysis of motion capture data.
Data set contains 128 channels EEG data (BrainProducts) collected alongside HTC-Vive motion captuer of HMD, Torso, and both feet.
10 patients with right medial-temporal lesions and navigated in mobile immersive VR environment and simulated desktop-based environment 
performing a human-scale variant of the Morris Water Maze task. Two matched controls with comparable age, sex, and education level for each patient performed the same task (N controls = 20). 

## How to use the scripts
Data directory is to be configured in ... WM_EEG_main.m calls other scripts ... (Work in progress) 

## Notes on data set   
82002 : run index issues  
82009 : excluded due to nausea  
82010 : first half of desktop session (desktop_B_rec1.xdf) misses HMD stream  
	fixed by replacing it with dummy stream in import  
83004 : broken recordings  
81005/82005/83005 : excluded due to development of symptoms that meet exclusion critera in the patient  

## Data Availability
BOSC results are available on [OSF](https://osf.io/3jv78/).

## Dependencies (WIP)
Matlab   
EEGLAB  
FieldTrip  
eBOSC
... 

## Authors (role assignments are tentative)
Sein Jeung (TUB) collected the data, implemented the EEG analysis.    
Deetje Iggena (CHARITE) collected the data, evaluated the analysis results.    
Partizia Maier (CHARITE) supported data collection and provided theoretical feedback.   
Berrak Hosgoren (Uni Padova) supported EEG preprocessing and initial evaluation of data quality.   
Christoph Ploner (CHARITE), Carsten Finke (CHARITE), Klaus Gramann (TUB) supervised the project, were involved in conception of the project as well as provided theoretical feedback. 

### Funding
This study was funded by the Deutsche Forschungsgemeinschaft DFG, German Research Foundation—Project number 327654276—SFB 1315

### Acknowledgements
Tore Knabe supported implemention of the virtual environment   

## License
GNU General Public License v2.0
