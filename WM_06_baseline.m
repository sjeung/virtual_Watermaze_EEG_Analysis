function WM_06_baseline(Pi, elecGroup)
% Inputs 
%   Pi          : participant ID
%   elecInds    : 'none' or channel indices
%
% Outputs 
%   none, writes data to disk 
%
%--------------------------------------------------------------------------
WM_config;                                                                  % load configs
freqRange                   = config_param.ERSP_freq_range; 


tasks       = {'stand', 'walk'};
sessions    = {'mobi', 'stat'};

for Ti = 1:2
    for Si = 1:2
        
        % create path to output file  
        [baseFileName,baseFileDir] = assemble_file(config_folder.results_folder, 'baseline_powers', ['_' tasks{Ti} '_' sessions{Si} '_' elecGroup.key '_baseline-power.mat'], Pi);
        
        % compute baseline ERSP 
        baseERSP    = util_WM_ERSP(elecGroup.chan_names, tasks{Ti}, sessions{Si}, Pi, freqRange);
        
        % remove outlier trials and condense trial dimension 
        ERSPIQR     = baseERSP; 
        powers      = mean(ERSPIQR.powspctrm, [2,3,4],'omitnan');
        [excInds]   = util_WM_IQR(powers);
        excTrials   = find(excInds);
        allTrials   = 1:numel(powers);
        keepTrials  = setdiff(allTrials, excTrials);
        
        % average across trials again
        cfg                 = [];
        cfg.trials          = keepTrials;
        ERSPIQR             = ft_selectdata(cfg, ERSPIQR);
        ERSPIQR.powspctrm   = squeeze(mean(ERSPIQR.powspctrm, 1,'omitnan'));
        ERSPIQR.cumtapcnt   = squeeze(mean(ERSPIQR.cumtapcnt, 1,'omitnan'));
        ERSPIQR.dimord      = 'chan_freq_time';
        ERSPIQR.elemtrials  = excTrials;
        
        if ~isfolder(baseFileDir)
            mkdir(baseFileDir)
        end
        
        save(fullfile(baseFileDir,baseFileName), 'ERSPIQR');

    end
end


end

        
   