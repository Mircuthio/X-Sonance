function ERP = filter_erp_conditions(ERP,cfg)

keepIdx = find(ismember( ...
    ERP.conditions,...
    cfg.conditions));

ERP.conditions = ERP.conditions(keepIdx);

if isfield(ERP,'grand_avg')
    ERP.grand_avg = ERP.grand_avg(keepIdx,:);
end

if isfield(ERP,'grand_se')
    ERP.grand_se = ERP.grand_se(keepIdx,:);
end

if isfield(ERP,'grand_std')
    ERP.grand_std = ERP.grand_std(keepIdx,:);
end

if isfield(ERP,'nTrials')
    ERP.nTrials = ERP.nTrials(keepIdx);
end

end