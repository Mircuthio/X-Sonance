%% MAIN_ROI.m
% ROI anatomiche e funzionali per analisi ERP

ROI = struct();

% ROI anatomiche
ROI.AllChannels = {'FP1','AFz','FP2','AF7','AF3','AF4','AF8','F7','F5','F3','F1','Fz','F2','F4','F6','F8', ...
                   'FT7','FC5','FC3','FC1','FCz','FC2','FC4','FC6','FT8', ...
                   'T7','C5','C3','C1','Cz','C2','C4','C6','T8', ...
                   'TP7','CP5','CP3','CP1','CPz','CP2','CP4','CP6','TP8', ...
                   'P7','P5','P3','P1','Pz','P2','P4','P6','P8', ...
                   'PO7','PO3','POz','PO4','PO8','O1','Oz','O2','TP9','TP10','FT9','FT10'};
ROI.Frontal       = {'Fp1','Fp2','Fpz','AF7','AF3','AF8','AF4','AFz','Fz','F1','F2','F3','F4','F5','F6','F7','F8'};
ROI.FrontoCentral = {'FC1','FC2','FC3','FC4','FC5','FC6','FCz'};
ROI.Central       = {'C1','C2','C3','C4','C5','C6','Cz'};
ROI.Temporal      = {'T7','T8','FT7','FT8','TP7','TP8'};
ROI.ParietoCentral = {'CP1','CP2','CP3','CP4','CP5','CP6','CPz'};
ROI.Parietal      = {'P1','P2','P3','P4','P5','P6','P7','P8','P9','P10','Pz'};
ROI.Occipital     = {'PO7','PO3','PO8','PO4','POz','O1','O2','Oz','Iz'};

% ROI funzionali ERP
ROI.Generic     = {'Fz','FCz','Cz','Pz','CPz'}; 
ROI.ERAN        = {'Fp1', 'Fp2', 'AF3', 'AF4', 'F3', 'F4', 'F7', 'F8', 'FC3', 'FC4', 'Fz', 'FCz'};
ROI.ERAN_RIGHT  = {'F4','F6','F8','FC4','AF4','AF8','Fp2','F2','FC2','Fz'};
ROI.ERAN_CORE   = {'AF3','AF4','F3','F4','F7','F8','FC3','FC4','Fz','FCz'};
ROI.MMN         = {'Fz','FCz','Cz','F3','F4','FC1','FC2','FC3','FC4'};
ROI.aMMN        = {'AF3','AFz','AF4','F3','Fz','F4','FC1','FCz','FC2'};
ROI.afMMN       = {'AF3','AFz','AF4','F1','Fz','F2'};
ROI.N5          = {'Fz','FCz','Cz','F1','F2','F3','F4','FC1','FC2','FC3','FC4','C1','C2','C3','C4'};
ROI.N5_FRONT    = {'F3','F1','Fz','F2','F4','FC1','FCz','FC2'};
ROI.N5_CENTRAL  = {'FC1','FCz','FC2','C1','Cz','C2'};
ROI.SPN_FRONTAL = {'F3','F1','Fz','F2','F4','FC1','FCz','FC2'};
ROI.SPN_CENTRAL = {'FC1','FCz','FC2','C1','Cz','C2'};
ROI.SPN_POSTERIOR = {'CPz','P1','Pz','P2','PO3','POz','PO4'};
ROI.SPN_GLOBAL  = {'F3','Fz','F4','FC1','FCz','FC2','C1','Cz','C2','CP1','CPz','CP2','P1','Pz','P2'};
