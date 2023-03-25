function [ERSPcorr] = util_WM_basecorrect(ERSPdata, ERSPbase)

for Ei = 1:numel(ERSPdata)
    basePower       = mean(ERSPbase{Ei},2);
    ERSPdata{Ei}    = ERSPdata{Ei} - repmat(basePower, [1,size(ERSPdata{Ei},2)]); 
end

ERSPcorr = ERSPdata; 

end