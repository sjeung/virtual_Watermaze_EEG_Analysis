function util_WM_plot_trial_lengths(learnSTAT, learnMOBI, probeSTAT, probeMOBI, Pi) 
WM_config; 

f = figure;
ERSPs           = {learnSTAT, learnMOBI, probeSTAT, probeMOBI};
titles          = {'learn, mobi','learn, stat','learn, mobi','probe, stat'};
for Fi = 1:4
    
    subplot(2,2,Fi)
    nTrials         = size(ERSPs{Fi}.powspctrm,1);
    tLengths        = [];
    for Ti = 1:nTrials 
        dataRow         = ERSPs{Fi}.powspctrm(Ti,1,1,:); 
        dataRow         = squeeze(dataRow);
        tLengths(end+1)  = find(~isnan(dataRow),1,'last')/250; 
    end
    barh(tLengths)
    xlabel('seconds')
    ylabel('trials')
    title(titles{Fi});
end

[~,erspFileDir]  = assemble_file(config_folder.results_folder, config_folder.ersp_folder, [], Pi);

if ~isfolder(erspFileDir)
    mkdir(erspFileDir)
end

saveas(f, fullfile(erspFileDir, ['sub-' num2str(Pi) '_trial_lengths.png']))
close(f);

end