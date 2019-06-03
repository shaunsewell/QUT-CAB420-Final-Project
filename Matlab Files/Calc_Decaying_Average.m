function average = Calc_Decaying_Average( games, played, alpha)
    
    totals = zeros(1,25);
    for i = 1:played
        decaying_game = (alpha^(played-i)) .* games(1,:,i);
        totals(1,:) = totals(1,:) + decaying_game;
    end
    alpha_multiplier = (1 - alpha)/(1 - (alpha^played));
    average = alpha_multiplier .* totals;
end