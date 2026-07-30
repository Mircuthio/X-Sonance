function plot_with_shade(x, m, se, color_rgb)
    x  = x(:);
    m  = m(:);
    se = se(:);

    n = min([numel(x), numel(m), numel(se)]);
    x  = x(1:n);
    m  = m(1:n);
    se = se(1:n);

    xx = [x; flipud(x)];
    yy = [m-se; flipud(m+se)];

    fill(xx, yy, color_rgb, ...
        'FaceAlpha', 0.20, ...
        'EdgeColor', 'none');
    hold on;
    plot(x, m, 'Color', color_rgb, 'LineWidth', 2);
end