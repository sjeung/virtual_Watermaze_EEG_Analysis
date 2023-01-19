% WM_main
%--------------------------------------------------------------------------
WM_config;

%% 01.Import files 
%WM_01_import

%% 02. process events and trim files 
for Pi = allParticipants
    WM_02_trim
end

%% 03. preprocess
for Pi = allParticipants
    WM_03_preprocess
end

%% 04. run AMICA
for Pi = allParticipants
    WM_04_amica
end

%% 05. IC based cleaning 
for Pi = allParticipants
    WM_05_ic_clean
end

%% 06. epoch
for Pi = allParticipants
    WM_06_epoch
end