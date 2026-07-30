function D = build_Barbieri_pipeline_scaffold(trcFile)
% build_Barbieri_pipeline_scaffold
% Crea uno scaffold coerente per TRC Micromed Brain-Quick.

if nargin < 1 || isempty(trcFile)
    error('trcFile is required.');
end

D = struct();
D.trcFile = trcFile;
D.fs = NaN;
D.epochMs = [-200 800];
D.baselineMs = [-200 0];
D.time = [];
D.chanLabels = {};
D.goodEEG = {};
D.badChannels = {'A1','A2'};
D.events = struct([]);
D.meta = struct();
D.meta.note = 'Scaffold iniziale per pipeline Barbieri.';
end