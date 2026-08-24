% Extraction_data_HilariousDubbing.mat

clear; close all

cd E:\Hilarious_Dubbing\Data_raw\ %'D:\main_scriptNSA\Older_and_Proof\Sound_pipeline\11_06\Data_raw'
dir_path = 'E:\Hilarious_Dubbing\Data_raw\'; %'D:\main_scriptNSA\Older_and_Proof\Sound_pipeline\11_06\Data_raw'; % Directory contenente i file .vhdr

output_directory = 'D:\main_scriptNSA\Older_and_Proof\Sound_pipeline\11_06\ERP_analysis\Audiobook'; % Directory dove salvare i files .mat

addpath(genpath("D:\eeglab2023.1\")) % Inserire tuo path

files = dir('*.vhdr');
names = {files(:).name};

for n = 1:numel(names)
    %load data
    EEG = pop_loadbv(dir_path,names{n});
    % EEG = pop_loadset('filename', names{n});

    %cut channel
    EEG = pop_select( EEG, 'rmchannel',{'LHEOG','vEOGup','vEOGdown','RHEOG','audio'});
    % EEG = pop_select(EEG, 'nochannel',{'LHEOG','vEOGup','vEOGdown','RHEOG','audio'});
    
    %data filter
    EEG = pop_eegfiltnew(EEG, 'locutoff',1,'hicutoff',125,'plotfreqz',0);

    %resample data
    EEG = pop_resample(EEG, 250);

    EEG.chanlocs(find(contains({EEG.chanlocs.labels}, 'RM'))).labels = 'M2';

    %reference
    % EEG = pop_chanedit(EEG, 'append',EEG.nbchan,'changefield',{EEG.nbchan+1, 'labels' 'M1'}, ...
    %     'lookup','C:\Program Files\MATLAB\R2023a\eeglab2023.1/plugins/dipfit/standard_BESA/standard-10-5-cap385.elp',...
    %                    'setref', {find(~contains({EEG.chanlocs.labels}, 'dir')), 'M1'});

    EEG = pop_chanedit(EEG, 'append',EEG.nbchan,'changefield',{EEG.nbchan+1, 'labels' 'M1'}, ...
        'lookup','D:\eeglab2023.1\plugins\dipfit\standard_BESA/standard-10-5-cap385.elp',...
        'setref', {find(~contains({EEG.chanlocs.labels}, 'dir')), 'M1'});

    %re-ref
    EEG = pop_reref( EEG, [],'refloc',struct('labels',{'M1'},'type',{'EEG'}, ...
        'theta',{-100.419},'radius',{0.74733},'X',{-10.9602},'Y',{59.6062},'Z',{-59.5984}, ...
        'sph_theta',{100.419},'sph_phi',{-44.52},'sph_radius',{85},'urchan',{60},'ref',{''},'datachan',{0}));

    %re-ref 2
    EEG = pop_reref( EEG, [1 60] );

    originalEEG = EEG;

    %clean_raw_ASR
    EEG = pop_clean_rawdata(EEG, 'FlatlineCriterion',5,'ChannelCriterion',0.8,'LineNoiseCriterion',4, ...
        'Highpass','off','BurstCriterion',20,'WindowCriterion','off','BurstRejection','off','Distance','Euclidian');

    % interpolate
    EEG = pop_interp(EEG, originalEEG.chanlocs, 'spherical');

    %trainnig ita
    training_ita = pop_rmdat( EEG, {'S221'},[-5 654] ,0);

    %training eng
    training_eng = pop_rmdat( EEG, {'S222'},[-5 671] ,0);


    %training dataset
    % training = pop_mergeset(training_ita, training_eng, 0);

    % test = pop_epoch( EEG, {  'S  1'  'S  2'  'S  3'  'S  4'  'S  5'  'S  6'  'S  7'  'S  8'  'S  9'  ...
    %     'S 10'  'S 11'  'S 12'  'S 13'  'S 14'  'S 15'  'S 16'  'S 17'  'S 18'  'S 19'  'S 20'  'S 21'  ...
    %     'S 22'  'S 23'  'S 24'  'S 25'  'S 26'  'S 27'  'S 28'  'S 29'  'S 30'  'S 31'  'S 32'  'S 33'  ...
    %     'S 34'  'S 35'  'S 36'  'S 37'  'S 38'  'S 39'  'S 40'  'S 41'  'S 42'  'S 43'  'S 44'  'S 45'  ...
    %     'S 46'  'S 47'  'S 48'  'S 49'  'S 50'  'S 51'  'S 52'  'S 53'  'S 54'  'S 55'  'S 56'  'S 57'  ...
    %     'S 58'  'S 59'  'S 60'  'S 61'  'S 62'  'S 63'  'S 64'  'S 65'  'S 66'  'S 67'  'S 68'  'S 69'  ...
    %     'S 70'  'S 71'  'S 72'  'S 73'  'S 74'  'S 75'  'S 76'  'S 77'  'S 78'  'S 79'  'S 80'  'S 81'  ...
    %     'S 82'  'S 83'  'S 84'  'S 85'  'S 86'  'S 87'  'S 88'  'S 89'  'S 90'  'S 91'  'S 92'  'S 93'  ...
    %     'S 94'  'S 95'  'S 96'  'S 97'  'S 98'  'S 99'  'S100'  }, [-6 9], 'newname', sprintf('%s_test', names{n}(1:end-4)), ...
    %     'epochinfo', 'yes');

    %ica
    trainITA_ica = pop_runica(training_ita, 'icatype', 'runica', 'extended',1,'interrupt','on');
    trainENG_ica = pop_runica(training_eng, 'icatype', 'runica', 'extended',1,'interrupt','on');

    %label components
    EEG_dataITA = pop_iclabel(trainITA_ica, 'default');
    EEG_dataENG = pop_iclabel(trainENG_ica, 'default');
    
    %flag artifacts
    EEG_dataITA = pop_icflag(EEG_dataITA, [NaN NaN;0.9 1;0.9 1;0.9 1;0.9 1;0.9 1;NaN NaN]);
    EEG_dataENG = pop_icflag(EEG_dataENG, [NaN NaN;0.9 1;0.9 1;0.9 1;0.9 1;0.9 1;NaN NaN]);

    %remove components
    EEG_dataITA = pop_subcomp( EEG_dataITA, [], 0);
    EEG_dataENG = pop_subcomp( EEG_dataENG, [], 0);

    fs = EEG_dataENG.srate;

    %% Organize trials
    label_final = [1;2];

    % Estrai il nome del file del dataset principale
    base_filename = erase(names{n},'.vhdr');



    % final data saving
    data(1).eeg             = EEG_dataENG.data;
    data(2).eeg             = EEG_dataITA.data;
    data(1).trialinfo          = 1;
    data(2).trialinfo          = 2;
    data(1).fs              = fs;
    data(2).fs              = fs;
    time_eng                = size(EEG_dataENG.data,2)/250;
    time_ita                = size(EEG_dataITA.data,2)/250;
    data(1).time            = linspace(0,time_eng,size(EEG_dataENG.data,2));
    data(2).time            = linspace(0,time_ita,size(EEG_dataITA.data,2));
    data(1).class_indices      = 'ENG';
    data(2).class_indices      = 'ITA';
    for nTrial =1:2
        data(nTrial).Tab_duration       = NaN;
        data(nTrial).Tab_final          = NaN;
    end

    file_name = strcat(base_filename,'_dictionary');

    full_dir = fullfile(output_directory,file_name);

    save(full_dir,'data')
end
