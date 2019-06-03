function average = Calc_HA_Average( games, played, home)
    
    home_stats = [];
    away = [];
    for i=1:played
        if games(1, 3, i) == 1
            home_stats = [home_stats; games(1, 4:28, i)];
        else
            away = [away; games(1, 4:28, i)];
        end
    end
    
    if home == 1  % update home game average
        totals = sum(home_stats,1);
        average = totals ./ size(home_stats,1);
    else
        totals = sum(away,1);
        average = totals ./ size(away,1);
    end
    
end