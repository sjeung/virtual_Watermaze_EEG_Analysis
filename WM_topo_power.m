function WM_topo_power(fLower, fUpper, allParticipants)

WM_config;
sessions        = {'mobi', 'stat'};
timeWindows     = {'start', 'mid', 'end'};
patientIDs      = allParticipants(floor((allParticipants-80000)/1000) == 1);
controlIDs      = allParticipants(floor((allParticipants-80000)/1000) >= 1);



for Si = 1:2
    session = sessions{Si};
    for Wi = 1:3
        timeWindow = timeWindows{Wi};
        for pGroups = 1:2
            if pGroups == 1
                participants = patientIDs;
            else
                participants = controlIDs;
            end
            
            % load baseline spectra
            baseFilePath = fullfile(config_folder.results_folder, 'baseline_spectra', [channelGroup.key '_' baseType '_' sessionType '_baseline.mat']);
            
            for Pi = participants
                
                [epochedFileName, epochedFileDir]    = assemble_file(config_folder.data_folder, config_folder.epoched_folder, ['_probe_', session, config_folder.epochedFileName], Pi);
                
                
                % load epoched data and rejected trials
                epoched             = load(fullfile(epochedFileDir, epochedFileName));
                EEG                 = epoched.ftEEG;
                rejectedTrials      = load(); 
                
                % do spectral anaylsis
                cfg                     = [];
                cfg.output              = 'pow';
                cfg.method              = 'mtmconvol';
                cfg.taper               = 'hanning';
                cfg.foi                 = fLower:1:fUpper;
                cfg.t_ftimwin           = ones(length(cfg.foi),1).*0.7;
                cfg.toi                 = 'all';
                cfg.pad                 = 'nextpow2';
                cfg.padratio            = 4;
                cfg.datatype            = 'raw';
                cfg.trials              = [1]; 
                cfg.keeptrials          = 'no';
                ERSP                    = ft_freqanalysis(cfg, EEG);
                
                cfg = [];
                cfg.xlim = [0 2];
                %cfg.zlim = [0 5];
                cfg.baseline = [-0.5 -0.0];
                cfg.baselinetype = 'absolute';
                cfg.layout = 'P:\Sein_Jeung\Project_Watermaze\WM_EEG_Data\source-data\81005\81005_eloc.elc';
                figure; ft_topoplotTFR(cfg,ERSP); colorbar
                
            end
            
            % concatenate
            
        end
        
        % plot scalp map
    end
end


end