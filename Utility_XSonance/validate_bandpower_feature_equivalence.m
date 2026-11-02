function validate_bandpower_feature_equivalence( ...
    subj_list,cfgFD,nTrialsPerSubj)

nSubj = numel(subj_list);
maxAbsDiffAll = 0;
maxRelDiffAll = 0;
nTested = 0;

for iSub = 1:nSubj
    data_trials = subj_list(iSub).data_trials;

    % Prendi le prime N trial valide
    validIdx = find(ismember( ...
        [data_trials.eventCode], ...
        cfgFD.class_codes));

    validIdx = validIdx(1:min(nTrialsPerSubj,numel(validIdx)));

    for iT = 1:numel(validIdx)
        tr = data_trials(validIdx(iT));

        BP_old = OLDextract_bandpower_features_v2(tr,cfgFD);
        BP_new = extract_bandpower_features_v2(tr,cfgFD);
        if ~isequal(BP_old.Names,BP_new.Names)

            nOld = numel(BP_old.Names);
            nNew = numel(BP_new.Names);

            fprintf('\n--- FEATURE NAME MISMATCH ---\n');
            fprintf('Subject: %s\n',string(subj_list(iSub).subj_id));
            fprintf('Trial  : %s\n',string(tr.trialID));
            fprintf('nOld   : %d\n',nOld);
            fprintf('nNew   : %d\n',nNew);

            nCompare = min(nOld,nNew);

            for iF = 1:nCompare
                if ~strcmp(BP_old.Names{iF},BP_new.Names{iF})
                    fprintf('\nFirst mismatch at feature %d:\n',iF);
                    fprintf('OLD: %s\n',BP_old.Names{iF});
                    fprintf('NEW: %s\n',BP_new.Names{iF});
                    break
                end
            end

            if nOld ~= nNew
                fprintf('\nExtra OLD names:\n');
                for iF = nCompare+1:nOld
                    fprintf('  %s\n',BP_old.Names{iF});
                end

                fprintf('\nExtra NEW names:\n');
                for iF = nCompare+1:nNew
                    fprintf('  %s\n',BP_new.Names{iF});
                end
            end

            fprintf('-----------------------------\n\n');
        end

        assert(isequal(BP_old.Names,BP_new.Names), ...
            'Feature names/order mismatch for subject %s, trial %s', ...
            string(subj_list(iSub).subj_id), ...
            string(tr.trialID));
        % 1. Stessi nomi e stesso ordine
        assert(isequal(BP_old.Names,BP_new.Names), ...
            'Feature names/order mismatch for subject %s, trial %s', ...
            string(subj_list(iSub).subj_id), ...
            string(tr.trialID));

        % 2. Stesso numero di valori
        assert(numel(BP_old.Values) == numel(BP_new.Values), ...
            'Feature count mismatch for subject %s, trial %s', ...
            string(subj_list(iSub).subj_id), ...
            string(tr.trialID));

        % 3. Confronto numerico
        vOld = BP_old.Values;
        vNew = BP_new.Values;

        % NaN devono trovarsi negli stessi punti
        assert(isequaln(isnan(vOld),isnan(vNew)), ...
            'NaN pattern mismatch for subject %s, trial %s', ...
            string(subj_list(iSub).subj_id), ...
            string(tr.trialID));

        notNaN = ~isnan(vOld) & ~isnan(vNew);

        absDiff = abs(vOld(notNaN) - vNew(notNaN));
        denom = max(abs(vOld(notNaN)),abs(vNew(notNaN)));
        relDiff = absDiff ./ max(denom,eps);

        maxAbsDiffAll = max(maxAbsDiffAll,max(absDiff));
        maxRelDiffAll = max(maxRelDiffAll,max(relDiff));
        nTested = nTested + 1;

        fprintf(['%s | %s | nFeat=%d | ' ...
            'maxAbsDiff=%.3e | maxRelDiff=%.3e\n'], ...
            string(subj_list(iSub).subj_id), ...
            string(tr.trialID), ...
            numel(vOld), ...
            max(absDiff), ...
            max(relDiff));
    end
end

fprintf('\n');
fprintf('================================\n');
fprintf('EQUIVALENCE TEST COMPLETED\n');
fprintf('================================\n');
fprintf('Trials tested : %d\n',nTested);
fprintf('Max abs diff  : %.3e dB\n',maxAbsDiffAll);
fprintf('Max rel diff  : %.3e\n',maxRelDiffAll);

% Tolleranza: pratica per confronto tra implementazioni equivalenti
absTol = 1e-8;
relTol = 1e-8;

pass = all( ...
    (maxAbsDiffAll <= absTol) | ...
    (maxRelDiffAll <= relTol));

assert(pass, ...
    'Bandpower feature extraction is NOT equivalent.')

fprintf('EQUIVALENCE TEST PASSED\n');
end