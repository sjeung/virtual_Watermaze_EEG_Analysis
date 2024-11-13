function [pValVec, omegaSquareds, Fs] = WM_stat_beh_eeg_BOSC(trial, timeWindow, chanGroup, responseVarName, parameter)

% EEG features 
%   FM/PM theta, alpha, beta, gamma
% Behavioral features
%   Memory score
%   idPhi
%   DTW distances
%--------------------------------------------------------------------------

WM_config
pThreshold              = 0.005; % 4 electrode groups X 5 waves 
pValVec                 = NaN(4,5); % 4 tests, 5 frequency bands
omegaSquareds           = NaN(4,5);
Fs                      = NaN(4,5);

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

% Behavioral measures 
tableData   = data; 
ids = [patientIDs controlIDs]; 

% Preallocate vectors for demographics
numIds = length([patientIDs controlIDs]);
group = zeros(numIds, 1);
setup = group; sex = group; age = group; education = group; sessionOrder = group;

% Step 3: Loop through each unique ID and extract demographics
for i = 1:numIds
    id = ids(i);
    % Find the first row where the ID matches
    firstRowIdx = find(data.id == id, 1, 'first');
    
    % Step 4: Extract the demographic information
    group(i) = data.group(firstRowIdx);                 % Extract group
    setup(i) = data.setup(firstRowIdx);                 % Extract setup
    sex(i) = data.sex(firstRowIdx);                     % Extract sex
    age(i) = data.age(firstRowIdx);                     % Extract age
    education(i) = data.education_years(firstRowIdx);   % Extract education years
    sessionOrder(i) = data.session(firstRowIdx);        % Extract session order
end

% Combine demographics into a table
demographicsTable = table(ids', group, sex, age, education, sessionOrder, ...
    'VariableNames', {'ID', 'Group', 'Sex', 'Age', 'Education', 'SessionOrder'});

% Convert categorical variables if needed
demographicsTable.Group = categorical(demographicsTable.Group);
demographicsTable.Sex = categorical(demographicsTable.Sex);
demographicsTable.SessionOrder = categorical(demographicsTable.SessionOrder);
demographicsTable.ID = categorical(demographicsTable.ID);
demographicsTable = [demographicsTable; demographicsTable];
demographicsTable.Setup(1:30,1) = 1; demographicsTable.Setup(31:60,1) = 2; % add setup code
demographicsTable.Setup = categorical(demographicsTable.Setup);

IDs         = tableData.id;
LP          = tableData.learning_or_probeTrial;
SU          = tableData.setup;
MS          = tableData.memory_score;
idPhis      = tableData.avg_idPhi_angular_velocity_5_sec;
DTWs        = tableData.learning_probe_avg_dTW_square;
responseVar  = eval(responseVarName);

pMeans      = [];

for sessionCode = 1:2
    for Pi = ids
        % average performance per participant
        tInds               = find(IDs == Pi);          % participant ID
        pInds               = find(LP == 2);            % probe only
        sInds               = find(SU == sessionCode);  % stat or mobi
        fullInds            = intersect(intersect(tInds,pInds),sInds); % trial inds without outlier removal
        pMeans(1,end+1)     = mean(responseVar(fullInds), 'omitnan');
    end
end

pMeans = pMeans';

