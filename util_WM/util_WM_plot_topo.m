function util_WM_plot_topo(data, chanlocs, figTitle, figFullpath)

f = figure; 
topoplot(data*0,chanlocs, 'maplimits', [min(data), max(data)], 'electrodes', 'on', 'emarker', {'o','k',[],1}); 

%topoplot(data,chanlocs, 'maplimits', [min(data), max(data)], 'electrodes', 'on'); 
title(figTitle, 'Interpreter', 'none')

if ~isfolder(fileparts(figFullpath))
    mkdir(fileparts(figFullpath))
end

saveas(f, figFullpath)
close(f);

end