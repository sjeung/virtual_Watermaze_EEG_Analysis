function [ERSPStart, ERSPEnd, times, freqs] = util_WM_cut_windows(ERSP, freqs, winWidth)

% inputs 
% ERSP : ERSP struct
%           ERSP{n}.times : vector of time in miliseconds
% width : time window in seconds


% Parameters
%--------------------------------------------------------------------------
buffer                  = 1; % buffer at the beginning and end of the edge events, in seconds
freqLower               = round(ERSP{1}.freqs(1));
freqUpper               = round(ERSP{1}.freqs(end));

%nFreqBins               = 60;
freqBinEdges            = [freqs freqs(end) + 0.01]; %linspace(freqLower, freqUpper, nFreqBins + 1);
nTimeBins               = 200;
ERSPStart               = {};
ERSPEnd                 = {};

for tInd = 1:size(ERSP,2)
    
    ERSPStartInTrial = {};
    ERSPEndInTrial = {};
    
    for Ei = 1:size(ERSP,1)
        
        binnedERSPStart         = nan(numel(freqs), nTimeBins); % initialize a nan-filed matrix to store re-binned power data
        binnedERSPEnd           = binnedERSPStart;
        times                   = ERSP{Ei,tInd}.times/1000;
        timeBinEdgesStart       = linspace(-buffer, winWidth + buffer, nTimeBins + 1);
        timeBinEdgesEnd         = timeBinEdgesStart + times(end) - buffer - winWidth;
        
        for Wi = 1:2
            
            if Wi == 1
                timeBinEdges    = timeBinEdgesStart;
            else
                timeBinEdges    = timeBinEdgesEnd;
            end
            
            % Assign the values to bins and average if multiple samples fall in the same bin
            for Ti = 1:nTimeBins
                for Fi = 1:numel(freqs)
                    
                    % Find the indices of the input data falling within the current bin
                    tInds   = find(times >= timeBinEdges(Ti) & times < timeBinEdges(Ti + 1));
                    fInds   = find(ERSP{Ei,tInd}.freqs >= freqBinEdges(Fi) & ERSP{Ei,tInd}.freqs < freqBinEdges(Fi +1));
                    
                    if isempty(tInds) || isempty(fInds)
                        binnedERSP(Fi,Ti) = NaN;
                    else
                        tfVals  = ERSP{Ei,tInd}.tf(fInds,tInds);
                        binnedERSP(Fi,Ti)   = mean(tfVals);
                    end
                    
                end
            end
            
            % Iterate through each row
            for Ri = 1:numel(freqs)
                nanIndices = isnan(binnedERSP(Ri, :));  % Find the indices of NaN values in the current row
                
                % Check if the row is entirely NaN
                if all(nanIndices)
                    if Ri > 1
                        binnedERSP(Ri, :) = binnedERSP(Ri-1, :); % Assign the values from the preceding row
                    end
                else
                    % Extrapolate NaN values by using the nearest non-NaN values
                    nearestIndices = find(~nanIndices);  % Find the indices of the nearest non-NaN values
                    for col = find(nanIndices)
                        [~, nearestIndex] = min(abs(col - nearestIndices)); % Find the index of the nearest non-NaN value
                        binnedERSP(Ri, col) = binnedERSP(Ri, nearestIndices(nearestIndex)); % Assign the value from the nearest non-NaN position
                    end
                end
            end
            
            if Wi == 1
                binnedERSPStart = binnedERSP;
            else
                binnedERSPEnd = binnedERSP;
            end
        end
        
        ERSPStartInTrial{Ei}       = binnedERSPStart;
        ERSPEndInTrial{Ei}         = binnedERSPEnd;
    end
    
    ERSPStart{tInd}       = mean(cat(3,ERSPStartInTrial{:}),3);
    ERSPEnd{tInd}         = mean(cat(3,ERSPEndInTrial{:}),3);
    
end

% % Average the matrices over electrodes
% ERSPStartAvg = mean(cat(3, ERSPStart{Ei,:}), 3);
% ERSPEndAvg = mean(cat(3, ERSPEnd{Ei,:}), 3);
% 
% % Assign the averaged matrices back to the cell array
% ERSPStart(Ei,:) = {ERSPStartAvg};
% ERSPEnd(Ei,:) = {ERSPEndAvg};

%freqs  = (freqBinEdges(1:end-1) + freqBinEdges(2:end)) / 2;
times  = (timeBinEdges(1:end-1) + timeBinEdges(2:end)) / 2;

end