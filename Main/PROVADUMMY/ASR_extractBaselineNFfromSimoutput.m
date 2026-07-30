function [baseline,nf]=ASR_extractBaselineNFfromSimoutput(simoutput,CleanDataset)
% baseline_FczCpz,nf_FczCpz,baseline_Fc3Cp3,nf_Fc3Cp3,baseline_Fc4Cp4,nf_Fc4Cp4,
% per FlexEEG

fs=125;
l_imm_baseline=fs*6;
l_imm_nf=fs*20;

j=1;
for i=1:size(simoutput.ScopeData.signals(2).values,1)-1
    bs=simoutput.ScopeData.signals(2).values(i+1)-simoutput.ScopeData.signals(2).values(i);
    if bs==1
        bas_im_start(j)=i+1;
        j=j+1;
    end
end

j=1;
for i=1:size(simoutput.ScopeData.signals(3).values,1)-1
     nf=simoutput.ScopeData.signals(3).values(i+1)-simoutput.ScopeData.signals(3).values(i);
    if nf==1
        nf_im_start(j)=i+1;
        j=j+1;
    end
end

% FczCpz
l_FczCpz=length(simoutput.ScopeData.signals(5).values);
%FczCpz=reshape(simoutput.ScopeData.signals(5).values,[1,l_FczCpz]);

baseline_FczCpz=[];
nf_FczCpz=[];
for i=1:size(bas_im_start,2)
    app_baseline_FczCpz=CleanDataset(2,bas_im_start(i):bas_im_start(i)+l_imm_baseline-1);
    baseline_FczCpz=[baseline_FczCpz; app_baseline_FczCpz];
end
for i=1:size(nf_im_start,2)
    app_nf_FczCpz=CleanDataset(2,nf_im_start(i):nf_im_start(i)+l_imm_nf-1);
    nf_FczCpz=[nf_FczCpz; app_nf_FczCpz];
end

% Fc3Cp3
l_Fc3Cp3=length(simoutput.ScopeData.signals(4).values);
%Fc3Cp3=reshape(simoutput.ScopeData.signals(4).values,[1,l_Fc3Cp3]);

baseline_Fc3Cp3=[];
nf_Fc3Cp3=[];
for i=1:size(bas_im_start,2)
    app_baseline_Fc3Cp3=CleanDataset(1,bas_im_start(i):bas_im_start(i)+l_imm_baseline-1);
    baseline_Fc3Cp3=[baseline_Fc3Cp3; app_baseline_Fc3Cp3];
end
for i=1:size(nf_im_start,2)
    app_nf_Fc3Cp3=CleanDataset(1,nf_im_start(i):nf_im_start(i)+l_imm_nf-1);
    nf_Fc3Cp3=[nf_Fc3Cp3; app_nf_Fc3Cp3];
end

% Fc4Cp4
l_Fc4Cp4=length(simoutput.ScopeData.signals(6).values);
%Fc4Cp4=reshape(simoutput.ScopeData.signals(6).values,[1,l_Fc4Cp4]);

baseline_Fc4Cp4=[];
nf_Fc4Cp4=[];
for i=1:size(bas_im_start,2)
    app_baseline_Fc4Cp4=CleanDataset(3,bas_im_start(i):bas_im_start(i)+l_imm_baseline-1);
    baseline_Fc4Cp4=[baseline_Fc4Cp4; app_baseline_Fc4Cp4];
end
for i=1:size(nf_im_start,2)
    app_nf_Fc4Cp4=CleanDataset(3,nf_im_start(i):nf_im_start(i)+l_imm_nf-1);
    nf_Fc4Cp4=[nf_Fc4Cp4; app_nf_Fc4Cp4];
end


baseline=[baseline_FczCpz;baseline_Fc3Cp3;baseline_Fc4Cp4];
nf=[nf_FczCpz;nf_Fc3Cp3;nf_Fc4Cp4];
end