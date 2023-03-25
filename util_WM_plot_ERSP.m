function util_WM_plot_ERSP(ERSPAll, times, freqs, figTitle, figFullpath, mask)


for Ei = 1:numel(ERSPAll)
    if Ei == 1
        ERSPMean = ERSPAll{1};
    else
        ERSPMean = ERSPMean + ERSPAll{Ei};
    end
end
ERSPMean = ERSPMean./numel(ERSPAll); 

f = figure;
imagesclogy(times,...
    freqs,...
    ERSPMean);%,...
axis xy;
ylabel('Frequency')
xlabel('Time in ms')
title(figTitle,'Interpreter', 'none')
xline(0,'black');
xticks([500, 1500, 2500])
colorbar; 

if ~isempty(mask)
 caxis([-4, 4]); 
end

if ~isfolder(fileparts(figFullpath))
    mkdir(fileparts(figFullpath))
end

saveas(f, figFullpath)
close(f);


if ~isempty(mask)
    MaskedMean = ERSPMean;
    allInds = 1:numel(MaskedMean);
    restInds = setdiff(allInds, mask{1});
    MaskedMean(restInds)    = 10;
    MaskedMean(mask{1})     = 2.5;
    f = figure;
    imagesclogy(times,...
        freqs,...
        MaskedMean);%,...
    axis xy;
    ylabel('Frequency')
    xlabel('Time in ms')
    title(figTitle,'Interpreter', 'none')
    xline(0,'black');
    xticks([500, 1500, 2500])
    caxis([0, 4.5]);
    colormap(gca, pink);
    saveas(f, [figFullpath(1:end-4) '_mask.png'])
    close(f);
end

end