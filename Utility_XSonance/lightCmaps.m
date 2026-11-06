function cmapslight = lightCmaps(cmaps)

alpha = 0.5;

cmapslight = ...
    cmaps + alpha*(1-cmaps);

end