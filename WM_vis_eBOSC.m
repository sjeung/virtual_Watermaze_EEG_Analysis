function WM_vis_eBOSC(trial, timeWindow, chanGroup)

if strcmp(timeWindow, 'Start') || strcmp(timeWindow, 'End')
    ERPlot = 1; 
else
    ERPlot = 0;
end

WM_config;
addpath(genpath('P:\Sein_Jeung\Tools\FDR'))

% Read in the data
resultsStat = load(fullfile('P:\Sein_Jeung\Project_Watermaze\WM_EEG_Results\BOSC', ['BOSC_' trial '_stat_' timeWindow '_' chanGroup.key '.mat']), 'boscOutputs');
resultsMobi = load(fullfile('P:\Sein_Jeung\Project_Watermaze\WM_EEG_Results\BOSC', ['BOSC_' trial '_mobi_' timeWindow '_' chanGroup.key '.mat']), 'boscOutputs');
freqAxis = resultsMobi.boscOutputs{1}.config.eBOSC.F;
numFreqs = numel(freqAxis);

if ERPlot
    for ses = 1:2
        if ses == 1
            results = resultsStat; figText = 'stat';
        else
            results = resultsMobi; figText = 'mobile'; 
        end
        
        meandepP = []; meandepC = [];
        for Pi = 1:10
            detect_ep   = results.boscOutputs{Pi}.detected_ep(:,:,:,:);
            meandep     = squeeze(mean(detect_ep,[1,2]));
            meandepP    = cat(3, meandepP, meandep);
        end
        for Pi = 11:30
            detect_ep   = results.boscOutputs{Pi}.detected_ep(:,:,:,:);
            meandep     = squeeze(mean(detect_ep,[1,2]));
            meandepC    = cat(3, meandepC, meandep);
        end        
        
        f1 = figure;
        subplot(1,2,1); hold on;
        imagesc(squeeze(mean(meandepP, 3)), [0 0.08])
        yticks(1:numFreqs);
        yticklabels(arrayfun(@(x) sprintf('%.2f', x), freqAxis, 'UniformOutput', false)); % Set Y-tick labels
        title('MTLR')
        subplot(1,2,2);
        imagesc(squeeze(mean(meandepC, 3)), [0 0.08])
        yticks(1:numFreqs);
        set(gca, 'YDir', 'normal');
        yticklabels(arrayfun(@(x) sprintf('%.2f', x), freqAxis, 'UniformOutput', false)); % Set Y-tick labels
        title('CTRL')
        
        saveas(f1,fullfile('P:\Sein_Jeung\Project_Watermaze\WM_EEG_Figures\bosc_timelock', ['BOSC_' trial '_' timeWindow '_' chanGroup.key '_' figText '.png']) )
        close(f1); 
    end
end

results = resultsStat; 
powersP     = []; powersC   = [];
pepP        = []; pepC      = [];
for Pi = 1:10
    pep         = squeeze(mean(results.boscOutputs{Pi}.pepisode,[1,2]));
    pow         = squeeze(mean(results.boscOutputs{Pi}.static.bg_log10_pow,1));
    pepP        = cat(2, pepP,pep);
    powersP     = cat(2, powersP,pow');
end
for Pi = 11:30
    pep         = squeeze(mean(results.boscOutputs{Pi}.pepisode,[1,2]));
    pow         = squeeze(mean(results.boscOutputs{Pi}.static.bg_log10_pow,1));
    pepC        = cat(2, pepC,pep);
    powersC     = cat(2, powersC,pow');
end
pwSP = powersP;
peSP = pepP; 
pwSC = powersC;
peSC = pepC; 

results = resultsMobi;
powersP     = []; powersC   = [];
pepP        = []; pepC      = [];
for Pi = 1:10
    pep         = squeeze(mean(results.boscOutputs{Pi}.pepisode,[1,2]));
    pow         = squeeze(mean(results.boscOutputs{Pi}.static.bg_log10_pow,1));
    pepP        = cat(2, pepP,pep);
    powersP     = cat(2, powersP,pow');
end
for Pi = 11:30
    pep         = squeeze(mean(results.boscOutputs{Pi}.pepisode,[1,2]));
    pow         = squeeze(mean(results.boscOutputs{Pi}.static.bg_log10_pow,1));
    pepC        = cat(2, pepC,pep);
    powersC     = cat(2, powersC,pow');
end
pwMP = powersP;
peMP = pepP; 
pwMC = powersC;
peMC = pepC;

% Define the target frequency values for xticks
target_xticks = [2, 4, 8, 16, 30, 60, 90];
[~, closest_indices] = arrayfun(@(x) min(abs(freqAxis - x)), target_xticks);

f2 = figure;
subplot(2,1,1)
plot(mean(pwSP,2), 'LineWidth', 2, 'Color', config_visual.pColor)
hold on;
plot(mean(pwMP,2), 'LineWidth', 2, 'Color', config_visual.pColor, 'LineStyle', '--')
plot(mean(pwSC,2), 'LineWidth', 2, 'Color', config_visual.cColor)
plot(mean(pwMC,2), 'LineWidth', 2, 'Color', config_visual.cColor,'LineStyle', '--')
title('powers')
xticks(closest_indices)  % Set xticks to closest indices
xticklabels(arrayfun(@num2str, target_xticks, 'UniformOutput', false))

subplot(2,1,2)
plot(mean(peSP,2), 'LineWidth', 2, 'Color', config_visual.pColor)
hold on;
plot(mean(peMP,2), 'LineWidth', 2, 'Color', config_visual.pColor, 'LineStyle', '--')
plot(mean(peSC,2), 'LineWidth', 2, 'Color', config_visual.cColor)
plot(mean(peMC,2), 'LineWidth', 2, 'Color', config_visual.cColor,'LineStyle', '--')
title('powers')
title('p-episodes')   
xticks(closest_indices)  % Set xticks to closest indices
xticklabels(arrayfun(@num2str, target_xticks, 'UniformOutput', false))

saveas(f2,fullfile('P:\Sein_Jeung\Project_Watermaze\WM_EEG_Figures\bosc_lines', ['BOSC_' trial '_' timeWindow '_' chanGroup.key '.png']))
close(f2); 
end