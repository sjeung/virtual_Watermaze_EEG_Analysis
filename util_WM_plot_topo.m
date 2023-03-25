function util_WM_plot_topo(data, chanlocs, figTitle, figFullpath)

f = figure; 
topoplot(data,chanlocs, 'maplimits', [min(data), max(data)]); 
title(figTitle, 'Interpreter', 'none')

if ~isfolder(fileparts(figFullpath))
    mkdir(fileparts(figFullpath))
end

saveas(f, figFullpath)
close(f);

end