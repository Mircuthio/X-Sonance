%% =========================================================================
% STEP8B_STATISTICAL_ANALYSIS
%% =========================================================================

clear
close all
clc

load_dir = ...
'D:\X-SONANCE\Dataset_MARCO\';

load('ERAN_STEP5.mat','ERAN_Stats')

export_stats_summary( ...
    ERAN_Stats,...
    'ERAN_Summary.xlsx');

load('MMN_STEP6.mat','MMN_Stats')

export_stats_summary( ...
    MMN_Stats,...
    'MMN_Summary.xlsx');

load('N5_STEP7.mat','N5_Stats')

export_stats_summary( ...
    N5_Stats,...
    'N5_Summary.xlsx');

load('SPN_STEP8.mat','SPN_Stats')

export_stats_summary( ...
    SPN_Stats,...
    'SPN_Summary.xlsx');