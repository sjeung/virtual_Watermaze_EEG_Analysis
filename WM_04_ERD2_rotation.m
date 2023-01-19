function [rotation_var_fm, rotation_var_allEloc] = WM_04_ERD2_rotation(epochedEEG)
% it calculates the intertrial variance values of one participant for rotation
% and stores them in seperated matricies
% it doesn't include erd values and calculation


    % 1. Create matricies for rotated and unrotared retrieval trials
    %-------------------------------------------------------------------
    
    
    % loop over session to calculate power seperately
    for session_idx = 1:2 % 1:MoBI 2:Desktop  
    
        
        % find roation epochs
        %------------------------------------------------
        
        % select the all epochs indicies in the sessions
        epochs_trials   = [];
        a = 1;
        for event_idx = 1:numel(epochedEEG.event(:))
            if epochedEEG.event(event_idx).session == session_idx
                epochs_trials(a) = event_idx;
                a = a + 1;
            end
        end    
              
        
        retrieval_epochs = [];
        ep_0 = [];
        ep_90 = [];
        ep_180 = [];
        ep_270 = [];
        
        % find retrieval event indicies in the sessions
        r = 1;
        
        for idx = 1:numel(epochs_trials)
            
            if contains({epochedEEG.event(epochs_trials(idx)).type}, 'guesstrial:start') == 1
                retrieval_epochs(r) = epochs_trials(idx);
                r = r + 1;
            end
            
        end  
        
        a = 1;
        b = 1;
        c = 1;
        d = 1;
        
        % find rotated and unrotated trials
        for idx = 1:numel(retrieval_epochs)
            
            if epochedEEG.event(retrieval_epochs(idx)).rotation == 0
                ep_0(a) = epochedEEG.event(retrieval_epochs(idx)).epoch;
                a = a + 1;
                
            elseif epochedEEG.event(retrieval_epochs(idx)).rotation == 90
                ep_90(b) = epochedEEG.event(retrieval_epochs(idx)).epoch;
                b = b + 1;
                
            elseif epochedEEG.event(retrieval_epochs(idx)).rotation == 180
                ep_180(c) = epochedEEG.event(retrieval_epochs(idx)).epoch;
                c = c + 1;
                
            elseif epochedEEG.event(retrieval_epochs(idx)).rotation == 270
                ep_270(d) = epochedEEG.event(retrieval_epochs(idx)).epoch; 
                d = d + 1;
                
            end    
            
        end
        
        
        
        % 2. calculate intertrial variance
        %--------------------------------------------------
        
        
        % all electrodes
        %---------------
        
        % take the average of data points
        
        % 0 rotation 
        for x = 1:numel(ep_0)
            for eloc = 1:128
                if session_idx == 1
                    rot0_avg_MoBI(eloc,x) = mean(epochedEEG.data(eloc,:,ep_0(x)), 2);
                else
                    rot0_avg_Desk(eloc,x) = mean(epochedEEG.data(eloc,:,ep_0(x)), 2);   
                end    
            end
        end
        
        % 90 rotation 
        for y = 1:numel(ep_90)
            for eloc = 1:128
                if session_idx == 1
                    rot90_avg_MoBI(eloc,y) = mean(epochedEEG.data(eloc,:,ep_90(y)), 2);
                else
                    rot90_avg_Desk(eloc,y) = mean(epochedEEG.data(eloc,:,ep_90(y)), 2);   
                end    
            end
        end
        
        % 180 rotation 
        for z = 1:numel(ep_180)
            for eloc = 1:128
                if session_idx == 1
                    rot180_avg_MoBI(eloc,z) = mean(epochedEEG.data(eloc,:,ep_180(z)), 2);
                else
                    rot180_avg_Desk(eloc,z) = mean(epochedEEG.data(eloc,:,ep_180(z)), 2);   
                end    
            end
        end
        
        % 270 rotation 
        for q = 1:numel(ep_270)
            for eloc = 1:128
                if session_idx == 1
                    rot270_avg_MoBI(eloc,q) = mean(epochedEEG.data(eloc,:,ep_270(q)), 2);
                else
                    rot270_avg_Desk(eloc,q) = mean(epochedEEG.data(eloc,:,ep_270(q)), 2);   
                end    
            end
        end
        
        
        % subtract the average from each data point
        % then take their square
        
        % 0 rotation
        for x = 1:numel(ep_0) % iterate over epochs
           for eloc = 1:128 % iterate over electrodes 
               for t = 1:500 % time points
                   if session_idx == 1
                       rot0_sqr_MoBI(eloc,t,x) = (epochedEEG.data(eloc,t,ep_0(x)) - rot0_avg_MoBI(eloc,x))^2;
                   else
                       rot0_sqr_Desk(eloc,t,x) = (epochedEEG.data(eloc,t,ep_0(x)) - rot0_avg_Desk(eloc,x))^2;
                   end
               end
           end   
        end
        
        
        % 90 rotation
        for y = 1:numel(ep_90) % iterate over epochs
           for eloc = 1:128 % iterate over electrodes 
               for t = 1:500 % time points
                   if session_idx == 1
                       rot90_sqr_MoBI(eloc,t,y) = (epochedEEG.data(eloc,t,ep_90(y)) - rot90_avg_MoBI(eloc,y))^2;
                   else
                       rot90_sqr_Desk(eloc,t,y) = (epochedEEG.data(eloc,t,ep_90(y)) - rot90_avg_Desk(eloc,y))^2;
                   end
               end
           end   
        end
        
        
        % 180 rotation
        for z = 1:numel(ep_180) % iterate over epochs
           for eloc = 1:128 % iterate over electrodes 
               for t = 1:500 % time points
                   if session_idx == 1
                       rot180_sqr_MoBI(eloc,t,z) = (epochedEEG.data(eloc,t,ep_180(z)) - rot180_avg_MoBI(eloc,z))^2;
                   else
                       rot180_sqr_Desk(eloc,t,z) = (epochedEEG.data(eloc,t,ep_180(z)) - rot180_avg_Desk(eloc,z))^2;
                   end
               end
           end   
        end
        
        
        % 270 rotation
        for q = 1:numel(ep_270) % iterate over epochs
           for eloc = 1:128 % iterate over electrodes 
               for t = 1:500 % time points
                   if session_idx == 1
                       rot270_sqr_MoBI(eloc,t,q) = (epochedEEG.data(eloc,t,ep_270(q)) - rot270_avg_MoBI(eloc,q))^2;
                   else
                       rot270_sqr_Desk(eloc,t,q) = (epochedEEG.data(eloc,t,ep_270(q)) - rot270_avg_Desk(eloc,q))^2;
                   end
               end
           end   
        end
       
        
        % calculate the number of epochs in each session for later
        % calculations
        if session_idx == 1
            n_rot0_MoBI   = numel(ep_0);
            n_rot90_MoBI  = numel(ep_90);
            n_rot180_MoBI = numel(ep_180);
            n_rot270_MoBI = numel(ep_270);
            
        else
            n_rot0_Desk   = numel(ep_0);
            n_rot90_Desk  = numel(ep_90);
            n_rot180_Desk = numel(ep_180);
            n_rot270_Desk = numel(ep_270);
        end
        

    end
    
    
    % take the average over trials
    rotation_var_allEloc(:,:,1) = sum(rot0_sqr_MoBI,3)/(n_rot0_MoBI - 1);
    rotation_var_allEloc(:,:,2) = sum(rot0_sqr_Desk,3)/(n_rot0_Desk - 1);
    rotation_var_allEloc(:,:,3) = sum(rot90_sqr_MoBI,3)/(n_rot90_MoBI - 1);
    rotation_var_allEloc(:,:,4) = sum(rot90_sqr_Desk,3)/(n_rot90_Desk - 1);
    rotation_var_allEloc(:,:,5) = sum(rot180_sqr_MoBI,3)/(n_rot180_MoBI - 1);
    rotation_var_allEloc(:,:,6) = sum(rot180_sqr_Desk,3)/(n_rot180_Desk - 1);
    rotation_var_allEloc(:,:,7) = sum(rot270_sqr_MoBI,3)/(n_rot270_MoBI - 1);
    rotation_var_allEloc(:,:,8) = sum(rot270_sqr_Desk,3)/(n_rot270_Desk - 1);

        
    
    % 3. Create a matrix that includes variance of only interested electrodes
    %------------------------------------------------------------------------
    
    
    % interested eloctrode names: {'y1','y2','y3','y25','y32'}
    eloc = [33,34,35,57,64];
    
    rotation_var_fm = rotation_var_allEloc(eloc,:,:);
    

end