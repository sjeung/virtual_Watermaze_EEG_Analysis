
function  WM_stat_baseline(channelGroup, baseType)

sessions = {'stat', 'mobi'};
WM_config;
freqRange                   = config_param.ERSP_freq_range;

pSpectra    = {};
cSpectra    = {};

for sInd = 1:2
    
    sessionType = sessions{sInd}; 
    baseFilePath = fullfile(config_folder.results_folder, 'baseline_spectra', [channelGroup.key '_' baseType '_' sessionType '_baseline.mat']);
       
    if exist(baseFilePath, 'file')
        loadedVar   = load(baseFilePath);
        pSpectra    = loadedVar.pSpectra;
        cSpectra    = loadedVar.cSpectra;
        baseERSP    = loadedVar.baseERSP;
    else
        pSpectra{sInd} = NaN(10,58);
        cSpectra{sInd} = NaN(20,58);
        
        patientIDs      = 81001:81011;
        controlIDs      = [82001:82011, 83001:83011, 84009];
        excludedIDs     = [81005, 82005, 83005, 81008, 82009, 83004]; % participant group 5 excluded due to psychosis. participant 81008 excluded due to massive spectral artefact
        patientIDs      = setdiff(patientIDs, excludedIDs);
        controlIDs      = setdiff(controlIDs, excludedIDs);
        
        pCount = 1;
        cCount = 1;
        
        for Pi = patientIDs
            baseERSP                                = util_WM_ERSP(channelGroup.chan_names, baseType, sessionType, Pi, freqRange);
            pSpectra{sInd}(pCount,:)                = squeeze(mean(baseERSP.powspctrm, [1,2,4], 'omitnan'))';
            pCount  = pCount + 1;
        end
        
        
        for Pi = controlIDs
            baseERSP                                = util_WM_ERSP(channelGroup.chan_names, baseType, sessionType, Pi, freqRange);
            cSpectra{sInd}(cCount,:)                = squeeze(mean(baseERSP.powspctrm, [1,2,4], 'omitnan'))';
            cCount  = cCount + 1;
        end
        
        if ~isfolder(baseFilePath)
            mkdir(fileparts(baseFilePath))
        end
        
        save(baseFilePath, 'pSpectra', 'cSpectra', 'baseERSP')
        
        pSpectra{sInd}(any(isnan(pSpectra{sInd}),2),:)  = [];
        cSpectra{sInd}(any(isnan(cSpectra{sInd}),2),:)  = [];
        
    end
end

pSpectraStat = 10*log(pSpectra{1});
cSpectraStat = 10*log(cSpectra{1});
pSpectraMoBI = 10*log(pSpectra{2});
cSpectraMoBI = 10*log(cSpectra{2});

% Assuming you have pSpectra and cSpectra matrices
% Calculate the mean and standard error for each frequency
mean_pSpectraStat   = nanmean(pSpectraStat, 1);
std_pSpectraStat    = nanstd(pSpectraStat, 1);
mean_cSpectraStat   = nanmean(cSpectraStat, 1);
std_cSpectraStat    = nanstd(cSpectraStat, 1);

mean_pSpectraMoBI   = nanmean(pSpectraMoBI, 1);
std_pSpectraMoBI    = nanstd(pSpectraMoBI, 1);
mean_cSpectraMoBI   = nanmean(cSpectraMoBI, 1);
std_cSpectraMoBI    = nanstd(cSpectraMoBI, 1);


% Define the x-axis (frequencies)
frequencies = 1:size(pSpectra{1}, 2); % You may need to adjust this based on your data

% Plot the mean lines
figure;
plot(frequencies, mean_pSpectraStat, 'LineWidth', 3, 'Color', config_visual.pColor);
hold on;
plot(frequencies, mean_cSpectraStat, 'LineWidth', 3, 'Color', config_visual.cColor);
plot(frequencies, mean_pSpectraMoBI, '--', 'LineWidth', 3, 'Color', config_visual.pColor);
plot(frequencies, mean_cSpectraMoBI, '--', 'LineWidth', 3, 'Color', config_visual.cColor);

% Plot the confidence intervals as filled areas
x = [frequencies, fliplr(frequencies)]; % x values for filling
y_p = [mean_pSpectraStat + std_pSpectraStat, fliplr(mean_pSpectraStat - std_pSpectraStat)]; % y values for filling
fill(x, y_p, config_visual.pColor, 'FaceAlpha', 0.2, 'EdgeColor', 'none'); % Fill confidence interval area for pSpectra

y_c = [mean_cSpectraStat + std_cSpectraStat, fliplr(mean_cSpectraStat - std_cSpectraStat)]; % y values for filling
fill(x, y_c, config_visual.cColor, 'FaceAlpha', 0.2, 'EdgeColor', 'none'); % Fill confidence interval area for cSpectra

y_p = [mean_pSpectraMoBI + std_pSpectraMoBI, fliplr(mean_pSpectraMoBI - std_pSpectraMoBI)]; % y values for filling
fill(x, y_p, config_visual.pColor, 'FaceAlpha', 0.2, 'EdgeColor', 'none'); % Fill confidence interval area for pSpectra

y_c = [mean_cSpectraMoBI + std_cSpectraMoBI, fliplr(mean_cSpectraMoBI - std_cSpectraMoBI)]; % y values for filling
fill(x, y_c, config_visual.cColor, 'FaceAlpha', 0.2, 'EdgeColor', 'none'); % Fill confidence interval area for cSpectra


ylim([-40 80]);
xlabel('Frequencies');
ylabel('Power (dB)');
title('Power Spectra with Confidence Intervals');
legend('MTLR-stat', 'CTRL-stat', 'MTLR-mobi', 'CTRL-mobi');
grid on; 
freqPoints = baseERSP.freq;
xticks(1:5:size(cSpectra{1},2))
xticklabelsCell = arrayfun(@num2str, round(freqPoints(1:5:size(cSpectra{1},2))), 'UniformOutput', false);
xticklabels(xticklabelsCell);
xlabel('Frequencies in Hz')
title(['Spectra baseline ' baseType ', ' channelGroup.key ])
save()

[clusters, p_values, t_sums, permutation_distribution ] = permutest(pSpectra{1}',cSpectra{1}', false, 0.05, 1000);

if p_values < 0.05
    disp(['Spectra baseline ' baseType ', ' sessions{1} ', ' channelGroup.key ])
    disp('frequencies in cluster')
    disp(baseERSP.freq(clusters{1}))
end 


[clusters, p_values, t_sums, permutation_distribution ] = permutest(pSpectra{2}',cSpectra{2}', false, 0.05, 1000);

if p_values < 0.05
    disp(['Spectra baseline ' baseType ', ' sessions{2} ', ' channelGroup.key ])
    disp('frequencies in cluster')
    disp(baseERSP.freq(clusters{1}))
end 


end