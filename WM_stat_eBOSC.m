function [pValVec, omegaSquareds, Fs, postP, postFs, postDF1, postDF2] = WM_stat_eBOSC(trial, timeWindow, chanGroup, parameter, runPosthoc)

if ~exist('runPosthoc','var')
    runPosthoc = false;
end

if strcmp(parameter, 'pepisodes')   
    ylims = [0 0.7]; 
else
    ylims = [2 6]; 
end

% 3 p values (interaction, group, setup) and 5 tests
pValVec                 = NaN(3,5);
omegaSquareds           = NaN(3,5);
Fs                      = NaN(3,5);

% post-hoc results 
postP = NaN(4,5); postFs = NaN(4,5); postDF1 = NaN(4,5); postDF2 = NaN(4,5); 
        

if strcmp(trial, 'stand') ||  strcmp(trial, 'walk')
    isBaseline = 1; 
else
    isBaseline = 0; 
end

WM_config;
addpath(genpath('P:\Sein_Jeung\Tools\FDR'))
groupLabels = {'Theta', 'Alpha', 'Beta', 'Gamma', 'High Gamma'};

% this needs to match WM_stat_ERSP
patientIDs      = 81001:81011; 
controlIDs      = [82001:82011, 83001:83011, 84009];
excludedIDs     = [81005, 82005, 83005 ...      % 81005 and matched controls excluded due to psychosis
                   82009 ];                     % 82009 nausea              
controlIDs      = setdiff(controlIDs, excludedIDs); 
patientIDs      = setdiff(patientIDs, excludedIDs); 
               
% Read in the data
data        = readtable('P:\Sein_Jeung\Project_Watermaze\WM_EEG_Data\BEHdata_OSF.xlsx');

try
    load(fullfile('P:\Sein_Jeung\Project_Watermaze\WM_EEG_Results\BOSC', ['BOSC-comp_' trial '_' timeWindow '_' chanGroup.key '.mat']), 'pEpisodesVec', 'bandpowerVec', 'freqAxis');
    preLoaded = 1; 
catch
    resultsStat = load(fullfile('P:\Sein_Jeung\Project_Watermaze\WM_EEG_Results\BOSC', ['BOSC_' trial '_stat_' timeWindow '_' chanGroup.key '.mat']), 'boscOutputs');
    resultsMobi = load(fullfile('P:\Sein_Jeung\Project_Watermaze\WM_EEG_Results\BOSC', ['BOSC_' trial '_mobi_' timeWindow '_' chanGroup.key '.mat']), 'boscOutputs');
    freqAxis = resultsStat.boscOutputs{1}.config.eBOSC.F; 
    preLoaded = 0; 
end

% Preallocate vectors for demographics
ids         = [patientIDs controlIDs patientIDs controlIDs]; 
numIds      = length([patientIDs controlIDs]);
group       = zeros(numIds, 1);
sex         = group; age = group; education = group; sessionOrder = group;
setup       = [ones(1,numIds) ones(1,numIds)*2]'; 

% Loop through each unique ID and extract demographics
for i = 1:numIds
    id              = ids(i);
    
    % Find the first row where the ID matches
    firstRowIdx     = find(data.id == id, 1, 'first');
    
    % Extract the demographic information
    group(i)        = data.group(firstRowIdx);                  % Extract group
    sex(i)          = data.sex(firstRowIdx);                    % Extract sex
    age(i)          = data.age(firstRowIdx);                    % Extract age
    education(i)    = data.education_years(firstRowIdx);        % Extract education years
    sessionOrder(i) = data.session(firstRowIdx);                % Extract session order
end

group = [group; group]; sex = [sex; sex]; age = [age; age]; education = [education; education]; sessionOrder = [sessionOrder; sessionOrder];

% Combine demographics into a table
demographicsTable = table(ids', group, setup, sex, age, education, sessionOrder, ...
    'VariableNames', {'ID', 'Group', 'Setup', 'Sex', 'Age', 'Education', 'SessionOrder'});

% Convert categorical variables if needed
demographicsTable.Group         = categorical(demographicsTable.Group);
demographicsTable.Sex           = categorical(demographicsTable.Sex);
demographicsTable.Setup         = categorical(demographicsTable.Setup);
demographicsTable.SessionOrder  = categorical(demographicsTable.SessionOrder);
demographicsTable.ID            = categorical(demographicsTable.ID);

