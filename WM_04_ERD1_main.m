function [variance_fm, variance_allEloc, erd_fm, erd_allEloc] = WM_04_ERD1_main(epochedEEG,epochedEEG_baseline)
% it calculates the intertrial variance and ERD values of one participant 
% and stores them in seperated matricies

    
    % rows: electrodes
    % columns: time points
    % 3rd dimension: encoding-MoBI, retrieval-MoBI, baseline-MoBI, 
    % encoding-Desktop, retrieval-Desktop, baseline-Desktop
    variance_allEloc = []; % all electrodes
    
    
    encoding_avg_MoBI  = [];
    encoding_avg_Desk  = [];
    retrieval_avg_MoBI = [];
    retrieval_avg_Desk = [];
    baseline_avg_MoBI  = [];
    baseline_avg_Desk  = [];
         
    encoding_sqr_MoBI  = [];
    encoding_sqr_Desk  = [];
    retrieval_sqr_MoBI = [];
    retrieval_sqr_Desk = [];
    baseline_sqr_MoBI  = [];
    baseline_sqr_Desk  = [];
        

    % 1. Calculate intertrial variance for all electrodes
    %------------------------------------------------------------------------------
    
    % loop over session to calculate the intertrial variance seperately
    for session_idx = 1:2 % 1:MoBI 2:Desktop
        
        % select the all epochs indicies in the sessions
        epochs_trials   = [];
        a = 1;
        for event_idx = 1:numel(epochedEEG.event(:))
            if epochedEEG.event(event_idx).session == session_idx
                epochs_trials(a) = event_idx;
                a = a + 1;
            end
        end        
        
        encoding_epochs  = [];
        retrieval_epochs = [];
        
        % find encoding and retrieval epoch indicies in the sessions
        b = 1;
        c = 1;
        for idx = 1:numel(epochs_trials)
            if contains({epochedEEG.event(epochs_trials(idx)).type}, 'searchtrial:found') == 1
                encoding_epochs(b) = epochedEEG.event(epochs_trials(idx)).epoch;
                b = b + 1;
            elseif contains({epochedEEG.event(epochs_trials(idx)).type}, 'guesstrial:start') == 1
                retrieval_epochs(c) = epochedEEG.event(epochs_trials(idx)).epoch;
                c = c + 1;
            end
        end    
        
        % find baseline epoch indicies in the sessions
        baseline_epochs = [];
        d = 1;
        for i = 1:numel(epochedEEG_baseline.epoch(:))
            if session_idx == 1
                if any(strcmp(epochedEEG_baseline.epoch(i).eventtype, 'X1'))
                    baseline_epochs(d) = i;
                    d = d + 1;
                end    
            else
                if any(strcmp(epochedEEG_baseline.epoch(i).eventtype, 'X2'))
                    baseline_epochs(d) = i;
                    d = d + 1;
                end
            end
        end
        
        
        %------------------------------------------------------------------
        % take the average of data points 
        % Sein : avearge across trials, not time series
        
        % encoding epochs:
        
        % iterate over encoding epochs
        for e = 1:18 % there are 18 epochs in a session in total                   
            for eloc = 1:128  % iterate over electrodes
                if session_idx == 1
                    %encoding_avg_MoBI(eloc,e) = mean(epochedEEG.data(eloc,:,encoding_epochs(e)), 2);    
                    encoding_avg_MoBI(eloc,:) = mean(epochedEEG.data(eloc,:,encoding_epochs(e)), 3);   
                else
                    %encoding_avg_Desk(eloc,e) = mean(epochedEEG.data(eloc,:,encoding_epochs(e)), 2);  
                    encoding_avg_Desk(eloc,:) = mean(epochedEEG.data(eloc,:,encoding_epochs(e)), 3); 
                end         
            end    
        end   
        
        
        % retrieval epochs:
        
        % iterate over retrieval epochs
        for r = 1:24 % there are 24 epochs in a session in total
            for eloc = 1:128 % iterate over electrodes     
                if session_idx == 1
                    retrieval_avg_MoBI(eloc,r) = mean(epochedEEG.data(eloc,:,retrieval_epochs(r)), 2);       
                else
                    retrieval_avg_Desk(eloc,r) = mean(epochedEEG.data(eloc,:,retrieval_epochs(r)), 2);     
                end               
            end
        end   
        
        
        % baseline epochs:
        
        % iterate over baseline epochs
        for b = 1:numel(baseline_epochs)
            for eloc = 1:128 % iterate over electrodes  
                if session_idx == 1
                    baseline_avg_MoBI(eloc,b) = mean(epochedEEG_baseline.data(eloc,:,baseline_epochs(b)), 2);       
                else
                    baseline_avg_Desk(eloc,b) = mean(epochedEEG_baseline.data(eloc,:,baseline_epochs(b)), 2);     
                end            
            end
        end   
        
        
        %----------------------------------------------------------
        % subtract the average from each data point
        % then take their square
        % Sein : compute instead point-to-point intertrial variance 
        %        by subtracting average time course from data samples
        %       (no need to take the square at this point)
        
        % encoding epochs:
        
        % iterate over encoding epochs
        for e = 1:18
            for eloc = 1:128 % iterate over electrodes 
                %for t = 1:500 % time points
                    if session_idx == 1
                        %encoding_sqr_MoBI(eloc,t,e) = (epochedEEG.data(eloc,t,encoding_epochs(e)) - encoding_avg_MoBI(eloc,e))^2;
                        encoding_sqr_MoBI(eloc,:,e) = (epochedEEG.data(eloc,:,encoding_epochs(e)) - encoding_avg_MoBI(eloc,:)).^2;
                    else
                        %encoding_sqr_Desk(eloc,t,e) = (epochedEEG.data(eloc,t,encoding_epochs(e)) - encoding_avg_Desk(eloc,e))^2;
                    end
                %end
            end   
        end
        
        
        % retrieval epochs:
        
        % iterate over retrieval epochs
        for r = 1:24
            for eloc = 1:128 % iterate over electrodes 
                for t = 1:500 % time points
                    if session_idx == 1
                        retrieval_sqr_MoBI(eloc,t,r) = (epochedEEG.data(eloc,t,retrieval_epochs(r)) - retrieval_avg_MoBI(eloc,r))^2;
                    else
                        retrieval_sqr_Desk(eloc,t,r) = (epochedEEG.data(eloc,t,retrieval_epochs(r)) - retrieval_avg_Desk(eloc,r))^2;
                    end
                end
            end   
        end
        
        
        % baseline epochs:
        
        % iterate over baseline epochs
        for b = 1:numel(baseline_epochs)
            for eloc = 1:128 % iterate over electrodes 
                for t = 1:500 % time points
                    if session_idx == 1
                        baseline_sqr_MoBI(eloc,t,b) = (epochedEEG_baseline.data(eloc,t,baseline_epochs(b)) - baseline_avg_MoBI(eloc,b))^2;
                    else
                        baseline_sqr_Desk(eloc,t,b) = (epochedEEG_baseline.data(eloc,t,baseline_epochs(b)) - baseline_avg_Desk(eloc,b))^2;
                    end
                end
            end   
        end
        
        
        % calculate the number of baseline epochs in each session for later calculations
        if session_idx == 1
            n_baseline_MoBI = numel(baseline_epochs);
        else
            n_baseline_Desk = numel(baseline_epochs);
        end
         
        
    end
            
    %---------------------------------------------------
    % take the average over trials
        
    
    % encoding-MoBI
    variance_allEloc(:,:,1) = sum(encoding_sqr_MoBI,3)/17;
        
    % encoding-Desk
    variance_allEloc(:,:,2) = sum(encoding_sqr_Desk,3)/17;
           
    % retrieval-MoBI
    variance_allEloc(:,:,3) = sum(retrieval_sqr_MoBI,3)/23;
        
    % retrieval-Desk
    variance_allEloc(:,:,4) = sum(retrieval_sqr_Desk,3)/23;
        
    % baseline-MoBI
    variance_allEloc(:,:,5) = sum(baseline_sqr_MoBI,3)/(n_baseline_MoBI - 1);
        
    % baseline-Desktop
    variance_allEloc(:,:,6) = sum(baseline_sqr_Desk,3)/(n_baseline_Desk - 1);
  
    
    
    % 2. Create a matrix that includes variance of only interested electrodes
    %---------------------------------------------------------------------
    
    % interested eloctrode names: {'y1','y2','y3','y25','y32'}
    eloc = [33,34,35,57,64];
    
    variance_fm = variance_allEloc(eloc,:,:);

    
    % 3. Calculate ERD/ERS for all electrodes
    %------------------------------------------------------------------

    % encoding-MoBI
    erd_allEloc(:,:,1) = ((variance_allEloc(:,:,1) - variance_allEloc(:,:,5))./variance_allEloc(:,:,5)).*100;
        
    % encoding-Desk
    erd_allEloc(:,:,2) = ((variance_allEloc(:,:,2) - variance_allEloc(:,:,6))./variance_allEloc(:,:,6)).*100;
           
    % retrieval-MoBI
    erd_allEloc(:,:,3) = ((variance_allEloc(:,:,3) - variance_allEloc(:,:,5))./variance_allEloc(:,:,5)).*100;
        
    % retrieval-Desk
    erd_allEloc(:,:,4) = ((variance_allEloc(:,:,4) - variance_allEloc(:,:,6))./variance_allEloc(:,:,6)).*100;
        
    
    
    % 4. Calculate ERD/ERS for only interested electrodes
    %-------------------------------------------------------------------
    
    erd_fm(:,:,:) = erd_allEloc(eloc,:,:); 
       
    
end