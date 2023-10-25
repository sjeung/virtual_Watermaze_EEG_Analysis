function WM_stat_beh_eeg(sessionType, trialType, windowType, channelGroup)
WM_config

% session code (1 = desktop, 2 = VR)
if strcmp(sessionType, 'stat')
    sessionCode     = 1;
elseif strcmp(sessionType, 'mobi')
    sessionCode     = 2;
end

% participants to include or exclude
patientIDs      = 81001:81011; 
controlIDs      = [82001:82011, 83001:83011, 84009];
excludedIDs     = [81005, 82005, 83005 ...              % 81005 and matched controls excluded due to psychosis
                   81008, 82008, 83008 ...              % 81008 and matched controls excluded due to extensive spectral artefacts in data
                   82009, 83004 ];                      % 82009 nausea   
controlIDs      = setdiff(controlIDs, excludedIDs); 
patientIDs      = setdiff(patientIDs, excludedIDs); 

% patients
[bandFileName, bandFileDir]     = assemble_file(config_folder.results_folder, config_folder.band_powers_folder, ['_' trialType '_' sessionType '_' windowType  '_' channelGroup.key '_' config_folder.bandPowerFileName], Pi);
loadedVar                       = load(fullfile(bandFileDir, bandFileName), 'bandpowersp'); 
patientsPower                   = loadedVar.bandpowersp; 

% controls 
[bandFileName, bandFileDir]     = assemble_file(config_folder.results_folder, config_folder.band_powers_folder, ['_' trialType '_' sessionType '_' windowType  '_' channelGroup.key '_' config_folder.bandPowerFileName], Pi);
loadedVar                       = load(fullfile(bandFileDir, bandFileName), 'bandpowersc');
controlsPower                   = loadedVar.bandpowersc; 

% memory scores 
tableData   = readtable('P:\Sein_Jeung\Project_Watermaze\WM_EEG_Data\BEHdata_OSF.xlsx'); 
IDs         = tableData.id;
MS          = tableData.memory_score;
LP          = tableData.learning_or_probeTrial; 
SU          = tableData.setup; 

pMeans = []; 
for Pi = patientIDs
    tInds = find(IDs == Pi); 
    pInds = find(LP == 2);
    sInds = find(SU == sessionCode); 
    this = MS(intersect(intersect(tInds,pInds),sInds));
    pMeans(end+1) = mean(this); 
end

cMeans = []; 
for Pi = controlIDs
    tInds = find(IDs == Pi);
    pInds = find(LP == 2);
    sInds = find(SU == sessionCode);
    this = MS(intersect(intersect(tInds,pInds), sInds));
    cMeans(end+1) = mean(this); 
end

pMeans = pMeans';
cMeans = cMeans'; 

bandNames = {'theta', 'alpha', 'beta', 'gamma'};
figure;
for iBand = 1:4
   
%     b1 = pMeans\patientsPower(:,iBand);
%     yCalc1 = b1*pMeans;
%     scatter(pMeans,patientsPower(:,iBand))
%     hold on
%     plot(pMeans,yCalc1)
%     title(['Patients, ' bandNames{iBand}])
%     ylim([0 1])
    subplot(2,2,iBand)
    memoryScore = pMeans; power = patientsPower(:,iBand); 
    mdl = fitlm(memoryScore, power); 
    plot(mdl)
    title(['MTLR, ' sessionType, ',' trialType, ',' windowType,',' channelGroup.key '-' bandNames{iBand}]); legend('off'); xlabel('memory score'); ylabel('power')
    
    if mdl.Coefficients.pValue(2) < 0.05
        disp(['MTLR, ' sessionType, ',' trialType, ',' windowType,',' channelGroup.key '-' bandNames{iBand} ', p = ' num2str(mdl.Coefficients.pValue(2))])
    end
end

figure;
for iBand = 1:4
   
%     b1 = pMeans\patientsPower(:,iBand);
%     yCalc1 = b1*pMeans;
%     scatter(pMeans,patientsPower(:,iBand))
%     hold on
%     plot(pMeans,yCalc1)
%     title(['Patients, ' bandNames{iBand}])
%     ylim([0 1])
    subplot(2,2,iBand)
    memoryScore = cMeans; power = controlsPower(:,iBand); 
    mdl = fitlm(memoryScore,power);
    plot(mdl)
    title(['CTRL, ' sessionType, ',' trialType, ',' windowType,',' channelGroup.key '-' bandNames{iBand}]); legend('off'); xlabel('memory score'); ylabel('power')
    
    if mdl.Coefficients.pValue(2) < 0.05
        disp(['CTRL, ' sessionType, ',' trialType, ',' windowType,',' channelGroup.key '-' bandNames{iBand} ', p = ' num2str(mdl.Coefficients.pValue(2))])
    end
end
    
    
end

