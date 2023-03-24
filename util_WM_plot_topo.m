function util_WM_plot_topo(data, chanlocs, figTitle, figFullpath)

f = figure; 
topoplot(data,chanlocs, 'maplimits', [min(data), max(data)], 'conv', 'on'); 
title(figTitle)

if ~isfolder(fileparts(figFullpath))
    mkdir(fileparts(figFullpath))
end

saveas(f, figFullpath)
close(f);

end