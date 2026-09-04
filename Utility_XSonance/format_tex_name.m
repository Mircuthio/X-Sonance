function txtOut = format_tex_name(txtIn)

tokens = split(string(txtIn),'_');

if numel(tokens) == 1

    txtOut = char(txtIn);

elseif numel(tokens) == 2

    txtOut = sprintf( ...
        '%s_{%s}', ...
        tokens{1}, ...
        tokens{2});

elseif numel(tokens) == 3

    txtOut = sprintf( ...
        '%s_{[%s-%s]}', ...
        tokens{1}, ...
        tokens{2}, ...
        tokens{3});

else

    txtOut = char(txtIn);

end

end