%--------------------------------------------------------------------------
if preLoaded == 0
    pEpisodesVec = NaN(60,5);
    bandpowerVec = NaN(60,5);
end

for Fi = 1:numel(config_param.band_names)
    
    fBandRange = [find(freqAxis >= config_param.FOI_lower(Fi), 1, 'first') , find(freqAxis < config_param.FOI_upper(Fi), 1,'last')]; 
    
    if preLoaded == 0
        for Pi = 1:30
            pEpisodesVec(Pi,Fi) = squeeze(mean(resultsStat.boscOutputs{Pi}.pepisode(:,:,fBandRange(1):fBandRange(2)), [1,2,3]));
            pEpisodesVec(Pi+30,Fi) = squeeze(mean(resultsMobi.boscOutputs{Pi}.pepisode(:,:,fBandRange(1):fBandRange(2)), [1,2,3]));
            
            bandpowerVec(Pi,Fi) = squeeze(mean(resultsStat.boscOutputs{Pi}.static.bg_log10_pow(:,fBandRange(1):fBandRange(2)), [1,2]));
            bandpowerVec(Pi+30,Fi) = squeeze(mean(resultsMobi.boscOutputs{Pi}.static.bg_log10_pow(:,fBandRange(1):fBandRange(2)), [1,2]));
        end
    end
    
    if strcmp(parameter, 'pepisodes')
        demographicsTable.Response  = log(pEpisodesVec(:,Fi)./(1-pEpisodesVec(:,Fi)));  % Add the response variable to demographicsTable
    elseif strcmp(parameter, 'powers')
        demographicsTable.Response  = bandpowerVec(:,Fi);  % Add the response variable to demographicsTable
    else
        error(['undefined parameter name ' parameter])
    end
    
    demographicsTableNEW        = demographicsTable;
    
    % Response ~ group  + sex + age + education + sessionOrder + (1 | participantID)
    lmeFormula = 'Response ~ Group*Setup + Sex + Age + Education + SessionOrder + (1 | ID)';
    
    % Fit the model using restricted maximum likelihood (REML)
    lme                 = fitlme(demographicsTableNEW, lmeFormula, 'FitMethod', 'REML');
    groupPValue         = lme.Coefficients.pValue(strcmp(lme.Coefficients.Name, 'Group_2'));
    setupPValue         = lme.Coefficients.pValue(strcmp(lme.Coefficients.Name, 'Setup_2'));
    interactionPValue   = lme.Coefficients.pValue(strcmp(lme.Coefficients.Name, 'Group_2:Setup_2')); 
    
    % Step 1: Extract the necessary components
    % Total sum of squares (SS_total)
    totalMean = mean(demographicsTableNEW.Response);
    SS_total = sum((demographicsTableNEW.Response - totalMean).^2);
    
    % Extract the sum of squares for the Group effect
    SS_Group = (lme.Coefficients.Estimate(strcmp(lme.Coefficients.Name, 'Group_2'))^2) * ...
        lme.Coefficients.DF(strcmp(lme.Coefficients.Name, 'Group_2'));
    
    % Sum of Squares for the Setup effect
    SS_Setup = (lme.Coefficients.Estimate(strcmp(lme.Coefficients.Name, 'Setup_2'))^2) * ...
        lme.Coefficients.DF(strcmp(lme.Coefficients.Name, 'Setup_2'));
    
    % Sum of Squares for the Group*Setup interaction effect
    SS_Interaction = (lme.Coefficients.Estimate(strcmp(lme.Coefficients.Name, 'Group_2:Setup_2'))^2) * ...
        lme.Coefficients.DF(strcmp(lme.Coefficients.Name, 'Group_2:Setup_2'));
    
    % Mean square error (MS_error)
    MS_error = lme.MSE;  % This is the residual mean square
    
    % Step 2: Calculate degrees of freedom for the Group effect
    df_Group = 1;  % For a binary group comparison, df is typically 1
    df_Setup = 1;  % Binary comparison
    df_Interaction = 1;  % Interaction of two binary factors
    
    % Step 3: Compute Omega Squared (ω²)
    groupOS         = (SS_Group - df_Group * MS_error) / (SS_total + MS_error);
    setupOS         = (SS_Setup - df_Setup * MS_error) / (SS_total + MS_error);
    interactionOS   = (SS_Interaction - df_Interaction * MS_error) / (SS_total + MS_error);
    
    groupFs     = (SS_Group / df_Group) / MS_error;
    setupFs = (SS_Setup / df_Setup) / MS_error;
    interactionFs = (SS_Interaction / df_Interaction) / MS_error;
    
    pValVec(1, Fi)          = interactionPValue;
    pValVec(2, Fi)          = groupPValue;
    pValVec(3, Fi)          = setupPValue;
    omegaSquareds(1, Fi)    = interactionOS;
    omegaSquareds(2, Fi)    = groupOS;
    omegaSquareds(3, Fi)    = setupOS;
    Fs(1, Fi)               = interactionFs;
    Fs(2, Fi)               = groupFs;
    Fs(3, Fi)               = setupFs;
    
    if runPosthoc
              
        ct = {}; 
       
        % Post-hoc test for Group × Setup interaction
        ct{1} = [ 0 0 0 0 0 0 0 0;        
                0 0 1 0 0 0 0 0; ];
        ct{2} = [ 1 0 0 0 0 0 0 0;        
                0 1 1 0 0 0 0 0; ];
        ct{3} = [ 0 0 0 0 0 0 0 0;       
                0 1 0 0 0 0 0 0; ];
        ct{4} = [ 0 1 1 0 0 0 0 0;       
                0 1 1 0 0 0 0 0; ];
        
        % Run the post-hoc test
        for Icont = 1:4
            [postP(Icont, Fi), postFs(Icont, Fi), postDF1(Icont, Fi), postDF2(Icont, Fi)] = coefTest(lme, ct{Icont});
        end
    end
    
