function subj_list_roi = select_roi_channels(subj_list, ROI)
% select_roi_channels
% Keep only ROI channels from data_trials.eeg for each subject/trial
%
% INPUT:
%   subj_list : struct array with fields subj_id and data_trials
%   ROI       : cell array of channel labels, e.g. {'Fp1','Cz'}
%
% OUTPUT:
%   subj_list_roi : same struct as subj_list, but each data_trials(k).eeg
%                   contains only ROI channels found in chanlocs

    subj_list_roi = subj_list;

    for s = 1:numel(subj_list_roi)

        if ~isfield(subj_list_roi(s), 'data_trials') || isempty(subj_list_roi(s).data_trials)
            continue;
        end

        for t = 1:numel(subj_list_roi(s).data_trials)

            if ~isfield(subj_list_roi(s).data_trials(t), 'chanlocs') || ...
               ~isfield(subj_list_roi(s).data_trials(t), 'eeg') || ...
               isempty(subj_list_roi(s).data_trials(t).chanlocs) || ...
               isempty(subj_list_roi(s).data_trials(t).eeg)
                continue;
            end

            chanlabels = {subj_list_roi(s).data_trials(t).chanlocs.labels};

            [isMatch, idxROI] = ismember(lower(ROI), lower(chanlabels));
            idxKeep = idxROI(isMatch);

            subj_list_roi(s).data_trials(t).eeg = subj_list_roi(s).data_trials(t).eeg(idxKeep, :);
            subj_list_roi(s).data_trials(t).chanlocs = subj_list_roi(s).data_trials(t).chanlocs(idxKeep);

            if isfield(subj_list_roi(s).data_trials(t), 'nbchan')
                subj_list_roi(s).data_trials(t).nbchan = numel(idxKeep);
            end
        end
    end
end