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

% save memory 
if strcmp(timeWindow, 'Mid')
    for Pi = 1:30
       resultsStat.boscOutputs{Pi}.detected =  []; 
       resultsStat.boscOutputs{Pi}.detected_ep =  []; 
    end
end

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
        
        target_yticks = [3, 8, 12, 30, 60, 90];
        [~, closest_indices] = arrayfun(@(x) min(abs(freqAxis - x)), target_yticks);
        
        f1 = figure;
        imagesc(squeeze(mean(meandepP(2:end,:,:), 3)) - squeeze(mean(meandepC(2:end,:,:), 3)), [-0.07 0.07]) % discard the first row for plotting (overestimation of prevalance for some reason)
        set(gca, 'YDir', 'normal');
        yticks(closest_indices);  % Set yticks to closest indices
        yticklabels(arrayfun(@num2str, target_yticks, 'UniformOutput', false));
        cmap = [linspace(0,1,64)', linspace(0,1,64)', ones(64,1); ... % Blue to White
            ones(64,1), linspace(1,0,64)', linspace(1,0,64)'];  % White to Red
        colormap(cmap);
        ax = gca; ax.FontSize = 25;
        xticks([1,250,500,750]);xticklabels({'0','1','2','3'});
        %colorbar;
        axis off;
        saveas(f1,fullfile('P:\Sein_Jeung\Project_Watermaze\WM_EEG_Figures\bosc_timelock', ['BOSC_' trial '_' timeWindow '_' chanGroup.key '_' figText '_diff.png']) ); close(f1);
        
        f2 = figure;
        imagesc(squeeze(mean(meandepP(2:end,:,:), 3)), [0 0.1]) % discard the first row for plotting (overestimation of prevalance for some reason)
        set(gca, 'YDir', 'normal');
        yticks(closest_indices);  % Set yticks to closest indices
        yticklabels(arrayfun(@num2str, target_yticks, 'UniformOutput', false));
        ax = gca; ax.FontSize = 25;
        xticks([1,250,500,750]);xticklabels({'-1','0','1','2'});
        %colorbar;
        axis off;
        saveas(f2,fullfile('P:\Sein_Jeung\Project_Watermaze\WM_EEG_Figures\bosc_timelock', ['BOSC_' trial '_' timeWindow '_' chanGroup.key '_' figText '_mtlr.png']) ); close(f2);
        
        f3 = figure;
        imagesc(squeeze(mean(meandepC(2:end,:,:), 3)), [0 0.1]) % discard the first row for plotting (overestimation of prevalance for some reason)
        set(gca, 'YDir', 'normal');
        yticks(closest_indices);  % Set yticks to closest indices
        yticklabels(arrayfun(@num2str, target_yticks, 'UniformOutput', false));
        ax = gca; ax.FontSize = 25;
        xticks([1,250,500,750]);xticklabels({'-1','0','1','2'});
        %colorbar;
        axis off;
        saveas(f3,fullfile('P:\Sein_Jeung\Project_Watermaze\WM_EEG_Figures\bosc_timelock', ['BOSC_' trial '_' timeWindow '_' chanGroup.key '_' figText '_ctrl.png']) ); close(f3);
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
pwSP = powersP*10;% decibel transformation
peSP = pepP*100;  % convert to percentage
pwSC = powersC*10;
peSC = pepC*100; 

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

pwMP = powersP*10; % decibel transformation
peMP = pepP*100; % percent transformation
pwMC = powersC*10;
peMC = pepC*100;


% Define the target frequency values for xticks
target_xticks = [3, 8, 12, 30, 60, 90];
[~, closest_indices] = arrayfun(@(x) min(abs(freqAxis - x)), target_xticks);

ci_pwSP = 1.96 * std(pwSP, 0, 2) / sqrt(size(pwSP, 2));
ci_pwMP = 1.96 * std(pwMP, 0, 2) / sqrt(size(pwMP, 2));
ci_pwSC = 1.96 * std(pwSC, 0, 2) / sqrt(size(pwSC, 2));
ci_pwMC = 1.96* std(pwMC, 0, 2) / sqrt(size(pwMC, 2));

ci_peSP = 1.96 * std(peSP, 0, 2) / sqrt(size(peSP, 2));
ci_peMP = 1.96 * std(peMP, 0, 2) / sqrt(size(peMP, 2));
ci_peSC = 1.96 * std(peSC, 0, 2) / sqrt(size(peSC, 2));
ci_peMC = 1.96* std(peMC, 0, 2) / sqrt(size(peMC, 2));

