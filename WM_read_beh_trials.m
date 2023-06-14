trialsStructPath    = 'P:\Sein_Jeung\Project_Watermaze\WM_EEG_Results\WP8_WM_table.mat';
targetFolder        = 'P:\Sein_Jeung\Project_Watermaze\WM_EEG_Results\'; 
load(trialsStructPath, 'wm'); 

groups  = 1:4;
IDs     = 1:11;  

for Gi = groups

    for Ii = IDs

        Pi = num2str(80000 + Gi*1000 + Ii);
        
        try 
            
        for Si = 1:2 % in the results struct, setup 1 is desktop and 2 is mobi
          
            presentation_order = cellfun(@(x) x(:).presented_order, wm.setup{Si}.group{Gi}.sub{Ii}.blocks(:))';
        
            learns(18)  = struct();
            probes(24)  = struct();

            lBlocks     = repelem([1:6], 1, 3); 
            lTrials     = repmat([1:3],1,6); 
            pBlocks     = repelem([1:6], 1, 4);
            pTrials     = repmat([1:4],1,6); 

            for iLearn = 1:18

                Oi      = lBlocks(iLearn); 
                Bi      = find(presentation_order == Oi);                   % convert order index to condition index to choose the right block in the struct (ordered by condition) 
                LT      = wm.setup{Si}.group{Gi}.sub{Ii}.blocks{Bi}.search; 
                lFN     = fieldnames(LT); 

                for Fi = 1:length(lFN)
                    if numel(LT.(lFN{Fi})) == 3 && isnumeric(LT.(lFN{Fi}))
                        learns(iLearn).(lFN{Fi}) = LT.(lFN{Fi})(lTrials(iLearn));  
                    elseif numel(LT.(lFN{Fi})) == 1 && isnumeric(LT.(lFN{Fi}))
                        learns(iLearn).(lFN{Fi}) = LT.(lFN{Fi});
                    end
                end

            end
            
            for iProbe = 1:24

                Oi      = pBlocks(iProbe); 
                Bi      = find(presentation_order == Oi);                   % convert order index to condition index to choose the right block in the struct (ordered by condition) 
                PT      = wm.setup{Si}.group{Gi}.sub{Ii}.blocks{Bi}.guess; 
                pFN     = fieldnames(PT);                                   % get probe trial field names 

                for Fi = 1:length(pFN)
                    if numel(PT.(pFN{Fi})) == 4 && isnumeric(PT.(pFN{Fi}))
                        probes(iProbe).(pFN{Fi}) = PT.(pFN{Fi})(pTrials(iProbe));
                    elseif numel(PT.(pFN{Fi})) == 1 && isnumeric(PT.(pFN{Fi}))
                        probes(iProbe).(pFN{Fi}) = PT.(pFN{Fi});
                    end
                end

            end
           
            if strcmp(wm.setup{Si}.setup, 'desktop')
                statLearn = learns; 
                statProbe = probes; 
            elseif strcmp(wm.setup{Si}.setup, 'VR')
                mobiLearn = learns; 
                mobiProbe = probes; 
            end
            
            clear('learns'); clear('probes');
        
        end % for Si = 1:2
        
        catch
            warning(['Could not convert beh results for ' Pi])
        end
        
    save(fullfile(targetFolder, [Pi '_beh_trials.mat']), 'mobiLearn', 'mobiProbe', 'statLearn', 'statProbe')
        
    end % for Ii = IDs
end
