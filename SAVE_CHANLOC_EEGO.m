%% SAVE_CHANLOC_EEGO
clear; close all; clc

debugMode = false;
%% ============================================================
% 1) PATHS AND DEPENDENCIES
% ============================================================
raw_dir    = 'D:\VCode_XSonance';
output_dir = 'D:\VCode_XSonance\Extracted\';

% addpath(genpath('D:\eeglab2023.1\'))
addpath(genpath('D:\eeglab2026.0.0\'))

if ~exist(output_dir, 'dir')
    mkdir(output_dir);
end

%% ============================================================
% 3) FILE SEARCH
% ============================================================
% files_xdf = dir(fullfile(raw_dir,'*.xdf'));
files_cnt = dir(fullfile(raw_dir,'*.cnt'));
files_set = dir(fullfile(raw_dir,'*.set'));
files_mat = dir(fullfile(raw_dir,'*.mat'));

allFiles = [files_cnt; files_set; files_mat];

[~,baseNames] = cellfun(@fileparts,{allFiles.name},'UniformOutput',false);

if numel(unique(baseNames)) ~= numel(baseNames)
    warning('Duplicate subject filenames detected.');
end

names = {allFiles.name};

if isempty(names)
    error('No supported EEG files found in raw_dir.');
end

%% ============================================================
% 4) SUBJECT LOOP
% ============================================================
for n = 1:numel(names)

    try
        [~, base_filename, ext] = fileparts(names{n});
        subjName = base_filename;
        QC = struct();
        fprintf('\n============================================================\n');
        fprintf('Processing subject %d/%d: %s\n', n, numel(names), names{n});
        fprintf('============================================================\n');

        %% --------------------------------------------------------
        % 4A) LOAD RAW DATA
        % --------------------------------------------------------
        switch lower(ext)
            case '.xdf'
                EEG = load_xdf_to_eeglab( ...
                fullfile(raw_dir,names{n}));
            case '.cnt'
                EEG = pop_loadeep_v4(fullfile(raw_dir, names{n}));
                % EEG = pop_loadcnt(fullfile(raw_dir, names{n}));
            case '.set'
                EEG = pop_loadset('filename', names{n}, 'filepath', raw_dir);
            case '.mat'
                tmp = load(fullfile(raw_dir, names{n}));
                if isfield(tmp, 'EEG')
                    EEG = tmp.EEG;
                else
                    warning('File %s does not contain a valid EEG variable. Skipped.', names{n});
                    continue
                end
            otherwise
                warning('Unsupported file format: %s', names{n});
                continue
        end
    catch ME

        fprintf('\nERROR in %s\n', names{n});
        fprintf('%s\n', ME.message);

        continue

    end
end
EEG = pop_chanedit(EEG,...
'lookup','standard_1005.elc');
chanlocsTemplate = EEG.chanlocs;

save('Chang_AntNeuro_chanlocs_template.mat',...
     'chanlocsTemplate');