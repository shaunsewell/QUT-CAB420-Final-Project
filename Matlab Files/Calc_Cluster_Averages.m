function average = Calc_Cluster_Averages( games, played, averages, cluster_members, running_average)
%
% Computes the averages of every team against every average.
% Where a team is a member of a new cluster the current running avergae for
% that team is used as an initialisation value. 
% 
    average = averages;
    [row,col] = size(average);
    
    cluster_col = 0;
    if col == 2
        cluster_col = 1;
    elseif col == 3
        cluster_col = 2;
    elseif col == 5
        cluster_col = 3;
    else
        cluster_col = 4;
    end
        
    for r=1:row
        for c=1:col
            totals = zeros(18,25);
            matchs_against_cluster = zeros(18,1);
            for t=1:18
                t_games = games(t, :, played(t, 1));
                for g = 1:size(t_games,1)
                    if cluster_members(t_games(g,2), cluster_col, r) == c
                        totals(t,:) = totals(t,:) + t_games(g,4:28);
                        matchs_against_cluster(t,1) = matchs_against_cluster(t,1) + 1;
                    end
                end
            end
            
            for z=1:18
                if matchs_against_cluster(z,1) == 0
                    matchs_against_cluster(z,1) = 1; 
                    totals(z,:) = running_average(z,:);
                    %previous average
                end
            end
            average(r,c) = {totals ./ matchs_against_cluster};
        end
    end
    
end