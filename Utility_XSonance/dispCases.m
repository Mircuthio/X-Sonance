function dispCases(M)

Cases = build_fbcsp_cases();

if M==0
    for i = 1:numel(Cases)

        fprintf('%02d  %s  %s\n', ...
            i,...
            Cases(i).case_id,...
            Cases(i).name);

    end
else 
    for i = 1:numel(Cases)
        fprintf('\n');
        fprintf('%02d\n',i);

        disp(Cases(i))
    end
end