function average = Calc_Running_Average( games, played)
    
    totals = sum(games,3);
    average = totals ./ played;
end