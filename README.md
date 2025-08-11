# Project virtual Morris Water Maze : EEG analysis  

This repository contains analysis and visualization scripts for virtual Morris Watermaze data set
collected 2019-2020 at the Berlin Mobile Brain-Body Imaging Lab, 
in collaboration between TU Berlin department of Biopsychology and Neuroergonomics and Charite department of Neurology.
The batch of Matlab script performs preprocessing of the EEG data and eBOSC analysis, to capture the oscillatory scalp EEG activity during active navigation. The results are to be reported in a manuscript in preparation (citation to be added upon acceptance). The analysis results on the motion data were published in Iggena et al. (2023, see below for full citation).    
  
The data set contains 128 channels EEG data (BrainProducts MOVE) collected alongside HTC-Vive motion captuer of HMD, Torso, and both feet.
10 patients with right medial-temporal lesions and navigated in mobile immersive VR environment and simulated desktop-based environment 
performing a human-scale variant of the Morris Water Maze task. 
Two matched controls with comparable age, sex, and education level for each patient performed the same task (N controls = 20). 

## How to use the scripts    
Modify *WM_config.m* and *WM_bemobil_config.m* to configure paths    
Script *WM_main.m* executes the preprocessing and extraction of p-episodes using eBOSC    
*statistics/LMEs.R* and *statistics/LEMs_BEH.R* scripts implments the statistical analysis of the results    

## Dependencies 
- Matlab 2021  
- EEGLAB v14.1.0
- FieldTrip 20230309
- [eBOSC](https://github.com/jkosciessa/eBOSC)
- R v4.4.2

## Data Availability
BOSC results are available on [OSF](https://osf.io/3jv78/).

## Author contributions
Sein Jeung+, Deetje Iggena+, Berrak Hosgoren, Patrizia M. Maier, Christoph J. Ploner, Carsten Finke*, & Klaus Gramann*    
+,* : equal contributions
  
- Conceptualization: D.I., S.J., K.G., C.J.P., and C.F.; Methodology: D.I., S.J., K.G.
- Participant recruitment: D.I., C.J.P., and C.F.    
- Data acquisition: D.I., S.J., and P.M.M.    
- Data analysis: S.J., D.I. and B.H.    
- Statistical analysis: S.J., and D.I.    
- Visualization: S.J. and D.I.    
- Supervision: C.J.P., C.F., and K.G.    
- Writing—original draft: S.J.    
- Writing—review & editing: S.J., D.I., P.M.M., K.G., C.F., C.J.P., and K.G.    
- Technical equipment: K.G.; Funding: C.J.P. and C.F. All authors approved the final manuscript.

## Related publication
Iggena, D., Jeung, S., Maier, P.M. et al. Multisensory input modulates memory-guided spatial navigation in humans. Commun Biol 6, 1167 (2023). https://doi.org/10.1038/s42003-023-05522-6

## Funding
This study was funded by the Deutsche Forschungsgemeinschaft DFG, German Research Foundation—Project number 327654276—SFB 1315

## Acknowledgements
We thank Tore Knabe for supporting implemention of the virtual environment.    
We thank Yiru Chen and Timotheus Berg for assisting data collection.    

## License
MIT License
