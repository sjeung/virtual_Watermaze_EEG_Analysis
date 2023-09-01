function rfpt_plot(rfptResults, IDs)
% read in a matrix containing classes and turner points for participants 
% visualizes the results as a scatter plot 
%
% Inputs 
%       rfptResults [Nx2 matrix]
%               : matrix containing class indices in column 1
%                 and turner points in column 2 for each pariticipant
%                 (class index 0 : unclassified, 1: turner, 2: nonturner)
%               example     [1,12;  1,11;  2,0;  2,2]
%
%
% author : Sein Jeung
%--------------------------------------------------------------------------

% Scatter plot
%--------------------------------------------------------------------------
turnerIndices       = find(rfptResults(:,1) == 1);  
nonturnerIndices    = find(rfptResults(:,1) == 2); 
noClassIndices      = find(rfptResults(:,1) == 0); 

figure
scatter(turnerIndices,rfptResults(turnerIndices,2), 200, 'filled', 'MarkerEdgeColor', 'none', 'MarkerFaceColor', turnerColor)
hold on
scatter(nonturnerIndices,rfptResults(nonturnerIndices,2), 200, 'filled', 'MarkerEdgeColor', 'none', 'MarkerFaceColor', nonturnerColor)
scatter(noClassIndices,rfptResults(noClassIndices,2), 200, 'filled', 'MarkerEdgeColor', 'none', 'MarkerFaceColor', noClassColor)
ylim([0 max(rfptResults(:,2)) + 3]);
ylabel('Turner points')
xlim([0 size(rfptResults,1) + 1]); 
xlabel('Participant')

xticks(1:nSubjects); 
xticklabels(IDs(:))
yticks(0:3:max(rfptResults(:,2)))

title('Turner points in RFPT')

ax = gca;
ax.FontSize = 15; 

end
