function dispCases(M)
% DISPCASES
%
%   dispCases(0)
%       Displays the list of all FBCSP cases.
%
%   dispCases(M)
%       Displays the details of case M.
%
% Examples:
%   dispCases(0)
%   dispCases(1)
%   dispCases(18)

Cases = build_fbcsp_cases();
nCases = numel(Cases);

%% ============================================================
% LIST ALL CASES
%% ============================================================
if M == 0

    for i = 1:nCases
        fprintf('%02d  %s  %s\n', ...
            i,...
            Cases(i).case_id,...
            Cases(i).name);
    end

    return
end

%% ============================================================
% DISPLAY ONE CASE
%% ============================================================
assert(isscalar(M) && isnumeric(M), ...
    'M must be a numeric scalar');

assert(M >= 1 && M <= nCases && M == floor(M), ...
    'M must be an integer between 1 and %d', ...
    nCases);

fprintf('\n');
fprintf('CASE %02d / %02d\n', ...
    M,...
    nCases);
fprintf('========================================\n');

disp(Cases(M))

end