end

if strcmp(parameter, 'pepisodes')
    parameterVec = pEpisodesVec; 
elseif strcmp(parameter, 'powers')
    parameterVec = bandpowerVec;  
end

% Stat figure
f = figure('visible', 'off');
subplot(1,2,1)
pMat = parameterVec(1:10,:);
cMat = parameterVec(11:30,:);
allData = [pMat; cMat];
positions = [repmat(1:2:9, size(pMat, 1), 1); repmat(2:2:10, size(cMat,1), 1)]; 
positions = positions(:);
boxplot(allData, positions, 'Colors', 'k', 'Symbol', '');
hold on;
for i = 1:5  
    scatter(repmat(i * 2 - 1, size(pMat, 1), 1), pMat(:, i), 30, config_visual.pColor, 'filled', 'jitter', 'on', 'jitterAmount', 0.1);
    scatter(repmat(i * 2, size(cMat, 1), 1), cMat(:, i), 30, config_visual.cColor, 'filled', 'jitter', 'on', 'jitterAmount', 0.1);
end
set(gca, 'XTick', 1.5:2:11.5, 'XTickLabel', groupLabels, 'FontSize', 10); 
ylabel(['Mean ' parameter]); 
ylim(ylims); 
title([parameter ', stat, ' chanGroup.key], 'Interpreter', 'none');
grid on; hold off;

% Mobi figure
subplot(1,2,2)
pMat = parameterVec(31:40,:); 
cMat = parameterVec(41:60,:); 
allData = [pMat; cMat];
boxplot(allData, positions, 'Colors', 'k', 'Symbol', '');
hold on;
for i = 1:5  % Loop through each frequency band (5 bands)
    scatter(repmat(i * 2 - 1, size(pMat, 1), 1), pMat(:, i), 30, config_visual.pColor, 'filled', 'jitter', 'on', 'jitterAmount', 0.1);
    scatter(repmat(i * 2, size(cMat, 1), 1), cMat(:, i), 30, config_visual.cColor, 'filled', 'jitter', 'on', 'jitterAmount', 0.1);
end
set(gca, 'XTick', 1.5:2:11.5, 'XTickLabel', groupLabels, 'FontSize', 10); 
ylabel(['Mean ' parameter]); 
ylim(ylims); 
title([parameter ', mobile, ' chanGroup.key], 'Interpreter', 'none');
grid on; hold off;

saveas(f, fullfile(config_folder.figures_folder, 'bosc_stat', ['BOSC_' parameter '_' trial '_' chanGroup.key  '_' timeWindow '.png']));
save(fullfile('P:\Sein_Jeung\Project_Watermaze\WM_EEG_Results\BOSC', ['BOSC-comp_' trial '_' timeWindow '_' chanGroup.key '.mat']), 'pEpisodesVec', 'bandpowerVec', 'freqAxis', 'omegaSquareds', 'Fs');

end