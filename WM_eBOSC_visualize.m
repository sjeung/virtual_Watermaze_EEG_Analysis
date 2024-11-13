    
% %--------------------------------------------------------------------------
% pMeans = zeros(numel(freqAxis),size(boscOutputs{1}.detected_ep,4));
% for Pi = 1:10
%     this = squeeze(mean(boscOutputs{Pi}.detected_ep,[1,2]));
%     pMeans = pMeans + this;
% end
% pMeans = pMeans/10;
% 
% cMeans = zeros(numel(freqAxis),size(boscOutputs{1}.detected_ep,4));
% for Pi = 11:30
%     this = squeeze(mean(boscOutputs{Pi}.detected_ep,[1,2]));
%     cMeans = cMeans + this;
% end
% cMeans = cMeans/20;
% 
% f = figure;
% subplot(2,2,1)
% imagesc(pMeans, [0 0.08])
% yticks(1:numFreqs);
% yticklabels(arrayfun(@(x) sprintf('%.2f', x), freqAxis, 'UniformOutput', false)); % Set Y-tick labels
% set(gca, 'YDir', 'normal'); % Flip the Y-axis
% title([session ', ' timeWindow ', Patients'])
% 
% subplot(2,2,2)
% imagesc(cMeans, [0 0.08])
% yticks(1:numFreqs); 
% yticklabels(arrayfun(@(x) sprintf('%.2f', x), freqAxis, 'UniformOutput', false)); % Set Y-tick labels
% 
% set(gca, 'YDir', 'normal'); % Flip the Y-axis
% title([session ', ' timeWindow ', Controls'])
% 
% condString  = [trial '_' session];
% saveas(f, fullfile('P:\Sein_Jeung\Project_Watermaze\WM_EEG_Results\BOSC', ['BOSC_' condString '_' timeWindow '_' chanGroup.key '.png']));