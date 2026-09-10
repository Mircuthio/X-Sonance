function EEG = load_xdf_to_eeglab(xdfFile)

% ============================================================
% LOAD_XDF_TO_EEGLAB
%
% Robust conversion:
%
% XDF
%   ↓
% EEGLAB EEG structure
%
% Automatically:
% - finds EEG stream
% - finds Marker stream
% - ignores empty streams
% - imports channel labels
% - converts timestamps to EEGLAB latencies
%
% ============================================================

fprintf('\n========================================\n');
fprintf('Loading XDF: %s\n', xdfFile);
fprintf('========================================\n');

%% ------------------------------------------------------------
% LOAD XDF
% ------------------------------------------------------------

streams = load_xdf(xdfFile);

if isempty(streams)
    error('No streams found in XDF file.');
end

fprintf('Streams found: %d\n',length(streams));

%% ------------------------------------------------------------
% IDENTIFY STREAMS
% ------------------------------------------------------------

eegIdx    = [];
markerIdx = [];

for s = 1:length(streams)

    try

        if isempty(streams{s}.time_series)
            continue
        end

        streamName = '';
        streamType = '';

        if isfield(streams{s}.info,'name')
            streamName = lower(string(streams{s}.info.name));
        end

        if isfield(streams{s}.info,'type')
            streamType = lower(string(streams{s}.info.type));
        end

        fprintf('\nStream %d\n',s);
        fprintf('Name : %s\n',char(streamName));
        fprintf('Type : %s\n',char(streamType));

        if contains(streamType,'eeg') || ...
                contains(streamName,'eeg')

            eegIdx = s;

        end

        if contains(streamType,'marker') || ...
                contains(streamType,'event') || ...
                contains(streamName,'marker')

            markerIdx = s;

        end

    catch

        fprintf('Unable to inspect stream %d\n',s);

    end

end

%% ------------------------------------------------------------
% CHECK REQUIRED STREAMS
% ------------------------------------------------------------

if isempty(eegIdx)
    error('EEG stream not found.');
end

if isempty(markerIdx)
    error('Marker stream not found.');
end

fprintf('\nEEG stream    : %d\n',eegIdx);
fprintf('Marker stream : %d\n',markerIdx);

%% ------------------------------------------------------------
% EXTRACT EEG STREAM
% ------------------------------------------------------------

eegStream = streams{eegIdx};

data = double(eegStream.time_series);

% ensure channels x samples

if size(data,1) > size(data,2)

    data = data';

end

%% ------------------------------------------------------------
% SAMPLING RATE
% ------------------------------------------------------------

srate = [];

try

    srate = str2double(eegStream.info.nominal_srate);

catch

end

if isempty(srate) || isnan(srate) || srate<=0

    srate = round( ...
        1/median(diff(eegStream.time_stamps)));

end

fprintf('Sampling rate: %.2f Hz\n',srate);

%% ------------------------------------------------------------
% CREATE EEGLAB DATASET
% ------------------------------------------------------------

EEG = eeg_emptyset;

EEG.data    = data;
EEG.nbchan  = size(data,1);
EEG.pnts    = size(data,2);
EEG.trials  = 1;
EEG.srate   = srate;
EEG.xmin    = 0;
EEG.xmax    = (EEG.pnts-1)/EEG.srate;

%% ------------------------------------------------------------
% CHANNEL LABELS
% ------------------------------------------------------------

try

    channels = ...
        eegStream.info.desc.channels.channel;

    for ch = 1:EEG.nbchan

        lbl = channels{ch}.label;

        EEG.chanlocs(ch).labels = ...
            char(string(lbl));

    end

catch

    warning('Unable to import channel labels.');

    for ch = 1:EEG.nbchan

        EEG.chanlocs(ch).labels = ...
            sprintf('Ch%d',ch);

    end

end

%% ------------------------------------------------------------
% MARKERS
% ------------------------------------------------------------

markerStream = streams{markerIdx};

markerTimes = markerStream.time_stamps;

markerCodes = markerStream.time_series;

if isempty(markerCodes)

    warning('No markers found.');

else

    eegT0 = eegStream.time_stamps(1);

    for ev = 1:length(markerTimes)

        try

            markerValue = markerCodes{ev};

        catch

            markerValue = markerCodes(ev);

        end

        EEG.event(ev).type = ...
            char(string(markerValue));

        EEG.event(ev).latency = ...
            (markerTimes(ev)-eegT0) * ...
            EEG.srate + 1;

    end

end

%% ------------------------------------------------------------
% CONSISTENCY CHECK
% ------------------------------------------------------------

EEG = eeg_checkset(EEG,'eventconsistency');

%% ------------------------------------------------------------
% QC INFO
% ------------------------------------------------------------

EEG.etc.xdfInfo.originalFile = xdfFile;

try
    EEG.etc.xdfInfo.eegStreamName = ...
        eegStream.info.name;
catch
end

try
    EEG.etc.xdfInfo.eegStreamType = ...
        eegStream.info.type;
catch
end

try
    EEG.etc.xdfInfo.markerStreamName = ...
        markerStream.info.name;
catch
end

try
    EEG.etc.xdfInfo.markerStreamType = ...
        markerStream.info.type;
catch
end

EEG.etc.xdfInfo.nEvents = ...
    numel(EEG.event);

fprintf('\nLoaded successfully\n');
fprintf('Channels : %d\n',EEG.nbchan);
fprintf('Samples  : %d\n',EEG.pnts);
fprintf('Events   : %d\n',numel(EEG.event));

end