% Create figure and plot 
f2 = figure;
%subplot(2,1,1);

% Plot the confidence intervals and mean lines using 'fill'
x = [1:length(mean(pwSP,2)), fliplr(1:length(mean(pwSP,2)))];

% y_p = [mean(pwSP,2)' + ci_pwSP', fliplr(mean(pwSP,2)' - ci_pwSP')];
% fill(x, y_p, config_visual.pColor, 'FaceAlpha', 0.2, 'EdgeColor', 'none'); % Shaded area
% hold on;
% 
% y_p = [mean(pwMP,2)' + ci_pwMP', fliplr(mean(pwMP,2)' - ci_pwMP')];
% fill(x, y_p, config_visual.pColor, 'FaceAlpha', 0.2, 'EdgeColor', 'none'); 
% 
% y_c = [mean(pwSC,2)' + ci_pwSC', fliplr(mean(pwSC,2)' - ci_pwSC')];
% fill(x, y_c, config_visual.cColor, 'FaceAlpha', 0.2, 'EdgeColor', 'none'); 
% 
% y_c = [mean(pwMC,2)' + ci_pwMC', fliplr(mean(pwMC,2)' - ci_pwMC')];
% fill(x, y_c, config_visual.cColor, 'FaceAlpha', 0.2, 'EdgeColor', 'none');
% 
% % Plot the mean lines
% plot(mean(pwSP,2), 'LineWidth', 2, 'Color', config_visual.pColor);
% plot(mean(pwMP,2), 'LineWidth', 2, 'Color', config_visual.pColor, 'LineStyle', '--');
% plot(mean(pwSC,2), 'LineWidth', 2, 'Color', config_visual.cColor);
% plot(mean(pwMC,2), 'LineWidth', 2, 'Color', config_visual.cColor, 'LineStyle', '--');
% 
% % Set title and labels
% xticks(closest_indices);  % Set xticks to closest indices
% xticklabels(arrayfun(@num2str, target_xticks, 'UniformOutput', false));
% ylim([20 60])
% ax = gca; ax.FontSize = 15; 
% if strcmp(chanGroup.key, 'FM')
%     ax.Box = 'off'; ax.YAxis.Visible = 'on'; %
% else
%     set(gca, 'YColor', 'none');
% end
% pbaspect([2 1 1]);
%subplot(2,1,2)

y_p = [mean(peSP,2)' + ci_peSP', fliplr(mean(peSP,2)' - ci_peSP')];
fill(x, y_p, config_visual.pColor, 'FaceAlpha', 0.2, 'EdgeColor', 'none'); % Shaded area
hold on;

y_p = [mean(peMP,2)' + ci_peMP', fliplr(mean(peMP,2)' - ci_peMP')];
fill(x, y_p, config_visual.pColor, 'FaceAlpha', 0.2, 'EdgeColor', 'none'); 

y_c = [mean(peSC,2)' + ci_peSC', fliplr(mean(peSC,2)' - ci_peSC')];
fill(x, y_c, config_visual.cColor, 'FaceAlpha', 0.2, 'EdgeColor', 'none'); 

y_c = [mean(peMC,2)' + ci_peMC', fliplr(mean(peMC,2)' - ci_peMC')];
fill(x, y_c, config_visual.cColor, 'FaceAlpha', 0.2, 'EdgeColor', 'none');

plot(mean(peSP,2), 'LineWidth', 2, 'Color', config_visual.pColor)
plot(mean(peMP,2), 'LineWidth', 2, 'Color', config_visual.pColor, 'LineStyle', '--')
plot(mean(peSC,2), 'LineWidth', 2, 'Color', config_visual.cColor)
plot(mean(peMC,2), 'LineWidth', 2, 'Color', config_visual.cColor, 'LineStyle', '--')

xticks(closest_indices)  % Set xticks to closest indices
xticklabels(arrayfun(@num2str, target_xticks, 'UniformOutput', false))
ylim([0 55])
ax = gca; ax.FontSize = 30; 
if strcmp(chanGroup.key, 'FM')
    ax.Box = 'off'; ax.YAxis.Visible = 'on'; %
else
    set(gca, 'YColor', 'none');
end
pbaspect([2 1 1]);


saveas(f2,fullfile('P:\Sein_Jeung\Project_Watermaze\WM_EEG_Figures\bosc_lines', ['BOSC_' trial '_' timeWindow '_' chanGroup.key '.png']))
close(f2); 
end