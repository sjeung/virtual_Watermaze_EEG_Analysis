% WM_main
%--------------------------------------------------------------------------
WM_config;
eeglab;

% participants 
% excluded due to technical error
% excluded due to strong nausea
allParticipants = [81001:81011, 82001:82011, 83001:83011, 84009]%[81001:81011, 82001:82011, 83001:83011];
excluded        = [81005, 82005, 83005]; % patient 81005 excluded due to psychosis   
allParticipants = setdiff(allParticipants,excluded);

%% 01.Import files 
%WM_01_import
errorParticipants = []; 
for Pi = allParticipants
    
%     %% 02. process events and trim files
%     WM_02_trim(Pi)
%     
%     %% 03. preprocess
%     WM_03_preprocess(Pi)
%     
%     %% 04. run AMICA
%     WM_04_amica(Pi)
%     
    %% 05. IC based cleaning
    %WM_05_ic_clean
    
    %     % 06. epoch
    %     WM_06_epoch(Pi)
    %
    %     % 07. channel level TFR
    try
        for Gi = 1:numel(config_param.chanGroups)
            WM_07_theta_channel(Pi,config_param.chanGroups(Gi))
        end
    catch
        errorParticipants(end+1) = Pi;
    end
    WM_08_bandpower(Pi); 
end

statArray = {}; 
for Gi = 1:numel(config_param.chanGroups)
    disp(config_param.chanGroups(Gi).key)
    [pMTL, pCTRL, statStruct] = WM_stat_ERSP('probe', 'start', config_param.chanGroups(Gi));
    
    statArray{end+1} = statStruct; 
    
    for pInd = 1:numel(pMTL)
        disp(['MTL cluster p = ' num2str(pMTL(pInd)) ' for ' config_param.chanGroups(Gi).key])
    end

    for pInd = 1:numel(pCTRL)
        disp(['CTRL cluster p = ' num2str(pCTRL(pInd)) ' for ' config_param.chanGroups(Gi).key])
    end

end
