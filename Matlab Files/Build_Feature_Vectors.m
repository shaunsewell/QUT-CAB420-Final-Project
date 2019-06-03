%% *CAB420 Final Project*
% *Predicting the result of AFL matches*
% Shaun Sewell
%
% N9509623


clear ; close all; clc
addpath(genpath('Matlab Files'));
load("AFLData.mat");

%% Building Feature Vectors

data = [train; test];
games_played = zeros(18, 1);
games = zeros(18,28,27);
PCA_comps = [4, 10, 15];
K = [2, 3, 5, 10];
running_average = zeros(18,25);
decaying_average = zeros(18,25,10);
alpha = 0.09:0.1:0.99;
h_a_average = zeros(18,25,2);       % :,:,1 is home average, :,:,2 is away averages

two_cluster_averages = cell(3,2);  % teams x stats x cluster x PCA
three_cluster_averages = cell(3,3);
five_cluster_averages = cell(3,5);
ten_cluster_averages = cell(3,10);

cluster_centers = cell(3,4);
cluster_members = zeros(18,4,3);

RA_feature_vectors = zeros(198,25,7);
DA_feature_vectors = zeros(198,25,10,7);
HA_feature_vectors = zeros(198,25,7);
PCAC_feature_vectors = zeros(198,25,3,4,7);

winner = zeros(198,1,7);


for season = 1:7
   
