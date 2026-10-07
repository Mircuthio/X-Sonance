comparisonNameList =  {'Consonance'};
for i=1:numel(comparisonNameList)
    cfg = struct();

    cfg.comparisonName = comparisonNameList{i};
    switch cfg.comparisonName
        case 'Consonance'
            cfg.conditions = { ...
                'Consonant',...
                'Dissonant'};
        case 'Difference'
            cfg.conditions = { ...
                'ConsonantGOAL',...
                'DissonantNoGOAL'};
        case 'Goal'
            cfg.conditions = { ...
                'ConsonantGOAL',...
                'DissonantGOAL'};
        case 'NoGoal'
            cfg.conditions = { ...
                'ConsonantNoGOAL',...
                'DissonantNoGOAL'};
        case 'Control'
            cfg.conditions = { ...
                'ControlGOAL',...
                'ControlNoGOAL'};
        case 'All'
            cfg.conditions = { ...
                'ConsonantGOAL',...
                'DissonantGOAL',...
                'ControlGOAL',...
                'ConsonantNoGOAL',...
                'DissonantNoGOAL',...
                'ControlNoGOAL',...
                'Consonant',...
                'Dissonant'};
    end
    fprintf('\n');
    fprintf('RUN %d/%d\n', ...
        i,...
        numel(comparisonNameList));

    fprintf('COMPARISON: %s\n', ...
        cfg.comparisonName);
    cfg.cond_field = 'eventLabel';
    MAIN_ROI
    cfg.rois = ROI;
    roiNames = fieldnames(cfg.rois);
    cfg.time_field = 'time';
    cfg.baseline_win = [-0.2 0];
    cfg.analysis_win = [-0.2 0.8];
    cfg.subject_ids = {};
    cfg.target_time_units = 's';
    cfg.generate_difference_plots = true;

    %% ------------------------------------------------------------
    % PLOT OPTIONS
    %% ------------------------------------------------------------
    cfgPlot = struct();

    cfgPlot.smooth_plot = false;
    cfgPlot.smooth_window = 5;

    cfgDiff = struct();

    cfgDiff.smooth_plot = false;
    cfgDiff.smooth_window = 5;

    fprintf('Conditions :\n');

    for iCond = 1:numel(cfg.conditions)

        fprintf('   %s\n', ...
            cfg.conditions{iCond});

    end

    fprintf('Cond field : %s\n',cfg.cond_field);
    fprintf('Baseline   : %.3f %.3f s\n', ...
        cfg.baseline_win);

    fprintf('Analysis   : %.3f %.3f s\n', ...
        cfg.analysis_win);

    fprintf('ROIs       : %d\n', ...
        numel(fieldnames(cfg.rois)));

    % fprintf('Subjects   : %d\n', ...
    %     numel(subj_list));

    fprintf('Trials     : %d\n', ...
        total_trials);

    % output dir
    step3_outdir = ...
        fullfile( ...
        step3_outroot,...
        cfg.comparisonName);

    if cfgPlot.smooth_plot
        step3_outdir = fullfile(step3_outdir,'SMOOTH');
    end

    if ~exist(step3_outdir,'dir')
        mkdir(step3_outdir);
    end
    for r = 2:numel(roiNames)
        roiName = roiNames{r};
        cfg_curr = cfg;
        cfg_curr.roi_labels = cfg.rois.(roiName);
        % ERP Pooled PLOT
        cfgPlot = struct();
        if strcmp(cfg.comparisonName,'All')

            cfgPlot.line_colors = [
                0.00 0.35 0.90 ;   % ConsonantGOAL
                0.85 0.20 0.20 ;   % DissonantGOAL
                0.10 0.60 0.25 ;   % ControlGOAL
                0.20 0.75 1.00 ;   % ConsonantNoGOAL
                1.00 0.55 0.00 ;   % DissonantNoGOAL
                0.60 0.20 0.80 ;   % ControlNoGOAL
                0.00 0.00 0.50 ;   % Consonant
                0.55 0.00 0.00     % Dissonant
                ];

            cfgPlot.patch_alpha = 0.08;

            cfgPlot.line_width_map = [
                2 2 2 2 2 2 2 2
                ];

        end
        cfgPlot.cond_idx = 1:numel(cfg.conditions);
        cfgPlot.title_str = sprintf('Pooled-Trial ERP - %s', roiName);
        cfgPlot.show_zero = true;
        cfgPlot.show_error = true;
        cfgPlot.error_type = 'sem';
        cfgPlot.error_data = ERP_Pooled.(roiName).grand_se;
        cfgPlot.save_path = fullfile(step3_outdir, 'ERP_plots', roiName, sprintf('ERP_Pooled_%s.png', roiName));
        [plot_dir,~,~] = fileparts(cfgPlot.save_path);
        if ~exist(plot_dir, 'dir'), mkdir(plot_dir); end
        plot_erp_waveforms(ERP_Pooled.(roiName), cfgPlot);
        if cfg.generate_difference_plots && ...
                numel(cfg.conditions)==2
            cfgDiff = struct();
            cfgDiff.title_str = sprintf('Pooled Difference ERP - %s',roiName);
            cfgDiff.save_path = fullfile( ...
                step3_outdir,'ERP_plots',roiName,sprintf('ERP_Pooled_Difference_%s.png',roiName));
            plot_difference_wave(ERP_Pooled.(roiName),cfgDiff);
        end
        %% Group-average ERP
        % ERP Group PLOT
        cfgPlot = struct();
        if strcmp(cfg.comparisonName,'All')

            cfgPlot.line_colors = [
                0.00 0.35 0.90 ;   % ConsonantGOAL
                0.85 0.20 0.20 ;   % DissonantGOAL
                0.10 0.60 0.25 ;   % ControlGOAL
                0.20 0.75 1.00 ;   % ConsonantNoGOAL
                1.00 0.55 0.00 ;   % DissonantNoGOAL
                0.60 0.20 0.80 ;   % ControlNoGOAL
                0.00 0.00 0.50 ;   % Consonant
                0.55 0.00 0.00     % Dissonant
                ];

            cfgPlot.patch_alpha = 0.08;

            cfgPlot.line_width_map = [
                2 2 2 2 2 2 2 2
                ];

        end
        cfgPlot.cond_idx = 1:numel(cfg.conditions);
        cfgPlot.title_str = sprintf('Group ERP - %s', roiName);
        cfgPlot.show_zero = true;
        cfgPlot.show_error = true;
        cfgPlot.error_type = 'sem';
        cfgPlot.error_data = ERP_Group.(roiName).grand_se;
        cfgPlot.save_path = fullfile(step3_outdir, 'ERP_plots', roiName, sprintf('ERP_Group_%s.png', roiName));
        [plot_dir,~,~] = fileparts(cfgPlot.save_path);
        if ~exist(plot_dir, 'dir'), mkdir(plot_dir); end
        plot_erp_waveforms(ERP_Group.(roiName), cfgPlot);
        if numel(cfg.conditions)==2
            cfgDiff = struct();
            cfgDiff.title_str = sprintf('Difference ERP - %s',roiName);
            cfgDiff.save_path = ...
                fullfile(step3_outdir,'ERP_plots',roiName,sprintf('ERP_Difference_%s.png',roiName));
            plot_difference_wave(ERP_Group.(roiName),cfgDiff);
        end
        %% LIMO PLOT
        if cfg.generate_difference_plots && ...
                numel(cfg.conditions)==2
            cfgLimoPlot = struct();
            cfgLimoPlot.conditions = cfg.conditions;
            cfgLimoPlot.alpha = 0.05;
            cfgLimoPlot.trim_percent = 0;
            cfgLimoPlot.line_colors = [
                0 0.4470 0.7410
                0.8500 0.3250 0.0980
                ];
            cfgLimoPlot.ci_alpha = 0.15;
            cfgLimoPlot.title_str =  sprintf('Limo-Group ERP - %s', roiName);
            cfgLimoPlot.save_path = fullfile(step3_outdir, 'ERP_plots', roiName, sprintf('Limo_Group_%s.png', roiName));
            [plot_dir,~,~] = fileparts(cfgLimoPlot.save_path);
            if ~exist(plot_dir, 'dir'), mkdir(plot_dir); end
            plot_limo_erp_comparison(limo_input.(roiName),cfgLimoPlot);
        end
    end

    %% ============================================================
    % ERP TOPOPLOTS
    %% ============================================================
    cfgERPTopo = struct();

    cfgERPTopo.enable = true;

    cfgERPTopo.erpWindows = struct();

    cfgERPTopo.erpWindows.ERAN = [0.15 0.25];

    cfgERPTopo.erpWindows.MMN = [0.10 0.20];

    cfgERPTopo.erpWindows.N5 = [0.45 0.55];


    % cfgERPTopo.erpWindows.EarlyEffect = [0.08 0.12];
    %
    % cfgERPTopo.erpWindows.MidEffect = [0.30 0.40];
    %
    % cfgERPTopo.erpWindows.LateEffect = [0.50 0.70];

    % cfgERPTopo.erpWindows.Effect1 = [0.xx 0.xx];
    %
    % cfgERPTopo.erpWindows.Effect2 = [0.xx 0.xx];

    cfgERPTopo.conditions = ...
        cfg.conditions;

    cfgERPTopo.cond_field = ...
        cfg.cond_field;

    cfgERPTopo.time_field = ...
        cfg.time_field;

    cfgERPTopo.measure = 'mean';

    topo_outdir = ...
        fullfile( ...
        step3_outdir,...
        'ERP_TOPOPLOTS');

    if ~exist(topo_outdir,'dir')

        mkdir(topo_outdir);

    end

    ERP_Topography = struct();

    windowNames = ...
        fieldnames( ...
        cfgERPTopo.erpWindows);

    for w = 1:numel(windowNames)

        windowName = ...
            windowNames{w};

        cfgTopo = struct();

        cfgTopo.conditions = cfg.conditions;

        cfgTopo.cond_field = cfg.cond_field;

        cfgTopo.time_field = cfg.time_field;

        cfgTopo.window = ...
            cfgERPTopo.erpWindows.(windowName);

        cfgTopo.measure = ...
            cfgERPTopo.measure;

        cfgTopo.baseline_win = ...
            cfg.baseline_win;

        cfgTopo.analysis_win = ...
            cfg.analysis_win;

        for c = 1:numel(cfg.conditions)

            condName = cfg.conditions{c};

            ERPTopoCond = ...
                create_condition_topography( ...
                subj_list,...
                cfgTopo,...
                condName);

            ERP_Topography.(windowName).( ...
                matlab.lang.makeValidName(condName)) = ...
                ERPTopoCond;

            cfgTopoPlot = struct();

            cfgTopoPlot.title_str = ...
                sprintf('%s - %s', ...
                windowName,...
                condName);

            cfgTopoPlot.save_path = ...
                fullfile( ...
                topo_outdir,...
                sprintf( ...
                'ERP_TOPO_%s_%s.png',...
                windowName,...
                condName));

            plot_erp_topoplot( ...
                ERPTopoCond,...
                cfgTopoPlot);
        end
        if numel(cfg.conditions) == 2

            ERPTopo = ...
                create_difference_topography( ...
                subj_list,...
                cfgTopo);

            ERP_Topography.(windowName).Difference = ...
                ERPTopo;

            cfgTopoPlot = struct();

            cfgTopoPlot.title_str = ...
                sprintf( ...
                '%s Difference Topography',...
                windowName);

            cfgTopoPlot.save_path = ...
                fullfile( ...
                topo_outdir,...
                sprintf( ...
                'ERP_TOPO_%s_DIFFERENCE.png',...
                windowName));

            cfgTopoPlot.clim = [];

            plot_difference_topoplot( ...
                ERPTopo,...
                cfgTopoPlot);

        end
    end
end