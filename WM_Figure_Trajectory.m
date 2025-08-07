
Pi = '83007'; 

trialInfo = load(['P:\Sein_Jeung\Project_Watermaze\WM_EEG_Results\BEH_output\sub-' Pi '_beh_trials.mat']);
learn = load(['P:\Sein_Jeung\Project_Watermaze\WM_EEG_Data\7_epoched\sub-' Pi '\sub-' Pi '_learn_mobi_motion_epoched.mat']); 
probe = load(['P:\Sein_Jeung\Project_Watermaze\WM_EEG_Data\7_epoched\sub-' Pi '\sub-' Pi '_probe_mobi_motion_epoched.mat']); 


TiVec  = [1, 4, 7, 10, 13, 16]; PTiVec = [1, 5, 9, 13, 17, 21]; 
for Bi  = 1:6
    
    Ti      = TiVec(Bi); 
    PTi     = PTiVec(Bi); 
    
    originPos   = [trialInfo.TrialLearnM(Ti).originPos_x, trialInfo.TrialLearnM(Ti).originPos_z];  
    targetPos   = [trialInfo.TrialLearnM(Ti).targetPos_x, trialInfo.TrialLearnM(Ti).targetPos_z];  
    
    figure;
    
    for iPlot = 1:3
        subplot(1,7,iPlot)
        xCoords = learn.ftMotion.trial{Ti + iPlot - 1}(4,501:end-500); % time cut like this because 2 sec buffer was included in epoches
        yCoords = learn.ftMotion.trial{Ti + iPlot - 1}(6,501:end-500);
        scatter(xCoords,yCoords, 30, 'MarkerFaceColor', [.5, .5, .5], 'MarkerEdgeColor', 'none')
        hold on; 
        scatter(xCoords(1), yCoords(1), 800, 'MarkerFaceColor', [0.705, 0.392, 0.960], 'MarkerEdgeColor', 'none', 'MarkerFaceAlpha', 0.8)
        scatter(targetPos(1), targetPos(2), 800, 'MarkerFaceColor', [0.207, 0.651, 0.451], 'MarkerEdgeColor', 'none', 'MarkerFaceAlpha', 0.6)
        
        rectangle('Position',[-4, -4, 8, 8], 'Curvature',[1 1], 'EdgeColor',[0.5 0.5 0.5])
        xlim([-4 4]); ylim([-4 4])
        axis off
        
    end
    
    
    for iPlot = 1:4
        subplot(1,7,iPlot + 3)
        xCoords = probe.ftMotion.trial{PTi + iPlot - 1}(4,501:end-500);
        yCoords = probe.ftMotion.trial{PTi + iPlot - 1}(6,501:end-500);
        scatter(xCoords,yCoords, 30, 'MarkerFaceColor', [.5, .5, .5], 'MarkerEdgeColor', 'none')
        hold on; 
        scatter(xCoords(1), yCoords(1), 800, 'MarkerFaceColor', [0.705, 0.392, 0.960], 'MarkerEdgeColor', 'none', 'MarkerFaceAlpha', 0.8)
        scatter(targetPos(1), targetPos(2), 800, 'MarkerFaceColor', [0.207, 0.651, 0.451], 'MarkerEdgeColor', 'none', 'MarkerFaceAlpha', 0.6)
        scatter(xCoords(end), yCoords(end), 300, 'MarkerFaceColor', [0.207, 0.651, 0.451], 'MarkerEdgeColor', 'none')
        
        rectangle('Position',[-3.9, -3.9, 7.8, 7.8], 'Curvature',[1 1], 'EdgeColor',[0.5 0.5 0.5])
        xlim([-4 4]); ylim([-4 4])
        axis off
    end
    
    
end