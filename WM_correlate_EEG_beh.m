function [correlation_coefficients] =  WM_correlate_EEG_beh(behData, EEGData)    

    % Get the number of behavioral measures and EEG power bands
    numBehMeasures = size(behData, 2);
    numEEGBands = size(EEGData, 2);
    
    % Initialize the correlation_coefficients matrix
    correlation_coefficients = zeros(numBehMeasures, numEEGBands);
    
    % Loop through each behavioral measure and EEG power band
    for behIdx = 1:numBehMeasures
        for EEGIdx = 1:numEEGBands
            % Extract the data for the current behavioral measure and EEG band
            x = behData(:, behIdx);
            y = EEGData(:, EEGIdx);
            
            % Calculate the Pearson correlation coefficient
            correlation = corr(x, y);
            
            % Store the correlation coefficient in the output matrix
            correlation_coefficients(behIdx, EEGIdx) = correlation;
        end
    end
    
    
end