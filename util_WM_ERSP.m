function [ERSPAll] = util_WM_ERSP(EEG, elecInds, trialType, session)

timeBuffer = [-1 1]; % buffer time pre- and post- epoch 

ERSPAll = {}; 

fft_options = struct();
fft_options.cycles = [3 0.25];
fft_options.freqrange = [3 20];
fft_options.freqscale = 'log';
fft_options.padratio = 2;
fft_options.alpha = NaN;
fft_options.powbase = NaN;

% extract trials
lStarts     = find(contains({EEG.event.type}, 'searchtrial:start')); 
lEnds       = find(contains({EEG.event.type}, 'searchtrial:found')); 
pStarts     = find(contains({EEG.event.type}, 'guesstrial:start')); 
pEnds       = find(contains({EEG.event.type}, 'guesstrial:keypress'));

assert(numel(lStarts) == numel(lEnds)); 
assert(numel(pStarts) == numel(pEnds)); 
assert(numel(lStarts) == 36); 
assert(numel(pStarts) == 48); 

learnTrials = [EEG.event(lStarts).latency; EEG.event(lEnds).latency]; % 2xN vector consisting of start and end indices
probeTrials = [EEG.event(pStarts).latency; EEG.event(pEnds).latency]; % 2xN vector consisting of start and end indices

% define learn versus probe trials 
if strcmp(trialType, 'learn')
    trials = learnTrials; 
elseif strcmp(trialType, 'probe') 
    trials = probeTrials; 
else
    disp(['trialType variable ' trialType ' not defined'])
end

% define stat versus mobi trials: VR comes first and then desktop
if strcmp(session, 'mobi')
    trials = trials(:,1:size(trials,2)/2); 
elseif strcmp(session, 'stat') 
    trials = trials(:,size(trials,2)/2+1:end); 
else
    disp(['session variable ' session ' not defined'])
end


for Ei = 1:numel(elecInds)
    for Ti = 1:size(trials, 2)
        tWindow = trials(1,Ti)+timeBuffer(1)*EEG.srate:trials(2,Ti)+timeBuffer(2)*EEG.srate; % in latency, for indexing data point
        [tf,~,~,times,freqs,~,~] = newtimef(EEG.data(Ei,tWindow),...
            numel(tWindow),...
            [timeBuffer(1)*1000 EEG.times(tWindow(end))-EEG.times(tWindow(1))-timeBuffer(2)*1000],... % in miliseconds, offset by event latency
            EEG.srate,...
            'cycles',fft_options.cycles,...
            'freqs',fft_options.freqrange,...
            'freqscale',fft_options.freqscale,...
            'padratio',fft_options.padratio,...
            'alpha',fft_options.alpha,...
            'powbase',fft_options.powbase,...
            'baseline',NaN,... % manually subtract baseline task activity
            'plotersp','off',...
            'plotitc','off',...
            'verbose','off',...
            'timesout',[-10]); % Number of output times (int<frames-winframes). Enter a
%                     negative value [-S] to subsample original times by S.
        disp(['Trial ' num2str(Ti) ' session ' session ', ' trialType ' ERSP processed'])
        
        ERSP.tf         = tf;
        ERSP.times      = times;                                            % times in miliseconds, offset by event latency
        ERSP.freqs      = freqs;
        ERSP.electrode  = elecInds(Ei);
        ERSP.duration   = ((trials(2,Ti)- trials(1,Ti))/EEG.srate)*1000;    % duration in miliseconds
        ERSPAll{Ei, Ti} = ERSP;
    end
end

end