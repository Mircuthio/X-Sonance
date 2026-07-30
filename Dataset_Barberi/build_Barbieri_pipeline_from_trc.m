function [D, labels, events, data_trials] = build_Barbieri_pipeline_from_trc(trcFile)
% build_Barbieri_pipeline_from_trc
% Wrapper unico da chiamare nel main.

D = build_Barbieri_pipeline_scaffold(trcFile);
labels = parse_Barbieri_channel_labels(trcFile);
D.chanLabels = labels;
D.goodEEG = setdiff(labels, D.badChannels, 'stable');

headerNames = {'EVENT A','EVENT B','TRIGGER','BRAINIMG'};
events = build_Barbieri_events_from_header(headerNames);
D.events = events;

data_trials = assemble_Barbieri_data_trials_from_scaffold(D, events);
end