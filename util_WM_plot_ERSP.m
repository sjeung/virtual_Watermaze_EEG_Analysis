function util_WM_plot_ERSP(ERSPAll, times, freqs, figTitle, figFullpath, mask, lims)

if iscell(ERSPAll{1}) && numel(ERSPAll) == 2 
    
    ERSPp = ERSPAll{1}; ERSPc = ERSPAll{2}; 
    ERSPMat    = NaN([size(ERSPp{1}),numel(ERSPp)]);
    
    for cellInd = 1:numel(ERSPp)
        ERSPMat(:,:,cellInd) = ERSPp{cellInd};
    end
    
    ERSPMeanP    = mean(ERSPMat,3,'omitnan');
    
    ERSPMat    = NaN([size(ERSPc{1}),numel(ERSPc)]);
    
    for cellInd = 1:numel(ERSPc)
        ERSPMat(:,:,cellInd) = ERSPc{cellInd};
    end
    
    ERSPMeanC    = mean(ERSPMat,3,'omitnan');
    ERSPMean    = ERSPMeanP - ERSPMeanC; 
    clims       = [-0.2, 0.2]; 
    
else
    
    ERSPMat    = NaN([size(ERSPAll{1}),numel(ERSPAll)]);
    
    for cellInd = 1:numel(ERSPAll)
       ERSPMat(:,:,cellInd) = ERSPAll{cellInd};
    end
    
    ERSPMean    = mean(ERSPMat,3,'omitnan');
    clims       = lims;
    
end 



if isempty(mask)
    f = figure;
    imagesclogy(times,...
        freqs,...
        ERSPMean);
else
    MaskedMean = ERSPMean;
    allInds = 1:numel(MaskedMean);
    restInds = setdiff(allInds, mask);
    MaskedMean(restInds)    = 0;
    
    f = figure;
    imagesclogy(times,...
        freqs,...
        MaskedMean);
end

axis xy;
ylabel('Frequency')
xlabel('Time in sec')
title(figTitle,'Interpreter', 'none')
xline(0,'black');
xticks([0, 1, 2, 3])
colorbar;
caxis(clims);

if ~isfolder(fileparts(figFullpath))
    mkdir(fileparts(figFullpath))
end

saveas(f, figFullpath)

end