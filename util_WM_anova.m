function util_WM_anova(data, trialType, chanGroupName)

% statistics - ANOVA
%--------------------------------------------------------------------------
anovaData =  data(:); 

group = {};
setup = {};
for Ci = 1:4
    if Ci == 1
        g = 'mtl';s = 'mobi';
    elseif Ci == 2
        g = 'mtl';s = 'stat'; 
    elseif Ci == 3
        g = 'ctrl';s = 'mobi'; 
    else
        g = 'ctrl';s = 'stat'; 
    end
    
    for ind = 1:size(data,1)
        group{end + 1} = g;
        setup{end + 1} = s; 
    end
end

p = anovan(anovaData,{group, setup},'model','full','varnames',{'group','setup'});

disp([ chanGroupName ', ' trialType ' group p = ' num2str(p(1))])
disp([ chanGroupName ', ' trialType ' session p = ' num2str(p(2))])
disp([ chanGroupName ', ' trialType ' interaction p = ' num2str(p(3))])

f = figure;
boxplot2(data,[1,1.2,2,2.2]);

h =  findobj(gca,'Tag','Box');

for j=1:length(h)
    
    if mod(j,2) == 1
        color = [255, 204, 51]/(256); % the bar indices are from right to left - this is ctrl color
    else
        color = 'b';
    end
    
    patch(get(h(j),'XData'),get(h(j),'YData'),color,'FaceAlpha',.3, 'EdgeColor','w');
    
end

hold on

pos = [1,1.2,2,2.2];


for i = 1:size(data,2)
    scatter(rand(1,size(data,1))*0.1 - 0.05 + ...
        pos(i)*ones(1,numel(data(:,i))), data(:,i), ...
        'MarkerFaceColor', [.5,.5,.5], 'MarkerFaceAlpha',.5, 'MarkerEdgeColor', 'none');
end

title([trialType ' trial, ' chanGroupName], 'Interpreter', 'none');
ylabel('theta power', 'Interpreter', 'none');
xlim([0.5, 2.5]);
xticks([1.1, 2.1]);
xlabel('groups','Interpreter', 'none');
set(gca,'xticklabel',{'mtl', 'ctrl'}, 'FontSize',14);
ax = gca;
ax.XGrid = 'off';
ax.YGrid = 'on';

saveas(f,[trialType '_anova_' chanGroupName '.png'])

end