for Fi = 1:5
    
    fBandRange = [find(freqAxis >= config_param.FOI_lower(Fi), 1, 'first') , find(freqAxis <= config_param.FOI_upper(Fi), 1,'last')]; 
  
    if preLoaded == 0
        for Pi = 1:30
            pEpisodesVec(Pi,Fi) = squeeze(mean(resultsStat.boscOutputs{Pi}.pepisode(:,:,fBandRange(1):fBandRange(2)), [1,2,3]));
            pEpisodesVec(Pi+30,Fi) = squeeze(mean(resultsMobi.boscOutputs{Pi}.pepisode(:,:,fBandRange(1):fBandRange(2)), [1,2,3]));
            
            bandpowerVec(Pi,Fi) = squeeze(mean(resultsStat.boscOutputs{Pi}.static.bg_log10_pow(:,fBandRange(1):fBandRange(2)), [1,2]));
            bandpowerVec(Pi+30,Fi) = squeeze(mean(resultsMobi.boscOutputs{Pi}.static.bg_log10_pow(:,fBandRange(1):fBandRange(2)), [1,2]));
        end
    end
    
    if strcmp(parameter, 'pepisodes')
        demographicsTable.Power  = log(pEpisodesVec(:,Fi)./(1-pEpisodesVec(:,Fi)));  % Add the response variable to demographicsTable
    elseif strcmp(parameter, 'powers')
        demographicsTable.Power  = bandpowerVec(:,Fi);  % Add the response variable to demographicsTable
    else
        error(['undefined parameter name ' parameter])
    end
    
    nonNorm = lillietest(pMeans(:,1));
    if nonNorm
        % Compute skewness and kurtosis
        skewness_val = skewness(pMeans(:,1));
        kurtosis_val = kurtosis(pMeans(:,1));
            
        % Apply log transformation if skewness or kurtosis exceed thresholds
        if skewness_val < -2 || skewness_val > 2 || kurtosis_val < -7 || kurtosis_val > 7
            disp('Applying log transformation due to skewness/kurtosis values.');
            demographicsTable.Response  = log(pMeans(:,1));  % Add the response variable to demographicsTable
        else
           % disp('Non-normal distribution but no correction')
            demographicsTable.Response  = pMeans(:,1);
        end
    else
        demographicsTable.Response  = pMeans(:,1); 
    end
    
    lmeFormula = 'Response ~ Power*Group*Setup + Sex + Age + Education + SessionOrder + (1 | ID)';
    
    % Fit the model using restricted maximum likelihood (REML)
    lme                     = fitlme(demographicsTable, lmeFormula, 'FitMethod', 'REML');
    interaction_threeway    = lme.Coefficients.pValue(strcmp(lme.Coefficients.Name, 'Group_2:Setup_2:Power'));
    interaction_groupPower  = lme.Coefficients.pValue(strcmp(lme.Coefficients.Name, 'Group_2:Power'));
    interaction_setupPower  = lme.Coefficients.pValue(strcmp(lme.Coefficients.Name, 'Setup_2:Power'));
    effect_Power            = lme.Coefficients.pValue(strcmp(lme.Coefficients.Name, 'Power'));
    
    if interaction_threeway <pThreshold || interaction_groupPower <pThreshold || interaction_setupPower <pThreshold || effect_Power < pThreshold
        
        groups = unique(demographicsTable.Group);
        setups = unique(demographicsTable.Setup);
        f = figure;
        
        if strcmp(parameter, 'pepisodes') % inverse logistic for p-episodes
            ilgPower = 1 ./ (1 + exp(-demographicsTable.Power));
            power_levels = linspace(min(ilgPower), max(ilgPower), 10);
        else
            power_levels = linspace(min(demographicsTable.Power), max(demographicsTable.Power), 10);
        end
        
        hold on;
        
        % Loop through each group and setup to create scatter plots
        for g = 1:length(groups)
            if g == 1
                groupColor = config_visual.pColor;
            else
                groupColor = config_visual.cColor;
            end
            
            for s = 1:length(setups)
                % Define marker style based on Setup
                if s == 1
                    markerStyle = 'o'; % solid circle for Setup 1
                    markerFaceColor = groupColor; % Solid color for Setup 1
                    lineStyle = '-'; % Solid line for Setup 1
                else
                    markerStyle = 'o'; % hollow circle for Setup 2
                    markerFaceColor = 'none'; % Hollow marker for Setup 2
                    lineStyle = '--'; % Dotted line for Setup 2
                end
                
                % Subset the data for current Group and Setup
                subset = demographicsTable(demographicsTable.Group == groups(g) & demographicsTable.Setup == setups(s), :);
                
                % Apply inverse logit transformation if required
                if strcmp(parameter, 'pepisodes')
                    subset.Power = 1 ./ (1 + exp(-subset.Power));
                end
                
                % Scatter plot individual response values vs. power values
                scatter(subset.Power, subset.Response, 'Marker', markerStyle, 'MarkerEdgeColor', groupColor, ...
                    'MarkerFaceColor', markerFaceColor, 'LineWidth', 1.5, ...
                    'DisplayName', sprintf('Group %d, Setup %d', groups(g), setups(s)));
                
                % Ensure Power and Response are column vectors
                xData = subset.Power(:);      % Convert to column vector
                yData = subset.Response(:);    % Convert to column vector
                
                % Fit a linear regression model to the subset data
                lm = fitlm(xData, yData); % Linear fit
                
                % Get the coefficients (intercept and slope)
                intercept = lm.Coefficients.Estimate(1); % Intercept (b)
                slope = lm.Coefficients.Estimate(2);     % Slope (m)
                
                % Plot the regression line
                % Generate values for plotting the regression line
                x_fit = linspace(min(xData), max(xData), 100);
                y_fit = slope * x_fit + intercept; % y = mx + b
                
                % Plot the regression line with the specified line style
                plot(x_fit, y_fit, 'Color', groupColor, 'LineStyle', lineStyle, 'LineWidth', 1.5, ...
                    'DisplayName', sprintf('Fit Group %d, Setup %d', groups(g), setups(s)));
            end
        end
        
        xlabel(parameter); ylabel(responseVarName);
        title([timeWindow, ', ' chanGroup.key '-' config_param.band_names{Fi}]);
        grid on; hold off;
        
        saveas(f, fullfile('P:\Sein_Jeung\Project_Watermaze\WM_EEG_Figures\bosc_stat', [parameter '_' responseVarName '_' trial '_' timeWindow '_' chanGroup.key '_' config_param.band_names{Fi} '.png']))
    end
    
    % Total sum of squares (SS_total)
    totalMean = mean(demographicsTable.Response);
    SS_total = sum((demographicsTable.Response - totalMean).^2);
    
    % Mean Square Error (MS_error)
    MS_error = lme.MSE;
    
    % Sum of Squares and F-statistics for each term
    
    % 1. Sum of Squares for the Power effect
    SS_Power = (lme.Coefficients.Estimate(strcmp(lme.Coefficients.Name, 'Power'))^2) * ...
        lme.Coefficients.DF(strcmp(lme.Coefficients.Name, 'Power'));
    
    % 2. Sum of Squares for the Group*Power interaction
    SS_GroupPower = (lme.Coefficients.Estimate(strcmp(lme.Coefficients.Name, 'Group_2:Power'))^2) * ...
        lme.Coefficients.DF(strcmp(lme.Coefficients.Name, 'Group_2:Power'));
    
    % 3. Sum of Squares for the Setup*Power interaction
    SS_SetupPower = (lme.Coefficients.Estimate(strcmp(lme.Coefficients.Name, 'Setup_2:Power'))^2) * ...
        lme.Coefficients.DF(strcmp(lme.Coefficients.Name, 'Setup_2:Power'));
    
    % 4. Sum of Squares for the three-way Group*Setup*Power interaction
    SS_Threeway = (lme.Coefficients.Estimate(strcmp(lme.Coefficients.Name, 'Group_2:Setup_2:Power'))^2) * ...
        lme.Coefficients.DF(strcmp(lme.Coefficients.Name, 'Group_2:Setup_2:Power'));
    
    % Degrees of freedom for each effect (df = 1 for binary factors/interactions)
    df_Power = 1;
    df_GroupPower = 1;
    df_SetupPower = 1;
    df_Threeway = 1;
    
    % Compute Omega Squared (ω²) for each effect
    powerOS = (SS_Power - df_Power * MS_error) / (SS_total + MS_error);
    groupPowerOS = (SS_GroupPower - df_GroupPower * MS_error) / (SS_total + MS_error);
    setupPowerOS = (SS_SetupPower - df_SetupPower * MS_error) / (SS_total + MS_error);
    threewayOS = (SS_Threeway - df_Threeway * MS_error) / (SS_total + MS_error);
    
    % Compute F-statistics for each effect
    powerFs = (SS_Power / df_Power) / MS_error;
    groupPowerFs = (SS_GroupPower / df_GroupPower) / MS_error;
    setupPowerFs = (SS_SetupPower / df_SetupPower) / MS_error;
    threewayFs = (SS_Threeway / df_Threeway) / MS_error;
    
    pValVec(1,Fi)           = interaction_threeway;
    pValVec(2,Fi)           = interaction_groupPower;
    pValVec(3,Fi)           = interaction_setupPower;
    pValVec(4,Fi)           = effect_Power;
    omegaSquareds(1, Fi)    = threewayOS;
    omegaSquareds(2, Fi)    = groupPowerOS;
    omegaSquareds(3, Fi)    = setupPowerOS;
    omegaSquareds(4, Fi)    = powerOS;
    Fs(1, Fi)               = threewayFs;
    Fs(2, Fi)               = groupPowerFs;
    Fs(3, Fi)               = setupPowerFs;
    Fs(4, Fi)               = powerFs;

    if interaction_threeway <pThreshold || interaction_groupPower <pThreshold || interaction_setupPower <pThreshold || effect_Power < pThreshold
      %  disp([responseVarName, ', ' timeWindow,',' chanGroup.key '-' bandNames{Fi}])
      %  disp(['3-way interaction p = ' num2str(interaction_threeway)])
      %  disp(['Group interaction p = ' num2str(interaction_groupPower) ', setup intraction p = ' num2str(interaction_setupPower)])
      %  disp(['Power main effect p = ' num2str(effect_Power)])
    end
 
end


end

