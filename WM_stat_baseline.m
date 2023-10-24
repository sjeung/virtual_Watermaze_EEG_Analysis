
function  WM_stat_baseline(channelGroup, sessionType, baseType)

if ~exist('ALLEEG', 'var')
    eeglab;
end

WM_config; 
freqRange                   = config_param.ERSP_freq_range; 

%--------------------------------------------------------------------------
pSpectra = NaN(10,58);
cSpectra = NaN(20,58);

patientIDs      = 81001:81011; 
controlIDs      = [82001:82011, 83001:83011, 84009];
excludedIDs     = [81005, 82005, 83005, 81008, 82009, 83004]; % participant group 5 excluded due to psychosis. participant 81008 excluded due to massive spectral artefact
patientIDs      = setdiff(patientIDs, excludedIDs); 
controlIDs      = setdiff(controlIDs, excludedIDs); 

baseFilePath = fullfile(config_folder.results_folder, 'baseline_spectra', [channelGroup.key '_' baseType '_' sessionType '_baseline.mat']);

if exist(baseFilePath, 'file')
    loadedVar   = load(baseFilePath); 
    pSpectra    = loadedVar.pSpectra;
    cSpectra    = loadedVar.cSpectra; 
    baseERSP    = loadedVar.baseERSP; 
else
    pCount = 1;
    cCount = 1;
    
    for Pi = patientIDs
        baseERSP                                = util_WM_ERSP(channelGroup.chan_names, baseType, sessionType, Pi, freqRange);
        pSpectra(pCount,:)                      = squeeze(mean(baseERSP.powspctrm, [1,2,4], 'omitnan'))';
        pCount  = pCount + 1;
    end
    
    
    for Pi = controlIDs
        baseERSP                                = util_WM_ERSP(channelGroup.chan_names, baseType, sessionType, Pi, freqRange);
        cSpectra(cCount,:)                      = squeeze(mean(baseERSP.powspctrm, [1,2,4], 'omitnan'))';
        cCount  = cCount + 1;
    end
    
    if ~isfolder(baseFilePath)
        mkdir(fileparts(baseFilePath))
    end
    
    save(baseFilePath, 'pSpectra', 'cSpectra', 'baseERSP')
    
end

pSpectra(any(isnan(pSpectra),2),:)  = [];
cSpectra(any(isnan(cSpectra),2),:)  = []; 

pSpectra = 10*log(pSpectra); 
cSpectra = 10*log(cSpectra); 

% Assuming you have pSpectra and cSpectra matrices
% Calculate the mean and standard error for each frequency
mean_pSpectra = nanmean(pSpectra, 1);
std_pSpectra = nanstd(pSpectra, 1);

mean_cSpectra = nanmean(cSpectra, 1);
std_cSpectra = nanstd(cSpectra, 1);

% Define the x-axis (frequencies)
frequencies = 1:size(pSpectra, 2); % You may need to adjust this based on your data

% Plot the mean lines
figure;
plot(frequencies, mean_pSpectra, 'LineWidth', 3, 'Color', config_visual.pColor);
hold on;
plot(frequencies, mean_cSpectra, 'LineWidth', 3, 'Color', config_visual.cColor);

% Plot the confidence intervals as filled areas
x = [frequencies, fliplr(frequencies)]; % x values for filling
y_p = [mean_pSpectra + std_pSpectra, fliplr(mean_pSpectra - std_pSpectra)]; % y values for filling
fill(x, y_p, config_visual.pColor, 'FaceAlpha', 0.5, 'EdgeColor', 'none'); % Fill confidence interval area for pSpectra

y_c = [mean_cSpectra + std_cSpectra, fliplr(mean_cSpectra - std_cSpectra)]; % y values for filling
fill(x, y_c, config_visual.cColor, 'FaceAlpha', 0.5, 'EdgeColor', 'none'); % Fill confidence interval area for cSpectra

ylim([-40 80]);
xlabel('Frequencies');
ylabel('Power (dB)');
title('Power Spectra with Confidence Intervals');
legend('MTLR', 'CTRL');
grid on; 
freqPoints = baseERSP.freq;
xticks(1:5:size(cSpectra,2))
xticklabelsCell = arrayfun(@num2str, round(freqPoints(1:5:size(cSpectra,2))), 'UniformOutput', false);
xticklabels(xticklabelsCell);
xlabel('Frequencies in Hz')
title(['Spectra baseline ' baseType ', ' sessionType ', ' channelGroup.key ])

[clusters, p_values, t_sums, permutation_distribution ] = permutest(pSpectra',cSpectra', false, 0.05, 1000);

if p_values < 0.05
    msgbox(['Spectra baseline ' baseType ', ' sessionType ', ' channelGroup.key ])
end 


end