% initialise the running average to the values after round 1
% 9 matches in a round so the first 18 lines represent round 1
    for t = 1:18
       team = data(t, 2, season);
       games_played(team, 1) = games_played(team, 1) + 1;
       games(team, :, 1) = data(t, 2:29, season);
       
       % set starting averages
       running_average(team, :) = games(team, 4:28, 1);
       % initialise home and away averages to round 1 stats to avoid
       % waiting several rounds to make predictions.
       h_a_average(team, :, 1) = games(team, 4:28, 1);
       h_a_average(team, :, 2) = games(team, 4:28, 1);
       
       for i = 1:11
            decaying_average(team, :, i) = games(team, 4:28, 1);
       end
    end
    
    % initialise PCA and cluster models
    for p = 1:length(PCA_comps)
        [coef, score] = pca(running_average, 'NumComponents',PCA_comps(p));
        for k = 1:length(K)
            [cluster_members(:,k,p),cluster_centers{p,k}] = kmeans(score, K(k));
        end
    end
    two_cluster_averages = Calc_Cluster_Averages(games, games_played, two_cluster_averages, cluster_members, running_average);
    three_cluster_averages = Calc_Cluster_Averages(games, games_played, three_cluster_averages, cluster_members, running_average);
    five_cluster_averages = Calc_Cluster_Averages(games, games_played, five_cluster_averages, cluster_members, running_average);
    ten_cluster_averages = Calc_Cluster_Averages(games, games_played, ten_cluster_averages, cluster_members, running_average);
    
    
    % Building feature vectors
    % matches are stat pairs i.e 1&2 make match 1 and so on
    for match = 1:2:396
        index = (match + 1) / 2;
        team_a = data(match + 18, 2, season);
        team_b = data(match + 19, 2, season);
        games_played(team_a, 1) = games_played(team_a, 1) + 1;
        games_played(team_b, 1) = games_played(team_b, 1) + 1;
        
        games(team_a, :, games_played(team_a,1)) = data(match + 18, 2:29, season);
        games(team_b, :, games_played(team_b,1)) = data(match + 19, 2:29, season);
        
        % find the recorded winner of the match
        % 1 = team_a wins, 0 = team_b wins. ignoring draws for simplicity
        if data(match + 18, 30, season) == 1
            winner(index, 1, season) = 1;
        elseif data(match + 19, 30, season) == 1
            winner(index, 1, season) = 0;
        else
            winner(index, 1, season) = 0;
        end
        
        % make the feature vector x = xa - xb
        % Running Average
        RA_feature_vectors(index, :, season) = running_average(team_a, :) - running_average(team_b, :);
        % Decaying Average
        for d = 1:10
            DA_feature_vectors(index, :, d, season) = decaying_average(team_a, :, d) - decaying_average(team_b, :, d);
        end
        % Home and Away Average
        % team_a is always the home team
        HA_feature_vectors(index, :, season) = h_a_average(team_a, :, 1) - h_a_average(team_b, :, 2);
        
        % PCA Clustering Average
        for k = 1:length(K)
            for p = 1:length(PCA_comps)
                if k == 1
                    team_a_cluster = cluster_members(team_a, k, p);
                    team_b_cluster = cluster_members(team_b, k, p);
                    
                    team_a_average = two_cluster_averages{p,team_b_cluster}(team_a,:);
                    team_b_average = two_cluster_averages{p,team_a_cluster}(team_b,:);
                    PCAC_feature_vectors(index, :, p, k, season) = team_a_average - team_b_average;
                elseif k == 2
                    team_a_cluster = cluster_members(team_a, k, p);
                    team_b_cluster = cluster_members(team_b, k, p);
                    
                    team_a_average = three_cluster_averages{p,team_b_cluster}(team_a,:);
                    team_b_average = three_cluster_averages{p,team_a_cluster}(team_b,:);
                    PCAC_feature_vectors(index, :, p, k, season) = team_a_average - team_b_average;
                elseif k == 3
                    team_a_cluster = cluster_members(team_a, k, p);
                    team_b_cluster = cluster_members(team_b, k, p);
                    
                    team_a_average = five_cluster_averages{p,team_b_cluster}(team_a,:);
                    team_b_average = five_cluster_averages{p,team_a_cluster}(team_b,:);
                    PCAC_feature_vectors(index, :, p, k, season) = team_a_average - team_b_average;
                else
                    team_a_cluster = cluster_members(team_a, k, p);
                    team_b_cluster = cluster_members(team_b, k, p);
                    
                    team_a_average = ten_cluster_averages{p,team_b_cluster}(team_a,:);
                    team_b_average = ten_cluster_averages{p,team_a_cluster}(team_b,:);
                    PCAC_feature_vectors(index, :, p, k, season) = team_a_average - team_b_average;
                end
            end
        end
        
        
        % update running averages
        running_average(team_a, :) = Calc_Running_Average( games(team_a, 4:28, :), games_played(team_a));
        running_average(team_b, :) = Calc_Running_Average( games(team_b, 4:28, :), games_played(team_b));
        
        % update decaying averages
        for a = 1:10
            decaying_average(team_a, :, a) = Calc_Decaying_Average(games(team_a, 4:28, :), games_played(team_a), alpha(a));
            decaying_average(team_b, :, a) = Calc_Decaying_Average(games(team_b, 4:28, :), games_played(team_b), alpha(a));
        end
        
        % update home and away averages, team_a is always home team
        h_a_average(team_a, :, 1) = Calc_HA_Average( games(team_a, :, :), games_played(team_a), 1);
        h_a_average(team_b, :, 2) = Calc_HA_Average( games(team_b, :, :), games_played(team_b), 0);
        
        % update clusters and averages against those clusters
        for p = 1:length(PCA_comps)
            [coef, score] = pca(running_average, 'NumComponents',PCA_comps(p));
            for k = 1:length(K)
                [cluster_members(:,k,p),cluster_centers{p,k}] = kmeans(score, [], 'Start', cluster_centers{p,k});
            end
        end
        two_cluster_averages = Calc_Cluster_Averages(games, games_played, two_cluster_averages, cluster_members, running_average);
        three_cluster_averages = Calc_Cluster_Averages(games, games_played, three_cluster_averages, cluster_members, running_average);
        five_cluster_averages = Calc_Cluster_Averages(games, games_played, five_cluster_averages, cluster_members, running_average);
        ten_cluster_averages = Calc_Cluster_Averages(games, games_played, ten_cluster_averages, cluster_members, running_average);
    end
    
    games_played = zeros(18, 1);
    games = zeros(18,28,27);
    
end

save FeatureVectors.mat RA_feature_vectors DA_feature_vectors HA_feature_vectors PCAC_feature_vectors winner