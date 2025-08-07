function WM_stat_topo(condText, allParticipants, param)
% condText : probe_mobi_End 

WM_config;

if contains(condText, 'start')
    timeWindow = [0 1]; 
elseif contains(condText, 'mid')
    timeWindow = [0 3]; 
else
    timeWindow = [-2 0]; 
end

if strcmp(param, 'power')
    zLims       = [-3 3];
else
    zLims       = [-2 2];
end

parts = split(condText, '_'); 

% for template for visualisation
if contains(condText, 'stand') || contains(condText, 'walk') 
    [erspFileName,erspFileDir] = assemble_file(config_folder.results_folder, config_folder.ersp_folder, ['_' strjoin({'probe', parts{2}, 'all_theta', 'Mid'}, '_') '_ERSP.mat'], 81001);
else
    [erspFileName,erspFileDir] = assemble_file(config_folder.results_folder, config_folder.ersp_folder, ['_' strjoin({parts{1}, parts{2}, 'all_theta', parts{3}}, '_') '_ERSP.mat'], 81001);
end

load(fullfile(erspFileDir, erspFileName), 'ERSPcorr');

% Initialize variables to store accumulated electrode positions
total_elec_pos = zeros(132, 3);

% Iterate over all participants
for Pi = allParticipants
    
    elec = ft_read_sens(['P:\Sein_Jeung\Project_Watermaze\WM_EEG_Data\source-data\' num2str(Pi) '\' num2str(Pi) '_eloc.elc']); 
    total_elec_pos = total_elec_pos + elec.chanpos;
end

% Calculate average electrode positions and rotate
average_elec_pos = total_elec_pos / numel(allParticipants);
average_elec = elec; 
average_elec.chanpos = [-average_elec_pos(:,2), average_elec_pos(:,1), average_elec_pos(:,3)]; 
average_elec.elecpos = average_elec.chanpos; 

% load summary data
this = load(fullfile('P:\Sein_Jeung\Project_Watermaze\WM_EEG_Results\BOSC-allchans', ['BOSC_' condText '.mat'])); 

% Define frequency bands
freqs = this.boscOutputs{1}.config.eBOSC.F;

% intialize arrays
pepisode_mtlr = []; pow_mtlr = [];
pepisode_ctrl = []; pow_ctrl = [];

% Loop through patients
for Pi = 1:10    % Extract the fields
    pepisode = squeeze(mean(this.boscOutputs{Pi}.pepisode, 2));       % Size: [129×24×46]
    bg_log10_pow = this.boscOutputs{Pi}.static.bg_log10_pow; % Size: [129×46]
    
    % Stack along the third dimension for pepisode and pow_mtlr
    if isempty(pepisode_mtlr)
        pepisode_mtlr = pepisode; % Initialize 3D array on the first iteration
    else
        pepisode_mtlr = cat(3, pepisode_mtlr, pepisode); % Concatenate along the third dimension
    end
    
    if isempty(pow_mtlr)
        pow_mtlr = bg_log10_pow; % Initialize 3D array on the first iteration
    else
        pow_mtlr = cat(3, pow_mtlr, bg_log10_pow); % Concatenate along the third dimension
    end
end

% Loop through controls
for Pi = 11:30    % Extract the fields
    pepisode        = squeeze(mean(this.boscOutputs{Pi}.pepisode, 2));       % Size: [129×24×46]
    bg_log10_pow    = this.boscOutputs{Pi}.static.bg_log10_pow; % Size: [129×46]
    
    % Stack along the third dimension for pepisode and pow_mtlr
    if isempty(pepisode_ctrl)
        pepisode_ctrl = pepisode; % Initialize 3D array on the first iteration
    else
        pepisode_ctrl = cat(3, pepisode_ctrl, pepisode); % Concatenate along the third dimension
    end
    
    if isempty(pow_ctrl)
        pow_ctrl = bg_log10_pow; % Initialize 3D array on the first iteration
    else
        pow_ctrl = cat(3, pow_ctrl, bg_log10_pow); % Concatenate along the third dimension
    end
end

epsilon = 1e-6; % Small offset to prevent extreme values
pepisode_mtlr = max(epsilon, min(1-epsilon, pepisode_mtlr));
pepisode_ctrl = max(epsilon, min(1-epsilon, pepisode_ctrl));

% logit transform the p-episode
pepisode_mtlr_logit = log(pepisode_mtlr ./ (1 - pepisode_mtlr));
pepisode_ctrl_logit = log(pepisode_ctrl ./ (1 - pepisode_ctrl));

% Initialize variables for storing results
sigVals = zeros(129, 5);  % p-values for each electrode
meanTs = zeros(129, 1);   % t-statistics for each electrode

for Fi = 1:5
    
    freqInds = find(freqs > config_param.FOI_lower(Fi) & freqs <= config_param.FOI_upper(Fi));
    
    % Loop through electrodes
    for Ei = 1:129 % Last electrode is reference
       
        if strcmp(param, 'power')
            pMat = nanmean(squeeze(pow_mtlr(Ei, freqInds, :)), 1);
            cMat = nanmean(squeeze(pow_ctrl(Ei, freqInds, :)), 1);
        else
            pMat = nanmean(squeeze(pepisode_mtlr_logit(Ei, freqInds, :)), 1);
            cMat = nanmean(squeeze(pepisode_ctrl_logit(Ei, freqInds, :)), 1);
        end
        % Perform a two-sample t-test
        [~, p, ~, stats] = ttest2(pMat, cMat);
        
        % Store the results
        sigVals(Ei, Fi) = p;                
        meanTs(Ei, Fi) = stats.tstat;       
    end
    
end

sigEs = find(sigVals < 0.05);

% correct p vals using benjamini hochberg method
sorted_pvals    = sort(sigVals(sigEs), 'ascend');
m               = length(sorted_pvals);
threshold       = (1:m) * 0.05 / m;
FDRcorrected    = arrayfun(@(x) [], 1:length(config_param.band_names), 'UniformOutput', false);

for Pi = 1:length(sigEs)
    sigEi = sigEs(Pi);
    if sigVals(sigEi) <= threshold(Pi)
        [Ei, Fi] = ind2sub(size(sigVals), sigEi);
        disp(['p = ' num2str(sigVals(sigEi)) ' for channel ' ERSPcorr.label{Ei} ', ' config_param.band_names{Fi} ' band, FDR corrected'])
        FDRcorrected{Fi}(end+1) = Ei;
    end
end

for Fi = 1:5
    
    ERSPd                   = ERSPcorr;
    ERSPd.powspctrm         = repmat(meanTs(:,Fi),1,1,numel(ERSPd.time));
    
    %--------------------------------------------------------------------------
    cfg                     = [];
    cfg.figure              = 'gcf';
    cfg.elec                = average_elec;
    cfg.xlim                = timeWindow;
    cfg.comment             = 'no';
    cfg.zlim                = zLims;
    cfg.highlight           = 'on';
    cfg.colormap            = 'coolwarm';
    %cfg.highlightchannel    = {ERSPcorr.label{FDRcorrected{Fi}}};
    %chanInterest              = {'y1','y2','y3','y25','y32', ... % FM
                               %'r9', 'r10', 'r11', 'r27', 'r32', ... % PM 
                               %'g1', 'y16', 'r15', 'r13', ... % LT
                               %'g24','y20', 'r18', 'r20'}; % RT 
   % cfg.highlightchannel    = chanInterest;
    %cfg.highlightsymbol     = '.';
    %cfg.highlightsize       = 40; 
    %cfg.highlightcolor      = repelem({[1,1,1]},1,numel(FDRcorrected));
    
    f3 = figure('visible', 'off');
    ft_topoplotTFR(cfg,ERSPd); colorbar;
    
    figureFileDir = fullfile(config_folder.figures_folder, 'topoplots');
    if ~isfolder(figureFileDir)
        mkdir(figureFileDir)
    end
    saveas(f3, fullfile(figureFileDir,[condText '_' config_param.band_names{Fi} '_diffs_' param '.png']))
    close(f3);
    
end


end